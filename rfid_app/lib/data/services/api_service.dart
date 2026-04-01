import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/desk.dart';
import '../../domain/entities/attendance.dart';
import '../../core/constants/app_roles.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'http://10.0.2.2:3000';
  String? _token;
  User? _currentUser;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  User? get currentUser => _currentUser;

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  Future<void> clearToken() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<void> saveUser(User user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode({
      'uid': user.uid,
      'prenom': user.prenom,
      'nom': user.nom,
      'email': user.email,
      'role': user.role == UserRole.admin ? 'admin' : 'employee',
    }));
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      try {
        final Map<String, dynamic> jsonData = json.decode(userData);
        _currentUser = User(
          uid: jsonData['uid'],
          employeeId: jsonData['uid'],
          prenom: jsonData['prenom'],
          nom: jsonData['nom'],
          email: jsonData['email'],
          department: 'Non spécifié',
          role: jsonData['role'] == 'admin' ? UserRole.admin : UserRole.employee,
          createdAt: DateTime.now(),
        );
      } catch (e) {
        // Silencieux
      }
    }
  }

  // AUTHENTIFICATION
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await setToken(data['token']);

        final user = User(
          uid: data['uid'],
          employeeId: data['uid'],
          prenom: data['nomComplet']?.split(' ')[0] ?? '',
          nom: data['nomComplet']?.split(' ').sublist(1).join(' ') ?? '',
          email: data['email'] ?? email,
          department: 'Non spécifié',
          role: data['role'] == 'admin' ? UserRole.admin : UserRole.employee,
          createdAt: DateTime.now(),
        );

        await saveUser(user);
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    await clearToken();
  }

  // UTILISATEURS (Admin)

  Future<List<User>> getUtilisateurs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/utilisateurs'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> utilisateurs = data['utilisateurs'] ?? [];
        return utilisateurs.map((json) => User.fromApi(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<User?> getUtilisateur(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/utilisateurs/$uid'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return User.fromApi(json.decode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> createUtilisateur({
    required String uid,
    required String email,
    required String password,
    required String prenom,
    required String nom,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/utilisateurs'),
        headers: _headers,
        body: json.encode({
          'uid': uid,
          'email': email,
          'password': password,
          'prenom': prenom,
          'nom': nom,
          'role': role,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateUtilisateur(String uid, {
    String? email,
    String? password,
    String? prenom,
    String? nom,
    String? role,
    bool? autorise,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (email != null) data['email'] = email;
      if (password != null && password.isNotEmpty) data['password'] = password;
      if (prenom != null) data['prenom'] = prenom;
      if (nom != null) data['nom'] = nom;
      if (role != null) data['role'] = role;
      if (autorise != null) data['autorise'] = autorise;

      final response = await http.put(
        Uri.parse('$baseUrl/utilisateurs/$uid'),
        headers: _headers,
        body: json.encode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUtilisateur(String uid) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/utilisateurs/$uid'),
        headers: _headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Desk>> getPostes(String floor) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/postes/$floor'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> postesJson = jsonResponse['postes'] ?? [];

        final List<Desk> desks = [];
        for (var posteJson in postesJson) {
          desks.add(Desk.fromApi(posteJson, floor: floor));
        }

        return desks;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> reserverPoste(String floor, String numero, String uid, String prenom) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/postes/$floor/$numero/reserver'),
        headers: _headers,
        body: json.encode({'uid': uid, 'prenom': prenom}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> libererPoste(String floor, String numero, String uid) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/postes/$floor/$numero/liberer'),
        headers: _headers,
        body: json.encode({'uid': uid}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changerStatutPoste(String id, String statut) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/postes/$id/statut'),
        headers: _headers,
        body: json.encode({'statut': statut}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // POINTAGE
  Future<List<Attendance>> getPointages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pointage'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> pointages = data['pointages'] ?? [];
        return pointages.map((json) => Attendance.fromApi(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Attendance>> getPointagesEmploye(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pointage/$uid'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> pointages = data['pointages'] ?? [];
        return pointages.map((json) => Attendance.fromApi(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}