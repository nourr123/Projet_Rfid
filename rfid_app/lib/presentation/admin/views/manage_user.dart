import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../domain/entities/user.dart';
import '../../../data/services/api_service.dart';
import '../widgets/user_tile.dart';
import 'add_edit_user.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({Key? key}) : super(key: key);

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final ApiService _apiService = ApiService();
  List<User> _users = [];
  List<User> _filteredUsers = [];
  String _searchQuery = '';
  String _selectedFilter = 'Tous';
  bool _isLoading = true;
  String? _errorMessage;

  final List<String> _filters = ['Tous', 'Administrateurs', 'Employés', 'Actifs', 'Inactifs'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _apiService.getUtilisateurs();
      setState(() {
        _users = users;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement des utilisateurs';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredUsers = _users.where((user) {
        final matchesSearch = _searchQuery.isEmpty ||
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.uid.toLowerCase().contains(_searchQuery.toLowerCase());

        bool matchesCategory = true;
        switch (_selectedFilter) {
          case 'Administrateurs':
            matchesCategory = user.role == UserRole.admin;
            break;
          case 'Employés':
            matchesCategory = user.role == UserRole.employee;
            break;
          case 'Actifs':
            matchesCategory = user.isActive;
            break;
          case 'Inactifs':
            matchesCategory = !user.isActive;
            break;
          default:
            matchesCategory = true;
        }

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  Future<void> _addUser() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditUserScreen(),
      ),
    );

    if (result == true) {
      _loadUsers();
      _showSuccessMessage('Utilisateur ajouté avec succès');
    }
  }

  Future<void> _editUser(User user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditUserScreen(user: user),
      ),
    );

    if (result == true) {
      _loadUsers();
      _showSuccessMessage('Utilisateur modifié avec succès');
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          user.isActive ? 'Désactiver' : 'Activer',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoal,
          ),
        ),
        content: Text(
          user.isActive
              ? 'Voulez-vous vraiment désactiver ${user.name} ?'
              : 'Voulez-vous vraiment réactiver ${user.name} ?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gray,
            ),
            child: const Text('Annuler'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: user.isActive
                    ? [Colors.orange, Colors.deepOrange]
                    : [Colors.green, AppColors.teal],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(user.isActive ? 'Désactiver' : 'Activer'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final success = await _apiService.updateUtilisateur(
        user.uid,
        autorise: !user.isActive,
      );

      if (success) {
        _loadUsers();
        _showSuccessMessage(
          user.isActive ? 'Utilisateur désactivé' : 'Utilisateur activé',
          color: user.isActive ? Colors.orange : Colors.green,
        );
      } else {
        setState(() => _isLoading = false);
        _showErrorMessage('Erreur lors de la modification');
      }
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Supprimer',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoal,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voulez-vous vraiment supprimer définitivement ${user.name} ?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette action est irréversible',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.gray,
            ),
            child: const Text('Annuler'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.redAccent],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Supprimer'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      final success = await _apiService.deleteUtilisateur(user.uid);

      if (success) {
        _loadUsers();
        _showSuccessMessage('Utilisateur supprimé', color: Colors.red);
      } else {
        setState(() => _isLoading = false);
        _showErrorMessage('Erreur lors de la suppression');
      }
    }
  }

  void _showSuccessMessage(String message, {Color color = AppColors.success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 13))),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilter();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un utilisateur...',
                  hintStyle: TextStyle(fontSize: 14, color: AppColors.gray.withOpacity(0.7)),
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppColors.gray,
                          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                          _applyFilter();
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: _getFilterColor(filter),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      elevation: 0,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: AppColors.primaryBlue, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_users.length} total',
                        style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${_users.where((u) => u.isActive).length} actifs',
                        style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
                : _errorMessage != null
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: AppColors.error),
                  const SizedBox(height: 10),
                  Text(_errorMessage!),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: _loadUsers, child: const Text('Réessayer')),
                ],
              ),
            )
                : _filteredUsers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.people_outline, size: 40, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun utilisateur trouvé',
                    style: TextStyle(color: AppColors.gray, fontSize: 15, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Essayez une autre recherche'
                        : 'Ajoutez votre premier utilisateur',
                    style: TextStyle(color: AppColors.gray.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: UserTile(
                    user: user,
                    onEdit: () => _editUser(user),
                    onToggle: () => _toggleUserStatus(user),
                    onDelete: () => _deleteUser(user),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Administrateurs':
        return Colors.orange;
      case 'Employés':
        return AppColors.teal;
      case 'Actifs':
        return Colors.green;
      case 'Inactifs':
        return Colors.red;
      default:
        return AppColors.primaryBlue;
    }
  }
}