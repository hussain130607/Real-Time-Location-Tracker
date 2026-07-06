import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Real-Time Location Tracker',
      debugShowCheckedModeBanner: false,
      home: LocationTrackerScreen(),
    );
  }
}

class LocationTrackerScreen extends StatefulWidget {
  const LocationTrackerScreen({super.key});

  @override
  State<LocationTrackerScreen> createState() => _LocationTrackerScreenState();
}

class _LocationTrackerScreenState extends State<LocationTrackerScreen> {
  GoogleMapController? _mapController;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  final List<LatLng> _routePoints = [];

  LatLng? _currentPosition;

  Timer? _locationTimer;

  static const CameraPosition _initialCamera = CameraPosition(
    target: LatLng(23.7216771, 90.4165835),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('Please turn on location services.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage('Location permission is required for this app.');
      return;
    }

    await _fetchAndUpdateLocation();
    _locationTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchAndUpdateLocation(),
    );
  }

  Future<void> _fetchAndUpdateLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng newPoint = LatLng(pos.latitude, pos.longitude);

      setState(() {
        if (_currentPosition != null) {
          _routePoints.add(_currentPosition!);
        }
        _routePoints.add(newPoint);

        _currentPosition = newPoint;

        _markers
          ..clear()
          ..add(
            Marker(
              markerId: const MarkerId('my_location'),
              position: newPoint,
              infoWindow: InfoWindow(
                title: 'My Current Location',
                snippet:
                    '${pos.latitude.toStringAsFixed(7)},${pos.longitude.toStringAsFixed(7)}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );

        if (_routePoints.length >= 2) {
          _polylines
            ..clear()
            ..add(
              Polyline(
                polylineId: const PolylineId('route'),
                points: List<LatLng>.from(_routePoints),
                color: Colors.blue,
                width: 5,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
                jointType: JointType.round,
              ),
            );
        }
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newPoint, zoom: 15),
        ),
      );
    } catch (e) {
      _showMessage('Could not get location: $e');
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text(
          'Real-Time Location Tracker',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: _initialCamera,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }
}
