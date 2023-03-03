import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';

class SlideshowWidget extends StatelessWidget {
  final List<String> slides;
  final double height;

  const SlideshowWidget(
      {required this.slides, required this.height, super.key});

  @override
  Widget build(BuildContext context) {
    return ImageSlideshow(
      width: (21 / 9) * height,
      height: height,
      initialPage: 0,
      indicatorColor: Colors.blue,
      indicatorBackgroundColor: Colors.white,
      autoPlayInterval: 3000,
      isLoop: true,
      children: [
        ...slides.map((slide) {
          Uri uri = Uri.parse(slide);

          return Center(
            child: FutureBuilder<http.Response>(
              future: http.get(uri),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                    return const Text('Tidak ada gambar');
                  case ConnectionState.active:
                  case ConnectionState.waiting:
                    return const CircularProgressIndicator();
                  case ConnectionState.done:
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.data!.statusCode == 200) {
                      return Container(
                        height: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          image: DecorationImage(
                              fit: BoxFit.cover,
                              image: MemoryImage(snapshot.data!.bodyBytes)),
                        ),
                      );
                    }

                    return const CircularProgressIndicator();
                }
              },
            ),
          );
        })
      ],
    );
  }
}
