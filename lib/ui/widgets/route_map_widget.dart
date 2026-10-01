import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      final oldPt = oldWidget.currentPoint;
      final newPt = widget.currentPoint;
      final locationChanged = oldPt == null ||
          oldPt.latitude != newPt!.latitude ||
          oldPt.longitude != newPt.longitude;

      if (locationChanged) {
        debugPrint('MAP CAMERA MOVED: ${newPt!.latitude}, ${newPt.longitude}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _followUser) {
            _centerOnCurrentLocation();
          }
        });
      }
    }
  }

  void _centerOnCurrentLocation() {
    if (widget.currentPoint != null) {
      try {
        double currentZoom = 16.0;
        try {
          currentZoom = _mapController.camera.zoom < 14 ? 16 : _mapController.camera.zoom;
        } catch (_) {}
        _mapController.move(
          LatLng(widget.currentPoint!.latitude, widget.currentPoint!.longitude),
          currentZoom,
        );
      } catch (e) {
        debugPrint('Error moving map camera: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentPoint != null) {
      debugPrint('MAP WIDGET UPDATED: ${widget.currentPoint!.latitude}, ${widget.currentPoint!.longitude}');
    }
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
          width: 60.r,
          height: 60.r,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: Text(
                  'START',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.location_on, color: const Color(0xFF10B981), size: 28.r),
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
          width: 60.r,
          height: 60.r,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: Text(
                  'END',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.flag, color: Colors.redAccent, size: 28.r),
            ],
          ),
        ),
      );
    }

    // Current Location Marker (Pulsing Dot + Live Tooltip)
    if (widget.currentPoint != null && widget.isTracking) {
      markers.add(
        Marker(
          point: LatLng(widget.currentPoint!.latitude, widget.currentPoint!.longitude),
          width: 150.r,
          height: 72.r,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live Location Tooltip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blueAccent, width: 1.2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6.r,
                          height: 6.r,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'LIVE LOCATION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${widget.currentPoint!.latitude.toStringAsFixed(5)}, ${widget.currentPoint!.longitude.toStringAsFixed(5)}',
                      style: TextStyle(
                        color: Colors.blueAccent.shade100,
                        fontSize: 9.sp,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              // Pulsing Dot Icon
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 28.r,
                    height: 28.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                    ),
                  ),
                  Container(
                    width: 16.r,
                    height: 16.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent,
                      border: Border.all(color: Colors.white, width: 2.5.r),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
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
            right: 12.w,
            bottom: 12.h,
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
              child: Icon(Icons.my_location, size: 20.r),
            ),
          ),
        ],
      ),
    );
  }
}

