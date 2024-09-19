import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather/services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedLocationsScreen extends StatefulWidget {
  final List<String> initialSavedLocations;

  const SavedLocationsScreen({super.key, required this.initialSavedLocations});

  @override
  _SavedLocationsScreenState createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  late List<String> _savedLocations;
  final TextEditingController _controller = TextEditingController();
  Map<String, Map<String, dynamic>?> _weatherData = {};
  final WeatherService _weatherService = WeatherService();
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _savedLocations = List.from(widget.initialSavedLocations);
    _loadWeatherDataFromCache();
    _fetchWeatherForSavedLocations();
  }

  Future<void> _loadWeatherDataFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (String location in _savedLocations) {
      final weatherJson = prefs.getString(location);
      if (weatherJson != null) {
        _weatherData[location] = json.decode(weatherJson);
      }
    }
    setState(() {}); // Update UI with cached data
  }

  Future<void> _fetchWeatherForSavedLocations() async {
    for (String location in _savedLocations) {
      if (_weatherData[location] == null) {
        await _fetchWeatherData(location);
      }
    }
  }

  Future<void> _fetchWeatherData(String city) async {
    try {
      final weather = await _weatherService.fetchCurrentWeather(city);
      setState(() {
        _weatherData[city] = {
          'temperature': weather['current']['temp_c'],
          'time': DateTime.now().toLocal().toString(),
          'condition': weather['current']['condition']['text'],
          'humidity': weather['current']['humidity'],
          'icon': weather['current']['condition']['icon'],
        };
      });
      await _saveWeatherDataToCache(city, _weatherData[city]!);
    } catch (e) {
      print('Error fetching weather data: $e');
      setState(() {
        _weatherData[city] = null;
      });
    }
  }

  Future<void> _saveWeatherDataToCache(String city, Map<String, dynamic> weatherData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(city, json.encode(weatherData));
  }

  void _addLocation(String location) async {
    if (location.isNotEmpty && !_savedLocations.contains(location)) {
      setState(() {
        _savedLocations.add(location);
      });
      await _saveLocations();
      _fetchWeatherData(location);
      _controller.clear();
      _filteredSuggestions.clear();
    }
  }

  Future<void> _saveLocations() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('savedLocations', _savedLocations);
  }

  void _deleteLocation(String location) {
    setState(() {
      _savedLocations.remove(location);
      _weatherData.remove(location);
    });
    _saveLocations();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$location deleted successfully!')),
    );
  }

  void _showDeleteConfirmationDialog(String location) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Location'),
          content: Text('Are you sure you want to delete $location?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteLocation(location);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _filterCities(String query) async {
    if (query.isNotEmpty) {
      try {
        final List<String> suggestions = await _weatherService.fetchCitySuggestions(query);
        setState(() {
          _filteredSuggestions = suggestions;
        });
      } catch (e) {
        print('Error fetching city suggestions: $e');
      }
    } else {
      setState(() {
        _filteredSuggestions.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Locations'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Enter a city name',
                  border: OutlineInputBorder(),
                ),
                onChanged: _filterCities,
                onSubmitted: (value) {
                  _addLocation(value);
                },
              ),
            ),
            if (_filteredSuggestions.isNotEmpty)
              Container(
                constraints: BoxConstraints(maxHeight: 200),
                color: Colors.white,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _filteredSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _filteredSuggestions[index];
                    return ListTile(
                      title: Text(suggestion),
                      onTap: () {
                        _addLocation(suggestion);
                      },
                    );
                  },
                ),
              ),
            _savedLocations.isEmpty
                ? Center(child: Text('No saved locations.'))
                : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _savedLocations.length,
              itemBuilder: (context, index) {
                final city = _savedLocations[index];
                final weather = _weatherData[city];

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context, city); // Return selected city
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          city,
                          style: GoogleFonts.lato(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                        ),
                        SizedBox(height: 10),
                        if (weather != null) ...[
                          Image.network(
                            'https:${weather['icon']}',
                            height: 50,
                            width: 50,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Temperature: ${weather['temperature']}°C',
                            style: GoogleFonts.lato(fontSize: 16, color: Colors.blue[900]),
                          ),
                          Text(
                            'Condition: ${weather['condition']}',
                            style: GoogleFonts.lato(fontSize: 16, color: Colors.blue[900]),
                          ),
                          Text(
                            'Humidity: ${weather['humidity']}%',
                            style: GoogleFonts.lato(fontSize: 16, color: Colors.blue[900]),
                          ),
                          Text(
                            'Last Updated: ${weather['time']}',
                            style: GoogleFonts.lato(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blue[700]),
                          ),
                        ] else ...[
                          Text(
                            'Loading ...',
                            style: GoogleFonts.lato(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.red),
                          ),
                        ],
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteConfirmationDialog(city);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
