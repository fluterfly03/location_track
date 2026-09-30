import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tracking_provider.dart';
import '../widgets/live_metrics_card.dart';
import '../widgets/location_details_card.dart';
import '../widgets/permission_banner.dart';
import '../widgets/route_map_widget.dart';
import '../widgets/history_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showHistoryModal(BuildContext context, TrackingProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.75,
        child: HistorySheet(
          history: provider.history,
          onClearHistory: () => provider.clearHistory(),
        ),
      ),
    );
  }

  void _showCheckoutSummaryDialog(BuildContext context, TrackingProvider provider) {
    final session = provider.lastCompletedSession;
    if (session == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 8),
            Text('Trip Completed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      'TOTAL DISTANCE',
                      style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.formattedDistanceKm,
                      style: const TextStyle(
                        color: Color(0xFF34D399),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            _buildDetailRow('Waypoints Logged:', '${session.points.length} points'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close Summary'),
          ),
        ],
      ),
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.navigation_rounded, color: Color(0xFF34D399), size: 20),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location Tracker',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Distance & GPS Tracker',
                      style: TextStyle(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Badge(
                  label: Text('${provider.history.length}'),
                  isLabelVisible: provider.history.isNotEmpty,
                  child: const Icon(Icons.history, color: Colors.white),
                ),
                onPressed: () => _showHistoryModal(context, provider),
                tooltip: 'Trip History',
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: provider.isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Color(0xFF10B981)),
                      SizedBox(height: 16),
                      Text('Initializing location service...'),
                    ],
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Permission Banner if GPS or location permission needed
                              PermissionBanner(
                                isGpsEnabled: provider.isGpsEnabled,
                                permission: provider.permission,
                                onRequestPermission: () => provider.requestPermissions(),
                                onOpenGpsSettings: () => provider.openLocationSettings(),
                                onOpenAppSettings: () => provider.openAppSettings(),
                              ),

                              // Live Metrics Card (Distance in km, Duration, Speed)
                              LiveMetricsCard(
                                session: provider.activeSession,
                                lastCompletedSession: provider.lastCompletedSession,
                                isTracking: isTracking,
                                currentSpeedMps: provider.currentPoint?.speed ?? 0.0,
                              ),
                              const SizedBox(height: 16),

                              // Route Map Display
                              SizedBox(
                                height: 260,
                                child: RouteMapWidget(
                                  points: provider.activeSession?.points ??
                                      provider.lastCompletedSession?.points ??
                                      [],
                                  currentPoint: provider.currentPoint,
                                  startPoint: provider.activeSession?.startLocation ??
                                      provider.lastCompletedSession?.startLocation,
                                  endPoint: provider.lastCompletedSession?.endLocation,
                                  isTracking: isTracking,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Coordinates and Timestamps Card
                              LocationDetailsCard(
                                session: provider.activeSession,
                                lastCompletedSession: provider.lastCompletedSession,
                                currentPoint: provider.currentPoint,
                                isTracking: isTracking,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Action Control Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          boxShadow: [
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
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: const Color(0xFF10B981).withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () async {
                                    final success = await provider.checkIn();
                                    if (!success && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(provider.statusMessage),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_arrow_rounded, size: 28),
                                      SizedBox(width: 8),
                                      Text(
                                        'START / CHECK IN',
                                        style: TextStyle(
                                          fontSize: 16,
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
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await provider.checkOut();
                                    if (context.mounted) {
                                      _showCheckoutSummaryDialog(context, provider);
                                    }
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.stop_rounded, size: 28),
                                      SizedBox(width: 8),
                                      Text(
                                        'STOP / CHECK OUT',
                                        style: TextStyle(
                                          fontSize: 16,
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
                    ],
                  ),
                ),
        );
      },
    );
  }
}
