import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_gallery/utils/hive_singleton.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class TextTransformerModel {
  Interpreter? _interpreter;
  IsolateInterpreter? isolateInterpreter;
  String progress = '0';

  Future<void> initModel() async {
    // var interpreterOptions = InterpreterOptions()..useNnApiForAndroid = true;
    // interpreterOptions.threads = 3;
    // final gpuDelegateV2 = GpuDelegateV2(
    //     options: GpuDelegateOptionsV2(isPrecisionLossAllowed: false));

    // var interpreterOptions = InterpreterOptions()..addDelegate(gpuDelegateV2);

    _interpreter = await Interpreter.fromAsset(
      'assets/models/text_transformer_model.tflite',
      // options: interpreterOptions,
    );
  }

  Future<List<double>> getTextEmbeddings(String searchQuery) async {
    String cleanedText = searchQuery
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    List<double> outputs = List<double>.filled(1024, 0);

    var inputTensor = _interpreter!.getInputTensor(0);

    // if (inputTensor.type != TfLiteType.kTfLiteString) {
    //   print("The model does not accept raw text as input.");
    // }

    _interpreter!.run([0, 2], outputs);
    return outputs;
  }
}
