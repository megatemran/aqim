import 'package:aqim/utils/plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDermaDialog extends StatelessWidget {
  const QrDermaDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // final cs = Theme.of(context).colorScheme;
    final qrAccout =
        '00020201021126460014A000000615000101066033460214883000212327305204000053034585802MY5925MEGAT SHAFRIL EMRAN BIN M6002MY6304938E';
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(24.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFED2E67),
                  borderRadius: BorderRadius.circular(radius),
                ),
                child: Padding(
                  padding: EdgeInsets.all(15.w),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(radius),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 10.h),
                            SizedBox(
                              height: 70.h,
                              child: Image.asset(
                                'assets/images/logo_qr.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 50.w),
                              child: QrImageView(
                                data: qrAccout,
                                version: QrVersions.auto,
                                // size: 250.w,
                                backgroundColor: Colors.white,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsGeometry.only(bottom: 12.h),
                              child: Text(
                                'AQIM',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsGeometry.symmetric(vertical: 10.h),
                        child: Text(
                          'MALAYSIA NATIONAL QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),

                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(radius),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Jika aplikasi ini membantu anda, pertimbangkan untuk memberi sedikit sumbangan sebagai tanda sokongan agar kami dapat terus membangunkannya. Terima kasih atas sokongan anda!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Column(
                              children: [
                                Container(
                                  height: 40.h,
                                  width: 40.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        'assets/images/logo_aqim.png',
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  'Aqim',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
    );
  }
}
