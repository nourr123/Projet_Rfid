enum UserRole {
  admin,
  employee
}

extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.employee:
        return 'Employé';
    }
  }

  String get code {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.employee:
        return 'employee';
    }
  }
}

class AppRoles {
  static const String adminEmail = 'admin@workspace.com';  // Vérifiez qu'il n'y a pas d'espace
  static const String adminPassword = 'Admin123!';         // Vérifiez que c'est exactement ça
  static const String adminId = 'admin_001';

  static bool isAdminEmail(String email) {
    return email.toLowerCase() == adminEmail.toLowerCase();
  }
}