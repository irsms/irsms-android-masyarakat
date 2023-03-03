import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'profil_edit.dart';

class Profil extends StatefulWidget {
  const Profil({super.key});

  @override
  State<Profil> createState() => _ProfilState();
}

class _ProfilState extends State<Profil> {
  Map<String, dynamic> _profile = <String, dynamic>{};

  late String _token;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      await _getProfile();
    });

    super.initState();
  }

  Future<void> _getProfile() async {
    var controller = 'masyarakat/profile';
    var params = {'token': _token};
    Map<String, dynamic> profile =
        await RestClient().get(controller: controller, params: params);

    if (profile['status']) {
      setState(() {
        _profile = profile['rows'][0];
      });
    } else {
      if (!mounted) return;

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
                content: Text(profile['error']),
                actions: [
                  TextButton(
                      onPressed: () {
                        if (_profile['error'] == 'Expired token') {
                          Navigator.pushNamed(context, '/');
                        } else {
                          Navigator.of(context).pop();
                        }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, '/desktop'),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Data Profil'),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/');
              },
              child: const Icon(Icons.logout),
            )
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _getProfile();
        },
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Center(
                child: InkWell(
                  onTap: _setAvatar,
                  child: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    radius: MediaQuery.of(context).size.width * .25,
                    child: FutureBuilder<http.Response>(
                      future: http.get(Uri.parse(
                          '${RestClient().baseURL}/${_profile["userpic"]}')),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                            return const Icon(
                              Icons.person,
                              size: 128,
                            );
                          case ConnectionState.active:
                          case ConnectionState.waiting:
                            return const CircularProgressIndicator();
                          case ConnectionState.done:
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }

                            if (snapshot.data!.statusCode == 200) {
                              return SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.width *
                                      0.5625,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(128),
                                    child: Image.memory(
                                      snapshot.data!.bodyBytes,
                                      width: 128,
                                      height: 128,
                                      fit: BoxFit.cover,
                                    ),
                                  ));
                            }

                            return const Icon(
                              Icons.person,
                              size: 172,
                              color: my_colors.yellow,
                            );
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 10,
                  child: SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'NAMA',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _profile['nama_depan'] ?? '',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(
                              height: 8.0,
                            ),
                            const Text(
                              'NIK',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _profile['nik'] ?? '',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(
                              height: 8.0,
                            ),
                            const Text(
                              'NO. HP',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _profile['no_hp'] ?? '',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(
                              height: 8.0,
                            ),
                            const Text(
                              'EMAIL',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _profile['email'] ?? '',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            const SizedBox(
                              height: 8.0,
                            ),
                            const Text(
                              'ALAMAT',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _profile['alamat'] ?? '',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      )),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfilEdit()));
                    },
                    child: const Text('Edit Profil')),
              )
            ],
          ),
        )),
      ),
    );
  }

  Future<void> _pickImage(String source) async {
    final ImagePicker picker = ImagePicker();
    File? image;

    XFile? xFile = await picker.pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300);

    if (xFile != null) {
      image = File(xFile.path);

      var resp =
          await RestClient().uploadAvatar(path: image.path, token: _token);

      if (resp['status'] == false) {
        if (!mounted) return;

        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('IRSMS'),
                  content: Text(resp['error'].toString()),
                  actions: [
                    TextButton(
                        onPressed: () {
                          if (resp['error'] == 'Expired token') {
                            Navigator.pushNamed(context, '/');
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Tutup'))
                  ],
                ));
      } else {
        var controller = 'masyarakat/profile';
        var params = {'token': _token};
        Map<String, dynamic> profile =
            await RestClient().get(controller: controller, params: params);

        setState(() {
          _profile = profile['rows'][0];
        });
      }
    }
  }

  void _setAvatar() {
    showModalBottomSheet(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(8.0))),
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _pickImage('camera');
                        },
                        child: const Text('Kamera')),
                    ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _pickImage('gallery');
                        },
                        child: const Text('Galeri')),
                  ],
                ),
              ),
            ));
  }
}
