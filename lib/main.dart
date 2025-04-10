import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set app to fullscreen mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes debug banner
      home: const LocationColorScreen(),
    );
  }
}

class LocationColorScreen extends StatefulWidget {
  const LocationColorScreen({super.key});

  @override
  _LocationColorScreenState createState() => _LocationColorScreenState();
}

class _LocationColorScreenState extends State<LocationColorScreen>
    with SingleTickerProviderStateMixin {
  bool _isInTargetLocation = false;
  bool _isLoading = true;
  String _locationStatus = "Checking location...";
  Timer? _locationTimer;

  // Animation controller for throbbing effect
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  // Define target location (latitude and longitude)
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

    // Force fullscreen mode whenever the app starts
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Create the color animation
    _colorAnimation = ColorTween(begin: Colors.black, end: Colors.red).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Make the animation repeat forward and backward
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });

    _checkLocationPermission();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _locationTimer?.cancel();
    // Restore system UI when disposing
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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

      // Start or stop the animation based on location
      if (isInLocation) {
        if (!_animationController.isAnimating) {
          _animationController.forward();
        }
      } else {
        _animationController.stop();
        _animationController.reset();
      }
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
      // Remove app bar for full screen experience
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: _isInTargetLocation ? _colorAnimation.value : _inactiveColor,
            child: SafeArea(
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
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Location checked every $_locationCheckIntervalSeconds seconds",
                      style: const TextStyle(color: Colors.white, fontSize: 6),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
