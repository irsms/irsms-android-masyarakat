import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/libraries/colors.dart' as my_colors;
import 'src/ui/desktop.dart';
import 'src/ui/registrasi.dart';
import 'src/ui/verifikasi_akun.dart';
import 'src/services/rest_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IRSMS',
      theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: my_colors.blue,
          textTheme: GoogleFonts.poppinsTextTheme(),
          colorScheme:
              ColorScheme.fromSwatch().copyWith(background: my_colors.grey)),
      initialRoute: '/',
      routes: <String, WidgetBuilder>{
        '/': (BuildContext context) => const MyHomePage(
              title: 'IRSMS',
            ),
        '/desktop': (BuildContext context) => const Desktop(),
        '/signup': (BuildContext context) => const Registrasi(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final LocalAuthentication auth = LocalAuthentication();
  _SupportState _supportState = _SupportState.unknown;
  // bool? _canCheckBiometrics;
  // List<BiometricType>? _availableBiometrics;
  String _authorized = 'Not Authorized';
  // bool _isAuthenticating = false;

  ConnectivityResult _connectionStatus = ConnectivityResult.none;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _streamSubscription;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool showPassword = false;
  bool isLoading = false;

  Future<void> _auth() async {
    if (_connectionStatus == ConnectivityResult.none) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_connectionStatus.toString())));
      return;
    }

    setState(() {
      isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();

    var controller = 'masyarakat/login';
    var data = {
      'username': _usernameController.text,
      'password': _passwordController.text
    };
    var response = await RestClient().post(controller: controller, data: data);

    setState(() {
      isLoading = false;
    });

    if (response['status']) {
      prefs.setString('username', _usernameController.text);
      prefs.setString('password', _passwordController.text);
      prefs.setString('token', response['token']);

      await Future.delayed(const Duration(seconds: 0));

      if (!mounted) return;

      Navigator.pushNamed(context, '/desktop');
    } else {
      if (!mounted) return;

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
                content: Text(response['error']),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Tutup'))
                ],
              ));
    }
  }

  void _registrasi() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Registrasi()));
  }

  void _lupaPassword() {
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => const VerifikasiAkun()));
  }

  @override
  void initState() {
    initConnectifity();
    _streamSubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    auth.isDeviceSupported().then((bool isSupported) => setState(
          () => _supportState =
              isSupported ? _SupportState.supported : _SupportState.unsupported,
        ));

    super.initState();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String appSubTitle = 'Aplikasi IRSMS Untuk Masyarakat';
    final double mediaW = MediaQuery.of(context).size.width;
    final double mediaH = MediaQuery.of(context).size.height;

    return SafeArea(
        child: Scaffold(
      body: SingleChildScrollView(
        child: Container(
          width: mediaW,
          height: mediaH,
          padding: EdgeInsets.symmetric(
              horizontal: mediaW > 500 ? mediaW / 4 : 32.0),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [my_colors.blue, Colors.blue.shade200],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Center(
              child: Image.asset(
                'assets/images/logo-irsms.png',
                width: 0.4 * mediaW,
              ),
            ),
            const SizedBox(
              height: 16.0,
            ),
            const AutoSizeText(
              appSubTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 48.0,
            ),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Nama Pengguna',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    key: const Key('username'),
                    controller: _usernameController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.only(
                          top: 0, right: 30, bottom: 0, left: 15),
                      hintText: 'Ketik Nama Penguna di Sini',
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '* wajib diisi';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  const Text(
                    'Kata Sandi',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    key: const Key('password'),
                    controller: _passwordController,
                    obscureText: showPassword ? false : true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Ketik Kata Sandi di Sini',
                      contentPadding: const EdgeInsets.only(
                          top: 0, right: 30, bottom: 0, left: 15),
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10, right: 15),
                          child: Icon(
                            showPassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: my_colors.blue,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: ((value) {
                      if (value == null || value.isEmpty) {
                        return "* wajib diisi";
                      }

                      return null;
                    }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _lupaPassword,
                        child: const Text(
                          'Lupa Password?',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: my_colors.blue, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate() &&
                                !isLoading) {
                              await _auth();
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(my_colors.yellow),
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.all(16)),
                          ),
                          child: (isLoading)
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).primaryColor,
                                    strokeWidth: 1.5,
                                  ),
                                )
                              : Text(
                                  'Masuk',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(
                        width: 8.0,
                      ),
                      TextButton(
                        onPressed: () async {
                          await _authenticate(
                              biometricOnly:
                                  _supportState != _SupportState.supported);

                          if (_authorized == 'Authorized') {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();

                            setState(() {
                              _usernameController.text =
                                  prefs.getString('username')!;
                              _passwordController.text =
                                  prefs.getString('password')!;
                            });

                            await _auth();
                          }
                        },
                        style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(my_colors.yellow),
                            padding: MaterialStateProperty.all(
                                const EdgeInsets.all(15))),
                        child: Builder(builder: (context) {
                          if (_supportState == _SupportState.unknown) {
                            return const CircularProgressIndicator();
                          } else if (_supportState ==
                              _SupportState.unsupported) {
                            return const Icon(
                              Icons.lock,
                              color: my_colors.blue,
                            );
                          }

                          return const Icon(
                            Icons.fingerprint,
                            color: my_colors.blue,
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 8.0,
            ),
            Center(
                child: RichText(
                    text: TextSpan(children: [
              const TextSpan(
                text: 'Belum punya akun?',
                style: TextStyle(color: my_colors.blue, fontSize: 13),
              ),
              TextSpan(
                  text: ' Daftar sekarang',
                  style: const TextStyle(
                      color: my_colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                  recognizer: TapGestureRecognizer()..onTap = _registrasi)
            ]))),
            const SizedBox(
              height: 64.0,
            )
          ]),
        ),
      ),
    ));
  }

  Future<void> initConnectifity() async {
    late ConnectivityResult result;

    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }

    if (!mounted) {
      return Future.value(null);
    }

    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {
    setState(() {
      _connectionStatus = result;
    });
  }

  // Future<void> _checkBiometrics() async {
  //   late bool canCheckBiometrics;
  //   try {
  //     canCheckBiometrics = await auth.canCheckBiometrics;
  //   } on PlatformException catch (e) {
  //     canCheckBiometrics = false;
  //   }

  //   if (!mounted) {
  //     return;
  //   }

  //   setState(() {
  //     _canCheckBiometrics = canCheckBiometrics;
  //   });
  // }

  // Future<void> _getAvailableBiometrics() async {
  //   late List<BiometricType> availableBiometrics;
  //   try {
  //     availableBiometrics = await auth.getAvailableBiometrics();
  //   } on PlatformException catch (e) {
  //     availableBiometrics = <BiometricType>[];
  //     print(e);
  //   }

  //   if (!mounted) {
  //     return;
  //   }

  //   setState(() {
  //     _availableBiometrics = availableBiometrics;
  //   });
  // }

  Future<void> _authenticate({bool biometricOnly = true}) async {
    bool authenticated = false;
    try {
      setState(() {
        // _isAuthenticating = true;
        _authorized = 'Authenticating';
      });

      authenticated = await auth.authenticate(
          localizedReason: 'Please authenticate yourself',
          options: AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: biometricOnly,
              useErrorDialogs: true));

      setState(() {
        // _isAuthenticating = false;
        _authorized = 'Authenticating';
      });
    } on PlatformException catch (e) {
      setState(() {
        // _isAuthenticating = false;
        _authorized = 'Error - ${e.message}';
      });

      return;
    }

    if (!mounted) {
      return;
    }

    setState(
      () => _authorized = authenticated ? 'Authorized' : 'Not Authorized',
    );
  }

  // Future<void> _cancelAuthentication() async {
  //   await auth.stopAuthentication();
  //   setState(
  //     () => _isAuthenticating = false,
  //   );
  // }
}

enum _SupportState {
  unknown,
  supported,
  unsupported,
}
