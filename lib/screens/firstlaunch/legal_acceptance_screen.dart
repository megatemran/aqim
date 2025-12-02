// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalAcceptanceScreen extends StatefulWidget {
  const LegalAcceptanceScreen({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  State<LegalAcceptanceScreen> createState() => _LegalAcceptanceScreenState();
}

class _LegalAcceptanceScreenState extends State<LegalAcceptanceScreen> {
  bool _agreePrivacy = false;
  bool _agreeTerms = false;
  bool _isLoading = false;
  bool _privacyRead = false;
  bool _termsRead = false;

  static const String privacyPolicyUrl =
      'https://megatemran.github.io/aqim/privacy-policy.html';
  static const String termsUrl = 'https://megatemran.github.io/aqim/terms.html';

  Future<void> _launchUrl(String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showError('Tidak dapat membuka dokumen.');
      }
    } catch (e) {
      _showError('Ralat berlaku: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _acceptAndContinue() async {
    if (!_privacyRead) {
      _showError('Sila baca Dasar Privasi terlebih dahulu.');
      return;
    }
    if (!_termsRead) {
      _showError('Sila baca Terma dan Syarat terlebih dahulu.');
      return;
    }

    if (!_agreePrivacy || !_agreeTerms) {
      _showError(
        'Anda perlu menerima kedua-dua Dasar Privasi dan Terma serta Syarat untuk meneruskan.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('legalAccepted', true);
      await prefs.setBool('privacyPolicyAccepted', true);
      await prefs.setBool('termsAccepted', true);

      await prefs.setString(
        'legalAcceptanceDate',
        DateTime.now().toIso8601String(),
      );

      await prefs.setString('privacyPolicyVersion', '1.0');
      await prefs.setString('termsVersion', '1.0');

      print('✅ Pengguna telah menerima dasar undang-undang.');
      print('📅 Tarikh penerimaan: ${DateTime.now()}');

      if (mounted) {
        widget.onAccepted();
      }
    } catch (e) {
      _showError('Ralat semasa menyimpan tetapan: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCanAccept =
        _agreePrivacy && _agreeTerms && _privacyRead && _termsRead;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda perlu menerima dasar untuk teruskan.'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: const Text('Penerimaan Dasar'),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.gpp_good_rounded,
                              size: 48.sp,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Selamat Datang ke Aqim',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Sebelum menggunakan aplikasi ini, sila baca dan terima dasar yang disediakan.',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: cs.onSurfaceVariant,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    _buildPolicyCard(
                      title: 'Dasar Privasi',
                      description:
                          'Ketahui bagaimana kami mengumpul, menggunakan dan melindungi maklumat peribadi anda.',
                      icon: Icons.privacy_tip_rounded,
                      isRead: _privacyRead,
                      isAccepted: _agreePrivacy,
                      onRead: () {
                        _launchUrl(privacyPolicyUrl);
                        setState(() => _privacyRead = true);
                      },
                      onAcceptChanged: (value) {
                        if (value != null && value && !_privacyRead) {
                          _showError(
                            'Sila baca Dasar Privasi terlebih dahulu.',
                          );
                          return;
                        }
                        setState(() => _agreePrivacy = value ?? false);
                      },
                      cs: cs,
                    ),
                    SizedBox(height: 16.h),

                    _buildPolicyCard(
                      title: 'Terma dan Syarat',
                      description:
                          'Baca terma dan syarat penggunaan aplikasi Aqim.',
                      icon: Icons.description_rounded,
                      isRead: _termsRead,
                      isAccepted: _agreeTerms,
                      onRead: () {
                        _launchUrl(termsUrl);
                        setState(() => _termsRead = true);
                      },
                      onAcceptChanged: (value) {
                        if (value != null && value && !_termsRead) {
                          _showError(
                            'Sila baca Terma dan Syarat terlebih dahulu.',
                          );
                          return;
                        }
                        setState(() => _agreeTerms = value ?? false);
                      },
                      cs: cs,
                    ),
                    SizedBox(height: 24.h),

                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: cs.secondary.withAlpha(100)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_rounded,
                                color: cs.onSecondaryContainer,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Maklumat Penting',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSecondaryContainer,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Penerimaan dasar ini adalah wajib untuk menggunakan Aqim. Kami menggunakan data lokasi bagi menentukan waktu solat yang tepat dan menghantar notifikasi. Segala maklumat dikendalikan secara selamat dan tidak akan dikongsi dengan pihak ketiga.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.6,
                              color: cs.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                border: Border(
                  top: BorderSide(color: cs.outlineVariant, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _buildStatusIndicator(
                        label: 'Privasi Dibaca',
                        isComplete: _privacyRead,
                        cs: cs,
                      ),
                      SizedBox(width: 12.w),
                      _buildStatusIndicator(
                        label: 'Terma Dibaca',
                        isComplete: _termsRead,
                        cs: cs,
                      ),
                      SizedBox(width: 12.w),
                      _buildStatusIndicator(
                        label: 'Diterima',
                        isComplete: _agreePrivacy && _agreeTerms,
                        cs: cs,
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: isCanAccept
                          ? cs.primary
                          : cs.primary.withAlpha(128),
                      foregroundColor: cs.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: isCanAccept && !_isLoading
                        ? _acceptAndContinue
                        : null,
                    child: _isLoading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                cs.onPrimary,
                              ),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Terima & Teruskan',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Anda tidak boleh meneruskan tanpa menerima kedua-dua dasar ini.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicyCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isRead,
    required bool isAccepted,
    required VoidCallback onRead,
    required Function(bool?) onAcceptChanged,
    required ColorScheme cs,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isAccepted ? cs.tertiaryContainer : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isRead
              ? cs.tertiary.withAlpha(100)
              : cs.outlineVariant.withAlpha(100),
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isRead ? cs.tertiary : cs.outline.withAlpha(50),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    icon,
                    color: isRead
                        ? cs.onTertiary
                        : cs.onSurfaceVariant.withAlpha(128),
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          if (isRead)
                            Icon(
                              Icons.check_circle_rounded,
                              color: cs.tertiary,
                              size: 18.sp,
                            )
                          else
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(200),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'Belum Dibaca',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: cs.onSurfaceVariant.withAlpha(200),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      side: BorderSide(
                        color: isRead ? cs.tertiary : cs.outlineVariant,
                        width: 1.5,
                      ),
                    ),
                    onPressed: onRead,
                    icon: Icon(
                      isRead ? Icons.check_rounded : Icons.open_in_new_rounded,
                      size: 16.sp,
                    ),
                    label: Text(
                      isRead ? 'Telah Dibaca ✓' : 'Baca Sekarang',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),

                Checkbox(
                  value: isAccepted,
                  onChanged: isRead ? onAcceptChanged : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  'Saya Bersetuju',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isRead ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator({
    required String label,
    required bool isComplete,
    required ColorScheme cs,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isComplete ? cs.tertiaryContainer : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isComplete ? cs.tertiary.withAlpha(100) : cs.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14.sp,
              color: isComplete ? cs.tertiary : cs.onSurfaceVariant,
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: isComplete ? cs.tertiary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
