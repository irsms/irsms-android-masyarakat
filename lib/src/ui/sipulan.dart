import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../libraries/colors.dart' as my_color;
import '../services/rest_client.dart';

class Sipulan extends StatefulWidget {
  const Sipulan({super.key});

  @override
  State<Sipulan> createState() => _SipulanState();
}

class _SipulanState extends State<Sipulan> {
  String _token = '';
  final List<RiwayatKecelakaanModel> _riwayatKecelakaan = [];
  Map<String, dynamic> _profile = {};

  Future<dynamic> tokenExpiredAlert(Map<String, dynamic> response) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('IRSMS'),
              content: Text(response['error']),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/');
                    },
                    child: const Text('OK'))
              ],
            ));
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      var profile =
          await RestClient().get(controller: 'masyarakat/profile', params: {
        'token': _token,
      });

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

      var params = {'token': _token};
      var controller = 'masyarakat/riwayat_kecelakaan';
      var riwayatKecelakaan =
          await RestClient().get(controller: controller, params: params);

      if (riwayatKecelakaan['status']) {
        riwayatKecelakaan['rows'].forEach((row) {
          _riwayatKecelakaan.add(RiwayatKecelakaanModel(
            noSep: row['no_sep'] ?? '-',
            nik: row['nik'] ?? '-',
            nama: row['name'] ?? '-',
            faskes: row['faskes_name'] ?? '-',
            noLp: row['no_lp_manual'] ?? row['no_lp_system'] ?? '-',
            tanggal: row['accident_date'] ?? '-',
            statusKlaim: row['status_korban'] ?? '-',
          ));
        });

        setState(() {});
      } else {
        tokenExpiredAlert(riwayatKecelakaan);
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIPULAN'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                height: 172,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(10.0)),
                child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          SizedBox(
                            width: 96,
                            height: 96,
                            child: FutureBuilder<http.Response>(
                              future: http.get(Uri.parse(
                                  '${RestClient().baseURL}/${_profile["userpic"]}')),
                              builder: (context, snapshot) {
                                switch (snapshot.connectionState) {
                                  case ConnectionState.none:
                                    return const Icon(
                                      Icons.person,
                                      size: 64,
                                    );
                                  case ConnectionState.active:
                                  case ConnectionState.waiting:
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  case ConnectionState.done:
                                    if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    }
                                    if (snapshot.data!.statusCode == 200) {
                                      return SizedBox(
                                          child: ClipRRect(
                                        borderRadius: BorderRadius.circular(96),
                                        child: Image.network(
                                          '${RestClient().baseURL}/${_profile["userpic"]}',
                                          width: 96,
                                          height: 96,
                                          fit: BoxFit.cover,
                                        ),
                                      ));
                                    }

                                    return Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                          color: my_color.yellow,
                                          borderRadius:
                                              BorderRadius.circular(96)),
                                      child: const Icon(
                                        Icons.person,
                                        color: my_color.blue,
                                        size: 72,
                                      ),
                                    );
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              "${_profile['nama_depan'] ?? ''} ${_profile['nama_belakng'] ?? ''}",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.white,
                              ),
                            ),
                          )
                        ],
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Username',
                                style: TextStyle(color: Colors.white),
                              ),
                              Text(
                                _profile['username'] ?? '-',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const InkWell(
                        child: Icon(
                          Icons.settings,
                          color: Colors.white,
                        ),
                      )
                    ]),
              ),
              SizedBox(
                  width: double.infinity,
                  child: _riwayatKecelakaan.isNotEmpty
                      ? RiwayatKecelakaanWidget(_riwayatKecelakaan)
                      : const Center(
                          child: Text(
                          'Tidak ada riwayat kecelakaan.',
                          style: TextStyle(height: 4),
                        )))
            ],
          ),
        ),
      ),
    );
  }
}

class InfoCardWidget extends StatelessWidget {
  final InfoCard? infoCard;

  const InfoCardWidget({this.infoCard, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(width: 2, color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(10.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  infoCard!.icon,
                  color: Colors.lightBlue,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    infoCard!.total,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(infoCard!.name),
                ],
              )
            ]),
      ),
    );
  }
}

class InfoCard {
  final String name;
  final IconData icon;
  final String total;

  const InfoCard({required this.name, required this.icon, required this.total});
}

final infoCard = [
  const InfoCard(
      name: 'Laka Pengguna', icon: Icons.directions_run, total: '10'),
  const InfoCard(name: 'Laka Hari Ini', icon: Icons.car_crash, total: '10'),
  const InfoCard(name: 'Korban Meninggal', icon: Icons.bed, total: '20'),
  const InfoCard(
      name: 'Total Laka', icon: Icons.local_hospital, total: '20.000'),
];

class RiwayatKecelakaanWidget extends StatelessWidget {
  final List kecelakaanList;

  const RiwayatKecelakaanWidget(this.kecelakaanList, {super.key});

  factory RiwayatKecelakaanWidget.dummy() {
    return RiwayatKecelakaanWidget(_createData());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child:
          Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        ...kecelakaanList.map((e) => Card(
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
                          'NO SEP',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          e.noSep,
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
                          e.nik,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          'NAMA',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          e.nama,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          'FASKES',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          e.faskes,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          'NO LP',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          e.noLp,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          'TANGGAL',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          e.tanggal.toString(),
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                        const Text(
                          'STATUS KLAIM',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          e.statusKlaim,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        const SizedBox(
                          height: 8.0,
                        ),
                      ],
                    ),
                  )),
            )),
      ]),
    );
  }

  static List _createData() {
    final data = [
      RiwayatKecelakaanModel(
          noSep: '0000000000000001',
          nik: '1234123412341234',
          nama: 'No Name',
          faskes: 'RSUD Tangerang',
          noLp: 'LP/0000/000/x/2022/LL',
          tanggal: DateTime.now().toString(),
          statusKlaim: 'DI-COVER JASARAHARJA'),
      RiwayatKecelakaanModel(
          noSep: '0000000000000001',
          nik: '1234123412341234',
          nama: 'No Name',
          faskes: 'RSUD Tangerang',
          noLp: 'LP/0000/000/x/2022/LL',
          tanggal: DateTime.now().toString(),
          statusKlaim: 'DI-COVER JASARAHARJA')
    ];

    return data;
  }
}

class RiwayatKecelakaanModel {
  final String? noSep;
  final String? nik;
  final String? nama;
  final String? faskes;
  final String? noLp;
  final String? tanggal;
  final String? statusKlaim;

  RiwayatKecelakaanModel({
    this.noSep,
    this.nik,
    this.nama,
    this.faskes,
    this.noLp,
    this.tanggal,
    this.statusKlaim,
  });
}
