import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_gallery/pages/view_asset.dart';
import 'package:smart_gallery/pages/view_images.dart';
import 'package:smart_gallery/utils/common_utils.dart';
import 'package:smart_gallery/utils/hive_singleton.dart';
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
  List<AssetEntity> _searchAssets = [];

  @override
  void initState() {
    _searchQuery = widget.searchQuery;
    _searchVector = widget.searchVector;
    if (_searchVector == null) {
      setSearchEmbeddings(_searchQuery);
    }
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
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            suffixIcon: Icon(Icons.search),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(12),
        child: isLoading ? loadingAnimation : getGridBody(),
      ),
    );
  }

  Future<void> setSearchEmbeddings(String? searchQuery) async {
    // _searchVector = [];

    SimilarityModel similarityModel = HiveService.instance.similarityModel;

    _searchAssets =
        await similarityModel.searchSimilar(widget.pathAsset, _searchVector!);

    if (_searchAssets.isNotEmpty) {
      setState(() {
        isLoading = false;
        print('my_logs setting isloading to false');
      });
    }

    return;
  }

  Widget getGridBody() {
    return GridView.builder(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _searchAssets!.length,
      itemBuilder: (context, index) {
        return GridItem(searchAsset: _searchAssets![index], context: context);
      },
    );
  }
}

class GridItem extends StatefulWidget {
  final AssetEntity searchAsset;
  final BuildContext context;

  const GridItem({super.key, required this.searchAsset, required this.context});

  @override
  State<GridItem> createState() => _GridItemState();
}

class _GridItemState extends State<GridItem>
    with AutomaticKeepAliveClientMixin {
  Uint8List? imageBytes;

  @override
  void initState() {
    _loadThumbnail();
    super.initState();
  }

  void _loadThumbnail() async {
    try {
      final thumbnailData = await widget.searchAsset
          .thumbnailDataWithSize(const ThumbnailSize(300, 300));
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
        CommonUtils.showSnackbar(
            context: widget.context, message: "Clicked on Image!");

        // Navigator.push(context, MaterialPageRoute(builder: (context) =>
        //         ViewAsset(index: widget.index, folderPath: widget.folderPath),))
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
