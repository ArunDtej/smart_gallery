import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:open_file/open_file.dart';
import 'dart:math';
import 'dart:async';

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
  bool _showDetails = false; // Tracks whether the details are visible
  Uint8List? imageBytes;
  AssetEntity? currentAsset;
  int currentIndex = 0;
  String? assetFilename;
  String? assetResolution;
  String? assetSize;
  DateTime? assetCreationDate;
  Timer? _hideDetailsTimer; // Timer to hide the details after a few seconds

  @override
  void initState() {
    super.initState();
    currentIndex = widget.index;
    _loadAsset();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
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

      // Set common metadata
      assetFilename = await currentAsset?.titleAsync;
      assetResolution = '${currentAsset?.width} x ${currentAsset?.height}';
      assetCreationDate = currentAsset?.createDateTime;

      // Get file size
      final File? file = await currentAsset?.originFile;
      if (file != null) {
        assetSize = _formatBytes(file.lengthSync());
      }

      if (currentAsset!.type == AssetType.video) {
        setState(() {
          isVideo = true;
        });

        final videoThumbnail = await currentAsset!.thumbnailDataWithSize(
          const ThumbnailSize(800, 800),
        );
        setState(() {
          imageBytes = videoThumbnail;
        });

        setState(() {
          isLoading = false;
        });
      } else if (currentAsset!.type == AssetType.image) {
        setState(() {
          isImage = true;
        });

        final imageData = await currentAsset!.thumbnailDataWithSize(
          const ThumbnailSize(800, 800),
        );
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

  void _nextAsset() {
    setState(() {
      currentIndex++;
    });
    _loadAsset();
  }

  /// Handle tap to show details and start the timer to hide them
  void _onTap() {
    setState(() {
      _showDetails = !_showDetails; // Toggle visibility
    });

    // If showing details, set a timer to hide them after a few seconds
    if (_showDetails) {
      _hideDetailsTimer?.cancel(); // Cancel any previous timer
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
            onTap: _onTap, // Detect tap to show/hide details
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                _previousAsset(); // Swipe right
              } else if (details.primaryVelocity! < 0) {
                _nextAsset(); // Swipe left
              }
            },
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : isImage && imageBytes != null
                      ? Image.memory(
                          imageBytes!,
                          fit: BoxFit.contain,
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
              left: 16,
              right: 16,
              child: Card(
                color: Colors.black.withOpacity(0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
