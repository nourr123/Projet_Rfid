import 'package:flutter/material.dart';
import '../../../domain/entities/desk.dart';

class DeskViewModel extends ChangeNotifier {
  List<Desk> _desks = [];
  String _selectedFloor = 'Étage 9';
  bool _isLoading = false;
  String? _errorMessage;

  List<Desk> get desks => _desks;
  String get selectedFloor => _selectedFloor;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Statistiques par étage
  Map<String, int> get statistics {
    int available = _desks.where((d) => d.status == DeskStatus.available).length;
    int occupied = _desks.where((d) => d.status == DeskStatus.occupied).length;
    int blocked = _desks.where((d) => d.status == DeskStatus.blocked).length;
    int booked = _desks.where((d) => d.status == DeskStatus.booked).length;

    return {
      'available': available,
      'occupied': occupied,
      'blocked': blocked,
      'booked': booked,
      'total': _desks.length,
    };
  }

  // Liste des employés présents
  List<Map<String, String>> get occupants {
    return _desks
        .where((d) => d.status == DeskStatus.occupied && d.occupiedByName != null)
        .map((d) => {
      'name': d.occupiedByName!,
      'desk': d.deskNumber,
      'department': d.department ?? 'Non spécifié',
    })
        .toList();
  }

  final List<String> floors = [
    'Étage 8',
    'Étage 9',
    'Étage 10',
    'Étage 11',
    'Étage 12',
  ];

  DeskViewModel() {
    _loadMockData();
  }

  void _loadMockData() {
    _isLoading = true;
    notifyListeners();

    // Données mockées pour simulation
    Future.delayed(const Duration(milliseconds: 500), () {
      _desks = _generateMockDesks();
      _isLoading = false;
      notifyListeners();
    });
  }

  List<Desk> _generateMockDesks() {
    List<Desk> mockDesks = [];

    // Générer 40 postes (5x8 grid)
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 8; col++) {
        int index = row * 8 + col;
        DeskStatus status;
        String? occupiedByName;
        String? department;

        // Répartition des statuts pour l'exemple
        if (index < 5) {
          status = DeskStatus.occupied;
          occupiedByName = ['Jean Dupont', 'Marie Martin', 'Pierre Durand', 'Sophie Lee', 'Thomas Bernard'][index];
          department = ['Marketing', 'RH', 'IT', 'Finance', 'Direction'][index];
        } else if (index < 8) {
          status = DeskStatus.blocked;
        } else if (index < 12) {
          status = DeskStatus.booked;
        } else {
          status = DeskStatus.available;
        }

        mockDesks.add(Desk(
          id: 'desk_${row}_$col',
          floor: _selectedFloor,
          deskNumber: '${String.fromCharCode(65 + row)}${col + 1}',
          status: status,
          occupiedBy: occupiedByName != null ? 'user_$index' : null,
          occupiedByName: occupiedByName,
          department: department,
          occupiedSince: occupiedByName != null ? DateTime.now().subtract(const Duration(hours: 2)) : null,
          row: row,
          column: col,
          hasPowerOutlet: true,
          hasMonitor: index % 3 == 0,
        ));
      }
    }

    return mockDesks;
  }

  void changeFloor(String floor) {
    if (_selectedFloor != floor) {
      _selectedFloor = floor;
      _loadMockData(); // Recharger avec les données du nouvel étage
    }
  }

  void refreshData() {
    _loadMockData();
  }

  List<Desk> getDesksByStatus(DeskStatus status) {
    return _desks.where((d) => d.status == status).toList();
  }
}