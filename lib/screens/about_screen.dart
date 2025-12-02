import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/app_localization.dart';
import '../utils/plugin.dart';
import '../utils/qr_derma_dialog.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('about')),
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          SizedBox(height: 20.h),

          // App Icon and Info
          Center(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '🕌',
                    style: TextStyle(fontSize: 80.sp),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Aqim',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '${loc.translate('version')} 1.0.0',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),

          // Info Links
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  context,
                  icon: Icons.code,
                  title: loc.translate('developer'),
                  onTap: () {
                    // Developer info
                  },
                  colorScheme: colorScheme,
                  isFirst: true,
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.support_agent,
                  title: loc.translate('contact_support'),
                  onTap: () {
                    // Contact support
                  },
                  colorScheme: colorScheme,
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.privacy_tip,
                  title: loc.translate('privacy_policy'),
                  onTap: () {
                    // Privacy policy
                  },
                  colorScheme: colorScheme,
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.description,
                  title: loc.translate('terms_of_service'),
                  onTap: () {
                    // Terms of service
                  },
                  colorScheme: colorScheme,
                ),
                _buildInfoTile(
                  context,
                  icon: Icons.article,
                  title: loc.translate('open_source_licenses'),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Aqim',
                      applicationVersion: '1.0.0',
                    );
                  },
                  colorScheme: colorScheme,
                  isLast: true,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // Support Development Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
                      child: const QrDermaDialog(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(radius),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '💝',
                        style: TextStyle(fontSize: 24.sp),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        loc.translate('support_development'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? Radius.circular(radius) : Radius.zero,
        bottom: isLast ? Radius.circular(radius) : Radius.zero,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          border: !isLast
              ? Border(
                  bottom: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}
