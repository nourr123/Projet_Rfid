import 'package:flutter/material.dart';

enum DeskStatus {
  available,     // Disponible - Vert
  occupied,      // Occupé - Rouge/Orange
  blocked,       // Bloqué (directeurs) - Gris
  booked         // Réservé - Bleu (correspond à "reserved" dans l'API)
}

class Desk {
  final String id;
  final String floor;
  final String deskNumber;
  final DeskStatus status;
  final String? occupiedBy;
  final String? occupiedByName;
  final String? department;
  final DateTime? occupiedSince;
  final String? bookedBy;
  final String? bookedByName;  // ← AJOUTÉ : nom de la personne qui a réservé
  final DateTime? bookedAt;
  final int row;
  final int column;
  final bool hasPowerOutlet;
  final bool hasMonitor;

  Desk({
    required this.id,
    required this.floor,
    required this.deskNumber,
    required this.status,
    this.occupiedBy,
    this.occupiedByName,
    this.department,
    this.occupiedSince,
    this.bookedBy,
    this.bookedByName,          // ← AJOUTÉ
    this.bookedAt,
    required this.row,
    required this.column,
    this.hasPowerOutlet = true,
    this.hasMonitor = false,
  });

  // Factory pour créer depuis l'API
  factory Desk.fromApi(Map<String, dynamic> json, {required String floor}) {
    String id = json['numero']?.toString() ?? '';
    String statut = json['statut'] ?? 'available';

    // Gérer la date de réservation
    DateTime? bookedAt;
    if (json['dateReservation'] != null && json['dateReservation'] != "null") {
      try {
        bookedAt = DateTime.parse(json['dateReservation']);
      } catch (e) {
        print('⚠️ Erreur parsing date: ${json['dateReservation']}');
        bookedAt = null;
      }
    }

    return Desk(
      id: id,
      floor: floor,
      deskNumber: id,
      status: _stringToStatus(statut),
      occupiedBy: json['reservePar'],
      occupiedByName: json['prenom'],
      bookedBy: json['reservePar'],
      bookedByName: json['prenom'],          // ← AJOUTÉ : nom du réservant
      bookedAt: bookedAt,
      row: 0,
      column: 0,
      hasPowerOutlet: true,
      hasMonitor: false,
    );
  }

  // Méthode copyWith
  Desk copyWith({
    String? id,
    String? floor,
    String? deskNumber,
    DeskStatus? status,
    String? occupiedBy,
    String? occupiedByName,
    String? department,
    DateTime? occupiedSince,
    String? bookedBy,
    String? bookedByName,                     // ← AJOUTÉ
    DateTime? bookedAt,
    int? row,
    int? column,
    bool? hasPowerOutlet,
    bool? hasMonitor,
  }) {
    return Desk(
      id: id ?? this.id,
      floor: floor ?? this.floor,
      deskNumber: deskNumber ?? this.deskNumber,
      status: status ?? this.status,
      occupiedBy: occupiedBy ?? this.occupiedBy,
      occupiedByName: occupiedByName ?? this.occupiedByName,
      department: department ?? this.department,
      occupiedSince: occupiedSince ?? this.occupiedSince,
      bookedBy: bookedBy ?? this.bookedBy,
      bookedByName: bookedByName ?? this.bookedByName,  // ← AJOUTÉ
      bookedAt: bookedAt ?? this.bookedAt,
      row: row ?? this.row,
      column: column ?? this.column,
      hasPowerOutlet: hasPowerOutlet ?? this.hasPowerOutlet,
      hasMonitor: hasMonitor ?? this.hasMonitor,
    );
  }

  static DeskStatus _stringToStatus(String value) {
    switch (value) {
      case 'occupied':
        return DeskStatus.occupied;
      case 'blocked':
        return DeskStatus.blocked;
      case 'reserved':
        return DeskStatus.booked;
      default:
        return DeskStatus.available;
    }
  }

  static String statusToString(DeskStatus status) {
    switch (status) {
      case DeskStatus.occupied:
        return 'Occupé';
      case DeskStatus.blocked:
        return 'Bloqué';
      case DeskStatus.booked:
        return 'Réservé';
      case DeskStatus.available:
        return 'Disponible';
    }
  }

  String get statusForApi {
    switch (status) {
      case DeskStatus.occupied:
        return 'occupied';
      case DeskStatus.blocked:
        return 'blocked';
      case DeskStatus.booked:
        return 'reserved';
      case DeskStatus.available:
        return 'available';
    }
  }

  Color get statusColor {
    switch (status) {
      case DeskStatus.available:
        return const Color(0xFF4CAF50); // Vert
      case DeskStatus.occupied:
        return const Color(0xFFFF6B6B); // Rouge/Orange
      case DeskStatus.blocked:
        return const Color(0xFF718096); // Gris
      case DeskStatus.booked:
        return const Color(0xFF4299E1); // Bleu
    }
  }

  Color get statusLightColor {
    switch (status) {
      case DeskStatus.available:
        return const Color(0xFFC8E6C9);
      case DeskStatus.occupied:
        return const Color(0xFFFFCDD2);
      case DeskStatus.blocked:
        return const Color(0xFFE2E8F0);
      case DeskStatus.booked:
        return const Color(0xFFBBDEFB);
    }
  }

  IconData get statusIcon {
    switch (status) {
      case DeskStatus.available:
        return Icons.check_circle_outline;
      case DeskStatus.occupied:
        return Icons.person_outline;
      case DeskStatus.blocked:
        return Icons.block_outlined;
      case DeskStatus.booked:
        return Icons.event_available_outlined;
    }
  }

  // AMÉLIORATION : Affiche le nom du réservant si disponible
  String get statusText {
    switch (status) {
      case DeskStatus.available:
        return 'Disponible';
      case DeskStatus.occupied:
        return 'Occupé par ${occupiedByName ?? "quelqu\'un"}';
      case DeskStatus.blocked:
        return 'Bloqué (Direction)';
      case DeskStatus.booked:
        if (bookedByName != null) {
          return 'Réservé par $bookedByName';
        }
        return 'Réservé';
    }
  }

  // Getter pour savoir si c'est le réservant
  bool isBookedBy(String? uid) {
    if (uid == null || bookedBy == null) return false;
    return bookedBy == uid;
  }

  // Getter pour le nom à afficher sur la carte
  String? get displayName {
    if (status == DeskStatus.booked && bookedByName != null) {
      return bookedByName!.split(' ').first; // Premier prénom
    }
    if (status == DeskStatus.occupied && occupiedByName != null) {
      return occupiedByName!.split(' ').last; // Dernier nom
    }
    return null;
  }
}