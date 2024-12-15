import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:smart_gallery/pages/view_images.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int minSize = 2;
  int maxSize = 5;
  int _scale = 2;
  double _previousDelta = 0.0; // For detecting horizontal swipe direction
  List<AssetPathEntity> albumPaths = [];
  bool _isSwiping = false;
  bool _isPermissionGranted = false;

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
        _isPermissionGranted = true;
      });
    } else {
      setState(() {
        _isPermissionGranted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: getDrawer(),
      body: _isPermissionGranted
          ? GestureDetector(
              onHorizontalDragUpdate: (details) {
                _handleSwipe(details.primaryDelta!);
              },
              onHorizontalDragEnd: (details) {
                _isSwiping = false;
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 8),
                child: getAlbums(),
              ),
            )
          : _permissionDeniedUI(), // Show the permission denied UI
    );
  }

  // UI when permission is not granted
  Widget _permissionDeniedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning,
            size: 50,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 16),
          Text(
            "Permission Denied\nPlease allow access to photos.",
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .labelSmall
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              fetchAlbums();
            },
            child: GestureDetector(
                onTap: () {
                  fetchAlbums();
                },
                child: Text("Try again!",style: Theme.of(context).textTheme.bodyLarge
                )),
          ),
        ],
      ),
    );
  }

  void _handleSwipe(double delta) {
    if (delta.abs() > 8.0) {
      setState(() {
        if (delta < 0 && _scale < maxSize) {
          _scale++;
        } else if (delta > 0 && _scale > minSize) {
          _scale--;
        }
      });
    }
  }

  GridView getAlbums() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _scale,
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
