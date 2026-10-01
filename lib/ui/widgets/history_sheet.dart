import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/tracking_session.dart';
import 'sync_status_badge.dart';

class HistorySheet extends StatelessWidget {
  final List<TrackingSession> history;
  final VoidCallback onClearHistory;

  const HistorySheet({
    super.key,
    required this.history,
    required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 700.w),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: const Color(0xFF0F172A), size: 22.r),
                      SizedBox(width: 8.w),
                      Text(
                        'Trip History (${history.length})',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  if (history.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.redAccent, size: 22.r),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 450.w),
                              child: Padding(
                                padding: EdgeInsets.all(20.r),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Clear History',
                                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 12.h),
                                    Text(
                                      'Are you sure you want to delete all saved trip records?',
                                      style: TextStyle(fontSize: 14.sp, color: Colors.black87),
                                    ),
                                    SizedBox(height: 16.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: Text('Cancel', style: TextStyle(fontSize: 14.sp)),
                                        ),
                                        SizedBox(width: 8.w),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            onClearHistory();
                                          },
                                          child: Text(
                                            'Delete All',
                                            style: TextStyle(color: Colors.red, fontSize: 14.sp, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              if (history.isEmpty)
                Container(
                  padding: EdgeInsets.all(32.r),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.directions_walk, size: 48.r, color: Colors.grey.shade400),
                      SizedBox(height: 12.h),
                      Text(
                        'No completed trips yet',
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Start tracking a trip to log total distance in kilometres.',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: history.length,
                    separatorBuilder: (context, index) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final session = history[index];
                      return Container(
                        padding: EdgeInsets.all(16.r),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    session.formattedDistanceKm,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    SyncStatusBadge(status: session.syncStatus, compact: true),
                                    SizedBox(width: 8.w),
                                    Icon(Icons.timer, size: 14.r, color: Colors.grey),
                                    SizedBox(width: 4.w),
                                    Text(
                                      session.formattedDuration,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              'Started: ${session.formattedStartTime}',
                              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
                            ),
                            Text(
                              'Ended:   ${session.formattedEndTime}',
                              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Start: ${session.startLocation?.latitude.toStringAsFixed(4) ?? 'N/A'}, ${session.startLocation?.longitude.toStringAsFixed(4) ?? 'N/A'}',
                                    style: TextStyle(fontSize: 10.sp, fontFamily: 'monospace', color: Colors.grey.shade600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${session.points.length} pts',
                                  style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

