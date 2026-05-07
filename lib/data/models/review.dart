import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  const Review({
    required this.id,
    required this.bakeryId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String bakeryId;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Review(
      id: doc.id,
      bakeryId: data['bakeryId'] ?? '',
      userName: data['userName'] ?? 'Guest',
      rating: (data['rating'] ?? 5).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
