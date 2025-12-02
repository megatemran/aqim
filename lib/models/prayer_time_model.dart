class PrayerTime {
  /// Name of the prayer (e.g., 'Subuh', 'Zohor', 'Asar')
  final String name;

  /// Prayer time in HH:mm format
  final String time;

  /// Whether the prayer time has already passed
  final bool isPassed;

  /// Whether this is the next upcoming prayer
  final bool isNext;

  PrayerTime({
    required this.name,
    required this.time,
    required this.isPassed,
    required this.isNext,
  });

  /// Convert from JSON map
  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      name: json['name'] ?? 'Unknown',
      time: json['time'] ?? '--:--',
      isPassed: json['isPassed'] ?? false,
      isNext: json['isNext'] ?? false,
    );
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() => {
    'name': name,
    'time': time,
    'isPassed': isPassed,
    'isNext': isNext,
  };

  @override
  String toString() => '$name: $time (passed: $isPassed, next: $isNext)';

  /// Create a copy with optional field updates
  PrayerTime copyWith({
    String? name,
    String? time,
    bool? isPassed,
    bool? isNext,
  }) {
    return PrayerTime(
      name: name ?? this.name,
      time: time ?? this.time,
      isPassed: isPassed ?? this.isPassed,
      isNext: isNext ?? this.isNext,
    );
  }

  /// Check equality
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerTime &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          time == other.time &&
          isPassed == other.isPassed &&
          isNext == other.isNext;

  @override
  int get hashCode =>
      name.hashCode ^ time.hashCode ^ isPassed.hashCode ^ isNext.hashCode;
}

class PrayerTimeData {
  /// Hijri date (e.g., '02-05-1447')
  final String hijri;

  /// Gregorian date (e.g., '24-10-2025')
  final String date;

  /// List of all prayer times for the day
  final List<PrayerTime> prayers;

  /// Prayer time zone/region code (e.g., 'PNG01')
  final String zone;

  /// Human-readable location name (e.g., 'Penang, Malaysia')
  final String location;

  /// Prayer data source (e.g., 'aladhan', 'jakim')
  final String sumber;

  /// Source website URL
  final String sumberWebsite;

  /// User's current location data with coordinates
  final Map<String, dynamic> userLocationData;

  PrayerTimeData({
    required this.hijri,
    required this.date,
    required this.prayers,
    required this.zone,
    required this.location,
    this.sumber = 'AlAdhan',
    this.sumberWebsite = 'https://www.aladhan.com',
    this.userLocationData = const {},
  });

  Map<String, dynamic> toJson() => {
    'hijri': hijri,
    'date': date,
    'zone': zone,
    'location': location,
    'sumber': sumber,
    'sumberWebsite': sumberWebsite,
    'userLocationData': userLocationData,
    'prayers': prayers.map((p) => p.toJson()).toList(),
  };

  /// Create from JSON map
  factory PrayerTimeData.fromJson(Map<String, dynamic> json) {
    final prayersList = (json['prayers'] as List<dynamic>? ?? [])
        .map((p) => PrayerTime.fromJson(p as Map<String, dynamic>))
        .toList();

    return PrayerTimeData(
      hijri: json['hijri'] ?? '',
      date: json['date'] ?? '',
      zone: json['zone'] ?? '',
      location: json['location'] ?? '',
      sumber: json['sumber'] ?? 'AlAdhan',
      sumberWebsite: json['sumberWebsite'] ?? 'https://www.aladhan.com',
      userLocationData: Map<String, dynamic>.from(
        json['userLocationData'] ?? {},
      ),
      prayers: prayersList,
    );
  }

  /// Detailed string representation
  @override
  String toString() {
    final prayerList = prayers.map((p) => '${p.name}: ${p.time}').join(', ');
    return '''
PrayerTimeData(
  hijri: $hijri,
  date: $date,
  zone: $zone,
  location: $location,
  sumber: $sumber,
  sumberWebsite: $sumberWebsite,
  userLocationData: $userLocationData,
  prayers: [$prayerList]
)
''';
  }

  /// Create a copy with optional field updates
  PrayerTimeData copyWith({
    String? hijri,
    String? date,
    List<PrayerTime>? prayers,
    String? zone,
    String? location,
    String? sumber,
    String? sumberWebsite,
    Map<String, dynamic>? userLocationData,
  }) {
    return PrayerTimeData(
      hijri: hijri ?? this.hijri,
      date: date ?? this.date,
      prayers: prayers ?? this.prayers,
      zone: zone ?? this.zone,
      location: location ?? this.location,
      sumber: sumber ?? this.sumber,
      sumberWebsite: sumberWebsite ?? this.sumberWebsite,
      userLocationData: userLocationData ?? this.userLocationData,
    );
  }

  /// Check equality
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrayerTimeData &&
          runtimeType == other.runtimeType &&
          hijri == other.hijri &&
          date == other.date &&
          zone == other.zone &&
          location == other.location;

  @override
  int get hashCode => hijri.hashCode ^ date.hashCode ^ zone.hashCode;
}
