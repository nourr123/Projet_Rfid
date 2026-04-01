import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/desk.dart';
import '../../../data/services/api_service.dart';
import '../../../domain/entities/user.dart';

class DeskCard extends StatefulWidget {
  final Desk desk;
  final bool isIndividual;
  final Function(Desk) onBook;
  final Function(Desk) onRelease;

  const DeskCard({
    Key? key,
    required this.desk,
    required this.isIndividual,
    required this.onBook,
    required this.onRelease,
  }) : super(key: key);

  @override
  State<DeskCard> createState() => _DeskCardState();
}

class _DeskCardState extends State<DeskCard> {
  late Desk _desk;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _desk = widget.desk;
  }

  // ===========================================
  // MÉTHODES DE RÉSERVATION ET LIBÉRATION
  // ===========================================
  Future<void> _bookDesk(DateTime date, String reason) async {
    final currentUser = _apiService.currentUser;
    if (currentUser == null) return;

    final success = await _apiService.reserverPoste(
        _desk.floor,
        _desk.deskNumber,
        currentUser.uid,
        currentUser.prenom
    );

    if (success) {
      setState(() {
        _desk = _desk.copyWith(
          status: DeskStatus.booked,
          bookedBy: currentUser.uid,
          bookedByName: currentUser.prenom,
          bookedAt: date,
        );
      });
      widget.onBook(_desk);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Poste ${_desk.deskNumber} réservé avec succès'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la réservation'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _releaseDesk() async {
    final currentUser = _apiService.currentUser;
    if (currentUser == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Libérer le poste'),
        content: Text('Voulez-vous vraiment libérer le poste ${_desk.deskNumber} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Libérer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _apiService.libererPoste(
      _desk.floor,
      _desk.deskNumber,
      currentUser.uid,
    );

    if (success) {
      setState(() {
        _desk = _desk.copyWith(
          status: DeskStatus.available,
          bookedBy: null,
          bookedByName: null,
          bookedAt: null,
        );
      });
      widget.onRelease(_desk);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Poste ${_desk.deskNumber} libéré avec succès'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la libération'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  // ===========================================
  // BUILD DE LA CARTE
  // ===========================================
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        width: widget.isIndividual ? 70 : 50,
        height: widget.isIndividual ? 70 : 50,
        margin: EdgeInsets.symmetric(horizontal: widget.isIndividual ? 8 : 4),
        decoration: BoxDecoration(
          color: _desk.statusColor.withOpacity(0.1),
          border: Border.all(color: _desk.statusColor, width: widget.isIndividual ? 2 : 1.5),
          borderRadius: BorderRadius.circular(widget.isIndividual ? 12 : 8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_desk.statusIcon, color: _desk.statusColor, size: widget.isIndividual ? 20 : 16),
            const SizedBox(height: 4),
            Text(_desk.deskNumber, style: TextStyle(fontWeight: FontWeight.bold, fontSize: widget.isIndividual ? 11 : 10)),

            // Afficher le prénom si le poste est réservé
            if (_desk.status == DeskStatus.booked && _desk.bookedByName != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  _desk.bookedByName!.split(' ').first,
                  style: TextStyle(
                    fontSize: widget.isIndividual ? 8 : 7,
                    color: AppColors.gray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Afficher le nom si le poste est occupé
            if (_desk.status == DeskStatus.occupied && _desk.occupiedByName != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  _desk.occupiedByName!.split(' ').last,
                  style: TextStyle(
                    fontSize: widget.isIndividual ? 8 : 7,
                    color: AppColors.gray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================
  // AFFICHAGE DES DÉTAILS (MODAL BOTTOM SHEET)
  // ===========================================
  void _showDetails(BuildContext context) {
    final currentUser = _apiService.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 30),
            _buildStatusDetails(),
            const SizedBox(height: 20),
            _buildActionButtons(currentUser),
          ],
        ),
      ),
    );
  }

  // ===========================================
  // SOUS-COMPOSANTS
  // ===========================================
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _desk.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_desk.statusIcon, color: _desk.statusColor, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Poste ${_desk.deskNumber}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(_desk.floor, style: TextStyle(color: AppColors.gray)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _desk.statusColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _desk.statusText.split(' ')[0],
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDetails() {
    if (_desk.status == DeskStatus.occupied && _desk.occupiedByName != null) {
      return Column(
        children: [
          _buildDetailRow(Icons.person, 'Occupé par', _desk.occupiedByName!),
          _buildDetailRow(Icons.business, 'Département', _desk.department ?? 'Non spécifié'),
          if (_desk.occupiedSince != null)
            _buildDetailRow(
                Icons.access_time,
                'Depuis',
                _formatTime(_desk.occupiedSince!)
            ),
        ],
      );
    }

    if (_desk.status == DeskStatus.blocked) {
      return Column(
        children: [
          _buildDetailRow(Icons.block, 'Statut', 'Bloqué - Direction'),
          _buildDetailRow(Icons.info_outline, 'Raison', 'Espace réservé à la direction'),
        ],
      );
    }

    if (_desk.status == DeskStatus.booked) {
      return Column(
        children: [
          _buildDetailRow(
              Icons.person_outline,
              'Réservé par',
              _desk.bookedByName ?? 'Quelqu\'un'
          ),
          if (_desk.bookedAt != null)
            _buildDetailRow(
                Icons.event,
                'Date',
                DateFormat('dd/MM/yyyy à HH:mm').format(_desk.bookedAt!)
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(User? currentUser) {
    if (_desk.status == DeskStatus.available && currentUser != null) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _showBookingDialog(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('Réserver ce poste'),
        ),
      );
    }

    if (_desk.status == DeskStatus.booked && _desk.bookedBy == currentUser?.uid) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              _releaseDesk();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryBlue,
              side: const BorderSide(color: AppColors.primaryBlue),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Libérer ce poste'),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gray),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: AppColors.gray, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================
  // DIALOGUE DE RÉSERVATION
  // ===========================================
  void _showBookingDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Réserver un poste'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Poste: ${_desk.deskNumber} (${_desk.floor})'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            DateFormat('dd/MM/yyyy').format(selectedDate),
                            style: const TextStyle(fontWeight: FontWeight.w500)
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (date != null) setState(() => selectedDate = date);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                      labelText: 'Motif (optionnel)',
                      border: OutlineInputBorder()
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler', style: TextStyle(color: AppColors.gray)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _bookDesk(selectedDate, reasonController.text);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue
                ),
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      ),
    );
  }
}