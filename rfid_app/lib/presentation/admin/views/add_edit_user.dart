import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../domain/entities/user.dart';
import '../../../data/services/api_service.dart';

class AddEditUserScreen extends StatefulWidget {
  final User? user;

  const AddEditUserScreen({Key? key, this.user}) : super(key: key);

  @override
  State<AddEditUserScreen> createState() => _AddEditUserScreenState();
}

class _AddEditUserScreenState extends State<AddEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uidController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.employee;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      // Mode édition
      _uidController.text = widget.user!.uid;
      _prenomController.text = widget.user!.prenom;
      _nomController.text = widget.user!.nom;
      _emailController.text = widget.user!.email;
      _selectedRole = widget.user!.role;
    }
  }

  @override
  void dispose() {
    _uidController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final apiService = ApiService();
      bool success;

      if (widget.user == null) {
        // MODE AJOUT
        success = await apiService.createUtilisateur(
          uid: _uidController.text,
          email: _emailController.text,
          password: _passwordController.text,
          prenom: _prenomController.text,
          nom: _nomController.text,
          role: _selectedRole == UserRole.admin ? 'admin' : 'employee',
        );
      } else {
        // MODE MODIFICATION
        success = await apiService.updateUtilisateur(
          widget.user!.uid,
          email: _emailController.text,
          password: _passwordController.text.isNotEmpty ? _passwordController.text : null,
          prenom: _prenomController.text,
          nom: _nomController.text,
          role: _selectedRole == UserRole.admin ? 'admin' : 'employee',
        );
      }

      setState(() => _isLoading = false);

      if (success) {
        _showSuccessMessage(widget.user == null
            ? 'Utilisateur ajouté avec succès'
            : 'Utilisateur modifié avec succès');

        if (widget.user == null) {
          _clearFields();
        } else {
          Navigator.pop(context, true);
        }
      } else {
        _showErrorMessage('Erreur lors de l\'enregistrement');
      }
    }
  }

  void _clearFields() {
    _uidController.clear();
    _prenomController.clear();
    _nomController.clear();
    _emailController.clear();
    _passwordController.clear();
    setState(() => _selectedRole = UserRole.employee);
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColors.primaryBlue.withOpacity(0.03),
              AppColors.teal.withOpacity(0.03),
              AppColors.offWhite,
            ],
            stops: const [0, 0.3, 1],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryBlue,
            ),
          )
              : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Espace supplémentaire en haut
                  const SizedBox(height: 20),

                  // Header avec flèche et titre alignés
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        // Flèche retour
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.charcoal,
                          ),
                          onPressed: () {
                            if (isEditing) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(
                                context,
                                '/admin-dashboard',
                              );
                            }
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  isEditing
                                      ? 'Modifier Utilisateur'
                                      : 'Nouvel Utilisateur',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isEditing
                                      ? 'Modifier les informations'
                                      : 'Ajouter un nouvel employé',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.gray.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Formulaire
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.cardShadow,
                      border: Border.all(
                        color: AppColors.lightGray,
                        width: 1,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Identifiant
                          _buildTextField(
                            controller: _uidController,
                            label: 'Identifiant',
                            hint: 'EMP001',
                            icon: Icons.badge_outlined,
                            enabled: !isEditing,
                            readOnly: isEditing,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Identifiant requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Prénom
                          _buildTextField(
                            controller: _prenomController,
                            label: 'Prénom',
                            hint: 'Prénom utilisateur',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Prénom requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Nom
                          _buildTextField(
                            controller: _nomController,
                            label: 'Nom',
                            hint: 'Nom utilisateur',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Nom requis';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'nom@entreprise.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email requis';
                              }
                              if (!value.contains('@')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Mot de passe
                          _buildTextField(
                            controller: _passwordController,
                            label: isEditing
                                ? 'Nouveau mot de passe (optionnel)'
                                : 'Mot de passe',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            validator: !isEditing
                                ? (value) {
                              if (value == null || value.isEmpty) {
                                return 'Mot de passe requis';
                              }
                              if (value.length < 6) {
                                return 'Minimum 6 caractères';
                              }
                              return null;
                            }
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Rôle
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: AppColors.offWhite,
                            ),
                            child: DropdownButtonFormField<UserRole>(
                              value: _selectedRole,
                              decoration: InputDecoration(
                                labelText: 'Rôle',
                                labelStyle: const TextStyle(
                                  fontSize: 14,
                                ),
                                prefixIcon: const Icon(
                                  Icons.admin_panel_settings_outlined,
                                  size: 22,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: AppColors.lightGray,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: AppColors.primaryBlue,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppColors.offWhite,
                                contentPadding:
                                const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: UserRole.employee,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: AppColors.teal
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.person_outline,
                                          size: 14,
                                          color: AppColors.teal,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Employé',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: UserRole.admin,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryBlue
                                              .withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.admin_panel_settings,
                                          size: 14,
                                          color: AppColors.primaryBlue,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      const Text(
                                        'Administrateur',
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedRole = value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bouton d'action
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  AppColors.primaryBlue,
                                  AppColors.teal,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppColors.buttonShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: _saveUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                isEditing
                                    ? 'Modifier l\'utilisateur'
                                    : 'Créer l\'utilisateur',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer avec le nom de l'app
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryBlue, AppColors.teal],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Workspace Pro',
                        style: TextStyle(
                          color: AppColors.gray,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.teal, AppColors.primaryBlue],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Version 2.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool enabled = true,
    bool readOnly = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.charcoal,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            enabled: enabled,
            readOnly: readOnly,
            validator: validator,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.gray.withOpacity(0.6),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: AppColors.gray, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.lightGray,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.error,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: readOnly
                  ? AppColors.lightGray.withOpacity(0.3)
                  : AppColors.offWhite,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}