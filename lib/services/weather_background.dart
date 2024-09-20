import 'package:flutter/material.dart';

class WeatherBackground extends StatelessWidget {
  final String condition;

  const WeatherBackground({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    String imagePath;

    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        imagePath = 'assets/images/sunny.jpg'; // Add your sunny image path
        break;
      case 'rain':
      case 'drizzle':
        imagePath = 'assets/images/rainy.jpg'; // Add your rainy image path
        break;
      case 'cloudy':
        imagePath = 'assets/images/cloudy.jpg'; // Add your cloudy image path
        break;
      case 'snow':
        imagePath = 'assets/images/snowy.jpg'; // Add your snowy image path
        break;
      default:
        imagePath = 'assets/images/default.jpg'; // Default background
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
