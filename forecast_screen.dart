import 'package:flutter/material.dart';
import 'package:weather/services/weather_service.dart';
import 'package:google_fonts/google_fonts.dart';

class ForecastScreen extends StatelessWidget {
  final String city;

  const ForecastScreen({super.key, required this.city});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('7-Day Forecast'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: WeatherService().fetchForecast(city),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('No data available.'));
          }

          final forecastData = snapshot.data!;

          return ListView.builder(
            itemCount: forecastData['forecast']['forecastday'].length,
            itemBuilder: (context, index) {
              final day = forecastData['forecast']['forecastday'][index];
              return ListTile(
                title: Text(day['date']),
                subtitle: Text(
                  '${day['day']['condition']['text']}: Max ${day['day']['maxtemp_c']}°C, Min ${day['day']['mintemp_c']}°C',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
