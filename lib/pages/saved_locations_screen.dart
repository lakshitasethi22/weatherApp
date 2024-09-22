import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather/services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SavedLocationsScreen extends StatefulWidget {
  final List<String> initialSavedLocations;

  const SavedLocationsScreen({super.key, required this.initialSavedLocations});

  @override
  _SavedLocationsScreenState createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  late List<String> _savedLocations;
  Map<String, Map<String, dynamic>?> _weatherData = {};
  final WeatherService _weatherService = WeatherService();

  List<String> _countries = [];
  Map<String, List<String>> _countryCities = {};
  String? _selectedCountry;
  String? _selectedCity;
  List<String> _filteredCountries = [];
  List<String> _filteredCities = [];
  TextEditingController _countryController = TextEditingController();
  TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _savedLocations = List.from(widget.initialSavedLocations);
    _loadWeatherDataFromCache();
    _fetchWeatherForSavedLocations();
    _fetchCountriesAndCities();
  }

  Future<void> _loadWeatherDataFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (String location in _savedLocations) {
      final weatherJson = prefs.getString(location);
      if (weatherJson != null) {
        _weatherData[location] = json.decode(weatherJson);
      }
    }
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
      _selectedCity = null; // Reset selected city
      _cityController.clear(); // Clear city input
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

  Future<void> _fetchCountriesAndCities() async {
    try {
      final response = await http.get(Uri.parse('https://countriesnow.space/api/v0.1/countries'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          _countries = List<String>.from(data.map((country) => country['country']));
          _countryCities = {
            for (var country in data)
              country['country']: List<String>.from(country['cities']),
          };
        });
      }
    } catch (e) {
      print('Error fetching countries and cities: $e');
    }
  }

  void _filterCountries(String query) {
    setState(() {
      _filteredCountries = _countries
          .where((country) => country.toLowerCase().startsWith(query.toLowerCase()))
          .toList();
    });
  }

  void _filterCities(String query) {
    if (_selectedCountry != null) {
      setState(() {
        _filteredCities = _countryCities[_selectedCountry]!
            .where((city) => city.toLowerCase().startsWith(query.toLowerCase()))
            .toList();
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
              child: Column(
                children: [
                  // Country selection input
                  TextField(
                    controller: _countryController,
                    decoration: InputDecoration(
                      labelText: 'Select Country',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: _filterCountries,
                  ),
                  // Country suggestions
                  if (_filteredCountries.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _filteredCountries.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_filteredCountries[index]),
                          onTap: () {
                            setState(() {
                              _selectedCountry = _filteredCountries[index];
                              _countryController.text = _selectedCountry!; // Set selected country
                              _selectedCity = null; // Reset city selection
                              _cityController.clear(); // Clear city input
                              _filteredCountries.clear(); // Clear suggestions
                            });
                          },
                        );
                      },
                    ),
                  SizedBox(height: 16), // Spacing between fields
                  // City selection input
                  if (_selectedCountry != null) ...[
                    TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'Select City',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: _filterCities,
                    ),
                    // City suggestions
                    if (_filteredCities.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _filteredCities.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(_filteredCities[index]),
                            onTap: () {
                              setState(() {
                                _selectedCity = _filteredCities[index];
                                _cityController.text = _selectedCity!; // Set selected city
                                _filteredCities.clear(); // Clear suggestions
                              });
                            },
                          );
                        },
                      ),
                    // Button to add the selected city with styling
                    ElevatedButton(
                      onPressed: () {
                        if (_selectedCity != null) {
                          _addLocation(_selectedCity!);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: Text('Add City'),
                    ),
                  ],
                ],
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
                    Navigator.pop(context, city);
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
                          style: GoogleFonts.lato(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
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
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.blue[900],
                            ),
                          ),
                          Text(
                            'Condition: ${weather['condition']}',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.blue[900],
                            ),
                          ),
                          Text(
                            'Humidity: ${weather['humidity']}%',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: Colors.blue[900],
                            ),
                          ),
                          Text(
                            'Last Updated: ${weather['time']}',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.blue[700],
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Loading ...',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: Colors.red,
                            ),
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
