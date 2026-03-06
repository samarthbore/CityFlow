import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/provider.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class ProviderMapScreen extends StatefulWidget {
  final Provider provider;

  const ProviderMapScreen({super.key, required this.provider});

  @override
  State<ProviderMapScreen> createState() => _ProviderMapScreenState();
}

class _ProviderMapScreenState extends State<ProviderMapScreen> {
  final LocationService _locationService = LocationService();
  Position? _userPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _userPosition = position;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchMaps() async {
    final lat = widget.provider.latitude;
    final lng = widget.provider.longitude;
    if (lat == null || lng == null) return;

    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.provider.latitude == null || widget.provider.longitude == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Location')),
        body: const Center(child: Text('Location data not available for this provider.')),
      );
    }

    final providerLocation = LatLng(widget.provider.latitude!, widget.provider.longitude!);
    final userLocation = _userPosition != null 
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude) 
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.provider.name, style: Theme.of(context).textTheme.headlineSmall),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: providerLocation,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.city_flow_app',
              ),
              MarkerLayer(
                markers: [
                  // Provider Marker
                  Marker(
                    point: providerLocation,
                    width: 50,
                    height: 50,
                    child: Icon(
                      Icons.location_on, 
                      color: Theme.of(context).primaryColor, 
                      size: 50,
                      shadows: [
                        Shadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                  ),
                  // User Marker
                  if (userLocation != null)
                    Marker(
                      point: userLocation,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
          
          if (!_isLoading && userLocation != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Distance: ${_locationService.calculateDistance(providerLocation.latitude, providerLocation.longitude, userLocation.latitude, userLocation.longitude).toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      ElevatedButton.icon(
                        onPressed: _launchMaps,
                        icon: const Icon(Icons.directions),
                        label: const Text('Get Directions'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (!_isLoading && userLocation == null) ? FloatingActionButton.extended(
        onPressed: _launchMaps,
        icon: const Icon(Icons.directions),
        label: const Text('Get Directions'),
      ) : null,
    );
  }
}
