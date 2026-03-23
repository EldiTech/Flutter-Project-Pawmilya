import 'package:cloud_firestore/cloud_firestore.dart';

class ShelterProfile {
  ShelterProfile({
    required this.shelterName,
    required this.ownerName,
    required this.email,
    required this.contact,
    required this.address,
    this.createdAt,
  });

  final String shelterName;
  final String ownerName;
  final String email;
  final String contact;
  final String address;
  final DateTime? createdAt;

  static String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  factory ShelterProfile.fromMap(
    Map<String, dynamic> map, {
    required String fallbackEmail,
  }) {
    final resolvedEmail = _firstString(map, const [
      'email',
      'ownerEmail',
      'userEmail',
      'mail',
    ]);

    final createdAt = _parseDate(map['createdAt']) ??
        _parseDate(map['created_at']) ??
        _parseDate(map['registeredAt']);

    return ShelterProfile(
      shelterName: _firstString(map, const [
        'shelterName',
        'shelter_name',
        'name',
      ]),
      ownerName: _firstString(map, const [
        'ownerName',
        'owner_name',
        'displayName',
        'display_name',
        'fullName',
        'full_name',
      ]),
      email: resolvedEmail.isNotEmpty ? resolvedEmail : fallbackEmail,
      contact: _firstString(map, const [
        'contact',
        'contactNumber',
        'phone',
        'mobile',
      ]),
      address: _firstString(map, const [
        'address',
        'location',
      ]),
      createdAt: createdAt,
    );
  }

  factory ShelterProfile.empty({required String fallbackEmail}) {
    return ShelterProfile(
      shelterName: '',
      ownerName: '',
      email: fallbackEmail,
      contact: '',
      address: '',
      createdAt: null,
    );
  }
}