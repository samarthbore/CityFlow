// lib/models/provider.dart

class Provider {
  final String id;
  final String name;
  final String category;
  final String address;
  final String city;
  final String staffEmail;
  final bool isActive;
  final double avgRating;
  final int totalReviews;
  final int efficiencyScore;
  final double recommendationScore;
  final bool isOpen;
  final int avgServiceTime;
  final String? phone;
  final String? description;
  final List<String> services;

  final double? latitude;
  final double? longitude;
  final int waitingCount;

  Provider({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.city,
    required this.staffEmail,
    required this.isActive,
    required this.avgRating,
    required this.totalReviews,
    required this.efficiencyScore,
    required this.recommendationScore,
    this.isOpen = true,
    this.avgServiceTime = 10,
    this.phone,
    this.description,
    this.services = const [],
    this.latitude,
    this.longitude,
    this.waitingCount = 0,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lng;

    if (json['location'] != null && json['location']['coordinates'] != null) {
      final coordinates = json['location']['coordinates'];
      if (coordinates is List && coordinates.length >= 2) {
        lng = (coordinates[0] as num).toDouble();
        lat = (coordinates[1] as num).toDouble();
      }
    }

    return Provider(
      id: json['_id'],
      name: json['name'],
      category: json['category'],
      address: json['address'],
      city: json['city'],
      staffEmail: json['staffEmail'],
      isActive: json['isActive'] ?? true,
      avgRating: (json['avgRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
      efficiencyScore: json['efficiencyScore'] ?? 0,
      recommendationScore: (json['recommendationScore'] ?? 0).toDouble(),
      isOpen: json['isOpen'] ?? true,
      avgServiceTime: json['avgServiceTime'] ?? 10,
      phone: json['phone'],
      description: json['description'],
      services: json['services'] != null ? List<String>.from(json['services']) : [],
      latitude: lat,
      longitude: lng,
      waitingCount: json['waitingCount'] ?? 0,
    );
  }
}