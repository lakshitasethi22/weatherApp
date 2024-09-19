import 'package:flutter/material.dart';

class WeatherBackground extends StatelessWidget {
  final String condition;

  const WeatherBackground({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_getBackgroundImage(condition)),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _getBackgroundImage(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
        return 'assets/images/sunny_background.jpg';
      case 'cloudy':
        return 'assets/images/cloudy_background.jpg';
      case 'rain':
      case 'rainy':
        return 'assets/images/rainy_background.jpg';
      case 'snow':
      case 'snowy':
        return 'assets/images/snowy_background.jpg';
      default:
        return 'assets/images/default_background.jpg';
    }
  }
}
