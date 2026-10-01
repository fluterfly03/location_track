import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        onPressed: onOpenGpsSettings,
        icon: Icon(Icons.location_off, size: 18.sp),
        label: Text('Turn On GPS', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
      );
    } else if (permission == LocationPermission.deniedForever) {
      title = 'Location Permission Permanently Denied';
      message = 'Location permission was denied permanently. Please open settings to grant permission manually.';
      actionButton = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        onPressed: onOpenAppSettings,
        icon: Icon(Icons.settings, size: 18.sp),
        label: Text('Open App Settings', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
      );
    } else {
      title = 'Location Permission Required';
      message = 'This app requires location permission to record start/checkout coordinates and track distance.';
      actionButton = ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        onPressed: onRequestPermission,
        icon: Icon(Icons.security, size: 18.sp),
        label: Text('Grant Permission', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 22.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            message,
            style: TextStyle(fontSize: 12.sp, color: Colors.amber.shade900),
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerRight,
            child: actionButton,
          ),
        ],
      ),
    );
  }
}
