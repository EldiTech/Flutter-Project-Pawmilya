import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/adoption_application.dart';
import '../models/dashboard_stats.dart';
import '../models/employee.dart';
import '../models/pet.dart';
import '../models/shelter_profile.dart';
import '../models/shelter_zone.dart';
import '../services/firestore_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider(this._service);

  final FirestoreService _service;

  List<Pet> _pets = [];
  List<AdoptionApplication> _applications = [];
  List<Employee> _employees = [];
  List<ShelterZone> _zones = [];
  ShelterProfile? _profile;

  bool _isLoading = true;
  bool _isSigningOut = false;
  String? _error;

  StreamSubscription<List<Pet>>? _petsSub;
  StreamSubscription<List<AdoptionApplication>>? _applicationsSub;
  StreamSubscription<List<Employee>>? _employeesSub;
  StreamSubscription<List<ShelterZone>>? _zonesSub;
  StreamSubscription<ShelterProfile?>? _profileSub;

  List<Pet> get pets => _pets;
  List<AdoptionApplication> get applications => _applications;
  List<Employee> get employees => _employees;
  List<ShelterZone> get zones => _zones;
  ShelterProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  DashboardStats get stats {
    final approved = _applications.where((item) => item.status == 'Approved').length;
    final pending = _applications.where((item) => item.status == 'Pending').length;
    final rejected = _applications.where((item) => item.status == 'Rejected').length;
    final adopted = _pets.where((item) => item.status == 'Adopted').length;
    final totalClosed = approved + rejected;
    final totalAdoptions = adopted + approved;

    final successRate = totalClosed == 0 ? 0 : ((approved / totalClosed) * 100).round();
    final avgTemp = _zones.isEmpty
        ? 0
        : (_zones.map((zone) => zone.temp).reduce((a, b) => a + b) / _zones.length).round();
    final avgHumidity = _zones.isEmpty
        ? 0
        : (_zones.map((zone) => zone.humidity).reduce((a, b) => a + b) / _zones.length).round();

    return DashboardStats(
      totalAnimals: _pets.length,
      totalApplications: _applications.length,
      pendingApplications: pending,
      totalAdoptions: totalAdoptions,
      approvedApplications: approved,
      activeEmployees: _employees.where((item) => item.status == 'Active').length,
      adoptedAnimals: adopted,
      avgTemp: avgTemp,
      avgHumidity: avgHumidity,
      successRate: successRate,
    );
  }

  void initialize() {
    _isSigningOut = false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    _cancelSubscriptions();

    _petsSub = _service.watchPets().listen(
      (data) {
        _pets = data;
        _finalizeLoading();
      },
      onError: _onError,
    );

    _applicationsSub = _service.watchApplications().listen(
      (data) {
        _applications = data;
        _finalizeLoading();
      },
      onError: _onError,
    );

    _employeesSub = _service.watchEmployees().listen(
      (data) {
        _employees = data;
        _finalizeLoading();
      },
      onError: _onError,
    );

    _zonesSub = _service.watchZones().listen(
      (data) {
        _zones = data;
        _finalizeLoading();
      },
      onError: _onError,
    );

    _profileSub = _service.watchShelterProfile().listen(
      (data) {
        _profile = data;
        _finalizeLoading();
      },
      onError: _onError,
    );
  }

  Future<void> stopForSignOut() async {
    _isSigningOut = true;
    await _cancelSubscriptions();
    _pets = [];
    _applications = [];
    _employees = [];
    _zones = [];
    _profile = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> _cancelSubscriptions() async {
    await _petsSub?.cancel();
    await _applicationsSub?.cancel();
    await _employeesSub?.cancel();
    await _zonesSub?.cancel();
    await _profileSub?.cancel();

    _petsSub = null;
    _applicationsSub = null;
    _employeesSub = null;
    _zonesSub = null;
    _profileSub = null;
  }

  void _finalizeLoading() {
    if (_isSigningOut) return;
    if (_isLoading) {
      _isLoading = false;
    }
    notifyListeners();
  }

  void _onError(Object error, StackTrace _) {
    if (_isSigningOut) return;
    _isLoading = false;
    _error = error.toString();
    notifyListeners();
  }

  Future<void> addPet({
    required String name,
    required String species,
    required String breed,
    required String age,
    required String gender,
    required String status,
    String? dateAdmitted,
    String? notes,
  }) async {
    await _runMutation(
      () => _service.createPet(
        name: name,
        species: species,
        breed: breed,
        age: age,
        gender: gender,
        status: status,
        dateAdmitted: dateAdmitted,
        notes: notes,
      ),
    );
  }

  Future<void> editPet(
    String id, {
    required String name,
    required String species,
    required String breed,
    required String age,
    required String gender,
    required String status,
    String? dateAdmitted,
    String? notes,
  }) async {
    await _runMutation(
      () => _service.updatePet(
        id,
        name: name,
        species: species,
        breed: breed,
        age: age,
        gender: gender,
        status: status,
        dateAdmitted: dateAdmitted,
        notes: notes,
      ),
    );
  }

  Future<void> removePet(String id) async {
    await _runMutation(() => _service.deletePet(id));
  }

  Future<void> addApplication({
    required String applicant,
    required String animal,
    required String status,
    String? date,
  }) async {
    await _runMutation(
      () => _service.createApplication(
        applicant: applicant,
        animal: animal,
        status: status,
        date: date,
      ),
    );
  }

  Future<void> editApplication(
    String id, {
    required String applicant,
    required String animal,
    required String status,
    String? date,
  }) async {
    await _runMutation(
      () => _service.updateApplication(
        id,
        applicant: applicant,
        animal: animal,
        status: status,
        date: date,
      ),
    );
  }

  Future<void> setApplicationStatus(String id, String status) async {
    await _runMutation(() => _service.updateApplicationStatus(id, status));
  }

  Future<void> removeApplication(String id) async {
    await _runMutation(() => _service.deleteApplication(id));
  }

  Future<void> addEmployee({
    required String name,
    required String role,
    required String status,
    String? dept,
    String? email,
    String? phone,
    String? dateHired,
  }) async {
    await _runMutation(
      () => _service.createEmployee(
        name: name,
        role: role,
        status: status,
        dept: dept,
        email: email,
        phone: phone,
        dateHired: dateHired,
      ),
    );
  }

  Future<void> editEmployee(
    String id, {
    required String name,
    required String role,
    required String status,
    String? dept,
    String? email,
    String? phone,
    String? dateHired,
  }) async {
    await _runMutation(
      () => _service.updateEmployee(
        id,
        name: name,
        role: role,
        status: status,
        dept: dept,
        email: email,
        phone: phone,
        dateHired: dateHired,
      ),
    );
  }

  Future<void> removeEmployee(String id) async {
    await _runMutation(() => _service.deleteEmployee(id));
  }

  Future<void> addZone({
    required String name,
    required int humidity,
    required String humidityStatus,
    required int temp,
    required String tempStatus,
  }) async {
    await _runMutation(
      () => _service.createZone(
        name: name,
        humidity: humidity,
        humidityStatus: humidityStatus,
        temp: temp,
        tempStatus: tempStatus,
      ),
    );
  }

  Future<void> editZone(
    String id, {
    required String name,
    required int humidity,
    required String humidityStatus,
    required int temp,
    required String tempStatus,
  }) async {
    await _runMutation(
      () => _service.updateZone(
        id,
        name: name,
        humidity: humidity,
        humidityStatus: humidityStatus,
        temp: temp,
        tempStatus: tempStatus,
      ),
    );
  }

  Future<void> removeZone(String id) async {
    await _runMutation(() => _service.deleteZone(id));
  }

  Future<void> _runMutation(Future<void> Function() action) async {
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _error = error.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
