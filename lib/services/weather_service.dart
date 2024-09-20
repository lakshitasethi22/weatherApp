import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  final String apiKey = '79e2286e76824509a9e45052241809';
  final String baseUrl = 'https://api.weatherapi.com/v1';

  Future<List<String>> fetchCitySuggestions(String query) async {

    final response = await http.get(Uri.parse('https://countriesnow.space/api/v0.1/countries'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((city) => city['name'].toString()).toList();
    } else {
      throw Exception('Failed to load cities');
    }
  }


  Future<Map<String, dynamic>> fetchCurrentWeather(String city) async {
    final response = await http.get(Uri.parse('$baseUrl/current.json?key=$apiKey&q=$city'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Map<String, dynamic>> fetchWeatherByLocation(double lat, double lon) async {
    final response = await http.get(Uri.parse('$baseUrl/current.json?key=$apiKey&q=$lat,$lon'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  Future<Map<String, dynamic>> fetchForecast(String city) async {
    final response = await http.get(Uri.parse('$baseUrl/forecast.json?key=$apiKey&q=$city&days=7'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load forecast data');
    }
  }

  Future<Map<String, dynamic>> fetchHourlyForecast(String city) async {
    final response = await http.get(Uri.parse('$baseUrl/forecast.json?key=$apiKey&q=$city&days=1&hourly=1'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load hourly forecast data');
    }
  }
}
