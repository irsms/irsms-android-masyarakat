import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_pagination/flutter_pagination.dart';
import 'package:flutter_pagination/widgets/button_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../libraries/colors.dart' as my_colors;
import '../services/rest_client.dart';
import 'form_aduan.dart';

class Pengaduan extends StatefulWidget {
  const Pengaduan({super.key});

  @override
  State<Pengaduan> createState() => _PengaduanState();
}

List aduan = <Aduan>[];

class _PengaduanState extends State<Pengaduan> {
  late String _token;

  final List<String> _categories = [];

  final List _isSelected = List.generate(5, (index) => [false]);

  Future<List<String>> get getCategories async {
    var controller = 'aduan_category';
    var params = {'token': _token};
    var resp = await RestClient().get(controller: controller, params: params);

    List<String> cats = [];
    if (resp['status']) {
      resp['rows'].forEach((row) => cats.add(row['aduan_category']));
    }
    return cats;
  }

  void _formAduan() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const FormAduan()));
  }

  int _totalPage = 0;
  int _currentPage = 1;

  @override
  void initState() {
    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';

      _categories.addAll(await getCategories);

      for (var i = 0; i < _categories.length; i++) {
        _isSelected[i] = [false];
      }

      await _getAduan();

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
        title: const Text('Pengaduan Masyarakat'),
        bottom: PreferredSize(
          preferredSize: const Size(double.infinity, 1.5 * kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
                width: 0.75 * MediaQuery.of(context).size.width,
                child: ElevatedButton(
                  onPressed: _formAduan,
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(my_colors.yellow),
                    padding:
                        MaterialStateProperty.all(const EdgeInsets.all(16)),
                  ),
                  child: const Text(
                    'Form Aduan',
                    style: TextStyle(
                        color: my_colors.blue, fontWeight: FontWeight.bold),
                  ),
                )),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _getAduan(page: _currentPage);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Center(
                child: Text(
                  'Daftar Aduan',
                  style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      height: 2),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ..._categories.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: ToggleButtons(
                            borderRadius: BorderRadius.circular(32),
                            constraints: BoxConstraints.expand(
                                width: (MediaQuery.of(context).size.width -
                                        32 * _categories.length) /
                                    _categories.length,
                                height: 32),
                            fillColor: Theme.of(context).primaryColor,
                            selectedColor: Colors.white,
                            onPressed: (index) async {
                              setState(() {
                                _isSelected[e.key][index] =
                                    !_isSelected[e.key][index];
                              });

                              await _getAduan();
                            },
                            isSelected: _isSelected[e.key],
                            children: [
                              Text(
                                e.value,
                                style: const TextStyle(fontSize: 14 * .75),
                              )
                            ]),
                      );
                    })
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: aduan.isNotEmpty
                    ? [...aduan.map((i) => AduanTile(aduan: i))]
                    : [const Text('Tidak ada data')],
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

  Future<void> _getAduan({int? page}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    var profil =
        await RestClient().get(controller: 'masyarakat/profile', params: {
      'token': token,
    });

    if (profil['status']) {
      page ??= 1;
      var controller = 'masyarakat/aduan';
      var params = {
        'token': token,
        'offset': page - 1,
        'limit': 5,
      };

      // for (var i = 0; i < _isSelected.length; i++) {
      //   if (_isSelected[i][0]) {
      //     params['category[$i]'] = _categories[i];
      //   }
      // }

      var resp = await RestClient().get(controller: controller, params: params);

      aduan.clear();

      setState(() {
        _totalPage = resp['total'].toInt();
      });

      if (resp['status']) {
        String baseUrl = RestClient().baseURL;

        resp['rows'].forEach((row) {
          String description = row['description'];
          String picture = "$baseUrl/${row['picture']}";
          String roadName = row['road_name'];
          String satuanKepolisian = row['satuan_kepolisian'];
          String cat = row['category'];
          aduan.add(Aduan(
              roadName: roadName,
              satuanKepolisian: satuanKepolisian,
              category: cat,
              description: description,
              picture: picture));
        });

        setState(() {});
      }
    } else {
      if (!mounted) return;

      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('IRSMS'),
                content: Text(profil['error']),
                actions: [
                  TextButton(
                      onPressed: () {
                        if (profil['error'] == 'Expired token') {
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

class AduanTile extends StatelessWidget {
  final Aduan? aduan;

  const AduanTile({this.aduan, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 10,
        child: PreferredSize(
            preferredSize: const Size(double.infinity, double.infinity),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Center(
                    child: FutureBuilder<http.Response>(
                      future: http.get(Uri.parse(aduan!.picture)),
                      builder: (context, snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                            return const Text('Tidak ada gambar');
                          case ConnectionState.active:
                          case ConnectionState.waiting:
                            return const CircularProgressIndicator();
                          case ConnectionState.done:
                            if (snapshot.hasError) {
                              return Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(
                                    overflow: TextOverflow.ellipsis),
                              );
                            }

                            if (snapshot.data!.statusCode == 200) {
                              return SizedBox(
                                  width: 64,
                                  child: Image.network(
                                    aduan!.picture,
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
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .625,
                          child: Text(
                            'Nama Jalan: ${aduan!.roadName}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .625,
                          child: Text(
                            'Wilayah: ${aduan!.satuanKepolisian}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .625,
                          child: Text(
                            'Kategori: ${aduan!.category}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .625,
                          child: Text(
                            'Deskripsi: ${aduan!.description}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )));
  }
}

class Aduan {
  final String roadName;
  final String satuanKepolisian;
  final String category;
  final String description;
  final String picture;

  Aduan(
      {required this.roadName,
      required this.satuanKepolisian,
      required this.category,
      required this.description,
      required this.picture});
}
