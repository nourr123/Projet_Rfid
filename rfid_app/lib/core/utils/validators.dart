class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '📧 L\'email est requis';
    }

    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegExp.hasMatch(value)) {
      return '❌ Format d\'email invalide';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '🔒 Le mot de passe est requis';
    }

    if (value.length < 6) {
      return '❌ Minimum 6 caractères requis';
    }

    // Vérifier la force du mot de passe (optionnel)
    bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
    bool hasDigits = value.contains(RegExp(r'[0-9]'));
    bool hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (value.length >= 8 && hasUppercase && hasDigits) {
      // Mot de passe fort
      return null;
    }

    return null; // On accepte quand même mais on peut afficher un indicateur
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '👤 Le nom est requis';
    }

    if (value.length < 2) {
      return '❌ Nom trop court';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }

    final phoneRegExp = RegExp(r'^[0-9]{8,15}$');
    if (!phoneRegExp.hasMatch(value.replaceAll(RegExp(r'[\s-]'), ''))) {
      return '❌ Numéro de téléphone invalide';
    }

    return null;
  }
}