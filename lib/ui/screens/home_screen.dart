import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/tracking_provider.dart';
import '../widgets/live_metrics_card.dart';
import '../widgets/location_details_card.dart';
import '../widgets/permission_banner.dart';
import '../widgets/route_map_widget.dart';
import '../widgets/history_sheet.dart';
import '../widgets/offline_sync_card.dart';
import '../widgets/api_distance_card.dart';
import 'ai_summary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showHistoryModal(BuildContext context, TrackingProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 700.w),
          child: FractionallySizedBox(
            heightFactor: 0.75,
            child: HistorySheet(
              history: provider.history,
              onClearHistory: () => provider.clearHistory(),
            ),
          ),
        ),
      ),
    );
  }

  void _showCheckoutSummaryDialog(
    BuildContext context,
    TrackingProvider provider,
  ) {
    final session = provider.lastCompletedSession;
    if (session == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 450.w),
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: const Color(0xFF10B981), size: 28.sp),
                SizedBox(width: 8.w),
                Text('Trip Completed!', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Text(
                            'TOTAL DISTANCE',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10.sp,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              session.formattedDistanceKm,
                              style: TextStyle(
                                color: const Color(0xFF34D399),
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildDetailRow('Duration:', session.formattedDuration),
                  _buildDetailRow('Start Time:', session.formattedStartTime),
                  _buildDetailRow('End Time:', session.formattedEndTime),
                  _buildDetailRow(
                    'Start Location:',
                    '${session.startLocation?.latitude.toStringAsFixed(5)}, ${session.startLocation?.longitude.toStringAsFixed(5)}',
                  ),
                  _buildDetailRow(
                    'End Location:',
                    '${session.endLocation?.latitude.toStringAsFixed(5)}, ${session.endLocation?.longitude.toStringAsFixed(5)}',
                  ),
                  _buildDetailRow(
                    'Waypoints Logged:',
                    '${session.points.length} points',
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text('Close Summary', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(
      builder: (context, provider, child) {
        final isTracking = provider.isTracking;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.navigation_rounded,
                    color: const Color(0xFF34D399),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location Tracker',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Distance & GPS Tracker',
                        style: TextStyle(fontSize: 11.sp, color: Colors.white54),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.auto_awesome, color: const Color(0xFF818CF8), size: 22.sp),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AiSummaryScreen()),
                  );
                },
                tooltip: 'AI Visit Assistant',
              ),
              IconButton(
                icon: Badge(
                  label: Text('${provider.history.length}', style: TextStyle(fontSize: 10.sp)),
                  isLabelVisible: provider.history.isNotEmpty,
                  child: Icon(Icons.history, color: Colors.white, size: 22.sp),
                ),
                onPressed: () => _showHistoryModal(context, provider),
                tooltip: 'Trip History',
              ),
              SizedBox(width: 8.w),
            ],
          ),
          body: provider.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF10B981)),
                      SizedBox(height: 16.h),
                      Text('Initializing location service...', style: TextStyle(fontSize: 13.sp)),
                    ],
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 700.w),
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(16.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Permission Banner if GPS or location permission needed
                                  PermissionBanner(
                                    isGpsEnabled: provider.isGpsEnabled,
                                    permission: provider.permission,
                                    onRequestPermission: () =>
                                        provider.requestPermissions(),
                                    onOpenGpsSettings: () =>
                                        provider.openLocationSettings(),
                                    onOpenAppSettings: () =>
                                        provider.openAppSettings(),
                                  ),
                                  SizedBox(height: 10.h),
                                  // Task 1: Offline & Synchronization Status Card
                                  const OfflineSyncCard(),
                                  SizedBox(height: 16.h),

                                  // Live Metrics Card (Distance in km, Duration, Speed)
                                  LiveMetricsCard(
                                    session: provider.activeSession,
                                    lastCompletedSession:
                                        provider.lastCompletedSession,
                                    isTracking: isTracking,
                                    currentSpeedMps:
                                        provider.currentPoint?.speed ?? 0.0,
                                  ),
                                  SizedBox(height: 16.h),

                                  // Route Map Display
                                  SizedBox(
                                    height: 260.h,
                                    child: RouteMapWidget(
                                      points:
                                          provider.activeSession?.points ??
                                          provider.lastCompletedSession?.points ??
                                          [],
                                      currentPoint: provider.currentPoint,
                                      startPoint:
                                          provider.activeSession?.startLocation ??
                                          provider
                                              .lastCompletedSession
                                              ?.startLocation,
                                      endPoint: provider
                                          .lastCompletedSession
                                          ?.endLocation,
                                      isTracking: isTracking,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),

                                  // Coordinates and Timestamps Card
                                  LocationDetailsCard(
                                    session: provider.activeSession,
                                    lastCompletedSession:
                                        provider.lastCompletedSession,
                                    currentPoint: provider.currentPoint,
                                    isTracking: isTracking,
                                  ),
                                  SizedBox(height: 16.h),

                                  // Task 2: API Distance Service Card
                                  const ApiDistanceCard(),
                                  SizedBox(height: 16.h),

                                  // AI Visit Assistant Navigation Card Button
                                  Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    color: Colors.white,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20.r),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const AiSummaryScreen(),
                                          ),
                                        );
                                      },
                                      child: Padding(
                                        padding: EdgeInsets.all(20.r),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(12.r),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF8B5CF6),
                                                    Color(0xFF6366F1),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(
                                                  16.r,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.auto_awesome,
                                                color: Colors.white,
                                                size: 24.sp,
                                              ),
                                            ),
                                            SizedBox(width: 16.w),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'AI Visit Assistant',
                                                    style: TextStyle(
                                                      fontSize: 16.sp,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  SizedBox(height: 2.h),
                                                  Text(
                                                    'Tap to view AI summaries & ask Q&A',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              color: const Color(0xFF6366F1),
                                              size: 18.sp,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom Action Control Bar
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 700.w),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20.w,
                              vertical: 16.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24.r),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 12,
                                  offset: Offset(0, -4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isTracking)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56.h,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16.r),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final success = await provider.checkIn();
                                        if (!success && context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(provider.statusMessage),
                                              backgroundColor: Colors.redAccent,
                                            ),
                                          );
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.play_arrow_rounded, size: 28.sp),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'START / CHECK IN',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56.h,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFEF4444),
                                        foregroundColor: Colors.white,
                                        elevation: 4,
                                        shadowColor: const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16.r),
                                        ),
                                      ),
                                      onPressed: () async {
                                        await provider.checkOut();
                                        if (context.mounted) {
                                          _showCheckoutSummaryDialog(
                                            context,
                                            provider,
                                          );
                                        }
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.stop_rounded, size: 28.sp),
                                          SizedBox(width: 8.w),
                                          Text(
                                            'STOP / CHECK OUT',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
