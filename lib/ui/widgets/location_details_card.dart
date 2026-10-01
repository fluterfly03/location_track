import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/tracking_point.dart';
import '../../models/tracking_session.dart';

class LocationDetailsCard extends StatelessWidget {
  final TrackingSession? session;
  final TrackingSession? lastCompletedSession;
  final TrackingPoint? currentPoint;
  final bool isTracking;

  const LocationDetailsCard({
    super.key,
    this.session,
    this.lastCompletedSession,
    this.currentPoint,
    required this.isTracking,
  });

  @override
  Widget build(BuildContext context) {
    final active = isTracking ? session : lastCompletedSession;
    final startPt = active?.startLocation;
    final endPt = active?.endLocation;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.my_location, color: Colors.blue.shade700, size: 20.sp),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Coordinates & Timestamps',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (currentPoint != null && isTracking)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Acc: ±${currentPoint!.accuracy.toStringAsFixed(1)}m',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),

          // Start Location Row
          _buildCoordinateTile(
            title: 'Start Location (Check-In)',
            icon: Icons.play_circle_fill,
            iconColor: const Color(0xFF10B981),
            lat: startPt?.latitude,
            lng: startPt?.longitude,
            time: active?.formattedStartTime,
          ),

          Padding(
            padding: EdgeInsets.only(left: 20.w),
            child: SizedBox(
              height: 16.h,
              child: const VerticalDivider(thickness: 1.5, color: Colors.grey),
            ),
          ),

          // Current Live Location Row (if tracking)
          if (isTracking)
            _buildCoordinateTile(
              title: 'Live Location (Current)',
              icon: Icons.radio_button_checked,
              iconColor: Colors.blueAccent,
              lat: currentPoint?.latitude,
              lng: currentPoint?.longitude,
              time: 'Live tracking active',
            ),

          // Checkout Location Row (if completed or has end point)
          if (!isTracking && endPt != null)
            _buildCoordinateTile(
              title: 'Checkout Location (Stop)',
              icon: Icons.stop_circle,
              iconColor: Colors.redAccent,
              lat: endPt.latitude,
              lng: endPt.longitude,
              time: active?.formattedEndTime,
            ),
        ],
      ),
    );
  }

  Widget _buildCoordinateTile({
    required String title,
    required IconData icon,
    required Color iconColor,
    required double? lat,
    required double? lng,
    required String? time,
  }) {
    final latStr = lat != null ? lat.toStringAsFixed(6) : 'N/A';
    final lngStr = lng != null ? lng.toStringAsFixed(6) : 'N/A';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 22.sp),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2.h),
              SelectableText(
                'Lat: $latStr,  Lng: $lngStr',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              if (time != null) ...[
                SizedBox(height: 1.h),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
