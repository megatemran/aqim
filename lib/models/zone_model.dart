// Malaysia Prayer Times Zones with Precise Coordinates
// Converted from DMS (Degrees, Minutes, Seconds) to Decimal Format
// Format: U X° Y' Z'' = X + Y/60 + Z/3600

const Map<String, dynamic> malaysiaZones = {
  // ========== PERLIS ==========
  'PLS01': {
    'name': 'Perlis (Seluruh Negeri)',
    'state': 'Perlis',
    'reference': 'Kuala Perlis',
    'latitude': 6.4219, // U 6° 25' 19''
    'longitude': 100.1217, // T 100° 07' 18''
  },

  // ========== KEDAH ==========
  'KDH01': {
    'name': 'Kota Setar, Pokok Sena, Kubang Pasu',
    'state': 'Kedah',
    'reference': 'Kuala Sanglang',
    'latitude': 6.25, // U 6° 15'
    'longitude': 100.1917, // T 100° 11' 30''
  },
  'KDH02': {
    'name': 'Kuala Muda, Pendang, Yan',
    'state': 'Kedah',
    'reference': 'Kuala Muda',
    'latitude': 5.5833, // U 5° 35'
    'longitude': 100.3417, // T 100° 20' 30''
  },
  'KDH03': {
    'name': 'Padang Terap, Sik',
    'state': 'Kedah',
    'reference': 'Kg. Paya Kelubi',
    'latitude': 6.2583, // U 6° 15' 30''
    'longitude': 100.5083, // T 100° 30' 30''
  },
  'KDH04': {
    'name': 'Baling',
    'state': 'Kedah',
    'reference': 'Kg. Kuala Sidim',
    'latitude': 5.55, // U 5° 33'
    'longitude': 100.6083, // T 100° 36' 30''
  },
  'KDH05': {
    'name': 'Kulim, Bandar Baharu',
    'state': 'Kedah',
    'reference': 'Bandar Baharu',
    'latitude': 5.1333, // U 5° 08'
    'longitude': 100.4917, // T 100° 29' 30''
  },
  'KDH06': {
    'name': 'Langkawi',
    'state': 'Kedah',
    'reference': 'Tanjung Ular',
    'latitude': 6.45, // U 6° 27'
    'longitude': 99.6333, // T 99° 38'
  },
  'KDH07': {
    'name': 'Gunung Jerai',
    'state': 'Kedah',
    'reference': 'Gunung Jerai',
    'latitude': 5.7875, // U 5° 47' 15''
    'longitude': 100.4417, // T 100° 26' 30''
    'elevation': 1214, // meters
  },

  // ========== PULAU PINANG ==========
  'PNG01': {
    'name': 'Pulau Pinang (Seluruh Negeri)',
    'state': 'Pulau Pinang',
    'reference': 'Pantai Acheh',
    'latitude': 5.4167, // U 5° 25'
    'longitude': 100.2, // T 100° 12'
    'notes': 'Bukit Bendera: -3 min (Subuh, Syuruk, Dhuha), +3 min (Maghrib)',
  },

  // ========== PERAK ==========
  'PRK01': {
    'name': 'Tapah, Slim River, Tanjung Malim',
    'state': 'Perak',
    'reference_east': 'Hulu Bernam Timur',
    'latitude_east': 3.7833, // U 03° 47' 00"
    'longitude_east': 101.6250, // T 101° 37' 30"
    'reference_west': 'Chenderiang',
    'latitude_west': 4.2597, // U 04° 15' 35"
    'longitude_west': 101.0750, // T 101° 04' 30"
  },
  'PRK02': {
    'name': 'Ipoh, Batu Gajah, Kampar, Sg. Siput, Kuala Kangsar',
    'state': 'Perak',
    'reference_east': 'Kg. Kasang',
    'latitude_east': 4.8917, // U 04° 53' 30"
    'longitude_east': 101.4458, // T 101° 26' 45"
    'reference_west': 'Gg. Sunting Buluh',
    'latitude_west': 4.5167, // U 04° 31' 00"
    'longitude_west': 100.7125, // T 100° 42' 45"
  },
  'PRK03': {
    'name': 'Pengkalan Hulu, Gerik, Lenggong',
    'state': 'Perak',
    'reference_east': 'Gg. Bieh',
    'latitude_east': 5.0083, // U 05° 00' 30"
    'longitude_east': 101.4458, // T 101° 26' 45"
    'reference_west': 'Gg. Bintang',
    'latitude_west': 5.4583, // U 05° 27' 30"
    'longitude_west': 100.8708, // T 100° 52' 15"
  },
  'PRK04': {
    'name': 'Temengor, Belum',
    'state': 'Perak',
    'reference_east': 'Gg. Basor',
    'latitude_east': 5.5042, // U 05° 30' 15"
    'longitude_east': 101.75, // T 101° 45' 00"
    'reference_west': 'Rizab Melayu Temengor',
    'latitude_west': 5.5708, // U 05° 34' 15"
    'longitude_west': 101.2097, // T 101° 12' 35"
  },
  'PRK05': {
    'name':
        'Teluk Intan, Bagan Datuk, Kg. Gajah, Seri Iskandar, Beruas, Parit, Lumut, Sitiawan, Pulau Pangkor',
    'state': 'Perak',
    'reference_east': 'Changkat Menteri',
    'latitude_east': 3.7167, // U 03° 43' 00"
    'longitude_east': 101.2333, // T 101° 14' 00"
    'reference_west': 'Teluk Belanga',
    'latitude_west': 4.2, // U 04° 12' 00"
    'longitude_west': 100.5333, // T 100° 32' 00"
  },
  'PRK06': {
    'name': 'Selama, Taiping, Bagan Serai, Parit Buntar',
    'state': 'Perak',
    'reference_east': 'Titiwangsa',
    'latitude_east': 5.2667, // U 05° 16' 00"
    'longitude_east': 100.95, // T 100° 57' 00"
    'reference_west': 'Tanjong Piandang',
    'latitude_west': 5.0750, // U 05° 04' 30"
    'longitude_west': 100.3833, // T 100° 23' 00"
  },
  'PRK07': {
    'name': 'Bukit Larut',
    'state': 'Perak',
    'reference': 'Bukit Larut',
    'latitude': 4.8667, // U 04° 52' 00"
    'longitude': 100.8, // T 100° 48' 00"
    'elevation': 945, // meters
  },

  // ========== SELANGOR ==========
  'SGR01': {
    'name': 'Hulu Selangor, Gombak, Petaling/Shah Alam, Hulu Langat, Sepang',
    'state': 'Selangor',
    'reference_west_1': 'Kg. Gedangsa',
    'latitude_west_1': 3.7333, // U 3° 44'
    'longitude_west_1': 101.3833, // T 101° 23'
    'reference_west_2': 'Tg. Rhu, Sepang',
    'latitude_west_2': 2.6378, // U 2° 38' 16''
    'longitude_west_2': 101.6167, // T 101° 37'
    'reference_east': 'Pekan Broga',
    'latitude_east': 2.9400, // U 2° 56' 24''
    'longitude_east': 101.9114, // T 101° 54' 41''
  },
  'SGR02': {
    'name': 'Sabak Bernam, Kuala Selangor',
    'state': 'Selangor',
    'reference_west': 'Balai Cerap Selangor',
    'latitude_west': 3.9333, // U 3° 56'
    'longitude_west': 100.7, // T 100° 42'
    'reference_east': 'Pekan Broga',
    'latitude_east': 3.2025, // U 3° 12' 09''
    'longitude_east': 101.4886, // T 101° 29' 19''
  },
  'SGR03': {
    'name': 'Klang, Kuala Langat',
    'state': 'Selangor',
    'reference_west': 'Pulau Ketam',
    'latitude_west': 3.0167, // U 3° 01'
    'longitude_west': 101.25, // T 101° 15'
    'reference_east': 'Tmn Langat Murni',
    'latitude_east': 2.8028, // U 2° 48' 10''
    'longitude_east': 101.6550, // T 101° 39' 18''
  },

  // ========== WILAYAH PERSEKUTUAN ==========
  'WLY01': {
    'name': 'Kuala Lumpur, Putrajaya',
    'state': 'Wilayah Persekutuan Kuala Lumpur',
    'reference': 'Kg. Gedangsa',
    'latitude': 3.7333, // U 3° 44'
    'longitude': 101.3833, // T 101° 23'
  },
  'WLY01_SYURUK': {
    'name': 'Kuala Lumpur (Waktu Syuruk)',
    'state': 'Wilayah Persekutuan Kuala Lumpur',
    'reference': 'Cheras KL',
    'latitude': 3.1900, // U 3° 11' 24''
    'longitude': 101.7583, // T 101° 45' 30''
  },
  'WLY02': {
    'name': 'Labuan',
    'state': 'Wilayah Persekutuan Labuan',
    'reference': 'Pulau Kuraman',
    'latitude': 5.2481, // U 5° 14' 53''
    'longitude': 115.1397, // T 115° 08' 23''
  },
  'WLY02_SYURUK': {
    'name': 'Labuan (Waktu Syuruk)',
    'state': 'Wilayah Persekutuan Labuan',
    'reference': 'Pulau Daat',
    'latitude': 5.2897, // U 5° 17' 23''
    'longitude': 115.3428, // T 115° 20' 34''
  },
  // 'WLY03': {
  //   'name': 'Putrajaya',
  //   'state': 'Putrajaya',
  //   'reference': 'Kg. Gedangsa',
  //   'latitude': 3.7333, // U 3° 44'
  //   'longitude': 101.3833, // T 101° 23'
  // },

  // ========== NEGERI SEMBILAN ==========
  'NGS01': {
    'name': 'Jempol, Tampin',
    'state': 'Negeri Sembilan',
    'reference': 'Kg. Baru Serting',
    'latitude': 2.9, // U 2° 54'
    'longitude': 102.3167, // T 102° 19'
  },
  'NGS02': {
    'name': 'Port Dickson, Seremban, Kuala Pilah, Jelebu, Rembau',
    'state': 'Negeri Sembilan',
    'reference': 'Port Dickson',
    'latitude': 2.5333, // U 2° 32'
    'longitude': 101.8, // T 101° 48'
  },

  // ========== MELAKA ==========
  'MLK01': {
    'name': 'Melaka (Seluruh Negeri)',
    'state': 'Melaka',
    'reference': 'Kuala Linggi',
    'latitude': 2.3833, // U 02° 23' 00"
    'longitude': 101.9833, // T 101° 59' 00"
  },

  // ========== JOHOR ==========
  'JHR01': {
    'name': 'Pulau Aur, Pulau Pemanggil',
    'state': 'Johor',
    'reference': 'Pulau Pemanggil (Kg. Buau)',
    'latitude': 2.5833, // U 2° 35'
    'longitude': 104.3167, // T 104° 19'
  },
  'JHR02': {
    'name': 'Kota Tinggi, Mersing, Johor Bahru',
    'state': 'Johor',
    'reference': 'Kg. Sedenak',
    'latitude': 1.7167, // U 1° 43'
    'longitude': 103.5333, // T 103° 32'
  },
  'JHR03': {
    'name': 'Kluang, Pontian',
    'state': 'Johor',
    'reference': 'Tampok',
    'latitude': 1.65, // U 1° 39'
    'longitude': 103.2, // T 103° 12'
  },
  'JHR04': {
    'name': 'Batu Pahat, Muar, Segamat, Gemas',
    'state': 'Johor',
    'reference': 'Tangkak',
    'latitude': 2.2667, // U 2° 16'
    'longitude': 102.5333, // T 102° 32'
  },

  // ========== KELANTAN ==========
  'KTN01': {
    'name':
        'Kota Bharu, Bachok, Pasir Puteh, Tumpat, Pasir Mas, Tanah Merah, Machang, Kuala Krai, Gua Musang (Chiku)',
    'state': 'Kelantan',
    'reference': 'Bandar Rantau Panjang',
    'latitude': 6.0167, // U 06° 01'
    'longitude': 101.9833, // T 101° 59'
  },
  'KTN02': {
    'name': 'Jeli, Gua Musang (Galas, Bertam), Lojing',
    'state': 'Kelantan',
    'reference': 'Pos Dakoh',
    'latitude': 4.95, // U 04° 57'
    'longitude': 101.5, // T 101° 30'
  },

  // ========== TERENGGANU ==========
  'TRG01': {
    'name': 'Kuala Terengganu, Marang, Kuala Nerus',
    'state': 'Terengganu',
    'reference': 'Kuala Terengganu',
    'latitude': 5.25, // U 05° 15'
    'longitude': 102.9667, // T 102° 58'
  },
  'TRG02': {
    'name': 'Besut, Setiu',
    'state': 'Terengganu',
    'reference': 'Besut',
    'latitude': 5.4167, // U 05° 25'
    'longitude': 102.4167, // T 102° 25'
  },
  'TRG03': {
    'name': 'Hulu Terengganu',
    'state': 'Terengganu',
    'reference': 'Hulu Terengganu',
    'latitude': 5.0, // U 05° 00'
    'longitude': 102.5333, // T 102° 32'
  },
  'TRG04': {
    'name': 'Dungun, Kemaman',
    'state': 'Terengganu',
    'reference': 'Dungun',
    'latitude': 4.5, // U 04° 30'
    'longitude': 102.8667, // T 102° 52'
  },

  // ========== PAHANG ==========
  'PHG01': {
    'name': 'Pulau Tioman',
    'state': 'Pahang',
    'reference': 'Kg. Genting Tioman',
    'latitude': 2.8, // 02° 48''
    'longitude': 104.15, // 104° 09''
  },
  'PHG02': {
    'name': 'Rompin, Pekan, Muadzam Shah, Kuantan',
    'state': 'Pahang',
    'reference': 'Felda Chempaka, Rompin',
    'latitude': 3.0833, // 03° 05''
    'longitude': 102.7833, // 102° 47''
  },
  'PHG03': {
    'name': 'Maran, Chenor, Temerloh, Bera, Jengka, Jerantut',
    'state': 'Pahang',
    'reference': 'Kg. Sempadan Temerloh',
    'latitude': 3.4667, // 03° 28''
    'longitude': 102.1167, // 102° 07''
  },
  'PHG04': {
    'name': 'Bentong, Raub, Lipis',
    'state': 'Pahang',
    'reference': 'Kg. Hulu Sungai Raub',
    'latitude': 3.9833, // 03° 59''
    'longitude': 101.7333, // 101° 44''
  },
  'PHG05': {
    'name': 'Bukit Tinggi, Genting Sempah, Janda Baik',
    'state': 'Pahang',
    'reference': 'Bukit Tinggi',
    'latitude': 3.3833, // 03° 23'
    'longitude': 101.8333, // 101° 50'
    'elevation': 686, // meters
  },
  'PHG06': {
    'name': 'Cameron Highlands, Bukit Fraser, Genting Highlands',
    'state': 'Pahang',
    'reference': 'Brinchang, Cameron Highlands',
    'latitude': 4.05, // 04° 03'
    'longitude': 101.4, // 101° 24'
    'elevation': 1600, // meters
  },

  // ========== SABAH ==========
  'SBH01': {
    'name':
        'Sandakan (Timur): Bandar Sandakan, Bukit Garam, Semawang, Temanggong, Tambisan',
    'state': 'Sabah',
    'reference': 'Bukit Garam',
    'latitude': 5.5, // U 5° 30'
    'longitude': 117.8, // T 117° 48'
  },
  'SBH02': {
    'name': 'Sandakan (Barat): Pinangah, Terusan, Beluran, Kuamut, Telupid',
    'state': 'Sabah',
    'reference': 'Pinangah',
    'latitude': 5.2167, // U 5° 13'
    'longitude': 116.8167, // T 116° 49'
  },
  'SBH03': {
    'name':
        'Tawau (Timur): Lahad Datu, Kunak, Silabukan, Tungku, Sahabat, Semporna',
    'state': 'Sabah',
    'reference': 'Lahad Datu',
    'latitude': 5.0167, // U 5° 01'
    'longitude': 118.3333, // T 118° 20'
  },
  'SBH04': {
    'name': 'Tawau (Barat): Bandar Tawau, Balong, Merotai, Kalabakan',
    'state': 'Sabah',
    'reference': 'Kalabakan',
    'latitude': 4.4167, // U 4° 25'
    'longitude': 117.5, // T 117° 30'
  },
  'SBH05': {
    'name': 'Kudat: Kudat, Kota Marudu, Pitas, Pulau Banggi',
    'state': 'Sabah',
    'reference': 'Kudat',
    'latitude': 6.8833, // U 6° 53'
    'longitude': 116.8333, // T 116° 50'
  },
  'SBH06': {
    'name': 'Gunung Kinabalu',
    'state': 'Sabah',
    'reference': 'Gunung Kinabalu',
    'latitude': 6.0833, // U 6° 05'
    'longitude': 116.5333, // T 116° 32'
    'elevation': 4101, // meters
  },
  'SBH07': {
    'name':
        'Pantai Barat: Kota Kinabalu, Penampang, Tuaran, Papar, Kota Belud, Putatan, Ranau',
    'state': 'Sabah',
    'reference': 'Papar',
    'latitude': 5.7333, // U 5° 44'
    'longitude': 115.9333, // T 115° 56'
  },
  'SBH08': {
    'name': 'Pedalaman (Atas): Pensiangan, Keningau, Tambunan, Nabawan',
    'state': 'Sabah',
    'reference': 'Keningau',
    'latitude': 5.3333, // U 5° 20'
    'longitude': 116.1667, // T 116° 10'
  },
  'SBH09': {
    'name':
        'Pedalaman (Bawah): Sipitang, Membakut, Beaufort, Kuala Penyu, Weston, Tenom, Long Pa Sia',
    'state': 'Sabah',
    'reference': 'Sipitang',
    'latitude': 5.0833, // U 5° 05'
    'longitude': 115.55, // T 115° 33'
  },

  // ========== SARAWAK ==========
  'SWK01': {
    'name': 'Limbang, Sundar, Trusan, Lawas',
    'state': 'Sarawak',
    'reference': 'Limbang',
    'latitude': 4.7833, // 4° 47'
    'longitude': 114.8333, // T 114° 50'
  },
  'SWK02': {
    'name': 'Niah, Sibuti, Miri, Bekenu, Marudi',
    'state': 'Sarawak',
    'reference': 'Niah',
    'latitude': 3.5833, // U 3° 35'
    'longitude': 113.7167, // T 113° 43'
  },
  'SWK03': {
    'name': 'Tatau, Suai, Belaga, Pandan, Sebauh, Bintulu',
    'state': 'Sarawak',
    'reference': 'Tatau',
    'latitude': 2.8833, // U 2° 53'
    'longitude': 112.8667, // T 112° 52'
  },
  'SWK04': {
    'name': 'Igan, Kanowit, Sibu, Dalat, Oya, Balingian, Mukah, Kapit, Song',
    'state': 'Sarawak',
    'reference': 'Igan',
    'latitude': 2.8333, // U 2° 50'
    'longitude': 111.7, // T 111° 42'
  },
  'SWK05': {
    'name': 'Belawai, Matu, Daro, Sarikei, Julau, Bintangor, Rajang',
    'state': 'Sarawak',
    'reference': 'Belawai',
    'latitude': 2.2333, // U 2° 14'
    'longitude': 111.2167, // T 111° 13'
  },
  'SWK06': {
    'name':
        'Kabong, Lingga, Sri Aman, Engkelili, Betong, Spaoh, Pusa, Saratok, Roban, Debak, Lubok Antu',
    'state': 'Sarawak',
    'reference': 'Kabong',
    'latitude': 1.7833, // U 1° 47'
    'longitude': 111.1167, // T 111° 07'
  },
  'SWK07': {
    'name': 'Samarahan, Simunjan, Serian, Sebuyau, Meludam',
    'state': 'Sarawak',
    'reference': 'Kota Samarahan',
    'latitude': 1.4667, // U 1° 28'
    'longitude': 110.4833, // T 110° 29'
  },
  'SWK08': {
    'name': 'Kuching, Bau, Lundu, Sematan',
    'state': 'Sarawak',
    'reference': 'Sematan',
    'latitude': 1.8167, // U 1° 49'
    'longitude': 109.7667, // T 109° 46'
  },
  'SWK09': {
    'name': 'Kampung Patarikan (Zon Khas)',
    'state': 'Sarawak',
    'reference': 'Kampung Patarikan',
    'latitude': 4.9611, // U 4° 57' 40"
    'longitude': 115.4861, // T 115° 29' 10"
  },
};

// Example usage in your Flutter app:
/*
// Get a specific zone
final zoneData = getZoneById('PLS01');
print('Zone: ${zoneData?['name']}');
print('Latitude: ${zoneData?['latitude']}');
print('Longitude: ${zoneData?['longitude']}');

// Get all zones in Selangor
final selangorZones = getZonesByState('Selangor');
for (var zone in selangorZones) {
  print('${zone['name']}: ${zone['latitude']}, ${zone['longitude']}');
}
*/
