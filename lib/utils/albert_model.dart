// import 'dart:convert';
// import 'dart:io';
// // import 'dart:typed_data';
// import 'package:flutter/services.dart';
// import 'package:onnxruntime/onnxruntime.dart';
// // import 'package:photo_manager/photo_manager.dart';
// // import 'package:smart_gallery/utils/hive_singleton.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';

// class AlbertModel {
//   String progress = '0';
//   OrtSession? session;
//   OrtRunOptions? runOptions;
//   Map<String, int>? vocab;
//   Map<String, String>? specialTokens;

//   Future<void> initModel() async {
//     OrtEnv.instance.init();
//     final sessionOptions = OrtSessionOptions();
//     const assetFileName = 'assets/models/albert_model.onnx';
//     final rawAssetFile = await rootBundle.load(assetFileName);
//     final bytes = rawAssetFile.buffer.asUint8List();
//     session = OrtSession.fromBuffer(bytes, sessionOptions);
//     runOptions = OrtRunOptions();
//     loadVocab('assets/models/tokenizer.json');
//   }

//   Future<List<double>> getTextEmbeddings(String searchQuery) async {
//     String cleanedText = searchQuery
//         .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
//         .replaceAll(RegExp(r'\s+'), ' ')
//         .trim();

//     Map<String, dynamic> tokens =
//         await tokenizeText(cleanedText, vocab!, specialTokens!);

//     // final List<int> inputIds = [101, 2009, 2003, 1037, 2742, 102];
//     // final List<int> attentionMask = [1, 1, 1, 1, 1, 1];

//     final List<int> inputIds = tokens['input_ids'];
//     final List<int> attentionMask = tokens['attention_mask'];

//     final inputShape = [1, inputIds.length];
//     final maskShape = [1, attentionMask.length];

//     final inputTensor = OrtValueTensor.createTensorWithDataList(
//       inputIds.map((e) => e.toInt()).toList(),
//       inputShape,
//     );

//     final attentionMaskTensor = OrtValueTensor.createTensorWithDataList(
//       attentionMask.map((e) => e.toInt()).toList(),
//       maskShape,
//     );

//     final inputs = {
//       'input_ids': inputTensor,
//       'attention_mask': attentionMaskTensor,
//     };

//     print("Input Tensor: ${inputIds}, Shape: ${inputShape}");
//     print("Attention Mask: ${attentionMask}, Shape: ${maskShape}");

//     final outputs = await session?.runAsync(runOptions!, inputs);

//     print("successfully called the predictions");

//     inputTensor.release();
//     attentionMaskTensor.release();

//     final result = outputs?[0]?.value as List<List<double>>?;
//     final embeddings = result?.first ?? [];

//     outputs?.forEach((element) {
//       element?.release();
//     });

//     print(
//         'ONNX predictions result: ${embeddings.shape}, ${embeddings.sublist(0, 10)}');
//     return embeddings;
//   }

//   Future<Map<String, dynamic>> tokenizeText(
//       String text, Map<String, int> vocab, Map<String, String> specialTokens,
//       {int maxLength = 24}) async {
//     List<String> words = text.split(" ");
//     List<int> tokenIds = [];

//     for (String word in words) {
//       String lowerWord = word.toLowerCase();
//       if (vocab.containsKey(lowerWord)) {
//         tokenIds.add(vocab[lowerWord]!);
//       } else {
//         tokenIds.add(vocab[specialTokens['unk_token']] ?? 100);
//       }
//     }

//     tokenIds.insert(0, vocab[specialTokens['cls_token']] ?? 101);
//     tokenIds.add(vocab[specialTokens['sep_token']] ?? 102);

//     while (tokenIds.length < maxLength) {
//       tokenIds.add(vocab[specialTokens['pad_token']] ?? 0);
//     }
//     tokenIds = tokenIds.sublist(0, maxLength);

//     List<int> tokenTypeIds = List<int>.filled(tokenIds.length, 0);

//     List<int> attentionMask = tokenIds
//         .map((token) =>
//             token != (vocab[specialTokens['pad_token']] ?? 0) ? 1 : 0)
//         .toList();

//     return {
//       "input_ids": tokenIds,
//       "token_type_ids": tokenTypeIds,
//       "attention_mask": attentionMask,
//     };
//   }

//   Future<void> loadVocab(String filePath) async {
//     // final file = File(filePath);
//     final content = await rootBundle.loadString(filePath);
//     // final content = await file.readAsString();
//     final Map<String, dynamic> jsonContent = jsonDecode(content);
//     vocab = Map<String, int>.from(jsonContent['vocab']);
//     specialTokens = Map<String, String>.from(jsonContent['special_tokens']);
//   }

//   void dispose() {
//     OrtEnv.instance.release();
//   }
// }
