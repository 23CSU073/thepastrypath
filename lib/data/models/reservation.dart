class Reservation {
  const Reservation({
    required this.id,
    required this.userId,
    required this.bakeryId,
    required this.bakeryName,
    required this.date,
    required this.timeSlot,
    required this.guests,
  });

  final String id;
  final String userId;
  final String bakeryId;
  final String bakeryName;
  final DateTime date;
  final String timeSlot;
  final int guests;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'bakeryId': bakeryId,
        'bakeryName': bakeryName,
        'date': date.toIso8601String(),
        'timeSlot': timeSlot,
        'guests': guests,
        'status': 'confirmed',
      };
}
