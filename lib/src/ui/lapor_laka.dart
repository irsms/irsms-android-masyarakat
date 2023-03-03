import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_pagination/flutter_pagination.dart';
import 'package:flutter_pagination/widgets/button_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../libraries/colors.dart' as my_colors;
import '../models/laka_model.dart';
import '../services/rest_client.dart';
import 'form_lapor.dart';

class LaporLaka extends StatefulWidget {
  const LaporLaka({super.key});

  @override
  State<LaporLaka> createState() => _LaporLakaState();
}

class _LaporLakaState extends State<LaporLaka> {
  int currentPage = 1;

  String _token = '';

  int _totalPage = 0;
  int _currentPage = 1;

  int _dalamProses = 0;
  int _dataTidakSah = 0;
  int _laporanSelesai = 0;

  Future<void> _fetchTotalLaporan() async {
    var controller = 'masyarakat/lapor_laka';
    var params = {'token': _token};
    var resp = await RestClient().get(controller: controller, params: params);

    if (resp['status']) {
      List rows = resp['rows'];
      for (var row in rows) {
        var statusLaporan = row['status_laporan'];

        if (statusLaporan == null || statusLaporan == '') {
          _dalamProses++;
        } else if (statusLaporan == 'SELESAI') {
          _laporanSelesai++;
        } else if (statusLaporan == 'TIDAK SAH') {
          _dataTidakSah++;
        } else {
          _dalamProses++;
        }
      }
    }
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      _fetchTotalLaporan();

      _getLaporan(page: 1);

      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, '/desktop'),
        ),
        title: const Text('Lapor Laka'),
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 1.5 * kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
                width: .75 * MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: _formLapor,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(my_colors.yellow),
                    padding:
                        MaterialStateProperty.all(const EdgeInsets.all(16)),
                  ),
                  child: const Text(
                    'Buat Laporan',
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                )),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _getLaporan();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(children: [
                        Container(
                          width: 20,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '$_dalamProses',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text(
                          ' Dalam Proses',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        )
                      ]),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(children: [
                        Container(
                          width: 20,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '$_dataTidakSah',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text(
                          ' Data Tidak Sah',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        )
                      ]),
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(children: [
                        Container(
                          width: 20,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            '$_laporanSelesai',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Text(
                          ' Selesai',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        )
                      ]),
                    ),
                  )
                ],
              ),
              const Center(
                child: Text(
                  'Daftar Laporan',
                  style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      height: 2),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [...laka.map((i) => LakaTile(lakaModel: i))],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: (_totalPage > 5
                    ? Pagination(
                        paginateButtonStyles: PaginateButtonStyles(
                            activeBackgroundColor: my_colors.blue,
                            backgroundColor: Colors.white,
                            paginateButtonBorderRadius:
                                BorderRadius.circular(50),
                            textStyle: const TextStyle(
                              color: my_colors.blue,
                            )),
                        prevButtonStyles: PaginateSkipButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: my_colors.blue,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          buttonBackgroundColor: Colors.white,
                        ),
                        nextButtonStyles: PaginateSkipButton(
                            icon: const Icon(
                              Icons.chevron_right,
                              color: my_colors.blue,
                            ),
                            borderRadius: BorderRadius.circular(50),
                            buttonBackgroundColor: Colors.white),
                        onPageChange: (page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        useGroup: false,
                        totalPage: _totalPage,
                        show: _totalPage - 1,
                        currentPage: _currentPage,
                      )
                    : const SizedBox(
                        width: double.infinity,
                      )),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _formLapor() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const Lapor()));
  }

  void _getLaporan({int? page}) async {
    var profile =
        await RestClient().get(controller: 'masyarakat/profile', params: {
      'token': _token,
    });

    if (profile['status']) {
      page ??= 1;
      var controller = 'masyarakat/lapor_laka';
      var params = {
        'token': _token,
        'offset': page - 1,
        'limit': 5,
      };

      var resp = await RestClient().get(controller: controller, params: params);

      laka.clear();

      _totalPage = resp['total'].toInt();

      if (resp['status']) {
        String baseUrl = RestClient().baseURL;

        resp['rows'].forEach((row) {
          var jumlahKorban = int.parse(row['md']);
          jumlahKorban += int.parse(row['lb']);
          jumlahKorban += int.parse(row['lr']);

          laka.add(LakaModel(
            id: int.parse(row['masyarakat__lapor_laka_id']),
            tanggal: row['accident_date'],
            namaJalan: row['road_name'],
            pelaksanaTugas: row['satuan_kepolisian'],
            petugasPelapor: row['officer_id'],
            jumlahKorban: jumlahKorban,
            deskripsi: row['chronological'],
            gambar: "$baseUrl/${row['picture']}",
            statusLaporan: row['status_laporan'],
            kategori: row['category'],
          ));
        });
        setState(() {});
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
  }
}

class LakaTile extends StatelessWidget {
  final LakaModel lakaModel;

  const LakaTile({required this.lakaModel, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 10,
        child: InkWell(
          onTap: () {},
          child: PreferredSize(
              preferredSize: const Size(double.infinity, double.infinity),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      width: 1,
                                      color: Theme.of(context).primaryColor))),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  lakaModel.tanggal,
                                  style: const TextStyle(
                                      color: Colors.blue, fontSize: 10),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                      color: Colors.blue.shade900,
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(
                                      lakaModel.statusLaporan ?? 'DALAM PROSES',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10)),
                                ),
                              ]),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Center(
                              child: FutureBuilder<http.Response>(
                                future: http.get(Uri.parse(lakaModel.gambar)),
                                builder: (context, snapshot) {
                                  switch (snapshot.connectionState) {
                                    case ConnectionState.none:
                                      return const Text('Tidak ada gambar');
                                    case ConnectionState.active:
                                    case ConnectionState.waiting:
                                      return const CircularProgressIndicator();
                                    case ConnectionState.done:
                                      if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      }

                                      if (snapshot.data!.statusCode == 200) {
                                        return SizedBox(
                                            width: 64,
                                            child: Image.network(
                                              lakaModel.gambar,
                                              fit: BoxFit.fitWidth,
                                            ));
                                      }

                                      return const SizedBox(
                                          width: 64,
                                          child: Icon(
                                            Icons.broken_image,
                                            color: my_colors.grey,
                                            size: 64,
                                          ));
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        .625,
                                    child: Text(
                                      'Nama Jalan: ${lakaModel.namaJalan}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        .625,
                                    child: Text(
                                      'Polres/Polda: ${lakaModel.pelaksanaTugas}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        .625,
                                    child: Text(
                                      'Petugas Pelapor: ${lakaModel.petugasPelapor}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  SizedBox(
                                    child: Text(
                                      'Jumlah Korban: ${lakaModel.jumlahKorban}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width *
                                        .625,
                                    child: Text(
                                      'Deskripsi: ${lakaModel.deskripsi}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              )),
        ));
  }
}

final laka = [];
