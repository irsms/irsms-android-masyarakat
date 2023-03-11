import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'card_picture.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Lapor extends StatefulWidget {
  const Lapor({super.key});

  @override
  State<Lapor> createState() => _LaporState();
}

class _LaporState extends State<Lapor> {
  final _formKey = GlobalKey<FormState>();

  final ImagePicker _picker = ImagePicker();
  File? _image;

  bool isLoading = false;

  String _token = '';
  String? _currentAddress;
  Position? _currentPosition;

  Map<String, dynamic> _wilayah = {};

  List<String> get _imagePaths => [_image!.path];

  final TextEditingController _roadNameController = TextEditingController();
  final TextEditingController _satuanKepolisianController =
      TextEditingController();
  final TextEditingController _mdController = TextEditingController();
  final TextEditingController _lbController = TextEditingController();
  final TextEditingController _lrController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _longController = TextEditingController();
  final TextEditingController _cronologicalController = TextEditingController();

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() => _currentPosition = position);
      _getAddressFromLatLng(_currentPosition!);
    }).catchError((e) {
      debugPrint(e);
    });
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        _currentAddress =
            '${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
      });
    }).catchError((e) {
      debugPrint(e);
    });
  }

  void _submit() async {
    setState(() {
      isLoading = true;
    });

    var profile =
        await RestClient().get(controller: 'masyarakat/profile', params: {
      'token': _token,
    });

    if (profile['status']) {
      var resp = await RestClient().uploadPhotos(_imagePaths);

      if (resp['status']) {
        String fullPath = resp['rows'][0]['full_path'];

        Map<String, dynamic> data = {
          'picture': fullPath,
          'road_name': _currentAddress,
          'satuan_kepolisian': _satuanKepolisianController.text,
          // 'md': _mdController.text,
          // 'lb': _lbController.text,
          // 'lr': _lrController.text,
          // 'md': _currentPosition?.latitude,
          // 'lb': _currentPosition?.longitude,
          'latitude': _currentPosition?.latitude,
          'longitude': _currentPosition?.longitude,
          'chronological': _cronologicalController.text,
          'accident_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
          'accident_time': DateFormat('HH:mm').format(DateTime.now()),
          'masyarakat__members_id': profile['rows'][0]['masyarakat__members_id']
        };

        String controller = 'masyarakat/lapor_laka';

        var postResp = await RestClient()
            .post(token: _token, controller: controller, data: data);

        setState(() {
          isLoading = false;
        });

        if (postResp['status']) {
          await Future.delayed(const Duration(seconds: 3));
          if (!mounted) return;
          Navigator.pop(context);
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
                  content: Text(profile['error']),
                  actions: [
                    TextButton(
                        onPressed: () {
                          setState(() {
                            isLoading = false;
                          });

                          if (profile['error'] == 'Expired token') {
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
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _getCurrentPosition();
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
        title: const Text('Lapor'),
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
                TextFormField(
                  controller: _roadNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.only(
                        top: 0, right: 30, bottom: 0, left: 15),
                    hintText: '${_currentAddress ?? ""}',
                  ),
                  //  autovalidateMode: AutovalidateMode.always,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return '* wajib diisi';
                  //   }

                  //   return null;
                  // },
                ),
                const SizedBox(
                  height: 16.0,
                ),
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
                  // autovalidateMode: AutovalidateMode.always,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return '* wajib diisi';
                  //   }

                  //   return null;
                  // },
                ),
                const SizedBox(
                  height: 16.0,
                ),
                const Text(
                  'Titik Koordinat',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Expanded(child: Text('Latitude')),
                    Expanded(
                      child: TextFormField(
                        enabled: false,
                        controller: _latController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Color.fromARGB(255, 225, 222, 222),
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: '${_currentPosition?.latitude ?? ""}',
                        ),
                        autovalidateMode: AutovalidateMode.always,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return '* wajib diisi';
                        //   }

                        //   return null;
                        // },
                      ),
                    ),
                  ],
                ),
                // ElevatedButton(
                //   onPressed: _getCurrentPosition,
                //   child: const Text("Get Current Location"),
                // ),
                const SizedBox(
                  height: 16.0,
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Expanded(child: Text('Longitude')),
                    Expanded(
                      child: TextFormField(
                        enabled: false,
                        controller: _mdController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: Color.fromARGB(255, 225, 222, 222),
                          contentPadding: const EdgeInsets.only(
                              top: 0, right: 30, bottom: 0, left: 15),
                          hintText: '${_currentPosition?.longitude ?? ""}',
                        ),
                        autovalidateMode: AutovalidateMode.always,
                        // validator: (value) {
                        //   if (value == null || value.isEmpty) {
                        //     return '* wajib diisi';
                        //   }

                        //   return null;
                        // },
                      ),
                    ),
                  ],
                ),
                // const Text(
                //   'Jumlah Korban',
                //   textAlign: TextAlign.left,
                //   style: TextStyle(
                //       color: my_colors.blue, fontWeight: FontWeight.bold),
                // ),
                // Row(
                //   mainAxisSize: MainAxisSize.min,
                //   children: [
                //     const Expanded(child: Text('Meninggal Dunia')),
                //     Expanded(
                //       child: TextFormField(
                //         controller: _mdController,
                //         keyboardType: TextInputType.number,
                //         decoration: InputDecoration(
                //           border: OutlineInputBorder(
                //               borderRadius: BorderRadius.circular(10)),
                //           filled: true,
                //           fillColor: Colors.white,
                //           contentPadding: const EdgeInsets.only(
                //               top: 0, right: 30, bottom: 0, left: 15),
                //           hintText: 'Masukkan di Sini',
                //         ),
                //         autovalidateMode: AutovalidateMode.always,
                //         validator: (value) {
                //           if (value == null || value.isEmpty) {
                //             return '* wajib diisi';
                //           }

                //           return null;
                //         },
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(
                //   height: 16.0,
                // ),
                // Row(
                //   mainAxisSize: MainAxisSize.min,
                //   children: [
                //     const Expanded(child: Text('Luka Berat')),
                //     Expanded(
                //       child: TextFormField(
                //         controller: _lbController,
                //         keyboardType: TextInputType.number,
                //         decoration: InputDecoration(
                //           border: OutlineInputBorder(
                //               borderRadius: BorderRadius.circular(10)),
                //           filled: true,
                //           fillColor: Colors.white,
                //           contentPadding: const EdgeInsets.only(
                //               top: 0, right: 30, bottom: 0, left: 15),
                //           hintText: 'Masukkan di Sini',
                //         ),
                //         autovalidateMode: AutovalidateMode.always,
                //         validator: (value) {
                //           if (value == null || value.isEmpty) {
                //             return '* wajib diisi';
                //           }

                //           return null;
                //         },
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(
                //   height: 16.0,
                // ),
                // Row(
                //   mainAxisSize: MainAxisSize.min,
                //   children: <Widget>[
                //     const Expanded(child: Text('Luka Ringan')),
                //     Expanded(
                //       child: TextFormField(
                //         controller: _lrController,
                //         keyboardType: TextInputType.number,
                //         decoration: InputDecoration(
                //           border: OutlineInputBorder(
                //               borderRadius: BorderRadius.circular(10)),
                //           filled: true,
                //           fillColor: Colors.white,
                //           contentPadding: const EdgeInsets.only(
                //               top: 0, right: 30, bottom: 0, left: 15),
                //           hintText: 'Masukkan di Sini',
                //         ),
                //         autovalidateMode: AutovalidateMode.always,
                //         validator: (value) {
                //           if (value == null || value.isEmpty) {
                //             return '* wajib diisi';
                //           }

                //           return null;
                //         },
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(
                  height: 16.0,
                ),
                const Text(
                  'Kronologis Singkat',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                      color: my_colors.blue, fontWeight: FontWeight.bold),
                ),
                TextFormField(
                  controller: _cronologicalController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.only(
                        top: 0, right: 30, bottom: 0, left: 15),
                    hintText: 'Masukkan di Sini',
                  ),
                  // autovalidateMode: AutovalidateMode.always,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return '* wajib diisi';
                  //   }

                  //   return null;
                  // },
                ),
                const SizedBox(
                  height: 16.0,
                ),
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
