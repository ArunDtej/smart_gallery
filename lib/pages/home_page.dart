import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:smart_gallery/pages/viewImages.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int min_size = 3;
  int max_size = 4;
  int _scale = 4;
  double _previousScale = 2;
  dynamic albumData = {'albums': [], 'length': 0};

  @override
  void initState() {
    super.initState();
    setData();
  }

  void setData() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      var paths = await PhotoManager.getAssetPathList();
      var albums = [];

      for (int i = 0; i < paths.length; i++) {
        var thumbnail =
            await (await paths[i].getAssetListPaged(page: 0, size: 1))[0]
                // .thumbnailDataWithSize(const ThumbnailSize(300, 300));
                .thumbnailData;

        if (thumbnail != null) {
          albums.add({
            'path': paths[i],
            'name': paths[i].name,
            'thumbnail': thumbnail
          });
        }
      }

      setState(() {
        albumData['albums'] = albums;
        albumData['length'] = albums.length;
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
        },
        onScaleUpdate: (details) {
          setState(() {
            double newScale = (_previousScale * details.scale)
                .clamp(min_size.toDouble(), max_size.toDouble());
            _scale = newScale.round();
          });
        },
        onScaleEnd: (details) {
          setState(() {
            _scale = _scale.clamp(min_size, max_size);
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: getBody(),
        ),
      ),
    );
  }

  Widget getBody() {
    return Skeletonizer(
        enabled: albumData['length'] < 1 ? true : false,
        child: albumData['length'] < 1 ? getDummyAlbum() : getAlbums());
  }

  GridView getAlbums() {
    albumData['length'] = albumData['albums']?.length ?? 0;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7 - _scale.toInt(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.85),
      itemCount: albumData['length'],
      itemBuilder: (context, index) {
        return Container(
          alignment: Alignment.center,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyWidget()),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                (albumData['albums']?[index]?['thumbnail'] != null
                    ? Expanded(
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              albumData['albums']?[index]?['thumbnail'],
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.image,
                        size: 50,
                        color: Colors.grey,
                      )),
                Text(
                  '${albumData['albums']?[index]?['name'] ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
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
            title: const Text('Item 1'),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Item 2'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget getDummyAlbum() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7 - _scale.toInt(),
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.85,
      ),
      itemCount: 13,
      itemBuilder: (context, index) {
        return Container(
          alignment: Alignment.center,
          child: InkWell(
            onTap: () {},
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: const Icon(
                      Icons.image, // Replace this with any icon you'd like
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Album Name',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
