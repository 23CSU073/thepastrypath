import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/models/bakery.dart';
import '../data/models/reservation.dart';
import '../data/repositories/reservation_repository.dart';

class ReservationProvider extends ChangeNotifier {
  ReservationProvider({ReservationRepository? repository})
    : _repository = repository ?? ReservationRepository();

  final ReservationRepository _repository;
  bool isSaving = false;
  String? errorMessage;

  Future<bool> reserve({
    required String userId,
    required Bakery bakery,
    required DateTime date,
    required String timeSlot,
    required int guests,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.createReservation(
        Reservation(
          id: '',
          userId: userId,
          bakeryId: bakery.id,
          bakeryName: bakery.name,
          date: date,
          timeSlot: timeSlot,
          guests: guests,
        ),
      );
      errorMessage = null;
      return true;
    } on TimeoutException {
      errorMessage = 'The reservation server took too long. Please try again.';
      return false;
    } on FirebaseException catch (error) {
      errorMessage = switch (error.code) {
        'permission-denied' =>
          'Reservations are blocked by Firestore rules. Please sign in or update database permissions.',
        'unavailable' =>
          'Reservation service is unavailable right now. Check your internet connection and try again.',
        _ =>
          'Could not confirm your reservation: ${error.message ?? error.code}.',
      };
      return false;
    } catch (_) {
      errorMessage = 'Could not confirm your reservation. Please try again.';
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
