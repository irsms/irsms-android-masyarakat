import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'card_picture.dart';
import 'pengaduan.dart';

class FormAduan extends StatefulWidget {
  const FormAduan({super.key});

  @override
  State<FormAduan> createState() => _FormAduanState();
}

class _FormAduanState extends State<FormAduan> {
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  File? _image;

  bool isLoading = false;

  String _token = '';

  Map<String, dynamic> _wilayah = {};

  List<String> get _imagePaths => [_image!.path];

  final TextEditingController _roadNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _satuanKepolisianController =
      TextEditingController();

  var kategoriLaporan = ['Kemacetan', 'Jalan Rusak', 'Rawan Laka'];

  String? selectedKategoriLaporan;

  Future<void> _submit() async {
    setState(() {
      isLoading = true;
    });

    var profile =
        await RestClient().get(controller: 'masyarakat/profile', params: {
      'token': _token,
    });

    if (profile['status']) {
      var resp = await RestClient().uploadPhotos(_imagePaths);

      if (resp.containsKey('status')) {
        if (resp['status']) {
          String fullPath = resp['rows'][0]['full_path'];

          Map<String, dynamic> data = {
            'picture': fullPath,
            'road_name': _roadNameController.text,
            'satuan_kepolisian': _satuanKepolisianController.text,
            'category': selectedKategoriLaporan,
            'description': _descriptionController.text,
            'created_at': DateFormat('yyyy-MM-dd').format(DateTime.now()),
            'masyarakat__members_id': profile['rows'][0]
                ['masyarakat__members_id']
          };

          String controller = 'masyarakat/aduan';

          var postResp = await RestClient()
              .post(token: _token, controller: controller, data: data);

          if (postResp['status']) {
            setState(() {
              isLoading = false;
            });

            await Future.delayed(const Duration(seconds: 3));
            if (!mounted) return;
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const Pengaduan()));
          } else {
            if (!mounted) return;

            showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: const Text('IRSMS'),
                      content: Text(postResp['error']),
                      actions: [
                        TextButton(
                            onPressed: () {
                              setState(() {
                                isLoading = false;
                              });

                              if (postResp['error'] == 'Expired token') {
                                Navigator.pushNamed(context, '/');
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Tutup'))
                      ],
                    ));
          }
        } else {
          if (!mounted) return;

          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('IRSMS'),
                    content: Text(resp['error']),
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
      } else {
        if (resp.containsKey('message')) {
          if (!mounted) return;

          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text('IRSMS'),
                    content: Text(resp['message']),
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
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      var controller = 'masyarakat/ref_wilayah';
      var params = {'token': _token};
      _wilayah = await RestClient().get(controller: controller, params: params);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Aduan'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
            child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: CardPicture(
                    onTap: () async {
                      XFile? xFile = await _picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 300,
                          maxHeight: 300);

                      if (xFile != null) {
                        _image = File(xFile.path);
                        _imagePaths.add(_image!.path);

                        setState(() {});
                      }
                    },
                    imagePath: _image?.path,
                  ),
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  'Nama Jalan',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _roadNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.only(
                            top: 0, right: 30, bottom: 0, left: 16),
                        hintText: 'Masukkan di Sini',
                      ),
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* wajib diisi';
                        }

                        return null;
                      },
                    )),
                const Text(
                  'Wilayah',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                TypeAheadFormField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: _satuanKepolisianController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.only(
                          top: 0, right: 30, bottom: 0, left: 16),
                      hintText: 'Masukkan di Sini',
                    ),
                  ),
                  onSuggestionSelected: ((suggestion) {
                    _satuanKepolisianController.text = suggestion.toString();
                  }),
                  itemBuilder: ((context, itemData) {
                    return ListTile(
                      title: Text(itemData.toString()),
                    );
                  }),
                  suggestionsCallback: (pattern) {
                    List<String> wilayah = [];
                    if (pattern.length > 2) {
                      _wilayah['rows'].forEach((item) {
                        if (RegExp(pattern).hasMatch(item['nama_dati'])) {
                          wilayah.add(item['nama_dati']);
                        }
                      });
                    }

                    return wilayah;
                  },
                  autovalidateMode: AutovalidateMode.always,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '* wajib diisi';
                    }

                    return null;
                  },
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  'Kategori Laporan',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField2(
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10))),
                    isExpanded: true,
                    hint: const Text('Pilih Kategori Laporan'),
                    icon: const Icon(Icons.keyboard_arrow_down),
                    iconSize: 30,
                    buttonHeight: kToolbarHeight,
                    buttonPadding: const EdgeInsets.only(left: 0, right: 10),
                    dropdownDecoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(16)),
                    items: kategoriLaporan
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    autovalidateMode: AutovalidateMode.always,
                    validator: (value) {
                      if (value == null) {
                        return 'Silahkan pilih kategori';
                      }

                      return null;
                    },
                    onChanged: (value) {
                      selectedKategoriLaporan = value.toString();
                    },
                    onSaved: (newValue) {
                      selectedKategoriLaporan = newValue.toString();
                    },
                  ),
                ),
                const Text(
                  'Deskripsi',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                Container(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.only(
                            top: 0, right: 30, bottom: 0, left: 16),
                        hintText: 'Masukkan di Sini',
                      ),
                      autovalidateMode: AutovalidateMode.always,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '* wajib diisi';
                        }

                        return null;
                      },
                    )),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_image == null) {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: const Text('IRSMS'),
                                    content:
                                        const Text('Gambar belum diambil.'),
                                    actions: [
                                      TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Tutup'))
                                    ],
                                  ));
                        } else if (_formKey.currentState!.validate() &&
                            !isLoading) {
                          _submit();
                        }
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(my_colors.blue),
                        padding:
                            MaterialStateProperty.all(const EdgeInsets.all(16)),
                      ),
                      child: (isLoading)
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 1.5,
                              ),
                            )
                          : const Text(
                              'Kirim',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                    )),
              ],
            ),
          ),
        )),
      ),
    );
  }
}

/**
class CardPicture extends StatefulWidget {
  const CardPicture({super.key});

  @override
  State<CardPicture> createState() => _CardPictureState();
}

class _CardPictureState extends State<CardPicture> {
  final ImagePicker _picker = ImagePicker();
  File? image;

  imageSelectorCamera() async {
    XFile? xFile = await _picker.pickImage(source: ImageSource.camera, maxWidth: 300, maxHeight: 300);
    if (xFile != null) {
      image = File(xFile.path);
      setState(() {
        
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Card(
          elevation: 3,
          child: InkWell(
            onTap: imageSelectorCamera,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
              width: 260,
              height: 360,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: (image == null
                        ? Text(
                            'Ambil gambar!',
                            style: TextStyle(fontSize: 17, color: Colors.grey[600]),
                          )
                        : Image.file(image!, fit: BoxFit.fitHeight, width: 300, height: 300,)),
                  ),
                  Icon(
                    Icons.photo_camera,
                    color: Colors.indigo[400],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
*/
