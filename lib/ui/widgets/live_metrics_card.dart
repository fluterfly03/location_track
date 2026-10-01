import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/tracking_session.dart';

class LiveMetricsCard extends StatelessWidget {
  final TrackingSession? session;
  final TrackingSession? lastCompletedSession;
  final bool isTracking;
  final double currentSpeedMps;

  const LiveMetricsCard({
    super.key,
    this.session,
    this.lastCompletedSession,
    required this.isTracking,
    this.currentSpeedMps = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final active = isTracking ? session : lastCompletedSession;
    final double distanceKm = active?.totalDistanceKm ?? 0.0;
    final String formattedDist = '${distanceKm.toStringAsFixed(3)} km';
    final String formattedDuration = active?.formattedDuration ?? '00:00';
    final double currentSpeedKmh = (currentSpeedMps * 3.6).clamp(0.0, 999.0);
    final int pointsCount = active?.points.length ?? 0;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTracking
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: (isTracking ? const Color(0xFF10B981) : Colors.black).withValues(alpha: 0.2),
            blurRadius: 16.r,
            offset: Offset(0, 8.h),
          ),
        ],
        border: Border.all(
          color: isTracking
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : Colors.white12,
          width: 1.5.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTracking ? const Color(0xFF34D399) : Colors.amberAccent,
                      boxShadow: [
                        BoxShadow(
                          color: isTracking ? const Color(0xFF34D399) : Colors.amberAccent,
                          blurRadius: 8.r,
                          spreadRadius: 2.r,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isTracking ? 'LIVE TRACKING' : 'LAST SUMMARY',
                    style: TextStyle(
                      color: isTracking ? const Color(0xFF34D399) : Colors.grey[400],
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Colors.white70, size: 14.sp),
                    SizedBox(width: 4.w),
                    Text(
                      formattedDuration,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Total Kilometres Counter
          Center(
            child: Column(
              children: [
                Text(
                  'TOTAL DISTANCE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formattedDist,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          const Divider(color: Colors.white12, height: 1),
          SizedBox(height: 14.h),
          // Sub-metrics row with Expanded widgets for non-overflowing responsive layout
          Row(
            children: [
              Expanded(
                child: _buildSubMetric(
                  icon: Icons.speed,
                  label: 'SPEED',
                  value: '${currentSpeedKmh.toStringAsFixed(1)} km/h',
                ),
              ),
              Container(width: 1.w, height: 28.h, color: Colors.white12),
              Expanded(
                child: _buildSubMetric(
                  icon: Icons.place_outlined,
                  label: 'WAYPOINTS',
                  value: '$pointsCount pts',
                ),
              ),
              Container(width: 1.w, height: 28.h, color: Colors.white12),
              Expanded(
                child: _buildSubMetric(
                  icon: Icons.straighten,
                  label: 'METERS',
                  value: '${(active?.totalDistanceMeters ?? 0.0).toStringAsFixed(0)} m',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white60, size: 14.sp),
            SizedBox(width: 4.w),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
