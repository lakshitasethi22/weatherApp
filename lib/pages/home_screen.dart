import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/services/weather_service.dart';
import 'package:weather/pages/saved_locations_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  String _city = 'London';
  Map<String, dynamic>? _currentWeather;
  bool _isLoading = false;
  List<String> _savedLocations = [];
  String _backgroundImage = 'assets/images/default_background.jpg'; // Background image variable

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final weatherData = await _weatherService.fetchWeatherByLocation(position.latitude, position.longitude);
      setState(() {
        _currentWeather = weatherData;
        _city = weatherData['location']['name'] ?? 'Unknown';
        String condition = _currentWeather?['current']?['condition']['text'] ?? 'Clear';
        _backgroundImage = _getBackgroundImage(condition); // Set background image
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch location. Please try again later.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final weatherData = await _weatherService.fetchCurrentWeather(_city);
      final forecastData = await _weatherService.fetchForecast(_city);
      final hourlyData = await _weatherService.fetchHourlyForecast(_city);

      setState(() {
        _currentWeather = weatherData;
        _currentWeather?['forecast'] = forecastData['forecast'];
        _currentWeather?['hourly'] = hourlyData['hour'];
        String condition = _currentWeather?['current']?['condition']['text'] ?? 'Clear';
        _backgroundImage = _getBackgroundImage(condition); // Update background image
      });
    } catch (e) {
      print('Error fetching weather data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch weather data. Please try again later.')),
      );
    }
  }

  void _saveCityWeather() {
    if (_currentWeather != null) {
      if (_savedLocations.contains(_city)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_city is already saved.')),
        );
      } else {
        _savedLocations.add(_city);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$_city saved successfully!')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No weather data to save.')),
      );
    }
  }

  void _navigateToSavedLocations() async {
    final selectedCity = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedLocationsScreen(initialSavedLocations: _savedLocations),
      ),
    );

    if (selectedCity != null) {
      setState(() {
        _city = selectedCity;
      });
      _fetchWeather();
    }
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
        return 'assets/images/snowy_background.jpg';
      default:
        return 'assets/images/default_background.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    String condition = _currentWeather?['current']?['condition']['text'] ?? 'Clear';

    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveCityWeather,
          ),
        ],
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _currentWeather == null
          ? Center(child: Text('No weather data available.'))
          : SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_backgroundImage), // Use the updated background image
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  InkWell(
                    child: Text(
                      _city,
                      style: GoogleFonts.lato(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: Column(
                      children: [
                        if (_currentWeather?['current'] != null) ...[
                          Image.network(
                            'http:${_currentWeather!['current']['condition']['icon']}',
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                          SizedBox(height: 10),
                          Text(
                            '${_currentWeather!['current']['temp_c']?.round() ?? 'N/A'}°C',
                            style: GoogleFonts.lato(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _currentWeather!['current']['condition']['text'] ?? 'No Condition',
                            style: GoogleFonts.lato(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 15),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeatherDetail('Sunrise', Icons.wb_sunny,
                          _currentWeather?['forecast']?['forecastday']?[0]['astro']?['sunrise'] ?? 'N/A'),
                      _buildWeatherDetail('Sunset', Icons.brightness_3,
                          _currentWeather?['forecast']?['forecastday']?[0]['astro']?['sunset'] ?? 'N/A'),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeatherDetail('Humidity', Icons.opacity,
                          _currentWeather?['current']?['humidity'] ?? 'N/A'),
                      _buildWeatherDetail('Wind (KPH)', Icons.wind_power,
                          _currentWeather?['current']?['wind_kph'] ?? 'N/A'),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Next 24 Hours Weather",
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Container(
                    height: 120, // Fixed height to prevent overflow
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _weatherService.fetchHourlyForecast(_city),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData || snapshot.data == null) {
                          return Center(child: Text('No data available.'));
                        }

                        final hourlyData = snapshot.data!;
                        final hours = hourlyData['forecast']['forecastday'][0]['hour'];

                        if (hours == null || hours.isEmpty) {
                          return Center(child: Text('No hourly data available.'));
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: hours.length,
                          itemBuilder: (context, index) {
                            final hour = hours[index];
                            final dateTime = DateTime.parse(hour['time']); // Parse the time string
                            final formattedTime = DateFormat.jm().format(dateTime); // Format to a readable time
                            return Container(
                              width: 100, // Set width for each hour
                              padding: EdgeInsets.all(8.0), // Adjust padding as needed
                              child: Card(
                                color: Colors.black54,
                                child: SingleChildScrollView( // Add SingleChildScrollView here
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.network(
                                        'http:${hour['condition']['icon']}',
                                        height: 40,
                                        width: 40,
                                      ),
                                      SizedBox(height: 4), // Reduce height to prevent overflow
                                      Text(
                                        '${hour['temp_c']}°C',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(height: 2), // Reduce height to prevent overflow
                                      Text(
                                        '${hour['chance_of_rain']}% chance of rain',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        formattedTime,
                                        style: TextStyle(color: Colors.white , fontSize: 12),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Next 7 Days Weather Forecast",
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  _build7DayForecast(),
                  SizedBox(height: 45),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToSavedLocations,
        child: Icon(Icons.list),
        tooltip: 'Saved Locations',
      ),
    );
  }

  Widget _build7DayForecast() {
    if (_currentWeather != null && _currentWeather!['forecast'] != null) {
      final forecastData = _currentWeather!['forecast']['forecastday'];

      return Column(
        children: List.generate(forecastData.length, (index) {
          final day = forecastData[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 5),
            child: ListTile(
              title: Text(
                DateFormat('EEEE').format(DateTime.parse(day['date'])),
                style: TextStyle(color: Colors.black),
              ),
              subtitle: Text(
                '${day['day']['condition']['text']} - Max: ${day['day']['maxtemp_c']}°C, Min: ${day['day']['mintemp_c']}°C',
              ),
              leading: Image.network(
                'http:${day['day']['condition']['icon']}',
                height: 40,
                width: 40,
              ),
            ),
          );
        }),
      );
    }
    return Center(child: Text('No 7-day forecast available.'));
  }

  Widget _buildWeatherDetail(String title, IconData icon, dynamic value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.white)),
            Text(value.toString(), style: TextStyle(color: Colors.white)), // Ensure value is a string
          ],
        ),
      ],
    );
  }
}
