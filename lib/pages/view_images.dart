import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:photo_manager/photo_manager.dart';

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
  double previousDelta = 0.0; // Store previous drag delta
  double dragThreshold =
      5.0; // Threshold for sensitivity, smaller = more sensitive

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
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(7),
                child: const Icon(Icons.arrow_back_ios_new, size: 20),
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
      ),
      body: totalAssets == 0
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onHorizontalDragUpdate: (details) {
                double delta = details.primaryDelta!;

                // Check if the delta is large enough to trigger the update
                if (delta.abs() > dragThreshold) {
                  // If swiping to the right, increase the grid count
                  if (delta < 0 && crossAxisCount < 5) {
                    setState(() {
                      crossAxisCount++;
                    });
                  }
                  // If swiping to the left, decrease the grid count
                  else if (delta > 0 && crossAxisCount > 1) {
                    setState(() {
                      crossAxisCount--;
                    });
                  }
                }

                // Store the previous delta value for next comparison
                previousDelta = delta;
              },
              child: getGridBody(),
            ),
    );
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

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  void _loadThumbnail() async {
    final asset = await widget.folderPath
        .getAssetListRange(start: widget.index, end: widget.index + 1);
    final firstAsset = asset.first;

    setState(() {
      isVideo = firstAsset.type == AssetType.video;
    });

    final thumbnailData =
        await firstAsset.thumbnailDataWithSize(const ThumbnailSize(300, 300));
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

    return Container(
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
    );
  }

  @override
  bool get wantKeepAlive => true;
}
