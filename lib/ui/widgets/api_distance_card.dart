import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../providers/distance_provider.dart';
import '../../services/distance_api_service.dart';

class ApiDistanceCard extends StatelessWidget {
  const ApiDistanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DistanceProvider>(
      builder: (context, provider, child) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.api_rounded, color: const Color(0xFF6366F1), size: 20.r),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'API Distance Feed',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Task 2 – Missing API Data Handling',
                            style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // Interactive Scenario Selector for Testing & Demonstration
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<DistanceApiScenario>(
                      isExpanded: true,
                      value: provider.activeScenario,
                      icon: Icon(Icons.arrow_drop_down_rounded, color: const Color(0xFF6366F1), size: 24.r),
                      style: TextStyle(fontSize: 12.sp, color: const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      onChanged: (DistanceApiScenario? newScenario) {
                        if (newScenario != null) {
                          provider.setScenario(newScenario);
                        }
                      },
                      items: DistanceApiScenario.values.map((scenario) {
                        return DropdownMenuItem<DistanceApiScenario>(
                          value: scenario,
                          child: Text(
                            scenario.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // State Rendering Switch
                _buildContentArea(context, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentArea(BuildContext context, DistanceProvider provider) {
    // 1. LOADING STATE
    if (provider.isLoading) {
      return Container(
        padding: EdgeInsets.all(20.r),
        alignment: Alignment.center,
        child: Column(
          children: [
            SizedBox(
              width: 24.r,
              height: 24.r,
              child: const CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF6366F1)),
            ),
            SizedBox(height: 10.h),
            Text(
              'Fetching distance from API...',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 2. SUCCESS STATE (Valid positive distance received)
    if (provider.isSuccess) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: const Color(0xFF059669), size: 18.r),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    'API DISTANCE LOADED',
                    style: TextStyle(
                      color: const Color(0xFF059669),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                provider.formattedDistance,
                style: TextStyle(
                  color: const Color(0xFF047857),
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 3. UNAVAILABLE STATE (Null distance, missing field, or negative/invalid value)
    if (provider.isUnavailable) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, color: const Color(0xFFD97706), size: 20.r),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    'Distance unavailable',
                    style: TextStyle(
                      color: const Color(0xFFB45309),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (provider.errorMessage != null) ...[
              SizedBox(height: 4.h),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.sp, color: const Color(0xFF92400E)),
              ),
            ],
            SizedBox(height: 12.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () => provider.retry(),
              icon: Icon(Icons.refresh_rounded, size: 16.r),
              label: Text('Retry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
            ),
          ],
        ),
      );
    }

    // 4. ERROR STATE (Timeout, Server Error, Network Error)
    if (provider.isError) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, color: const Color(0xFFDC2626), size: 20.r),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    'API Request Failed',
                    style: TextStyle(
                      color: const Color(0xFFB91C1C),
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              provider.errorMessage ?? 'Unable to retrieve distance. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF991B1B)),
            ),
            SizedBox(height: 12.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () => provider.retry(),
              icon: Icon(Icons.refresh_rounded, size: 16.r),
              label: Text('Retry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp)),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

