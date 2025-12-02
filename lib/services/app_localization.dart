import 'package:flutter/material.dart';

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static final Map<String, Map<String, String>> _localizedValues = {
    'ms': {
      // Onboarding
      'welcome': 'Selamat Datang',
      'app_description': 'Aplikasi waktu solat yang mudah dan tepat',
      'choose_theme': 'Pilih Tema',
      'light': 'Cerah',
      'dark': 'Gelap',
      'auto': 'Auto',
      'choose_language': 'Pilih Bahasa',
      'continue': 'Teruskan',
      'get_started': 'Mulakan',

      // Permission Dialog
      'app_permissions': 'Kebenaran Aplikasi',
      'best_experience': 'Untuk pengalaman terbaik',
      'permissions_required': 'Aplikasi ini memerlukan kebenaran berikut:',
      'location': 'Lokasi',
      'location_desc': 'Menentukan waktu solat mengikut kawasan anda',
      'notification': 'Notifikasi',
      'notification_desc': 'Mengingatkan anda masuk waktu solat',
      'exact_alarm': 'Alarm Tepat',
      'exact_alarm_desc': 'Memastikan azan berbunyi tepat pada waktunya',
      'data_safe': 'Data anda selamat dan dilindungi',
      'data_safe_message': 'Data anda selamat dan dilindungi',

      // Prayer Times
      'prayer_times': 'Waktu Solat',
      'next_prayer': 'Solat Seterusnya',
      'view_all_times': 'Lihat Semua Waktu Solat',
      'main_menu': 'Menu Utama',
      'dua': 'Doa',
      'hadith': 'Hadith',
      'qibla': 'Qiblat',
      'calendar': 'Kalendar',
      'dua_of_the_day': 'Doa Hari Ini',
      'hadith_of_the_day': 'Hadith Hari Ini',
      'narrated_by': 'Diriwayatkan oleh',
      'dua_collection': 'Koleksi Doa',
      'hadith_collection': 'Koleksi Hadith',
      'daily_duas': 'Doa Harian',
      'prayer_duas': 'Doa Solat',
      'food_duas': 'Doa Makan & Minum',
      'travel_duas': 'Doa Perjalanan',
      'morning_evening': 'Doa Pagi & Petang',
      'protection_duas': 'Doa Perlindungan',

      // Location Service Translations
      'location_services_disabled': 'Perkhidmatan Lokasi Dilumpuhkan',
      'location_services_disabled_desc':
          'Perkhidmatan lokasi sedang dilumpuhkan pada peranti anda. Kami memerlukannya untuk menyediakan ciri-ciri berasaskan lokasi yang tepat.',
      'why_we_need_this': 'Mengapa kami memerlukan ini',
      'to_show_nearby':
          'Untuk menunjukkan tempat berhampiran dan menyediakan perkhidmatan yang tepat',
      'your_privacy': 'Privasi anda',
      'can_disable_anytime':
          'Anda boleh melumpuhkan lokasi pada bila-bila masa daripada tetapan peranti',

      // ✅ Qibla Screen Translations (NEW)
      'qibla_title': 'Arah Qiblat',
      'determining_location': 'Menentukan lokasi...',
      'calculating_qibla': 'Sedang mengira arah qiblat...',
      'compass_unavailable': 'Tidak dapat mengesan kompas',
      'compass_unavailable_desc':
          'Pastikan peranti anda mempunyai sensor kompas',
      'retry': 'Cuba Lagi',
      'current_direction': 'Arah Semasa',
      'qibla_direction': 'Arah Qiblat',
      'distance_to_mecca': 'Jarak ke Makkah',
      'accuracy_tips': 'Petua untuk Ketepatan Lebih Baik',
      'tip_away_from_metal': '🧭 Jauh dari logam dan perangkat elektronik',
      'tip_gps_accurate': '📍 Gunakan GPS untuk lokasi yang tepat',
      'tip_calibrate': '🔄 Putar peranti perlahan untuk kalibrasi',
      'next_prayer_label': 'Solat Seterusnya',
      'time': 'Masa',
      'current_heading': 'Arah Semasa',
      'looking_for_qibla': 'Mencari Arah Qiblat',

      // Settings Screen Translations
      'settings': 'Tetapan',
      'prayer_notifications': 'Notifikasi Solat',
      'configure_azan': 'Konfigurasi azan & peringatan',
      'display_language': 'Paparan & Bahasa',
      'theme_language_format': 'Tema, bahasa & format',
      'about_info': 'Tentang & Info',
      'version_credits': 'Versi, kredit & sokongan',

      // Appearance Settings
      'appearance': 'Setting',
      'theme': 'Tema',
      'system_default': 'Lalai Sistem',
      'language': 'Bahasa',
      'time_format': 'Format Masa',
      '24_hour_format': 'Format 24 Jam',
      'example': 'Contoh',

      // About Screen
      'about': 'Tentang',
      'developer': 'Pembangun',
      'contact_support': 'Hubungi & Sokongan',
      'privacy_policy': 'Dasar Privasi',
      'terms_of_service': 'Terma Perkhidmatan',
      'open_source_licenses': 'Lesen Sumber Terbuka',
      'support_development': 'Sokong Pembangunan',
      'version': 'Versi',
    },
    'en': {
      // Onboarding
      'welcome': 'Welcome',
      'app_description': 'Simple and accurate prayer times app',
      'choose_theme': 'Choose Theme',
      'light': 'Light',
      'dark': 'Dark',
      'auto': 'Auto',
      'choose_language': 'Choose Language',
      'continue': 'Continue',
      'get_started': 'Get Started',

      // Permission Dialog
      'app_permissions': 'App Permissions',
      'best_experience': 'For the best experience',
      'permissions_required': 'This app requires the following permissions:',
      'location': 'Location',
      'location_desc': 'Determine prayer times based on your area',
      'notification': 'Notification',
      'notification_desc': 'Remind you when prayer time arrives',
      'exact_alarm': 'Exact Alarm',
      'exact_alarm_desc': 'Ensure azan sounds exactly on time',
      'data_safe': 'Your data is safe and protected',
      'data_safe_message': 'Your data is safe and protected',

      // Prayer Times
      'prayer_times': 'Prayer Times',
      'next_prayer': 'Next Prayer',
      'view_all_times': 'View All Prayer Times',
      'main_menu': 'Main Menu',
      'dua': 'Dua',
      'hadith': 'Hadith',
      'qibla': 'Qibla',
      'calendar': 'Calendar',
      'dua_of_the_day': 'Dua of the Day',
      'hadith_of_the_day': 'Hadith of the Day',
      'narrated_by': 'Narrated by',
      'dua_collection': 'Dua Collection',
      'hadith_collection': 'Hadith Collection',
      'daily_duas': 'Daily Duas',
      'prayer_duas': 'Prayer Duas',
      'food_duas': 'Food & Drink Duas',
      'travel_duas': 'Travel Duas',
      'morning_evening': 'Morning & Evening Duas',
      'protection_duas': 'Protection Duas',

      // Location Service Translations
      'location_services_disabled': 'Location Services Disabled',
      'location_services_disabled_desc':
          'Location services are currently disabled on your device. We need them to provide accurate location-based features.',
      'why_we_need_this': 'Why we need this',
      'to_show_nearby':
          'To show you nearby places and provide accurate services',
      'your_privacy': 'Your privacy',
      'can_disable_anytime':
          'You can disable location anytime from device settings',

      // ✅ Qibla Screen Translations (NEW)
      'qibla_title': 'Qibla Direction',
      'determining_location': 'Determining location...',
      'calculating_qibla': 'Calculating qibla direction...',
      'compass_unavailable': 'Cannot detect compass',
      'compass_unavailable_desc': 'Ensure your device has a compass sensor',
      'retry': 'Retry',
      'current_direction': 'Current Direction',
      'qibla_direction': 'Qibla Direction',
      'distance_to_mecca': 'Distance to Mecca',
      'accuracy_tips': 'Tips for Better Accuracy',
      'tip_away_from_metal': '🧭 Stay away from metal and electronic devices',
      'tip_gps_accurate': '📍 Use GPS for accurate location',
      'tip_calibrate': '🔄 Rotate device slowly for calibration',
      'next_prayer_label': 'Next Prayer',
      'time': 'Time',
      'current_heading': 'Current Heading',
      'looking_for_qibla': 'Looking for Qibla',

      // Settings Screen Translations
      'settings': 'Settings',
      'prayer_notifications': 'Prayer Notifications',
      'configure_azan': 'Configure azan & alerts',
      'display_language': 'Display & Language',
      'theme_language_format': 'Theme, language & format',
      'about_info': 'About & Info',
      'version_credits': 'Version, credits & support',

      // Appearance Settings
      'appearance': 'Appearance',
      'theme': 'Theme',
      'system_default': 'System Default',
      'language': 'Language',
      'time_format': 'Time Format',
      '24_hour_format': '24-Hour Format',
      'example': 'Example',

      // About Screen
      'about': 'About',
      'developer': 'Developer',
      'contact_support': 'Contact & Support',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'open_source_licenses': 'Open Source Licenses',
      'support_development': 'Support Development',
      'version': 'Version',
    },
    'ar': {
      // Onboarding
      'welcome': 'مرحباً',
      'app_description': 'تطبيق مواقيت الصلاة البسيط والدقيق',
      'choose_theme': 'اختر الموضوع',
      'light': 'فاتح',
      'dark': 'داكن',
      'auto': 'تلقائي',
      'choose_language': 'اختر اللغة',
      'continue': 'متابعة',
      'get_started': 'ابدأ الآن',

      // Permission Dialog
      'app_permissions': 'أذونات التطبيق',
      'best_experience': 'للحصول على أفضل تجربة',
      'permissions_required': 'يتطلب هذا التطبيق الأذونات التالية:',
      'location': 'الموقع',
      'location_desc': 'لتحديد مواقيت الصلاة حسب منطقتك',
      'notification': 'الإشعارات',
      'notification_desc': 'لتنبيهك عند دخول وقت الصلاة',
      'exact_alarm': 'المنبه الدقيق',
      'exact_alarm_desc': 'لضمان رفع الأذان في الوقت المحدد',
      'data_safe': 'بيانات آمنة ومحمية',
      'data_safe_message': 'بيانات آمنة ومحمية',

      // Prayer Times
      'prayer_times': 'مواقيت الصلاة',
      'next_prayer': 'الصلاة القادمة',
      'view_all_times': 'عرض جميع أوقات الصلاة',
      'main_menu': 'القائمة الرئيسية',
      'dua': 'الدعاء',
      'hadith': 'الحديث',
      'qibla': 'القبلة',
      'calendar': 'التقويم',
      'dua_of_the_day': 'دعاء اليوم',
      'hadith_of_the_day': 'حديث اليوم',
      'narrated_by': 'رواه',
      'dua_collection': 'مجموعة الأدعية',
      'hadith_collection': 'مجموعة الأحاديث',
      'daily_duas': 'أدعية يومية',
      'prayer_duas': 'أدعية الصلاة',
      'food_duas': 'أدعية الطعام والشراب',
      'travel_duas': 'أدعية السفر',
      'morning_evening': 'أدعية الصباح والمساء',
      'protection_duas': 'أدعية الحماية',

      // Location Service Translations
      'location_services_disabled': 'تعطيل خدمات الموقع',
      'location_services_disabled_desc':
          'خدمات الموقع معطلة حالياً على جهازك. نحتاجها لتوفير ميزات دقيقة قائمة على الموقع.',
      'why_we_need_this': 'لماذا نحتاج هذا',
      'to_show_nearby': 'لإظهار الأماكن القريبة منك وتوفير خدمات دقيقة',
      'your_privacy': 'خصوصيتك',
      'can_disable_anytime': 'يمكنك تعطيل الموقع في أي وقت من إعدادات الجهاز',

      // ✅ Qibla Screen Translations (NEW)
      'qibla_title': 'اتجاه القبلة',
      'determining_location': 'جاري تحديد الموقع...',
      'calculating_qibla': 'جاري حساب اتجاه القبلة...',
      'compass_unavailable': 'لا يمكن الوصول إلى البوصلة',
      'compass_unavailable_desc': 'تأكد من أن جهازك يحتوي على مستشعر البوصلة',
      'retry': 'إعادة محاولة',
      'current_direction': 'الاتجاه الحالي',
      'qibla_direction': 'اتجاه القبلة',
      'distance_to_mecca': 'المسافة إلى مكة',
      'accuracy_tips': 'نصائح للحصول على دقة أفضل',
      'tip_away_from_metal': '🧭 ابتعد عن المعادن والأجهزة الإلكترونية',
      'tip_gps_accurate': '📍 استخدم GPS للحصول على موقع دقيق',
      'tip_calibrate': '🔄 أدر جهازك ببطء للمعايرة',
      'next_prayer_label': 'الصلاة القادمة',
      'time': 'الوقت',
      'current_heading': 'الاتجاه الحالي',
      'looking_for_qibla': 'البحث عن اتجاه القبلة',

      // Settings Screen Translations
      'settings': 'الإعدادات',
      'prayer_notifications': 'إشعارات الصلاة',
      'configure_azan': 'تكوين الأذان والتنبيهات',
      'display_language': 'العرض واللغة',
      'theme_language_format': 'المظهر واللغة والتنسيق',
      'about_info': 'حول ومعلومات',
      'version_credits': 'الإصدار والاعتمادات والدعم',

      // Appearance Settings
      'appearance': 'المظهر',
      'theme': 'المظهر',
      'system_default': 'افتراضي النظام',
      'language': 'اللغة',
      'time_format': 'تنسيق الوقت',
      '24_hour_format': 'تنسيق 24 ساعة',
      'example': 'مثال',

      // About Screen
      'about': 'حول',
      'developer': 'المطور',
      'contact_support': 'الاتصال والدعم',
      'privacy_policy': 'سياسة الخصوصية',
      'terms_of_service': 'شروط الخدمة',
      'open_source_licenses': 'تراخيص مفتوحة المصدر',
      'support_development': 'دعم التطوير',
      'version': 'الإصدار',
    },
  };

  String translate(String key) {
    return _localizedValues[languageCode]?[key] ?? key;
  }

  static AppLocalizations? maybeOf(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<LocalizationProvider>();
    return provider?.localizations;
  }

  static AppLocalizations of(BuildContext context) {
    final localizations = maybeOf(context);
    assert(localizations != null, 'No LocalizationProvider found in context');
    return localizations!;
  }
}

class LocalizationProvider extends InheritedWidget {
  final AppLocalizations localizations;

  const LocalizationProvider({
    super.key,
    required this.localizations,
    required super.child,
  });

  @override
  bool updateShouldNotify(LocalizationProvider oldWidget) {
    return localizations.languageCode != oldWidget.localizations.languageCode;
  }

  static AppLocalizations of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<LocalizationProvider>();
    return provider!.localizations;
  }
}
