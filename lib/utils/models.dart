import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_gallery/main.dart';
import 'package:smart_gallery/utils/hive_singleton.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Model {
  Interpreter? _interpreter;
  IsolateInterpreter? isolateInterpreter;
  String progress = '0';

  Future<void> initModel() async {
    var interpreterOptions = InterpreterOptions()..useNnApiForAndroid = true;

    _interpreter = await Interpreter.fromAsset(
      'assets/models/mobilenet_v3_embedder.tflite',
      options: interpreterOptions,
    );
  }

  Future<Float32List> preprocessImage(Uint8List imageBytes) async {
    img.Image? imageDecoded = img.decodeImage(Uint8List.fromList(imageBytes));
    if (imageDecoded == null) {
      throw Exception("Failed to decode image");
    }

    img.Image resizedImage =
        img.copyResize(imageDecoded, width: 224, height: 224);
    // img.Image resizedImage = imageDecoded;

    List<double> floatValues = [];
    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        img.Pixel pixel = resizedImage.getPixel(x, y);
        floatValues.add(pixel.r / 255.0);
        floatValues.add(pixel.g / 255.0);
        floatValues.add(pixel.b / 255.0);
      }
    }

    return Float32List.fromList(floatValues);
  }

  Future<List<dynamic>> predictBatch(List<Float32List> batchInput) async {
    List<Object> inputList = [];
    for (var image in batchInput) {
      inputList.add(image.reshape([224, 224, 3]));
    }

    List<Object> inputs = inputList;

    List<dynamic> oup =
        List<double>.from(List<double>.filled(1024 * inputs.length, 0.0))
            .reshape([inputs.length, 1024]);

    _interpreter?.run(inputs, oup);

    return oup;
  }

  Future<void> predictFolder(
      AssetPathEntity folderPath, BuildContext context) async {
    HiveService.instance.isModelRunning = true;
    Box embeddingBox = HiveService.instance.getEmbeddingsBox();
    Map<dynamic, dynamic> rawEmbeddings = embeddingBox.get('rawEmbeddings');
    var existingImages = rawEmbeddings.keys;

    List paths = [];

    try {
      int page = 0;
      bool hasMoreAssets = true;
      int batchSize = 25;
      int total = 0;
      int maxImageSize = HiveService.instance.resolutionLimit;

      while (hasMoreAssets) {
        List<AssetEntity> assets =
            await folderPath.getAssetListPaged(page: page, size: 25);
        paths.clear();

        print('Processing page $page with ${assets.length} assets.');

        if (assets.isNotEmpty) {
          List<Float32List> batchInput = [];

          for (var asset in assets) {
            String filePath = '${asset.relativePath}${asset.title}';
            try {
              if (asset.type == AssetType.image &&
                  asset.orientatedHeight < maxImageSize &&
                  asset.orientatedWidth < maxImageSize &&
                  !existingImages.contains(filePath)) {
                paths.add(filePath);

                // var byteData = await asset.originBytes;
                var byteData = await asset
                    .thumbnailDataWithSize(const ThumbnailSize(224, 224));

                if (byteData != null) {
                  var decodedImage =
                      img.decodeImage(Uint8List.fromList(byteData));
                  if (decodedImage == null) {
                    continue;
                  }

                  Float32List preprocessedImage =
                      await preprocessImage(byteData);
                  batchInput.add(preprocessedImage);

                  if (batchInput.length == batchSize) {
                    List<dynamic> results = await _processBatch(batchInput);
                    total += batchInput.length;

                    assignLabels(paths, results, rawEmbeddings);

                    batchInput.clear();
                    paths.clear();
                  }

                  decodedImage = null;
                }
                byteData = null;
              }
            } catch (e) {
              print('Error processing asset: $e');
            }
          }

          if (batchInput.isNotEmpty) {
            List<dynamic> results = await _processBatch(batchInput);
            total += batchInput.length;
            assignLabels(paths, results, rawEmbeddings);

            batchInput.clear();
            paths.clear();
          }

          page++;
        } else {
          hasMoreAssets = false;
        }
      }

      await _showNotification(
        'Folder images Encoding Complete.',
        'Processed $total new images successfully!',
      );
      embeddingBox.put('rawEmbeddings', rawEmbeddings);

      HiveService.instance.isModelRunning = false;
    } catch (e) {
      print('Error during folder prediction: $e');
    }
  }

  Future<List<dynamic>> _processBatch(List<Float32List> batchInput) async {
    try {
      List<dynamic> predictions = await predictBatch(batchInput);
      return predictions;
    } catch (e) {
      print('Error during batch prediction: $e');
      return [[]];
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'prediction_channel_id',
      'Prediction Notifications',
      channelDescription: 'Notifications for prediction tasks',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
    );
  }

  void assignLabels(
      List paths, List<dynamic> results, Map<dynamic, dynamic> rawEmbeddings) {
    for (int i = 0; i < paths.length; i++) {
      rawEmbeddings[paths[i]] = results[i];
    }
  }
}
