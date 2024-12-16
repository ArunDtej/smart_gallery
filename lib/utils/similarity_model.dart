import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_gallery/main.dart';
import 'package:smart_gallery/utils/hive_singleton.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class SimilarityModel {
  Interpreter? _interpreter;
  IsolateInterpreter? isolateInterpreter;
  String progress = '0';

  Future<void> initModel() async {
    var interpreterOptions = InterpreterOptions()..useNnApiForAndroid = true;

    _interpreter = await Interpreter.fromAsset(
      'assets/models/cosine_similarity_model.tflite',
      options: interpreterOptions,
    );
    final isolateInterpreter =
        await IsolateInterpreter.create(address: _interpreter!.address);
  }
}
