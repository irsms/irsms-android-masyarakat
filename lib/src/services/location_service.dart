import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:uuid/uuid.dart';

class LocationService {
  // final String key = 'AIzaSyAo-NGabWkkLrOVFkBJmw2hPRSXT_IR-j4';
  final String key = 'AIzaSyAOhYsmTmd7YWwCSFz-MQMRb2ACqlmIA68';

  Future<String> getPlaceId(String input) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key';

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    var placeId = json['candidates'][0]['place_id'] as String;

    return placeId;
  }

  Future<Map<String, dynamic>> getPlace(String input) async {
    final placeId = await getPlaceId(input);
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key';

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    var results = json['result'] as Map<String, dynamic>;

    return results;
  }

  Future<Map<String, dynamic>> getDirections(
      String origin, String destination) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$key';

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    var results = {
      'status': response.statusCode,
      'bounds_ne': json['routes'][0]['bounds']['northeast'],
      'bounds_sw': json['routes'][0]['bounds']['southwest'],
      'start_location': json['routes'][0]['legs'][0]['start_location'],
      'end_location': json['routes'][0]['legs'][0]['end_location'],
      'polyline': json['routes'][0]['overview_polyline']['points'],
      'polyline_decoded': PolylinePoints()
          .decodePolyline(json['routes'][0]['overview_polyline']['points']),
      'geocoded_waypoints': json['geocoded_waypoints'],
      '_raw': json
    };

    return results;
  }

  Future<String> getAddress(
      {required double latitude, required double longitude}) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$key';

    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    var address = json['plus_code']['compound_code'];

    return address;
  }

  Future<Map<String, dynamic>> getAutocomplete(String input) async {
    String uuid = const Uuid().v1();
    final query = [
      'input=$input',
      'key=$key',
      'components=country:id',
      'sessiontoken=$uuid'
    ].join('&');
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?$query';
    var response = await http.get(Uri.parse(url));

    var json = convert.jsonDecode(response.body);

    return json;
  }
}
