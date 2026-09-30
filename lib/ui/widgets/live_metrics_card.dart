import 'package:flutter/material.dart';
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTracking
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFF1E293B), const Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isTracking ? const Color(0xFF10B981) : Colors.black).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isTracking
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : Colors.white12,
          width: 1.5,
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
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTracking ? const Color(0xFF34D399) : Colors.amberAccent,
                      boxShadow: [
                        BoxShadow(
                          color: isTracking ? const Color(0xFF34D399) : Colors.amberAccent,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isTracking ? 'LIVE TRACKING' : 'LAST SUMMARY',
                    style: TextStyle(
                      color: isTracking ? const Color(0xFF34D399) : Colors.grey[400],
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      formattedDuration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Total Kilometres Counter
          Center(
            child: Column(
              children: [
                const Text(
                  'TOTAL DISTANCE',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    formattedDist,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),
          // Sub-metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSubMetric(
                icon: Icons.speed,
                label: 'SPEED',
                value: '${currentSpeedKmh.toStringAsFixed(1)} km/h',
              ),
              Container(width: 1, height: 28, color: Colors.white12),
              _buildSubMetric(
                icon: Icons.place_outlined,
                label: 'WAYPOINTS',
                value: '$pointsCount pts',
              ),
              Container(width: 1, height: 28, color: Colors.white12),
              _buildSubMetric(
                icon: Icons.straighten,
                label: 'METERS',
                value: '${(active?.totalDistanceMeters ?? 0.0).toStringAsFixed(0)} m',
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
          children: [
            Icon(icon, color: Colors.white60, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
