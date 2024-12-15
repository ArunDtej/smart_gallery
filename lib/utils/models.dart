import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class Model {
  Interpreter? _interpreter;
  String progress = '0';

  Future<void> initModel() async {
    final gpuDelegateV2 = GpuDelegateV2(
      options: GpuDelegateOptionsV2(
        isPrecisionLossAllowed: true,
      ),
    );

    var interpreterOptions = InterpreterOptions()..addDelegate(gpuDelegateV2);

    _interpreter = await Interpreter.fromAsset(
      'assets/models/mobilenet_v3_embedder.tflite',
      options: interpreterOptions,
    );
  }

  Future<Uint8List> preprocessImage(Uint8List bytes,
      {int inputSize = 224}) async {
    img.Image? imageDecoded = img.decodeImage(Uint8List.fromList(bytes));

    if (imageDecoded == null) {
      throw Exception("Failed to decode image");
    }

    img.Image resizedImage =
        img.copyResize(imageDecoded, width: inputSize, height: inputSize);

    return imageToFloatList(resizedImage);
  }

  Future<Uint8List> imageToFloatList(img.Image image) async {
    List<double> floatValues = [];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        img.Pixel pixel = image.getPixel(x, y);

        floatValues.add(pixel.r / 255.0);
        floatValues.add(pixel.g / 255.0);
        floatValues.add(pixel.b / 255.0);
      }
    }

    Float32List floatList = Float32List.fromList(floatValues);
    var inp = floatList.reshape([1, 224, 224, 3]);

    return floatList.buffer.asUint8List();
  }

  Future<List<List<double>>> predictBatch(List<Uint8List> input) async {
    List<List<double>> results = [];

    for (var imageBytes in input) {
      var output = List.filled(1 * 1024, 0.0).reshape([1, 1024]);
      _interpreter?.run(imageBytes, output);
      results.add(output[0]);
    }

    return results;
  }

  String getProgress() {
    return progress;
  }

  void close() {
    _interpreter?.close();
  }
}
