import 'package:flutter/material.dart';

class WeatherBackground extends StatelessWidget {
  final String condition;

  const WeatherBackground({Key? key, required this.condition}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String imagePath;

    switch (condition.toLowerCase()) {
      case 'sunny':
        imagePath = 'assets/images/sunny.jpg';
        break;
      case 'cloudy':
        imagePath = 'assets/images/cloudy.jpg';
        break;
      case 'rain':
      case 'rainy':
        imagePath = 'assets/images/rainy.jpg';
        break;
      case 'snow':
        imagePath = 'assets/images/snowy.jpg';
        break;
      default:
        imagePath = 'assets/images/default.jpg'; // Fallback image
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
