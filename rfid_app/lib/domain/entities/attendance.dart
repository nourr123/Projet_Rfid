import 'package:intl/intl.dart';

class Attendance {
  final String uid;
  final String date;
  final String? nom;
  final double? totalTravail;
  final List<Session> sessions;

  Attendance({
    required this.uid,
    required this.date,
    this.nom,
    this.totalTravail,
    required this.sessions,
  });

  factory Attendance.fromApi(Map<String, dynamic> json) {
    List<Session> sessions = [];
    if (json['sessions'] != null) {
      sessions = (json['sessions'] as List)
          .map((s) => Session.fromApi(s))
          .toList();
    }

    return Attendance(
      uid: json['uid'] ?? '',
      date: json['date'] ?? '',
      nom: json['nom'],
      totalTravail: json['total_travail'] != null
          ? double.tryParse(json['total_travail'].toString())
          : null,
      sessions: sessions,
    );
  }

  bool get isPresentToday {
    if (sessions.isEmpty) return false;
    final today = DateFormat('dd-MM-yyyy').format(DateTime.now());
    return date == today;
  }

  bool get isCurrentlyWorking {
    if (sessions.isEmpty) return false;
    final lastSession = sessions.last;
    return lastSession.entree != null && lastSession.sortie == null;
  }
}

class Session {
  final String session;
  final String? entree;
  final String? sortie;

  Session({
    required this.session,
    this.entree,
    this.sortie,
  });

  factory Session.fromApi(Map<String, dynamic> json) {
    return Session(
      session: json['session'] ?? '',
      entree: json['entree'],
      sortie: json['sortie'],
    );
  }

  bool get isActive => entree != null && sortie == null;
}