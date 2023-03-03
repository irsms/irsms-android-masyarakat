import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../libraries/colors.dart' as my_color;
import '../services/rest_client.dart';

class Korban extends StatefulWidget {
  const Korban({super.key});

  @override
  State<Korban> createState() => _KorbanState();
}

class _KorbanState extends State<Korban> {
  final _formKey = GlobalKey<FormState>();

  List<KorbanLaka> korban = [];

  String _token = '';

  final TextEditingController _searchController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';
    });

    super.initState();
  }

  void _alertDialog(Map<String, dynamic> data) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('IRSMS'),
              content: Text(data['error'].toString()),
              actions: [
                TextButton(
                    onPressed: () {
                      if (data['error'] == 'Expired token') {
                        Navigator.pushNamed(context, '/');
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Tutup'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencarian Korban Laka'),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: TextFormField(
                    key: const Key('s'),
                    controller: _searchController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Ketik Nomor Identitas di sini',
                      contentPadding: const EdgeInsets.only(
                          top: 0, right: 30, bottom: 0, left: 15),
                      suffixIcon: GestureDetector(
                        onTap: () async {
                          if (_formKey.currentState!.validate()) {
                            await _submit();
                          }
                        },
                        child: (isLoading)
                            ? const Center(
                                child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator()),
                              )
                            : const Icon(
                                Icons.search,
                                size: 30,
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
                ),
                const SizedBox(
                  height: 16.0,
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith(
                        (states) => my_color.grey),
                    columns: const [
                      DataColumn(
                          label: Text(
                        '#',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black54),
                      )),
                      DataColumn(
                          label: Text(
                        'NAMA',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black54),
                      )),
                      DataColumn(
                          label: Text(
                        'TANGGAL',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black54),
                      )),
                      DataColumn(
                          label: Text(
                        'POLRES',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black54),
                      )),
                    ],
                    rows: korban
                        .map((e) => DataRow(cells: [
                              DataCell(Text('${korban.indexOf(e) + 1}')),
                              DataCell(Text(e.nama)),
                              DataCell(Text(e.tanggalLaka)),
                              DataCell(
                                e.whatsapp == ''
                                    ? Text(e.polda)
                                    : InkWell(
                                        onTap: () async {
                                          await _openwhatsapp(e.whatsapp);
                                        },
                                        child: Text(
                                          e.polres,
                                          maxLines: 1,
                                          softWrap: false,
                                          textAlign: TextAlign.left,
                                          style: const TextStyle(
                                              color: Colors.lightBlue),
                                        )),
                              )
                            ]))
                        .toList(),
                  ),
                )
              ],
            ),
          ),
        ),
      )),
    );
  }

  // void _getPolres(String polda) async {
  //   var dataPolda = await RestClient()
  //       .get(controller: 'polda', params: {'token': _token, 'name': polda});

  //   var poldaId = dataPolda['rows'][0]['id'];
  //   var controller = 'polres';
  //   var params = {'token': _token, 'polda_id': poldaId};
  //   var polres = await RestClient().get(controller: controller, params: params);

  //   _polresList.clear();
  //   polres['rows'].forEach((p) {
  //     _polresList.add(p['name']);
  //   });

  //   setState(() {});
  // }

  Future<void> _submit() async {
    setState(() {
      isLoading = true;
    });

    var controller = 'masyarakat/korban';
    var params = {
      'token': _token,
      'search': _searchController.text,
      // 'start': tanggalAwal.toString().substring(0, 10),
      // 'end': tanggalAkhir.toString().substring(0, 10),
      // 'polda': polda,
      // 'polres': polres
    };
    var resp = await RestClient().get(controller: controller, params: params);

    if (resp['status']) {
      korban.clear();
      resp['rows'].forEach((row) {
        korban.add(KorbanLaka(
            nama: row['nama'],
            tanggalLaka: row['accident_date'],
            polda: row['polda'],
            polres: row['polres'],
            whatsapp: row['whatsapp']));
      });

      setState(() {});
    } else {
      _alertDialog(resp);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _openwhatsapp(String whatsapp) async {
    String whatsappURlAndroid = "whatsapp://send?phone=$whatsapp&text=hello";
    String whatappURLIos = "https://wa.me/$whatsapp?text=${Uri.parse("hello")}";
    if (Platform.isIOS) {
      // for iOS phone only
      if (await canLaunchUrl(Uri.parse(whatappURLIos))) {
        await launchUrl(Uri.parse(whatappURLIos));
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("WhatsApp no installed")));
      }
    } else {
      // android , web
      if (await canLaunchUrl(Uri.parse(whatsappURlAndroid))) {
        await launchUrl(Uri.parse(whatsappURlAndroid));
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("WhatsApp no installed")));
      }
    }
  }
}

// class _TanggalWidget extends StatefulWidget {
//   final DateTime date;
//   final ValueChanged<DateTime> onChanged;

//   const _TanggalWidget({
//     required this.date,
//     required this.onChanged,
//   });

//   @override
//   State<_TanggalWidget> createState() => _TanggalWidgetState();
// }

// class _TanggalWidgetState extends State<_TanggalWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.only(bottom: 15),
//       child: TextField(
//         decoration: InputDecoration(
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//           filled: true,
//           fillColor: Colors.white,
//           hintText: intl.DateFormat.yMd().format(widget.date),
//           contentPadding:
//               const EdgeInsets.only(top: 0, right: 30, bottom: 0, left: 15),
//           suffixIcon: GestureDetector(
//             child: TextButton(
//               onPressed: () async {
//                 var newDate = await showDatePicker(
//                   context: context,
//                   initialDate: widget.date,
//                   firstDate: DateTime(1900),
//                   lastDate: DateTime(2100),
//                 );

//                 // Don't change the date if the date picker returns null.
//                 if (newDate == null) {
//                   return;
//                 }

//                 widget.onChanged(newDate);
//               },
//               child: const Icon(
//                 Icons.calendar_today,
//                 color: Color.fromARGB(255, 84, 8, 168),
//                 size: 20,
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

class KorbanLaka {
  String nama;
  String tanggalLaka;
  String polda;
  String polres;
  String whatsapp;

  KorbanLaka({
    required this.nama,
    required this.tanggalLaka,
    required this.polda,
    required this.polres,
    required this.whatsapp,
  });
}
