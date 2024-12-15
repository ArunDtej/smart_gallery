import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_gallery/pages/view_images.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int minSize = 3;
  int maxSize = 5;
  int _scale = 4;
  double _previousScale = 1.0;
  List<AssetPathEntity> albumPaths = [];
  bool _isPinchInProgress = false;
  int _pointerCount = 0;

  @override
  void initState() {
    super.initState();
    fetchAlbums();
  }

  void fetchAlbums() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      final paths = await PhotoManager.getAssetPathList();

      setState(() {
        albumPaths = paths;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: getDrawer(),
      body: GestureDetector(
        onScaleStart: (details) {
          _previousScale = _scale.toDouble();
          setState(() {
            _pointerCount = details.pointerCount; // Track number of fingers
            _isPinchInProgress = _pointerCount > 1; // Only active when pinch
          });
        },
        onScaleUpdate: (details) {
          if (_isPinchInProgress) {
            setState(() {
              double newScale = (_previousScale * details.scale)
                  .clamp(minSize.toDouble(), maxSize.toDouble());
              _scale = newScale.round();
            });
          }
        },
        onScaleEnd: (details) {
          setState(() {
            _scale = _scale.clamp(minSize, maxSize);
            _isPinchInProgress = false;
            _pointerCount = 0;
          });
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
          child: _isPinchInProgress
              ? _disableScrollOnPinch(getAlbums())
              : getAlbums(),
        ),
      ),
    );
  }

  Widget _disableScrollOnPinch(Widget child) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {},
      onHorizontalDragUpdate:
          (details) {},
      child: child,
    );
  }

  GridView getAlbums() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7 - _scale,
        mainAxisSpacing: 0,
        crossAxisSpacing: 0,
        childAspectRatio: 0.85,
      ),
      itemCount: albumPaths.length,
      itemBuilder: (context, index) {
        return AlbumGridItem(albumPath: albumPaths[index]);
      },
    );
  }

  Drawer getDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Drawer Header'),
          ),
          ListTile(
            title: const Text('Rate us'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class AlbumGridItem extends StatefulWidget {
  final AssetPathEntity albumPath;

  const AlbumGridItem({super.key, required this.albumPath});

  @override
  State<AlbumGridItem> createState() => _AlbumGridItemState();
}

class _AlbumGridItemState extends State<AlbumGridItem>
    with AutomaticKeepAliveClientMixin {
  dynamic thumbnailBytes;

  static final Map<String, dynamic> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    loadThumbnail();
  }

  void loadThumbnail() async {
    final cacheKey = widget.albumPath.id;

    if (_thumbnailCache.containsKey(cacheKey)) {
      setState(() {
        thumbnailBytes = _thumbnailCache[cacheKey];
      });
    } else {
      final assets = await widget.albumPath.getAssetListPaged(page: 0, size: 1);
      if (assets.isNotEmpty) {
        final thumbnailData = await assets[0]
            .thumbnailDataWithSize(const ThumbnailSize(300, 300));
        if (thumbnailData != null) {
          setState(() {
            thumbnailBytes = thumbnailData;
          });
          _thumbnailCache[cacheKey] = thumbnailData;
        } else {
          _handleThumbnailError();
        }
      } else {
        _handleThumbnailError();
      }
    }
  }

  void _handleThumbnailError() {
    setState(() {
      thumbnailBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final placeholderColor =
        theme.brightness == Brightness.dark ? Colors.black : Colors.white;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Viewimages(folderPath: widget.albumPath),
          ),
        );
      },
      child: Column(
        children: [
          Expanded(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: placeholderColor,
                  child: thumbnailBytes == null
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Image.memory(
                            thumbnailBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            ),
          ),
          Text(
            widget.albumPath.name,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
