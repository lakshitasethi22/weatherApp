import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/services/weather_service.dart';
import 'package:weather/pages/saved_locations_screen.dart';
import 'package:weather/services/weather_background.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();
  String _city = 'London';
  List<Map<String, dynamic>> _citySuggestions = [];
  Map<String, dynamic>? _currentWeather;
  List<String> _savedLocations = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final weatherData = await _weatherService.fetchWeatherByLocation(position.latitude, position.longitude);
      setState(() {
        _currentWeather = weatherData;
        _city = weatherData['location']['name'] ?? 'Unknown';
      });
    } catch (e) {
      print('Error fetching location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch location. Please try again later.')),
      );
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final weatherData = await _weatherService.fetchCurrentWeather(_city);
      final forecastData = await _weatherService.fetchForecast(_city);
      final hourlyData = await _weatherService.fetchHourlyForecast(_city); // Fetch hourly data

      setState(() {
        _currentWeather = weatherData;
        _currentWeather?['forecast'] = forecastData['forecast'];
        _currentWeather?['hourly'] = hourlyData['hour']; // Store hourly data
      });
    } catch (e) {
      print('Error fetching weather data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch weather data. Please try again later.')),
      );
    }
  }

  void _showCitySelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter City Name"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) async {
                  if (value.isNotEmpty) {
                    var suggestions = await _weatherService.fetchCitySuggestions(value);
                    setState(() {
                      _citySuggestions = (suggestions as List<Map<String, dynamic>>?) ?? [];
                    });
                  } else {
                    setState(() {
                      _citySuggestions = [];
                    });
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "City",
                ),
              ),
              SizedBox(height: 10),
              _citySuggestions.isNotEmpty
                  ? Container(
                height: 200,
                child: ListView.builder(
                  itemCount: _citySuggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_citySuggestions[index]['name']),
                      onTap: () {
                        setState(() {
                          _city = _citySuggestions[index]['name'];
                        });
                        Navigator.pop(context);
                        _fetchWeather();
                      },
                    );
                  },
                ),
              )
                  : SizedBox.shrink(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
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
        _city = selectedCity; // Update the city in HomeScreen
      });
      _fetchWeather(); // Fetch weather for the selected location
    }
  }

  @override
  Widget build(BuildContext context) {
    String condition = _currentWeather?['current']?['condition']['text'] ?? 'Clear';

    return Scaffold(
      backgroundColor: Colors.blueAccent,
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
      body: _currentWeather == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Stack(
          children: [
            WeatherBackground(condition: condition),
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  InkWell(
                    onTap: _showCitySelectionDialog,
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
                  _build24HourForecast(), // New method for 24-hour forecast
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

  Widget _build24HourForecast() {
    if (_currentWeather != null && _currentWeather!['hourly'] != null) {
      final hourlyData = _currentWeather!['hourly'];

      return SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: hourlyData.length,
          itemBuilder: (context, index) {
            final hour = hourlyData[index];
            return Container(
              width: 80,
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Display time in HH:MM format
                  Text(
                    hour['time'].substring(11, 16), // Extract time
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  // Display weather icon
                  Image.network(
                    'http:${hour['condition']['icon']}',
                    height: 40,
                    width: 40,
                  ),
                  // Display temperature
                  Text(
                    '${hour['temp_c']}°C',
                    style: TextStyle(color: Colors.white),
                  ),
                  // Display chance of rain
                  Text(
                    '${hour['chance_of_rain']}% Rain',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      return Center(child: Text('No hourly data available.'));
    }
  }

  Widget _build7DayForecast() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherService.fetchForecast(_city),
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
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: forecastData['forecast']['forecastday'].length,
          itemBuilder: (context, index) {
            final day = forecastData['forecast']['forecastday'][index];
            return ListTile(
              title: Text(day['date']),
              leading: Image.network(
                'http:${day['day']['condition']['icon']}',
                height: 40,
                width: 40,
              ),
              subtitle: Text(
                'Max: ${day['day']['maxtemp_c']}°C, Min: ${day['day']['mintemp_c']}°C',
                style: TextStyle(color: Colors.white),
              ),
              trailing: Text(
                '${day['day']['avgtemp_c']}°C',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeatherDetail(String label, IconData icon, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(
            padding: EdgeInsets.all(5),
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: AlignmentDirectional.topStart,
                end: AlignmentDirectional.bottomEnd,
                colors: [
                  Color(0xFF1A2344).withOpacity(0.5),
                  Color(0xFF1A2344).withOpacity(0.2),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white),
                SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value.toString(),
                  style: GoogleFonts.lato(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
