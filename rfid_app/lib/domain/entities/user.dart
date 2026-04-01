import '../../core/constants/app_roles.dart';

class User {
  final String uid;
  final String employeeId;
  final String prenom;
  final String nom;
  final String email;
  final String department;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;
  final String? phoneNumber;
  final DateTime? lastLogin;

  String get name => '$prenom $nom';
  String get id => uid;

  User({
    required this.uid,
    required this.employeeId,
    required this.prenom,
    required this.nom,
    required this.email,
    required this.department,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.phoneNumber,
    this.lastLogin,
  });

  factory User.fromApi(Map<String, dynamic> json) {
    // Convertir uid en String (gère les cas où uid est un int)
    final uidValue = json['uid'];
    final String uidString = uidValue.toString();

    return User(
      uid: uidString,
      employeeId: uidString,
      prenom: json['prenom'] ?? '',
      nom: json['nom'] ?? '',
      email: json['email'] ?? '',
      department: json['department'] ?? 'Non spécifié',
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.employee,
      createdAt: DateTime.now(),
      isActive: json['autorise'] ?? true,
    );
  }

  factory User.fromAuth(Map<String, dynamic> json) {
    return User(
      uid: json['uid']?.toString() ?? '',
      employeeId: json['uid']?.toString() ?? '',
      prenom: json['nomComplet']?.split(' ')[0] ?? '',
      nom: json['nomComplet']?.split(' ').sublist(1).join(' ') ?? '',
      email: json['email'] ?? '',
      department: 'Non spécifié',
      role: json['role'] == 'admin' ? UserRole.admin : UserRole.employee,
      createdAt: DateTime.now(),
      isActive: true,
    );
  }

  Map<String, dynamic> toApi() {
    return {
      'uid': uid,
      'prenom': prenom,
      'nom': nom,
      'email': email,
      'role': role.code,
    };
  }

  static UserRole _stringToRole(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.employee;
    }
  }

  User copyWith({
    String? uid,
    String? employeeId,
    String? prenom,
    String? nom,
    String? email,
    String? department,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    bool? isActive,
    String? phoneNumber,
    DateTime? lastLogin,
  }) {
    return User(
      uid: uid ?? this.uid,
      employeeId: employeeId ?? this.employeeId,
      prenom: prenom ?? this.prenom,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      department: department ?? this.department,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  bool get isAdmin => role == UserRole.admin;
}