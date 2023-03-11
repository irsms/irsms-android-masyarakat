import 'package:slider_captcha/slider_capchar.dart';
import 'package:slider_captcha/utils/insets.dart';
import 'package:flutter/material.dart';

class MyCaptcha extends StatefulWidget {
  const MyCaptcha({super.key});

  @override
  State<MyCaptcha> createState() => _MyCaptchaState();
}

class _MyCaptchaState extends State<MyCaptcha> {
  final SliderController controller = SliderController();

  @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: const Text('Slider CaptChar'),
  //       centerTitle: true,
  //     ),
  //     body: SafeArea(
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 50),
  //         child: SliderCaptcha(
  //           controller: controller,
  //           image: Image.asset(
  //             'assets/images/logo-irsms.png',
  //             fit: BoxFit.fitWidth,
  //           ),
  //           colorBar: Colors.blue,
  //           colorCaptChar: Colors.blue,
  //           space: 10,
  //           fixHeightParent: false,
  //           onConfirm: (value) async {
  //             if (value.toString() == 'true') {
  //               print('success');
  //             } else {
  //               print('gagal');
  //             }
  //             // debugPrint(value.toString());
  //             return await Future.delayed(const Duration(seconds: 1)).then(
  //               (value) {
  //                 // print('success');
  //                 controller.create.call();
  //               },
  //             );
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Slider CaptChar'),
        centerTitle: true,
      ),
      body: Center(
        child: OutlinedButton(
          onPressed: () => _dialogBuilder(context),
          child: const Text('Open Dialog'),
        ),
      ),
    );
  }

  Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          // title: const Text('Basic dialog title'),
          // content: const Text('A dialog is a type of modal window that\n'
          //     'appears in front of app content to\n'
          //     'provide critical information, or prompt\n'
          //     'for a decision to be made.'),
          actions: <Widget>[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: SliderCaptcha(
                  controller: controller,
                  image: Image.asset(
                    'assets/images/logo-irsms.png',
                    fit: BoxFit.fitWidth,
                  ),
                  colorBar: Colors.blue,
                  colorCaptChar: Colors.blue,
                  space: 10,
                  fixHeightParent: false,
                  onConfirm: (value) async {
                    if (value.toString() == 'true') {
                      print('success');
                    } else {
                      print('gagal');
                    }
                    // debugPrint(value.toString());
                    return await Future.delayed(const Duration(seconds: 1))
                        .then(
                      (value) {
                        // print('success');
                        controller.create.call();
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
