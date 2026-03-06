// lib/models/queue_entry.dart

class QueueEntry {
  final String id;
  final String providerId;
  final String queueNumber;
  final String status;
  final String userName;
  final String? userPhone;
  final int estimatedWaitTimeMinutes;
  final DateTime joinedAt;

  QueueEntry({
    required this.id,
    required this.providerId,
    required this.queueNumber,
    required this.status,
    required this.userName,
    this.userPhone,
    required this.estimatedWaitTimeMinutes,
    required this.joinedAt,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      id: json['_id'],
      providerId: json['providerId'],
      queueNumber: json['queueNumber'],
      status: json['status'],
      userName: json['userName'],
      userPhone: json['userPhone'],
      estimatedWaitTimeMinutes: json['estimatedWaitTimeMinutes'] ?? 0,
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'providerId': providerId,
      'queueNumber': queueNumber,
      'status': status,
      'userName': userName,
      'userPhone': userPhone,
      'estimatedWaitTimeMinutes': estimatedWaitTimeMinutes,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}