import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title: 'Location Color App',
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      //   visualDensity: VisualDensity.adaptivePlatformDensity,
      // ),
      home: const LocationColorScreen(),
    );
  }
}

class LocationColorScreen extends StatefulWidget {
  const LocationColorScreen({super.key});

  @override
  _LocationColorScreenState createState() => _LocationColorScreenState();
}

class _LocationColorScreenState extends State<LocationColorScreen> {
  bool _isInTargetLocation = false;
  bool _isLoading = true;
  String _locationStatus = "Checking location...";
  Timer? _locationTimer;

  // Define target location (latitude and longitude)
  // Example coordinates - replace with your desired location
  final double _targetLatitude = 25.09;
  final double _targetLongitude = 55.15;

  // Define radius in meters (how close the user needs to be to target location)
  final double _radiusInMeters = 2500;

  // Colors
  final Color _activeColor = Colors.red;
  final Color _inactiveColor = Colors.grey;

  // Timer interval (2 minutes = 120 seconds)
  final int _locationCheckIntervalSeconds = 120;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    var status = await Permission.location.status;

    if (status.isDenied) {
      // Request permission
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      _checkUserLocation();
      _startPeriodicLocationCheck();
    } else {
      setState(() {
        _isLoading = false;
        _locationStatus = "Location permission denied";
      });
    }
  }

  void _startPeriodicLocationCheck() {
    // Cancel any existing timer
    _locationTimer?.cancel();

    // Create a new timer that fires every 2 minutes
    _locationTimer = Timer.periodic(
      Duration(seconds: _locationCheckIntervalSeconds),
      (timer) => _checkUserLocation(),
    );
  }

  Future<void> _checkUserLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoading = false;
          _locationStatus = "Location services are disabled";
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(position);

      // Calculate distance between current position and target location
      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _targetLatitude,
        _targetLongitude,
      );

      print(distanceInMeters);

      // Check if user is within the radius of the target location
      bool isInLocation = distanceInMeters <= _radiusInMeters;

      setState(() {
        _isInTargetLocation = isInLocation;
        _isLoading = false;
        _locationStatus =
            isInLocation
                ? "You're in Al Qadsiah FC end of Season cermony"
                : "You're not in the event location";
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _locationStatus = "Error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Color App')),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: _isInTargetLocation ? _activeColor : _inactiveColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: SizedBox(
                  height: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Welcome",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48, // Large size for "Welcome"
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "to Al Qadsiah End of Season Ceremony",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28.8, // 60% of 48 = 28.8
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              if (_isLoading)
                const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                _locationStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Location checked every $_locationCheckIntervalSeconds seconds",
                style: const TextStyle(color: Colors.white, fontSize: 2),
              ),
              //const SizedBox(height: 20),
              // ElevatedButton(
              //   onPressed: _checkUserLocation,
              //   child: const Text('Check Location Now'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
