import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_roles.dart';
import '../../../domain/entities/desk.dart';
import '../../../data/services/api_service.dart';
import '../widgets/desk_card.dart';

class DeskMapScreen extends StatefulWidget {
  const DeskMapScreen({Key? key}) : super(key: key);

  @override
  State<DeskMapScreen> createState() => _DeskMapScreenState();
}

class _DeskMapScreenState extends State<DeskMapScreen> {
  final ApiService _apiService = ApiService();

  bool _showFloorsDropdown = false;
  String _selectedFloor = 'Floor01';
  final List<String> floors = ['Floor01', 'Floor02'];
  bool _showOccupantsList = false;

  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();

  List<Desk> _desksFloor01 = [];
  List<Desk> _desksFloor02 = [];
  List<Desk> _desks = [];
  List<Map<String, String>> _occupants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllDesks();
    _loadOccupants();
  }

  Future<void> _loadAllDesks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _apiService.getPostes('Floor01'),
        _apiService.getPostes('Floor02'),
      ]);
      setState(() {
        _desksFloor01 = results[0];
        _desksFloor02 = results[1];
        _desks = _selectedFloor == 'Floor01' ? _desksFloor01 : _desksFloor02;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement des postes';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDesks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final desks = await _apiService.getPostes(_selectedFloor);
      setState(() {
        if (_selectedFloor == 'Floor01') {
          _desksFloor01 = desks;
        } else {
          _desksFloor02 = desks;
        }
        _desks = desks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement des postes';
        _isLoading = false;
      });
    }
  }

  Future<String?> _findPosteByUid(String uid) async {
    try {
      for (var desk in _desks) {
        if (desk.occupiedBy == uid || desk.bookedBy == uid) {
          return desk.deskNumber;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadOccupants() async {
    try {
      final pointages = await _apiService.getPointages();
      final occupants = <Map<String, String>>[];
      for (var attendance in pointages) {
        if (attendance.isPresentToday && attendance.sessions.isNotEmpty) {
          final session = attendance.sessions.firstWhere(
                (s) => s.isActive,
            orElse: () => attendance.sessions.first,
          );

          if (session.isActive) {
            final poste = await _findPosteByUid(attendance.uid);
            occupants.add({
              'name': attendance.nom ?? 'Employé',
              'uid': attendance.uid,
              'time': session.entree ?? '',
              'poste': poste ?? 'Non assigné',
            });
          }
        }
      }

      setState(() {
        _occupants = occupants;
      });
    } catch (e) {
      // Silencieux
    }
  }

  Map<String, int> get stats {
    int available = 0;
    int occupied = 0;
    int blocked = 0;
    int booked = 0;
    for (var desk in _desks) {
      switch (desk.status) {
        case DeskStatus.available:
          available++;
          break;
        case DeskStatus.occupied:
          occupied++;
          break;
        case DeskStatus.blocked:
          blocked++;
          break;
        case DeskStatus.booked:
          booked++;
          break;
      }
    }
    return {
      'available': available,
      'occupied': occupied,
      'blocked': blocked,
      'booked': booked,
    };
  }

  int _getAvailableForFloor(String floor) {
    if (floor == 'Floor01') {
      return _desksFloor01.where((d) => d.status == DeskStatus.available).length;
    } else {
      return _desksFloor02.where((d) => d.status == DeskStatus.available).length;
    }
  }

  void _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Déconnexion',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.charcoal,
          ),
        ),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.gray),
            child: const Text('Annuler'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.teal],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Déconnexion'),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _apiService.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  String get currentMonthYear =>
      DateFormat('MMMM yyyy').format(_currentMonth);

  List<int> get weekDays {
    final firstDayOfWeek =
    _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    return List.generate(
        7, (i) => firstDayOfWeek.add(Duration(days: i)).day);
  }

  void _previousMonth() => setState(() {
    _currentMonth =
        DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
  });

  void _nextMonth() => setState(() {
    _currentMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
  });

  void _selectDate(DateTime date) => setState(() => _selectedDate = date);

  void _refreshDesks() {
    _loadDesks();
    _loadOccupants();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _apiService.currentUser;
    final isAdmin = currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: isAdmin
          ? null
          : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        title: Text(
          'Postes de travail',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        actions: [
          if (currentUser != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currentUser.prenom,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.charcoal),
            onPressed: _logout,
          ),
        ],
      ),

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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildCalendar(),
                  const SizedBox(height: 20),
                  _buildLegend(),
                  const SizedBox(height: 20),
                  _buildWorkspaceSection(),
                  const SizedBox(height: 20),
                  _buildFloorHeader(),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            color: AppColors.primaryBlue),
                      ),
                    )
                  else if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline,
                                size: 50, color: AppColors.error),
                            const SizedBox(height: 10),
                            Text(_errorMessage!),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _loadDesks,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    _buildDeskGrid(),
                  const SizedBox(height: 30),
                  _buildFooter(),
                  const SizedBox(height: 20),
                  Text(
                    'Version 2.0.0',
                    style: TextStyle(fontSize: 12, color: AppColors.gray),
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

  Widget _buildDeskGrid() {
    if (_desks.isEmpty) {
      return const Center(child: Text('Aucun poste disponible'));
    }

    _desks.sort((a, b) => a.deskNumber.compareTo(b.deskNumber));
    final List<Widget> rows = [];

    if (_selectedFloor == 'Floor01') {
      final rang1 = _desks.where((d) => d.deskNumber.startsWith('A')).toList();
      final rang2 = _desks.where((d) => d.deskNumber.startsWith('B')).toList();
      final rang3 = _desks.where((d) => d.deskNumber.startsWith('C')).toList();
      if (rang1.isNotEmpty) rows.add(_buildRang(rang1));
      if (rang1.isNotEmpty && (rang2.isNotEmpty || rang3.isNotEmpty))
        rows.add(_buildEspace());
      if (rang2.isNotEmpty) rows.add(_buildRang(rang2));
      if (rang2.isNotEmpty && rang3.isNotEmpty) rows.add(_buildEspace());
      if (rang3.isNotEmpty) rows.add(_buildRang(rang3));
    } else {
      final rang1 = _desks.where((d) => d.deskNumber.startsWith('D')).toList();
      final rang2 = _desks.where((d) => d.deskNumber.startsWith('E')).toList();
      final rang3 = _desks.where((d) => d.deskNumber.startsWith('F')).toList();
      if (rang1.isNotEmpty) rows.add(_buildRang(rang1));
      if (rang1.isNotEmpty && (rang2.isNotEmpty || rang3.isNotEmpty))
        rows.add(_buildEspace());
      if (rang2.isNotEmpty) rows.add(_buildRang(rang2));
      if (rang2.isNotEmpty && rang3.isNotEmpty) rows.add(_buildEspace());
      if (rang3.isNotEmpty) rows.add(_buildRang(rang3));
    }

    return Column(children: rows);
  }

  Widget _buildRang(List<Desk> rang) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: rang.map((desk) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: DeskCard(
                desk: desk,
                isIndividual: false,
                onBook: (updatedDesk) => _refreshDesks(),
                onRelease: (updatedDesk) => _refreshDesks(),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEspace() {
    return Container(
      height: 30,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          height: 2,
          width: 100,
          color: AppColors.lightGray.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.lightGray, width: 1),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _previousMonth,
                color: AppColors.primaryBlue,
              ),
              Text(
                currentMonthYear,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
                color: AppColors.primaryBlue,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('S', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('M', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('T', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('W', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('T', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('F', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('S', style: TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.asMap().entries.map((entry) {
              final day = entry.value;
              final isToday = day == DateTime.now().day &&
                  _selectedDate.month == DateTime.now().month &&
                  _selectedDate.year == DateTime.now().year;
              final isSelected = day == _selectedDate.day;

              return GestureDetector(
                onTap: () => _selectDate(DateTime(
                  _selectedDate.year,
                  _selectedDate.month,
                  day,
                )),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : isToday
                        ? AppColors.primaryBlue.withOpacity(0.1)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      day.toString(),
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : isToday
                            ? AppColors.primaryBlue
                            : AppColors.charcoal,
                        fontWeight:
                        isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.lightGray, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Occupied', AppColors.occupied),
          _buildLegendItem('Available', AppColors.available),
          _buildLegendItem('Blocked', AppColors.blocked),
          _buildLegendItem('Booked', AppColors.booked),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.gray)),
      ],
    );
  }

  Widget _buildWorkspaceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.lightGray, width: 1),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () =>
                setState(() => _showFloorsDropdown = !_showFloorsDropdown),
            child: Row(
              children: [
                const Text(
                  'Workspace Pro',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showFloorsDropdown
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                  color: AppColors.gray,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(
                          () => _showOccupantsList = !_showOccupantsList),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Who is in the office',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.gray),
                        ),
                        Icon(
                          _showOccupantsList
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 16,
                          color: AppColors.gray,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showFloorsDropdown)
            Column(
              children: [
                const Divider(height: 20),
                ...floors.map((floor) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFloor = floor;
                        _showFloorsDropdown = false;
                      });
                      _loadDesks();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: AppColors.lightGray, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            floor,
                            style: TextStyle(
                              fontWeight: floor == _selectedFloor
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: floor == _selectedFloor
                                  ? AppColors.primaryBlue
                                  : AppColors.charcoal,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.available,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_getAvailableForFloor(floor)} disponibles',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          if (_showOccupantsList && _occupants.isNotEmpty)
            Column(
              children: [
                const Divider(height: 20),
                ..._occupants.take(5).map((occupant) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.offWhite,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                          AppColors.primaryBlue.withOpacity(0.1),
                          child: Text(
                            occupant['name']![0],
                            style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                occupant['name']!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Poste ${occupant['poste']} • Depuis ${occupant['time']?.substring(11, 16) ?? ''}',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.gray),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFloorHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: AppColors.lightGray, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primaryBlue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _selectedFloor,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.charcoal,
                ),
              ),
            ],
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.available,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_seat, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${stats['available']} disponibles',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.teal]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Workspace Pro',
          style:
          TextStyle(color: AppColors.gray, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 12),
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.primaryBlue]),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}