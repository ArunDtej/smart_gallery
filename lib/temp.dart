import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_gallery/utils/permission_manager.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

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

  Future<void> asycInit() async {
    await PhotoManager.requestPermissionExtend();
    paths = await PhotoManager.getAssetPathList();
    setState(() {}); // Trigger a rebuild once paths are loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thumbnails')),
      body: RefreshIndicator(
        onRefresh: asycInit, // Trigger the async function on pull down
        child: paths == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children:
                      paths!.map((path) => buildAlbumThumbnail(path)).toList(),
                ),
              ),
      ),
    );
  }

  Widget buildAlbumThumbnail(AssetPathEntity path) {
    return FutureBuilder<List<AssetEntity>>(
      future: path.getAssetListPaged(page: 0, size: 1),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const ListTile(
            title: Text('No Image'),
          );
        } else {
          // Fetch the thumbnail data for the first asset
          var thumbnailDataFuture = snapshot.data![0].thumbnailData;

          return FutureBuilder<Uint8List?>(
            future: thumbnailDataFuture,
            builder: (context, thumbnailSnapshot) {
              if (thumbnailSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('Loading thumbnail...'),
                );
              } else if (thumbnailSnapshot.hasError ||
                  thumbnailSnapshot.data == null) {
                return const ListTile(
                  title: Text('No Image'),
                );
              } else {
                return InkWell(
                  onTap: () {
                    print('my_logs hello');
                  },
                  child: ListTile(
                    leading: Image.memory(
                      thumbnailSnapshot.data!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(path.name),
                  ),
                );
              }
            },
          );
        }
      },
    );
  }
}
