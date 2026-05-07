import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reservation.dart';

class ReservationRepository {
  ReservationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createReservation(Reservation reservation) async {
    await _firestore
        .collection('reservations')
        .add({
          ...reservation.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        })
        .timeout(const Duration(seconds: 15));
  }
}
