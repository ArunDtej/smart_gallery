import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_gallery/pages/search_page.dart';
import 'package:smart_gallery/pages/view_asset.dart';
import 'package:smart_gallery/utils/common_utils.dart';
import 'package:smart_gallery/utils/hive_singleton.dart';
import 'package:smart_gallery/utils/models.dart';

const loadingAnimation = Center(
  child: SpinKitFadingCircle(
    color: Colors.blue,
    size: 22.0,
  ),
);

class Viewimages extends StatefulWidget {
  final AssetPathEntity folderPath;

  const Viewimages({super.key, required this.folderPath});

  @override
  State<Viewimages> createState() => _ViewimagesState();
}

class _ViewimagesState extends State<Viewimages> {
  int totalAssets = 0;
  int crossAxisCount = 4;
  double dragThreshold = 8.0;
  double previousDelta = 0.0;
  bool showProgressBar = false;
  double progressValue = 0;

  @override
  void initState() {
    super.initState();
    loadTotalAssets();
  }

  void loadTotalAssets() async {
    final total = await widget.folderPath.assetCountAsync;
    setState(() {
      totalAssets = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    String albumName = widget.folderPath.name;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(7),
                child: Icon(Icons.arrow_back_ios_new, size: 20),
              ),
            ),
            Expanded(
              child: Text(
                albumName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SearchPage(
                            searchQuery: null,
                            pathAsset: widget.folderPath,
                            searchVector: null)));
              },
              icon: const Icon(Icons.search)),
          IconButton(
            onPressed: () {
              CommonUtils.showDialogBox(
                  context: context,
                  title: "Generate labels?",
                  content:
                      "Generate labels for images in this folder locally to enable search. This one-time process usually takes just a few minutes.",
                  onConfirm: () async {
                    Model model = HiveService.instance.getModel();
                    HiveService.instance.isBroken = false;
                    if (HiveService.instance.isModelRunning) {
                      CommonUtils.showSnackbar(
                          context: context,
                          message:
                              "Model is already running in the background!, please try again after the current task has been executed!");
                      return;
                    }
                    model.predictFolder(widget.folderPath, context);
                    CommonUtils.showSnackbar(
                        context: context,
                        message:
                            "Generating encodings for images in the background, we will notify you once we are done!");

                    setState(() {
                      showProgressBar = true;
                    });
                    trackProgressbar();
                  },
                  onCancel: () {});
            },
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
        ],
      ),
      body: totalAssets == 0
          ? const Center(child: loadingAnimation)
          : GestureDetector(
              onHorizontalDragUpdate: (details) {
                _handleSwipe(details.primaryDelta!);
              },
              child: Stack(
                children: [
                  getGridBody(),
                  if (showProgressBar) ...[
                    AbsorbPointer(
                      absorbing: true,
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 45),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                loadingAnimation,
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 25),
                                  child: LinearProgressIndicator(
                                    value: progressValue,
                                    backgroundColor: Colors.grey[200],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.blue),
                                    minHeight: 5,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                      "Generating encodings. Please stay on this page and avoid pressing the back button or navigating away. You can keep the app running in the background, but ensure not to go back or close the page until the process is complete."),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  void _handleSwipe(double delta) {
    if (delta.abs() > dragThreshold) {
      setState(() {
        if (delta < 0 && crossAxisCount < 5) {
          crossAxisCount++;
        } else if (delta > 0 && crossAxisCount > 1) {
          crossAxisCount--;
        }
      });
    }
    previousDelta = delta;
  }

  Future<void> trackProgressbar() async {
    Timer.periodic(const Duration(seconds: 2), (timer) {
      print(
          'my_logs printing ${HiveService.instance.generateEmbeddingsProgress}');
      if (HiveService.instance.generateEmbeddingsProgress < 1) {
        setState(() {
          progressValue = HiveService.instance.generateEmbeddingsProgress;
        });
      } else {
        setState(() {
          progressValue = 1;
          HiveService.instance.generateEmbeddingsProgress = 0;
          showProgressBar = false;
          timer.cancel();
        });
      }
    });
    return;
  }

  Widget getGridBody() {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: totalAssets,
      itemBuilder: (context, index) {
        return GridItem(index: index, folderPath: widget.folderPath);
      },
    );
  }

  @override
  void dispose() {
    HiveService.instance.isBroken = true;
    HiveService.instance.isModelRunning = false;
    super.dispose();
  }
}

class GridItem extends StatefulWidget {
  final int index;
  final AssetPathEntity folderPath;

  const GridItem({super.key, required this.index, required this.folderPath});

  @override
  State<GridItem> createState() => _GridItemState();
}

class _GridItemState extends State<GridItem>
    with AutomaticKeepAliveClientMixin {
  Uint8List? imageBytes;
  bool isVideo = false;
  AssetEntity? firstAsset;
  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  void _loadThumbnail() async {
    final asset = await widget.folderPath
        .getAssetListRange(start: widget.index, end: widget.index + 1);
    firstAsset = asset.first;

    setState(() {
      isVideo = firstAsset?.type == AssetType.video;
    });

    final thumbnailData =
        await firstAsset?.thumbnailDataWithSize(const ThumbnailSize(224, 224));
    setState(() {
      imageBytes = thumbnailData;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final placeholderColor =
        theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ViewAsset(index: widget.index, folderPath: widget.folderPath),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withOpacity(0.5),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            color: placeholderColor,
            child: Stack(
              children: [
                imageBytes == null
                    ? loadingAnimation
                    : Image.memory(
                        imageBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                if (isVideo)
                  const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
