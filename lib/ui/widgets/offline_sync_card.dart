import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/tracking_provider.dart';
import '../../models/sync_record.dart';
import 'sync_status_badge.dart';

class OfflineSyncCard extends StatefulWidget {
  const OfflineSyncCard({super.key});

  @override
  State<OfflineSyncCard> createState() => _OfflineSyncCardState();
}

class _OfflineSyncCardState extends State<OfflineSyncCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<TrackingProvider>(
      builder: (context, provider, child) {
        final isOnline = provider.isOnline;
        final isSimulatingOffline = provider.isSimulatingOffline;
        final queue = provider.syncQueue;
        final syncService = provider.syncService;
        final serverService = provider.serverService;

        final pendingCount = syncService.pendingCount;
        final syncedCount = syncService.syncedCount;
        final failedCount = syncService.failedCount;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Connectivity Status & Network Toggle Switch
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOnline ? Icons.wifi : Icons.wifi_off_rounded,
                        color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 20.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  isOnline ? 'Network Online' : 'Network Offline',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.sp,
                                    color: const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 6.w),
                              if (isSimulatingOffline)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    'Simulated',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            isOnline
                                ? 'Auto-sync active when connected'
                                : 'Data saved locally until internet returns',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isSimulatingOffline,
                      activeThumbColor: Colors.amber,
                      inactiveTrackColor: isOnline ? const Color(0xFFD1FAE5) : Colors.grey.shade300,
                      activeTrackColor: Colors.amber.shade200,
                      onChanged: (_) => provider.toggleSimulatedOffline(),
                    ),
                  ],
                ),

                Divider(height: 24.h),

                // Sync Queue Metrics Counter Row
                Row(
                  children: [
                    _buildMetricChip(
                      label: 'Pending',
                      count: pendingCount,
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFEF3C7),
                      icon: Icons.cloud_queue_rounded,
                    ),
                    SizedBox(width: 8.w),
                    _buildMetricChip(
                      label: 'Synced',
                      count: syncedCount,
                      color: const Color(0xFF059669),
                      bgColor: const Color(0xFFD1FAE5),
                      icon: Icons.cloud_done_rounded,
                    ),
                    SizedBox(width: 8.w),
                    _buildMetricChip(
                      label: 'Failed',
                      count: failedCount,
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEE2E2),
                      icon: Icons.cloud_off_rounded,
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Status Message & Server Database Info
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16.r,
                        color: Colors.blueGrey.shade600,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          '${provider.syncStatusMessage} • Server Db: ${serverService.serverRecordCount} records',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: provider.isSyncing
                            ? null
                            : () => provider.triggerManualSync(),
                        icon: provider.isSyncing
                            ? SizedBox(
                                width: 16.r,
                                height: 16.r,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(Icons.sync_rounded, size: 18.r),
                        label: Text(
                          provider.isSyncing ? 'Syncing...' : 'Sync Now',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _isExpanded ? 'Hide Queue' : 'Queue (${queue.length})',
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18.r,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8.h),

                // SPECIAL DEMO BUTTON FOR DUPLICATE PREVENTION SCENARIO
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  ),
                  onPressed: () async {
                    await provider.simulateResponseLossScenario();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Simulated network drop after server created record! Tap "Sync Now" or connect internet to test duplicate prevention.',
                          ),
                          backgroundColor: Colors.amber,
                          duration: Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.science_rounded, size: 16.r),
                  label: Flexible(
                    child: Text(
                      'Test Edge Case: Loss of Server Response (Idempotency)',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Expandable Sync Queue Items List
                if (_isExpanded) ...[
                  Divider(height: 20.h),
                  Text(
                    'PENDING & COMPLETED SYNC QUEUE',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  if (queue.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(12.r),
                      child: Center(
                        child: Text(
                          'No records in sync queue.',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: queue.length,
                      separatorBuilder: (_, _) => SizedBox(height: 8.h),
                      itemBuilder: (ctx, index) {
                        final item = queue[index];
                        return Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SyncStatusBadge(status: item.status, compact: true),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      'Key: ${item.idempotencyKey}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (item.status == SyncStatus.failed || item.status == SyncStatus.pending)
                                    IconButton(
                                      icon: Icon(Icons.refresh_rounded, size: 18.r, color: const Color(0xFF2563EB)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => syncService.retrySingleRecord(item),
                                      tooltip: 'Retry sync',
                                    ),
                                ],
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Session: ${item.sessionId}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                                    ),
                                  ),
                                  Text(
                                    'Retries: ${item.retryCount}',
                                    style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              if (item.serverRecordId != null) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  'Server Record: ${item.serverRecordId}',
                                  style: TextStyle(fontSize: 10.sp, color: const Color(0xFF059669), fontWeight: FontWeight.bold),
                                ),
                              ],
                              if (item.errorMessage != null) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  'Error: ${item.errorMessage}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.sp, color: const Color(0xFFDC2626)),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricChip({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14.r, color: color),
              SizedBox(width: 4.w),
              Text(
                '$label: ',
                style: TextStyle(fontSize: 11.sp, color: color, fontWeight: FontWeight.w600),
              ),
              Text(
                '$count',
                style: TextStyle(fontSize: 12.sp, color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
