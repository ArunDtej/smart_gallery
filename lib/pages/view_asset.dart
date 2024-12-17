import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:open_file/open_file.dart';
import 'package:photo_view/photo_view.dart';
import 'package:smart_gallery/pages/search_page.dart';
import 'dart:math';
import 'dart:async';

import 'package:smart_gallery/pages/view_images.dart';
import 'package:smart_gallery/utils/common_utils.dart';
import 'package:smart_gallery/utils/hive_singleton.dart';
import 'package:smart_gallery/utils/similarity_model.dart';

class ViewAsset extends StatefulWidget {
  final int index;
  final AssetPathEntity folderPath;

  const ViewAsset({super.key, required this.index, required this.folderPath});

  @override
  _ViewAssetState createState() => _ViewAssetState();
}

class _ViewAssetState extends State<ViewAsset> {
  bool isVideo = false;
  bool isImage = false;
  bool isLoading = true;
  bool _showDetails = false;
  Uint8List? imageBytes;
  AssetEntity? currentAsset;
  int currentIndex = 0;
  String? assetFilename;
  String? assetResolution;
  String? assetSize;
  DateTime? assetCreationDate;
  Timer? _hideDetailsTimer;

  final double swipeThreshold = 50.0;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.index;
    _loadAsset();
  }

  @override
  void dispose() {
    _hideDetailsTimer?.cancel();
    super.dispose();
  }

  void _loadAsset() async {
    setState(() {
      isLoading = true;
      isVideo = false;
      isImage = false;
      imageBytes = null;
      assetFilename = null;
      assetResolution = null;
      assetSize = null;
      assetCreationDate = null;
    });

    final List<AssetEntity> assets = await widget.folderPath
        .getAssetListRange(start: currentIndex, end: currentIndex + 1);

    if (assets.isNotEmpty) {
      currentAsset = assets.first;
      assetFilename = await currentAsset?.titleAsync;
      assetResolution = '${currentAsset?.width} x ${currentAsset?.height}';
      assetCreationDate = currentAsset?.createDateTime;

      final File? file = await currentAsset?.originFile;
      if (file != null) {
        assetSize = _formatBytes(file.lengthSync());
      }

      if (currentAsset!.type == AssetType.video) {
        setState(() {
          isVideo = true;
        });
        final videoThumbnail = await currentAsset!
            .thumbnailDataWithSize(const ThumbnailSize(800, 800));
        setState(() {
          imageBytes = videoThumbnail;
          isLoading = false;
        });
      } else if (currentAsset!.type == AssetType.image) {
        setState(() {
          isImage = true;
        });
        final imageData = await currentAsset!
            .thumbnailDataWithSize(const ThumbnailSize(800, 800));
        setState(() {
          imageBytes = imageData;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatBytes(int bytes, [int decimals = 2]) {
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  Future<void> _openVideo(File videoFile) async {
    final result = await OpenFile.open(videoFile.path);
    if (result.type != ResultType.done) {
      print('Could not open the video. Error: ${result.message}');
    }
    setState(() {
      isLoading = false;
    });
  }

  void _previousAsset() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
      _loadAsset();
    }
  }

  void _nextAsset() async {
    int size = await widget.folderPath.assetCountAsync;
    if (currentIndex < size - 1) {
      setState(() {
        currentIndex++;
      });
      _loadAsset();
    }
  }

  void _onTap() {
    setState(() {
      _showDetails = !_showDetails;
    });

    if (_showDetails) {
      _hideDetailsTimer?.cancel();
      _hideDetailsTimer = Timer(const Duration(seconds: 3), () {
        setState(() {
          _showDetails = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GestureDetector(
            onTap: _onTap,
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity!.abs() > swipeThreshold) {
                if (details.primaryVelocity! > 0) {
                  _previousAsset();
                } else if (details.primaryVelocity! < 0) {
                  _nextAsset();
                }
              }
            },
            child: Center(
              child: isLoading
                  ? loadingAnimation
                  : isImage && imageBytes != null
                      ? PhotoView(
                          imageProvider: MemoryImage(imageBytes!),
                        )
                      : isVideo && imageBytes != null
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.memory(imageBytes!),
                                IconButton(
                                  icon: const Icon(
                                    Icons.play_circle_fill,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    currentAsset?.originFile.then((videoFile) {
                                      if (videoFile != null) {
                                        _openVideo(videoFile);
                                      }
                                    });
                                  },
                                ),
                              ],
                            )
                          : const Center(child: Text('Unsupported asset type')),
            ),
          ),
          if (_showDetails && !isLoading && currentAsset != null)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filename: $assetFilename',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.settings,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Resolution: $assetResolution',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.file_present,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Size: $assetSize',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Created: ${assetCreationDate?.toLocal().toString().split('.')[0]}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_showDetails && !isLoading) toolbar(),
        ],
      ),
    );
  }

  Widget toolbar() {
    double iconSize = 20;
    return Positioned(
      top: 40,
      right: 16,
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.black.withOpacity(0.7),
        child: Column(
          spacing: 6,
          children: [
            IconButton(
              iconSize: iconSize,
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                searchForSimilar();
              },
            ),
          ],
        ),
      ),
    );
  }

  void searchForSimilar() {
    if (currentAsset == null ||
        (currentAsset?.orientatedHeight ?? 3001) > 3000 ||
        (currentAsset?.orientatedWidth ?? 3001) > 3000 ||
        currentAsset?.type != AssetType.image) {
      CommonUtils.showSnackbar(
          context: context,
          message:
              "Image too large or not a valid image, can't perform search!");
      return;
    }
    Box embeddingBox = HiveService.instance.getEmbeddingsBox();
    Map<dynamic, dynamic> rawEmbeddings = embeddingBox.get('rawEmbeddings');
    String filePath = '${currentAsset?.relativePath}${currentAsset?.title}';

    if (rawEmbeddings.keys.contains(filePath)) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SearchPage(
                  searchQuery: null,
                  pathAsset: widget.folderPath,
                  searchVector: rawEmbeddings[filePath])));
    } else {
      CommonUtils.showSnackbar(
          context: context,
          message:
              "Image has not been encoded, go back and generate encodings in the previous page!");
      return;
    }
  }
}
