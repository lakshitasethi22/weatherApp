import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:weather/services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherDetailScreen extends StatelessWidget {
  final String city;
  final WeatherService weatherService = WeatherService();

  WeatherDetailScreen({Key? key, required this.city}) : super(key: key);

  Future<Map<String, dynamic>> _fetchWeatherData() async {
    final weather = await weatherService.fetchCurrentWeather(city);
    return {
      'temperature': weather['current']['temp_c'],
      'condition': weather['current']['condition']['text'],
      'humidity': weather['current']['humidity'],
      'icon': weather['current']['condition']['icon'],
    };
  }

  Future<void> _saveLocation(String city) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedLocations = prefs.getStringList('savedLocations') ?? [];
    if (!savedLocations.contains(city)) {
      savedLocations.add(city);
      prefs.setStringList('savedLocations', savedLocations);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(city),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchWeatherData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final weather = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network('https:${weather['icon']}', height: 100, width: 100),
                  SizedBox(height: 10),
                  Text(
                    'Temperature: ${weather['temperature']}°C',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text('Condition: ${weather['condition']}', style: TextStyle(fontSize: 18)),
                  Text('Humidity: ${weather['humidity']}%', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _saveLocation(city);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$city saved successfully!')),
                      );
                    },
                    child: Text('Save Location'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
