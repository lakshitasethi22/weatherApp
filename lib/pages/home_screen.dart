import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather/services/weather_service.dart';
import 'package:weather/services/weather_background.dart';
import 'package:weather/pages/saved_locations_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _loadSavedLocations();
    _getCurrentLocation();
  }

  Future<void> _loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedLocations = prefs.getStringList('savedLocations') ?? [];
    });
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
      await _fetchWeather();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch location. Please try again later.')),
      );
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final weatherData = await _weatherService.fetchCurrentWeather(_city);
      final forecastData = await _weatherService.fetchForecast(_city);
      final hourlyData = await _weatherService.fetchHourlyForecast(_city);

      // Debugging output
      print('Weather Data: $weatherData');

      setState(() {
        _currentWeather = weatherData;

        // Debugging output
        print('Current Weather: $_currentWeather');

        _currentWeather?['forecast'] = forecastData['forecast'];
        _currentWeather?['hourly'] = hourlyData['hour'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch weather data. Please try again later.')),
      );
    }
  }

  // New method to get background image
  String _getBackgroundImage() {
    if (_currentWeather != null && _currentWeather!['current'] != null) {
      String condition = _currentWeather!['current']['condition']['text'].toLowerCase();
      print('Weather Condition: $condition'); // Debugging output
      return _mapConditionToBackgroundImage(condition);
    }
    return 'assets/images/default_background.jpg';
  }

  String _mapConditionToBackgroundImage(String condition) {
    switch (condition) {
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

  Widget _buildSunriseSunset() {
    if (_currentWeather != null && _currentWeather!['forecast'] != null && _currentWeather!['forecast']['forecastday'].isNotEmpty) {
      final astro = _currentWeather!['forecast']['forecastday'][0]['astro'];
      final sunrise = astro?['sunrise'] ?? 'N/A';
      final sunset = astro?['sunset'] ?? 'N/A';

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildWeatherDetail('Sunrise', Icons.wb_sunny, sunrise),
          _buildWeatherDetail('Sunset', Icons.brightness_3, sunset),
        ],
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildNext7DaysForecast() {
    if (_currentWeather != null && _currentWeather!['forecast'] != null) {
      final forecastDays = _currentWeather!['forecast']['forecastday'];

      return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: forecastDays.length,
        itemBuilder: (context, index) {
          final day = forecastDays[index];
          return ListTile(
            title: Text(day['date'], style: TextStyle(color: Colors.white)),
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
    } else {
      return Center(child: Text('No forecast data available.'));
    }
  }

  Widget
  _buildHourlyForecast() {
    if (_currentWeather != null && _currentWeather!['hourly'] != null && _currentWeather!['hourly'].isNotEmpty) {
      final hourlyData = _currentWeather!['hourly'];

      return Container(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: hourlyData.length,
          itemBuilder: (context, index) {
            final hour = hourlyData[index];
            return Container(
              width: 70,
              child: Column(
                children: [
                  Text(
                    hour['time'].substring(11, 16),
                    style: TextStyle(color: Colors.white),
                  ),
                  Image.network(
                    'http:${hour['condition']['icon']}',
                    height: 40,
                    width: 40,
                  ),
                  Text(
                    '${hour['temp_c']}°C',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else {
      return Center(child: Text('No hourly forecast data available.'));
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
                      _citySuggestions = suggestions.cast<Map<String, dynamic>>();
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
        setState(() {
          _savedLocations.add(_city);
        });
        _saveLocations();
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

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('savedLocations', _savedLocations);
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

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      appBar: AppBar(
        title: Text('Weather App'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveCityWeather,
          ),

          IconButton(
            icon: Icon(Icons.location_city),
            onPressed: _navigateToSavedLocations,
          ),

        ],
        backgroundColor: Colors.blueAccent,
      ),
      body: _currentWeather == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Stack(
          children: [
            WeatherBackground(condition: _getBackgroundImage()),
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
                  _buildSunriseSunset(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeatherDetail('Humidity', Icons.opacity, _currentWeather?['current']?['humidity'] ?? 'N/A'),
                      _buildWeatherDetail('Wind (KPH)', Icons.wind_power, _currentWeather?['current']?['wind_kph'] ?? 'N/A'),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    "Next 24 Hours Weather Forecast",
                    style: GoogleFonts.lato(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  _build24HourForecast(),
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
                  _buildNext7DaysForecast(),
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

      return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: hourlyData.length,
        itemBuilder: (context, index) {
          final hour = hourlyData[index];
          return ListTile(
            title: Text(hour['time'].substring(11, 16), style: TextStyle(color: Colors.white)),
            leading: Image.network(
              'http:${hour['condition']['icon']}',
              height: 40,
              width: 40,
            ),
            subtitle: Text(
              '${hour['temp_c']}°C',
              style: TextStyle(color: Colors.white),
            ),
            trailing: Text(
              '${hour['chance_of_rain']}% Rain',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          );
        },
      );
    } else {
      return Center(child: Text('No hourly forecast data available.'));
    }
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
