// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DoaService {
  final List<Map<String, dynamic>> doaHeader = [
    {
      'arabic': "وَقَالَ رَبُّكُمُ ادْعُونِي أَسْتَجِبْ لَكُمْ ۚ",
      'ms':
          'Dan Tuhan kamu berfirman: "Berdoalah kamu kepada-Ku, nescaya Aku perkenankan doa permohonan kamu.',
      'ref': 'Ghafir (40:60)',
      'nota':
          'Ayat paling terkenal tentang kepentingan doa dan janji Allah untuk memakbulkannya.',
    },
    {
      'arabic':
          'وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ ۖ',
      'ms':
          'Dan apabila hamba-hamba-Ku bertanya kepadamu mengenai Aku, maka (beritahulah kepada mereka): Sesungguhnya Aku (Allah) sentiasa hampir (kepada mereka); Aku perkenankan permohonan orang yang berdoa apabila ia berdoa kepada-Ku',
      'ref': 'Al-Baqarah (2:186)',
      'nota':
          'Menunjukkan kedekatan Allah dengan hamba-Nya ketika mereka berdoa.',
    },
    {
      'arabic': 'ادْعُوا رَبَّكُمْ تَضَرُّعًا وَخُفْيَةً ۚ',
      'ms':
          'Berdoalah kepada Tuhanmu dengan merendah diri dan (dengan suara) perlahan-lahan',
      'ref': 'Al-A\'raf (7:55)',
      'nota':
          'Menekankan adab berdoa — dengan rendah hati dan penuh keikhlasan.',
    },
    {
      'arabic': "قُلْ مَا يَعْبَؤُا بِكُمْ رَبِّي لَوْلَا دُعَاؤُكُمْ ۖ",
      'ms':
          'Katakanlah (wahai Muhammad kepada golongan yang ingkar): "Tuhanku tidak akan menghargai kamu kalau tidak adanya doa ibadat kamu kepadaNya;',
      'ref': 'Al-Furqan (25:77)',
      'nota':
          'Menunjukkan betapa doa adalah tanda perhatian Allah kepada manusia.',
    },
  ];
  final List<Map<String, String>> kategoriDoa = [
    {'en': 'Daily', 'ms': 'Harian'},
    {'en': 'Hygiene', 'ms': 'Kebersihan'},
    {'en': 'Eating', 'ms': 'Makan'},
    {'en': 'Mosque', 'ms': 'Masjid'},
    {'en': 'Ablution', 'ms': 'Wuduk'},
    {'en': 'Fasting', 'ms': 'Puasa'},
    {'en': 'Home', 'ms': 'Rumah'},
    {'en': 'Protection', 'ms': 'Perlindungan'},
    {'en': 'Travel', 'ms': 'Perjalanan'},
    {'en': 'Clothing', 'ms': 'Pakaian'},
    {'en': 'Weather', 'ms': 'Cuaca'},
    {'en': 'Repentance', 'ms': 'Taubat'},
    {'en': 'Supplication', 'ms': 'Doa'},
    {'en': 'Calamity', 'ms': 'Musibah'},
    {'en': 'Debt', 'ms': 'Hutang'},
    {'en': 'Wellbeing', 'ms': 'Kesejahteraan'},
    {'en': 'Etiquette', 'ms': 'Adab'},
    {'en': 'Character', 'ms': 'Akhlak'},
    {'en': 'Adhan', 'ms': 'Azan'},
    {'en': 'Parents', 'ms': 'Ibu Bapa'},
  ];

  String getCategory(String text) {
    // cari padanan Bahasa Malaysia ke Bahasa Inggeris
    final map = kategoriDoa.firstWhere(
      (element) => element['ms'] == text,
      orElse: () => {'en': text},
    );
    return map['en']!;
  }

  static const String apiUrl =
      'https://api.github.com/repos/megatemran/aqim/contents/duas_all.json?ref=main';
  static const String cacheKey = 'cached_duas';
  static const String lastFetchKey = 'last_dua_fetch_time';

  static Future<List<dynamic>> fetchDuas() async {
    //GET DOA DATA ONCE PER DAY
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    // Check when last fetched
    final lastFetchString = prefs.getString(lastFetchKey);
    if (lastFetchString != null) {
      final lastFetch = DateTime.tryParse(lastFetchString);
      if (lastFetch != null && now.difference(lastFetch).inHours < 24) {
        // Less than a day → load cached data
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          print('📦 Loaded duas from cache');
          return jsonDecode(cached);
        }
      }
    }

    try {
      final response = await Dio().get(apiUrl);

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map && data.containsKey('content')) {
          // decode Base64 JSON
          final base64Content = data['content'].replaceAll('\n', '');
          final decoded = utf8.decode(base64.decode(base64Content));
          final List<dynamic> jsonData = jsonDecode(decoded);

          // Save to local cache
          await prefs.setString(cacheKey, jsonEncode(jsonData));
          await prefs.setString(lastFetchKey, now.toIso8601String());

          print('✅ Dua data updated & cached');
          return jsonData;
        } else {
          throw Exception('Invalid GitHub content structure');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Failed to fetch duas: $e');
      // fallback to cached
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        print('⚠️ Using cached data due to error');
        return jsonDecode(cached);
      }
      return [];
    }
  }

  /// Get one random doa from the fetched list
  static Future<Map<String, dynamic>?> getRandomDoa(
    List<dynamic>? doaData,
  ) async {
    // final allDuas = await fetchDuas();
    if (doaData!.isEmpty) {
      doaData = await fetchDuas();
    }

    final random = Random();
    final randomIndex = random.nextInt(doaData.length);
    return doaData[randomIndex];
  }

  /// Get multiple random duas (e.g., 3 random ones)
  static Future<List<Map<String, dynamic>>> getRandomDuas(int count) async {
    final allDuas = await fetchDuas();
    if (allDuas.isEmpty) return [];

    final random = Random();
    final shuffled = List<Map<String, dynamic>>.from(allDuas)..shuffle(random);
    return shuffled.take(count).toList();
  }
}
