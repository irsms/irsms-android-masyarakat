import 'dart:io';
import 'package:flutter/material.dart';

class CardPicture extends StatelessWidget {
  const CardPicture({this.onTap, this.imagePath, super.key});

  final Function()? onTap;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (imagePath != null) {
      return Card(
        child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
              width: size.width * .50,
              height: size.width * .50,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: (imagePath == null
                        ? Text(
                            'Ambil gambar!',
                            style: TextStyle(
                                fontSize: 17, color: Colors.grey[600]),
                          )
                        : Container(
                            width: size.width * .50,
                            height: size.width * .50 - 64,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                              image: DecorationImage(
                                  fit: BoxFit.fitHeight, image: FileImage(File(imagePath as String))),
                            ),
                        )
                      )
                  ),
                  Icon(
                    Icons.photo_camera,
                    color: Colors.indigo[400],
                  )
                ],
              ),
            ),
          ),
      );
    }

    return Card(
        elevation: 3,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            width: size.width * .50,
            height: size.width * .50,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Gambar lampiran',
                  style: TextStyle(fontSize: 17.0, color: Colors.grey[600]),
                ),
                Icon(
                  Icons.photo_camera,
                  color: Colors.indigo[400],
                )
              ],
            ),
          ),
        )
      );
  }
}