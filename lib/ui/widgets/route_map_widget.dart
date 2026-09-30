import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/tracking_point.dart';

class RouteMapWidget extends StatefulWidget {
  final List<TrackingPoint> points;
  final TrackingPoint? currentPoint;
  final TrackingPoint? startPoint;
  final TrackingPoint? endPoint;
  final bool isTracking;

  const RouteMapWidget({
    super.key,
    required this.points,
    this.currentPoint,
    this.startPoint,
    this.endPoint,
    this.isTracking = false,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  final MapController _mapController = MapController();
  bool _followUser = true;

  @override
  void didUpdateWidget(covariant RouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_followUser && widget.currentPoint != null) {
      _centerOnCurrentLocation();
    }
  }

  void _centerOnCurrentLocation() {
    if (widget.currentPoint != null) {
      _mapController.move(
        LatLng(widget.currentPoint!.latitude, widget.currentPoint!.longitude),
        _mapController.camera.zoom < 14 ? 16 : _mapController.camera.zoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    LatLng centerLocation = const LatLng(0, 0);

    if (widget.currentPoint != null) {
      centerLocation = LatLng(
        widget.currentPoint!.latitude,
        widget.currentPoint!.longitude,
      );
    } else if (widget.startPoint != null) {
      centerLocation = LatLng(
        widget.startPoint!.latitude,
        widget.startPoint!.longitude,
      );
    } else if (widget.points.isNotEmpty) {
      centerLocation = LatLng(
        widget.points.first.latitude,
        widget.points.first.longitude,
      );
    }

    final polylinePoints = widget.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    List<Marker> markers = [];

    // Start Location Marker (Green Pin)
    if (widget.startPoint != null) {
      markers.add(
        Marker(
          point: LatLng(widget.startPoint!.latitude, widget.startPoint!.longitude),
          width: 50,
          height: 50,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'START',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.location_on, color: Color(0xFF10B981), size: 28),
            ],
          ),
        ),
      );
    }

    // End Location Marker (Red Pin) if checked out
    if (widget.endPoint != null && !widget.isTracking) {
      markers.add(
        Marker(
          point: LatLng(widget.endPoint!.latitude, widget.endPoint!.longitude),
          width: 50,
          height: 50,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'END',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.flag, color: Colors.redAccent, size: 28),
            ],
          ),
        ),
      );
    }

    // Current Location Marker (Pulsing Dot)
    if (widget.currentPoint != null && widget.isTracking) {
      markers.add(
        Marker(
          point: LatLng(widget.currentPoint!.latitude, widget.currentPoint!.longitude),
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withValues(alpha: 0.3),
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerLocation,
              initialZoom: 16.0,
              onPositionChanged: (pos, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _followUser = false;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.task1',
              ),
              if (polylinePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF2563EB),
                      borderColor: const Color(0xFF60A5FA),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              heroTag: 'recenter_map_btn',
              backgroundColor: _followUser ? Colors.blueAccent : Colors.white,
              foregroundColor: _followUser ? Colors.white : Colors.black87,
              onPressed: () {
                setState(() {
                  _followUser = true;
                });
                _centerOnCurrentLocation();
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
