import 'package:flutter/material.dart';
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Connectivity Status & Network Toggle Switch
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFFEF4444).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOnline ? Icons.wifi : Icons.wifi_off_rounded,
                        color: isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isOnline ? 'Network Online' : 'Network Offline',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSimulatingOffline)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Simulated',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
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
                              fontSize: 11,
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

                const Divider(height: 24),

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
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      label: 'Synced',
                      count: syncedCount,
                      color: const Color(0xFF059669),
                      bgColor: const Color(0xFFD1FAE5),
                      icon: Icons.cloud_done_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildMetricChip(
                      label: 'Failed',
                      count: failedCount,
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEE2E2),
                      icon: Icons.cloud_off_rounded,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Status Message & Server Database Info
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: Colors.blueGrey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${provider.syncStatusMessage} • Server Db: ${serverService.serverRecordCount} records',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: provider.isSyncing
                            ? null
                            : () => provider.triggerManualSync(),
                        icon: provider.isSyncing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: Text(
                          provider.isSyncing ? 'Syncing...' : 'Sync Now',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Row(
                        children: [
                          Text(
                            _isExpanded ? 'Hide Queue' : 'View Queue (${queue.length})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // SPECIAL DEMO BUTTON FOR DUPLICATE PREVENTION SCENARIO
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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
                  icon: const Icon(Icons.science_rounded, size: 16),
                  label: const Text(
                    'Test Edge Case: Loss of Server Response (Idempotency)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                  ),
                ),

                // Expandable Sync Queue Items List
                if (_isExpanded) ...[
                  const Divider(height: 20),
                  const Text(
                    'PENDING & COMPLETED SYNC QUEUE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (queue.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Center(
                        child: Text(
                          'No records in sync queue.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: queue.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final item = queue[index];
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SyncStatusBadge(status: item.status, compact: true),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Key: ${item.idempotencyKey}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (item.status == SyncStatus.failed || item.status == SyncStatus.pending)
                                    IconButton(
                                      icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF2563EB)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => syncService.retrySingleRecord(item),
                                      tooltip: 'Retry sync',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Session: ${item.sessionId}',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Retries: ${item.retryCount}',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              if (item.serverRecordId != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Server Record: ${item.serverRecordId}',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                                ),
                              ],
                              if (item.errorMessage != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Error: ${item.errorMessage}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, color: Color(0xFFDC2626)),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              '$label: ',
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
            Text(
              '$count',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
