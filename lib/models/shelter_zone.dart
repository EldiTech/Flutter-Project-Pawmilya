class ShelterZone {
  ShelterZone({
    required this.id,
    required this.name,
    required this.humidity,
    required this.humidityStatus,
    required this.temp,
    required this.tempStatus,
  });

  final String id;
  final int humidity;
  final String humidityStatus;
  final String name;
  final int temp;
  final String tempStatus;

  factory ShelterZone.fromMap(String id, Map<String, dynamic> map) {
    return ShelterZone(
      id: id,
      name: (map['name'] ?? '').toString(),
      humidity: (map['humidity'] as num?)?.round() ?? 0,
      humidityStatus: (map['humidityStatus'] ?? 'Normal').toString(),
      temp: (map['temp'] as num?)?.round() ?? 0,
      tempStatus: (map['tempStatus'] ?? 'Normal').toString(),
    );
  }
}
