import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_gallery/pages/view_asset.dart';
import 'package:smart_gallery/pages/view_images.dart';
import 'package:smart_gallery/utils/hive_singleton.dart';
import 'package:smart_gallery/utils/selectable_gridview.dart';
import 'package:smart_gallery/utils/similarity_model.dart';

class SearchPage extends StatefulWidget {
  final String? searchQuery;
  final AssetPathEntity pathAsset;
  final List<double>? searchVector;
  const SearchPage(
      {super.key,
      required this.searchQuery,
      required this.pathAsset,
      required this.searchVector});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late List<double>? _searchVector;
  late String? _searchQuery;
  bool isLoading = true;
  List<int> _searchIndices = [];

  @override
  void initState() {
    _searchQuery = widget.searchQuery;
    _searchVector = widget.searchVector;
    setSearchEmbeddings(_searchQuery);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios_sharp)),
        title: TextField(
          onChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            suffixIcon: IconButton(
                onPressed: () async {
                  var result = await HiveService.instance.albertModel
                      .getTextEmbeddings(_searchQuery!);
                  setState(() {
                    // _searchVector = result;
                  });
                },
                icon: const Icon(Icons.search)),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(4),
        child: (_searchVector != null)
            ? (isLoading ? loadingAnimation : getGridBody())
            : const Center(
                child: Text(
                  "No search query provided,\n type something in the search bar!",
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }

  Future<void> setSearchEmbeddings(String? searchQuery) async {
    SimilarityModel similarityModel = HiveService.instance.similarityModel;

    if (_searchVector != null) {
      _searchIndices =
          await similarityModel.searchSimilar(widget.pathAsset, _searchVector!);
    } else {}

    if (_searchIndices.isNotEmpty) {
      HiveService.instance.searchIndices = _searchIndices;
      setState(() {
        isLoading = false;
      });
    }

    return;
  }

  Widget getGridBody() {
    return SelectableGridview(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _searchIndices.length,
      itemBuilder: (context, index) {
        return GridItem(
            searchAssetIndex: index,
            context: context,
            pathEntity: widget.pathAsset);
      },
    );
  }
}

class GridItem extends StatefulWidget {
  final int searchAssetIndex;
  final BuildContext context;
  final AssetPathEntity pathEntity;

  const GridItem(
      {super.key,
      required this.searchAssetIndex,
      required this.context,
      required this.pathEntity});

  @override
  State<GridItem> createState() => _GridItemState();
}

class _GridItemState extends State<GridItem>
    with AutomaticKeepAliveClientMixin {
  Uint8List? imageBytes;

  late AssetEntity searchAsset;

  @override
  void initState() {
    _loadThumbnail();
    super.initState();
  }

  void _loadThumbnail() async {
    try {
      final asset = await widget.pathEntity.getAssetListRange(
          start: HiveService.instance.searchIndices[widget.searchAssetIndex],
          end: HiveService.instance.searchIndices[widget.searchAssetIndex] + 1);
      searchAsset = asset.first;

      final thumbnailData = await searchAsset.thumbnailData;

      setState(() {
        imageBytes = thumbnailData;
      });
    } catch (e) {
      _handleThumbnailError();
    }
  }

  void _handleThumbnailError() {
    setState(() {
      imageBytes = null;
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
            builder: (context) => ViewAsset(
              index: widget.searchAssetIndex,
              folderPath: widget.pathEntity,
              indices: HiveService.instance.searchIndices,
            ),
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
