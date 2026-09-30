import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class PermissionBanner extends StatelessWidget {
  final bool isGpsEnabled;
  final LocationPermission permission;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenGpsSettings;
  final VoidCallback onOpenAppSettings;

  const PermissionBanner({
    super.key,
    required this.isGpsEnabled,
    required this.permission,
    required this.onRequestPermission,
    required this.onOpenGpsSettings,
    required this.onOpenAppSettings,
  });

  @override
  Widget build(BuildContext context) {
    if (isGpsEnabled &&
        (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse)) {
      return const SizedBox.shrink();
    }

    String title;
    String message;
    Widget actionButton;

    if (!isGpsEnabled) {
      title = 'GPS Service Disabled';
      message = 'Please turn on Location Services / GPS on your device to track distance.';
      actionButton = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade800,
          foregroundColor: Colors.white,
        ),
        onPressed: onOpenGpsSettings,
        icon: const Icon(Icons.location_off, size: 18),
        label: const Text('Turn On GPS'),
      );
    } else if (permission == LocationPermission.deniedForever) {
      title = 'Location Permission Permanently Denied';
      message = 'Location permission was denied permanently. Please open settings to grant permission manually.';
      actionButton = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
        ),
        onPressed: onOpenAppSettings,
        icon: const Icon(Icons.settings, size: 18),
        label: const Text('Open App Settings'),
      );
    } else {
      title = 'Location Permission Required';
      message = 'This app requires location permission to record start/checkout coordinates and track distance.';
      actionButton = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
        onPressed: onRequestPermission,
        icon: const Icon(Icons.security, size: 18),
        label: const Text('Grant Permission'),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: actionButton,
          ),
        ],
      ),
    );
  }
}
