import 'package:auto_size_text/auto_size_text.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/rest_client.dart';
import 'landasan_hukum.dart';

class Informasi extends StatefulWidget {
  const Informasi({super.key});

  @override
  State<Informasi> createState() => _InformasiState();
}

class _InformasiState extends State<Informasi> {
  String _token = '';
  Map<String, dynamic> _statistics = <String, dynamic>{};

  final List _infoCard = [
    const InfoCard(
        name: 'Laka Pengguna', icon: Icons.directions_run, total: '0'),
    const InfoCard(name: 'Laka Hari Ini', icon: Icons.car_crash, total: '0'),
    const InfoCard(name: 'Korban Meninggal', icon: Icons.bed, total: '0'),
    const InfoCard(name: 'Total Laka', icon: Icons.local_hospital, total: '0'),
  ];

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      var params = {'token': _token};
      var controller = 'masyarakat/riwayat_kecelakaan';
      var riwayatKecelakaan =
          await RestClient().get(controller: controller, params: params);
      if (riwayatKecelakaan['status']) {
        setState(() {
          _infoCard[0] = InfoCard(
              name: 'Laka Pengguna',
              icon: Icons.directions_run,
              total: '${riwayatKecelakaan['rows'].length}');
        });

        if (riwayatKecelakaan['status'] == false) {
          await Future.delayed(const Duration(seconds: 0));
          if (!mounted) return;
          String msg = riwayatKecelakaan['error'].toString();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        }
      } else {
        tokenExpiredAlert(riwayatKecelakaan);
      }

      String cdate = DateFormat("yyyy-MM-dd").format(DateTime.now());
      Map<String, dynamic> resToday =
          await RestClient().sipulanCount(token: _token, start: cdate);

      if (resToday['status']) {
        setState(() {
          _infoCard[1] = InfoCard(
              name: 'Laka Hari Ini',
              icon: Icons.car_crash,
              total: resToday['total'].toString());
        });
      } else {
        tokenExpiredAlert(resToday);
      }

      var now = DateTime.now();
      var start = DateTime(now.year, 1, 1).toString().substring(0, 10);

      Map<String, dynamic> resYear = await RestClient()
          .sipulanCount(token: _token, start: start, end: cdate);

      if (resYear['status']) {
        setState(() {
          _infoCard[3] = InfoCard(
              name: 'Total Laka ${now.year.toString()}',
              icon: Icons.local_hospital,
              total: resYear['total'].toString());
        });
      } else {
        tokenExpiredAlert(resYear);
      }

      _statistics = await RestClient()
          .sipulanStatistics(token: _token, start: start, end: cdate);

      if (_statistics['status']) {
        int totalMd = 0;
        _statistics['rows'].forEach((row) {
          totalMd += int.parse(row['md']);
        });

        setState(() {
          _infoCard[2] = InfoCard(
              name: 'Korban Meninggal',
              icon: Icons.bed,
              total: totalMd.toString());
        });
      } else {
        tokenExpiredAlert(_statistics);
      }
    });

    super.initState();
  }

  Future<dynamic> tokenExpiredAlert(Map<String, dynamic> response) {
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('IRSMS'),
              content: Text(response['error']),
              actions: [
                ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    // var size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamed(context, '/desktop'),
        ),
        title: const Text('Informasi'),
        bottom: PreferredSize(
            preferredSize: const Size(double.infinity, 1.5 * kToolbarHeight),
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4.0, bottom: 8.0),
                      child: ElevatedButton(
                        onPressed: () => {setState(() {})},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              Theme.of(context).primaryColor),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(16)),
                        ),
                        child: const Text(
                          'Laka',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: ElevatedButton(
                        onPressed: () => {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: ((context) =>
                                      const LandasanHukum())))
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                            Colors.grey,
                          ),
                          padding: MaterialStateProperty.all(
                              const EdgeInsets.all(16)),
                        ),
                        child: const Text(
                          'Landasan Hukum',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                children: List.generate(
                    4,
                    (index) => InfoCardWidget(
                          infoCard: _infoCard[index],
                        )).toList(),
              ),
              const SizedBox(
                height: 16,
              ),
              const Text('Statistik'),
              const Text(
                'Jumlah Laka',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(top: 8.0),
                decoration: const BoxDecoration(color: Colors.white),
                child: PointsLineChart.create(data: _statistics['rows']),
              ),
              const SizedBox(
                height: 16,
              ),
              const Text('Jumlah Laka'),
              const Text(
                'Meninggal Dunia',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(top: 8.0),
                decoration: const BoxDecoration(color: Colors.white),
                child: StackedFillColorBarChart.create(
                  data: _statistics['rows'],
                ),
              ),
              const SizedBox(
                height: 32,
              )
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
          border: Border.all(width: 1, color: Theme.of(context).primaryColor),
          borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  infoCard!.icon,
                  color: Colors.lightBlue,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    NumberFormat('#,###', 'id-ID')
                        .format(int.parse(infoCard!.total)),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  AutoSizeText(infoCard!.name),
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

class PointsLineChart extends StatelessWidget {
  final List<charts.Series<dynamic, int>> seriesList;
  final bool animate;

  const PointsLineChart(this.seriesList, {this.animate = false, super.key});

  factory PointsLineChart.create({List? data}) {
    return PointsLineChart(
      _createData(rawData: data),
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.LineChart(
      seriesList,
      animate: animate,
      defaultRenderer: charts.LineRendererConfig(includePoints: true),
      // behaviors: [charts.SeriesLegend()],
    );
  }

  static List<charts.Series<ChartsModel, int>> _createData({List? rawData}) {
    final data = <ChartsModel>[];

    if (rawData != null) {
      for (var e in rawData) {
        data.add(
            ChartsModel(int.parse(e['bulan']), int.parse(e['total_laka'])));
      }
    }

    return [
      charts.Series<ChartsModel, int>(
          id: 'Laka',
          colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
          domainFn: (ChartsModel chartsModel, _) => chartsModel.id,
          measureFn: (ChartsModel chartsModel, _) => chartsModel.total,
          data: data),
    ];
  }
}

class StackedFillColorBarChart extends StatelessWidget {
  final List<charts.Series<dynamic, String>> seriesList;
  final bool animate;

  const StackedFillColorBarChart(this.seriesList,
      {this.animate = true, super.key});

  factory StackedFillColorBarChart.create({List? data}) {
    return StackedFillColorBarChart(
      _createData(rawData: data),
      animate: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return charts.BarChart(
      seriesList,
      animate: animate,
      defaultRenderer: charts.BarRendererConfig(
          groupingType: charts.BarGroupingType.stacked, strokeWidthPx: 2.0),
      // behaviors: [charts.SeriesLegend()],
    );
  }

  static List<charts.Series<ChartsModel, String>> _createData({List? rawData}) {
    final data = <ChartsModel>[];

    if (rawData != null) {
      for (var e in rawData) {
        data.add(ChartsModel(int.parse(e['bulan']), int.parse(e['md'])));
      }
    }

    return [
      charts.Series<ChartsModel, String>(
        id: 'Meninggal Dunia',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (ChartsModel chartsModel, _) => chartsModel.id.toString(),
        measureFn: (ChartsModel chartsModel, _) => chartsModel.total,
        data: data,
        fillColorFn: (_, __) =>
            charts.MaterialPalette.blue.shadeDefault.lighter,
      ),
    ];
  }
}

class ChartsModel {
  final int id;
  final int total;
  ChartsModel(this.id, this.total);
}
