import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'informasi.dart';
import 'korban.dart';
import 'lapor_laka.dart';
import 'pengaduan.dart';
import 'peta.dart';
import 'profil.dart';
import 'sipulan.dart';
import 'slideshow.dart';
//import 'otp.dart';

class Desktop extends StatefulWidget {
  const Desktop({super.key});

  @override
  State<Desktop> createState() => _DesktopState();
}

class _DesktopState extends State<Desktop> {
  static final List<String> _slides = [];

  Future<bool> _onWillPop() async {
    return (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Anda yakin?'),
                  content: const Text('Anda ingin keluar dari aplikasi?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Tidak')),
                    TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/'),
                        child: const Text('Ya')),
                  ],
                ))) ??
        false;
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String token = prefs.getString('token') ?? '';
      var controller = 'masyarakat/slides';
      var params = {'token': token};
      Map<String, dynamic> slides =
          await RestClient().get(controller: controller, params: params);

      setState(() {
        _slides.clear();
      });

      if (slides['status']) {
        setState(() {
          slides['rows'].forEach((slide) {
            _slides.add('${RestClient().baseURL}/${slide['slide']}');
          });
        });
      } else {
        if (!mounted) return;

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('IRSMS'),
                  content: Text(slides['error']),
                  actions: [
                    TextButton(
                        onPressed: () {
                          if (slides['error'] == 'Expired token') {
                            Navigator.pushNamed(context, '/');
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Tutup'))
                  ],
                ));
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double mainContainerHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        kBottomNavigationBarHeight;

    final double sliderContainerHeight = 0.5 * mainContainerHeight;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Beranda IRSMS'),
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: ((context) => const Profil())));
                  },
                  child: Container(
                      width: kToolbarHeight - 16,
                      height: kToolbarHeight - 16,
                      decoration: BoxDecoration(
                          color: my_colors.yellow,
                          borderRadius:
                              BorderRadius.circular(kToolbarHeight - 16)),
                      child: const Icon(
                        Icons.person,
                        color: my_colors.blue,
                      )),
                )
              ],
            ),
          ),
          body: Container(
            height: MediaQuery.of(context).size.height,
            decoration: const BoxDecoration(
              image: DecorationImage(
                  image: AssetImage(
                      'assets/images/Insignia_of_the_Indonesian_Traffic_Police.svg.png'),
                  repeat: ImageRepeat.repeat,
                  scale: 4),
            ),
            child: Container(
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(color: Colors.white.withAlpha(192)),
              child: SingleChildScrollView(
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: sliderContainerHeight,
                      child: _slides.isNotEmpty
                          ? SlideshowWidget(
                              slides: _slides,
                              height: sliderContainerHeight,
                            )
                          : const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  SizedBox(
                    height: mainContainerHeight - sliderContainerHeight,
                    child: Center(
                      child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 16.0,
                        shrinkWrap: true,
                        children: List.generate(
                            6,
                            (index) => ShortcutWidget(
                                  shortcut: shortcut[index],
                                )),
                      ),
                    ),
                  )
                ]),
              ),
            ),
          )),
    );
  }
}

class SlideWidget extends StatelessWidget {
  final String image;

  const SlideWidget({required this.image, super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(image, fit: BoxFit.fitHeight);
  }
}

class ShortcutWidget extends StatelessWidget {
  final Shortcut? shortcut;

  const ShortcutWidget({this.shortcut, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
        // mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
              // width: 128,
              // height: 128,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context, MaterialPageRoute(builder: shortcut!.builder));
                },
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(my_colors.yellow),
                    padding:
                        MaterialStateProperty.all(const EdgeInsets.all(15)),
                    shape: MaterialStateProperty.all(const CircleBorder())),
                child: Icon(
                  shortcut!.icon,
                  color: my_colors.blue,
                  size: 0.125 * MediaQuery.of(context).size.width - 16,
                ),
              )),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
              // width: 96,
              // height: 50,
              child: Text(
            shortcut!.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
                color: my_colors.blue, fontWeight: FontWeight.w900),
          ))
        ]);
  }
}

class Shortcut {
  final String name;
  final IconData icon;
  final WidgetBuilder builder;

  const Shortcut(
      {required this.name, required this.icon, required this.builder});
}

final shortcut = [
  Shortcut(
    name: 'Sipulan',
    icon: Icons.directions_car,
    builder: (context) => const Sipulan(),
  ),
  Shortcut(
    name: 'Peta',
    icon: Icons.map_outlined,
    builder: (context) => const Peta(),
  ),
  Shortcut(
    name: 'Lapor Laka',
    icon: Icons.add_to_photos_outlined,
    builder: (context) => const LaporLaka(),
  ),
  Shortcut(
    name: 'Informasi',
    icon: Icons.library_books,
    builder: (context) => const Informasi(),
  ),
  Shortcut(
    name: 'Pengaduan',
    icon: Icons.group_add,
    builder: (context) => const Pengaduan(),
  ),
  Shortcut(
    name: 'Pencarian Korban Laka',
    icon: Icons.car_crash,
    builder: (context) => const Korban(),
  ),
  // Shortcut(
  //   name: 'OTP',
  //   icon: Icons.car_crash,
  //   builder: (context) => const Otp(),
  // ),
];
