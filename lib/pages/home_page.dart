import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  dynamic albumData = {'albums': [], 'lengeth': 0};
  @override
  void initState() {
    super.initState();
    setData();
  }

  void setData() async {
    final PermissionState ps = await PhotoManager
        .requestPermissionExtend(); // the method can use optional param `permission`.
    if (ps.isAuth) {
      var paths = await PhotoManager.getAssetPathList();
      var albums = [];

      for (int i = 0; i < paths.length; i++) {
        var thumbnail =
            await (await paths[i].getAssetListPaged(page: 0, size: 1))[0]
                .thumbnailData;
        if (thumbnail != null) {
          albums.add({
            'path': paths[i],
            'name': paths[i].name,
            'thumbnail': thumbnail
          });
        }
        if (i == 18) {
          print(paths[i].name);
          print(thumbnail);
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
      body: Container(padding: const EdgeInsets.all(16), child: getBody()),
    );
  }

  Widget getBody() {
    return Column(
      spacing: 5,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 30),
          child: Text(
            "Albums",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Expanded(child: getAlbums()),
      ],
    );
  }

  GridView getAlbums() {
    albumData['length'] = albumData['albums']?.length ?? 0;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.85),
      itemCount: albumData['length'],
      itemBuilder: (context, index) {
        return Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.start, // Align items at the start
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // The image will take most of the available space
              albumData['albums']?[index]?['thumbnail'] != null
                  ? Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            8), // Rounded corners for the image
                        child: Image.memory(
                          albumData['albums']?[index]?['thumbnail'],
                          width: double
                              .infinity, // Make the image take up all available width
                          fit:
                              BoxFit.cover, // Ensure the image covers the space
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey, // Icon color when no image
                    ),

              // Text/icon below the image
              Padding(
                padding: const EdgeInsets.only(
                    top: 8.0), // Space between image and text
                child: Text(
                  '${albumData['albums']?[index]?['name'] ?? 'Unknown'}',
                  style: Theme.of(context).textTheme.labelLarge,
                  overflow:
                      TextOverflow.ellipsis, // Prevent overflow of long text
                  textAlign: TextAlign.center, // Center the text
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
