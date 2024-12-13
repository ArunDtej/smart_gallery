import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_gallery/utils/permission_manager.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

import 'package:image/image.dart' as img;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<AssetPathEntity>? paths;

  @override
  void initState() {
    super.initState();
    asycInit();
  }

  void asycInit() async {
    await PermissionManager.requestPhotoPermissions();

    paths = await PhotoManager.getAssetPathList();
    print('my_logs: $paths');
    return;
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

// final ImagePicker picker = ImagePicker();

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   XFile? image;
//   dynamic interpreter;
//   String progress = '0';

//   @override
//   void initState() {
//     initCustomModules();
//     super.initState();
//   }

//   void initCustomModules() async {
//     final gpuDelegateV2 = GpuDelegateV2(
//         options: GpuDelegateOptionsV2(
//       isPrecisionLossAllowed: true,
//     ));

//     var interpreterOptions = InterpreterOptions()..useNnApiForAndroid = true;

//     // var interpreterOptions = InterpreterOptions()..addDelegate(gpuDelegateV2);

//     interpreter = await Interpreter.fromAsset(
//         'assets/models/mobilenet_v3_embedder.tflite',
//         options: interpreterOptions);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: getBody(),
//       ),
//     );
//   }

//   Widget getBody() {
//     return Center(
//       child: Container(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           children: [
//             InkWell(
//               onTap: () async {
//                 if (await PermissionManager.requestPhotoPermissions()) {
//                   final selectedImage =
//                       await picker.pickImage(source: ImageSource.gallery);

//                   if (selectedImage != null) {
//                     setState(() {
//                       image = selectedImage;
//                       preprocessImage(selectedImage);
//                     });
//                   }
//                 }
//               },
//               onLongPress: () {
//                 setState(() {
//                   image = null;
//                 });
//               },
//               child: Column(children: [
//                 (image == null)
//                     ? const Icon(Icons.image, size: 100)
//                     : SizedBox(
//                         width: 100,
//                         height: 100,
//                         child: Image.file(
//                           File(image!.path),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//               ]),
//             ),
//             Text('Progress'),
//             Text(progress)
//           ],
//         ),
//       ),
//     );
//   }

//   Future<Uint8List> preprocessImage(XFile file, {int inputSize = 224}) async {
//     Uint8List imageData = await file.readAsBytes();

//     img.Image? imageDecoded = img.decodeImage(imageData);

//     if (imageDecoded == null) {
//       throw Exception("Failed to decode image");
//     }

//     img.Image resizedImage =
//         img.copyResize(imageDecoded, width: inputSize, height: inputSize);

//     return imageToFloatList(resizedImage);
//   }

//   Future<Uint8List> imageToFloatList(img.Image image) async {
//     List<double> floatValues = [];

//     for (int y = 0; y < image.height; y++) {
//       for (int x = 0; x < image.width; x++) {
//         img.Pixel pixel = image.getPixel(x, y);

//         floatValues.add(pixel.r / 255.0);
//         floatValues.add(pixel.g / 255.0);
//         floatValues.add(pixel.b / 255.0);
//       }
//     }

//     Float32List floatList = Float32List.fromList(floatValues);
//     var inp = floatList.reshape([1, 224, 224, 3]);

//     var output = List.filled(1 * 1024, 0.0).reshape([1, 1024]);
//     for (int i = 0; i < 200; i++) {
//       if (i % 20 == 0) {
//         await Future.delayed(Duration(milliseconds: 5));
//         setState(() {
//           progress = i.toString();
//         });
//       }

//       interpreter.run(inp, output);
//     }

//     print("Model OP: $output");

//     return floatList.buffer.asUint8List();
//   }
// }
