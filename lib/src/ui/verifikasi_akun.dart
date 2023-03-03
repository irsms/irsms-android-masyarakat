import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../libraries/colors.dart' as my_colors;
import 'reset_password.dart';
import '../services/rest_client.dart';

class VerifikasiAkun extends StatefulWidget {
  const VerifikasiAkun({super.key});

  @override
  State<VerifikasiAkun> createState() => _VerifikasiAkunState();
}

class _VerifikasiAkunState extends State<VerifikasiAkun> {
  final _formKey = GlobalKey<FormState>();
  bool showPassword = false;

  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();

  bool isLoading = false;

  void _submit() async {
    isLoading = true;
    setState(() {});

    Map<String, dynamic> params = {
      "nik": _nikController.text,
      "email": _emailController.text,
      "no_hp": _noHpController.text,
    };
    var controller = 'masyarakat/verifikasi';
    var resp = await RestClient().get(controller: controller, params: params);

    if (resp['status'] && resp['rows'].isNotEmpty) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(
          'masyarakat__members_id', resp['rows'][0]['masyarakat__members_id']);

      await Future.delayed(const Duration(seconds: 0));
      if (!mounted) return;

      isLoading = false;
      setState(() {});
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ResetPassword()));
    } else {
      if (!mounted) return;

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
                content: const Text('Akun tidak ditemukan.'),
                actions: [
                  TextButton(
                      onPressed: () {
                        setState(() {
                          isLoading = false;
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Tutup'))
                ],
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verifikasi Akun'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verifikasi Akun',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: my_colors.blue),
            ),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(
                    height: 16.0,
                  ),
                  const Text(
                    'NIK Terdaftar',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: TextFormField(
                        controller: _nikController,
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '* wajib diisi';
                          }

                          if (value.length != 16) {
                            return 'Format NIK tidak sah.';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: 'Masukkan di Sini',
                        ),
                      )),
                  const Text(
                    'Email Terdaftar',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '* wajib diisi';
                          }

                          bool emailValid = RegExp(
                                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(value);

                          if (!emailValid) {
                            return 'Alamat email tidak sah.';
                          }

                          return null;
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: 'Masukkan di Sini',
                        ),
                      )),
                  const Text(
                    'Nomor Handphone Terdaftar',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                  Container(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: TextFormField(
                        controller: _noHpController,
                        autovalidateMode: AutovalidateMode.always,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '* wajib diisi';
                          }

                          return null;
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: 'Masukkan di Sini',
                        ),
                      )),
                  const Divider(
                    height: 32,
                  ),
                  SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!isLoading && _formKey.currentState!.validate()) {
                            _submit();
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
                                'Verifikasi',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                      )),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
