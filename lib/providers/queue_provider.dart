// lib/providers/queue_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/provider.dart';
import '../models/queue_entry.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class QueueProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Provider> _allProviders = []; // Store all providers
  List<Provider> _filteredProviders = []; // Store filtered list for UI
  Map<String, dynamic>? _queueStatus; 
  String? _currentProviderId;
  String? _currentProviderName;
  QueueEntry? _currentQueueEntry;
  List<dynamic> _history = [];
  bool _isLoading = false;

  // ...
  
  String? get currentProviderName => _currentProviderName;
  
  // User Info
  String? currentUserName;
  String? currentUserPhone;
  String? currentUserEmail;
  List<dynamic> currentUserAddresses = [];
  String? _authToken;
  String? get authToken => _authToken;
  String? _guestPhone; // Fallback for guest users

  
  // Staff Info
  String? _staffToken;
  String? _managedProviderId;
  String? _managedProviderName;
  String? _managedProviderQRCode;
  bool _isManagedProviderOpen = true;
  int _managedProviderAvgTime = 10;

  String? get staffToken => _staffToken;
  String? get managedProviderName => _managedProviderName;
  String? get managedProviderQRCode => _managedProviderQRCode;
  bool get isManagedProviderOpen => _isManagedProviderOpen;
  int get managedProviderAvgTime => _managedProviderAvgTime;
  
  // Security
  bool _isBiometricsEnabled = false;
  bool get isBiometricsEnabled => _isBiometricsEnabled;

  late Socket _socket;
  bool _isSocketInitialized = false;

  List<Provider> get availableProviders => _filteredProviders; // Return filtered list
  Map<String, dynamic>? get queueStatus => _queueStatus;
  QueueEntry? get currentQueueEntry => _currentQueueEntry;
  List<dynamic> get history => _history;
  bool get isLoading => _isLoading;
  
  void initialize() {
    if (!_isSocketInitialized) {
      _apiService.initializeSocket();
      _socket = _apiService.getSocket();
      _isSocketInitialized = true;
      _listenForGlobalUpdates(); 
      NotificationService().initialize(); // Initialize notifications
    }
    fetchProviders();
    fetchProviders();
    _loadQueueFromPrefs();
    _loadGuestPhone();
  }

  Future<void> login(String identifier, String password) async {
    try {
      final result = await _apiService.loginUser(identifier, password);
      _authToken = result['token'];
      final user = result['user'];
      currentUserName = user['name'];
      currentUserPhone = user['phone'];
      currentUserEmail = user['email'];
      currentUserAddresses = user['addresses'] ?? [];
      
      await _saveUserToPrefs(currentUserName!, currentUserPhone, _authToken!, currentUserEmail, jsonEncode(currentUserAddresses));
      
      // Check server for active queue entry (this is the key fix!)
      await _checkAndRestoreActiveQueue();
      
      fetchHistory(silent: true);
      
      notifyListeners();
    } catch (e) {
      print('Login Error: $e');
      rethrow;
    }
  }

  // Check server for active queue and restore queue state
  Future<void> _checkAndRestoreActiveQueue() async {
    final identifier = currentUserPhone ?? currentUserEmail;
    if (identifier == null) return;
    
    try {
      final result = await ApiService.checkActiveQueue(identifier);
      if (result['hasActiveQueue'] == true && result['entry'] != null) {
        final entry = result['entry'];
        _currentQueueEntry = QueueEntry.fromJson(entry);
        _currentProviderId = entry['providerId']?['_id'] ?? entry['providerId'];
        _currentProviderName = entry['providerId']?['name'];
        
        // Save to prefs so it persists
        await _saveQueueToPrefs(_currentProviderName ?? 'Your Queue');
        
        // Start listening for updates
        if (_currentProviderId != null) {
          fetchQueueStatus(_currentProviderId!);
          requestNotificationPermission();
        }
        
        print('Restored active queue: ${_currentQueueEntry?.queueNumber} at $_currentProviderName');
      }
    } catch (e) {
      print('Error checking active queue: $e');
    }
  }

  Future<void> signup(String name, String identifier, String password) async {
    try {
      final result = await _apiService.registerUser(
        name: name,
        identifier: identifier,
        password: password,
      );
      _authToken = result['token'];
      final user = result['user'];
      currentUserName = user['name'];
      currentUserPhone = user['phone'];
      currentUserEmail = user['email'];
      currentUserAddresses = user['addresses'] ?? [];
      
      await _saveUserToPrefs(currentUserName!, currentUserPhone, _authToken!, currentUserEmail, jsonEncode(currentUserAddresses));
      notifyListeners();
    } catch (e) {
      print('Signup Error: $e');
      rethrow;
    }
  }

  Future<void> _saveUserToPrefs(String name, String? phone, String token, String? email, String addresses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    if (phone != null) await prefs.setString('userPhone', phone);
    await prefs.setString('authToken', token);
    if (email != null) await prefs.setString('userEmail', email);
    await prefs.setString('userAddresses', addresses);
  }
  
  Future<void> setBiometricsEnabled(bool enabled) async {
    _isBiometricsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBiometricsEnabled', enabled);
    notifyListeners();
  }

  Future<bool> loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName');
    final phone = prefs.getString('userPhone');
    final token = prefs.getString('authToken');
    final email = prefs.getString('userEmail');
    final addresses = prefs.getString('userAddresses');
    _isBiometricsEnabled = prefs.getBool('isBiometricsEnabled') ?? false;

    if (name != null && token != null) {
      currentUserName = name;
      currentUserPhone = phone;
      _authToken = token;
      currentUserEmail = email;
      if (addresses != null) {
        currentUserAddresses = jsonDecode(addresses);
      }
      notifyListeners();
      return true;
    }
    return false;
  }
  
  // Separate loader for guest phone
  Future<void> _loadGuestPhone() async {
    final prefs = await SharedPreferences.getInstance();
    _guestPhone = prefs.getString('guestPhone');
  }

  Future<void> _saveQueueToPrefs(String providerName) async {
    if (_currentQueueEntry == null || _currentProviderId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currentQueueEntry', jsonEncode(_currentQueueEntry!.toJson()));
    await prefs.setString('currentProviderId', _currentProviderId!);
    await prefs.setString('currentProviderName', providerName);
  }

  Future<void> _loadQueueFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final queueEntryString = prefs.getString('currentQueueEntry');
    final providerId = prefs.getString('currentProviderId');
    final providerName = prefs.getString('currentProviderName');

    if (queueEntryString != null && providerId != null) {
      try {
        _currentQueueEntry = QueueEntry.fromJson(jsonDecode(queueEntryString));
        _currentProviderId = providerId;
        _currentProviderName = providerName;
        fetchQueueStatus(providerId);
        requestNotificationPermission();
        notifyListeners();
      } catch (e) {
        print('Error loading queue from prefs: $e');
        await leaveQueue();
      }
    }
  }

  Future<void> leaveQueue() async {
    final entryId = _currentQueueEntry?.id;
    if (entryId != null) {
      try {
        await _apiService.cancelQueueEntry(entryId);
        // Refresh history to show "Canceled" status immediately
        fetchHistory(silent: true);
      } catch (e) {
        print('Error calling leave queue API: $e');
        // Continue to clear local state even if API fails (offline support-ish)
      }
    }

    _currentQueueEntry = null;
    _currentProviderId = null;
    _queueStatus = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentQueueEntry');
    await prefs.remove('currentProviderId');
    
    notifyListeners();
  }

  // Clear queue entry locally (without API call) - for when user is served
  Future<void> clearCurrentQueue() async {
    _currentQueueEntry = null;
    _currentProviderId = null;
    _currentProviderName = null;
    _queueStatus = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentQueueEntry');
    await prefs.remove('currentProviderId');
    await prefs.remove('currentProviderName');
    
    // Refresh history to show updated status
    fetchHistory(silent: true);
    
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    currentUserName = null;
    currentUserPhone = null;
    currentUserEmail = null;
    currentUserAddresses = [];
    _authToken = null;
    _staffToken = null;
    _managedProviderId = null;
    _currentQueueEntry = null;
    _currentProviderId = null;
    _queueStatus = null;
    _guestPhone = null;
    await prefs.remove('guestPhone');
    notifyListeners();
  }

  void _listenForGlobalUpdates() {
    // Listen for provider status changes (open/closed)
    _socket.on('provider-status-update', (data) {
      print('Provider status update received: $data');
      final providerId = data['providerId'];
      final isOpen = data['isOpen'];
      
      // Update the local provider list
      final index = _allProviders.indexWhere((p) => p.id == providerId);
      if (index != -1) {
        final old = _allProviders[index];
        _allProviders[index] = Provider(
          id: old.id,
          name: old.name,
          city: old.city,
          category: old.category,
          address: old.address,
          staffEmail: old.staffEmail,
          isActive: old.isActive,
          avgRating: old.avgRating,
          totalReviews: old.totalReviews,
          efficiencyScore: old.efficiencyScore,
          recommendationScore: old.recommendationScore,
          isOpen: isOpen ?? old.isOpen,
          avgServiceTime: old.avgServiceTime,
          phone: old.phone,
          description: old.description,
          services: old.services,
          latitude: old.latitude,
          longitude: old.longitude,
          waitingCount: old.waitingCount,
        );
        _filteredProviders = List.from(_allProviders);
        print('Updated provider ${old.name} isOpen to $isOpen');
        notifyListeners();
      } else {
        // Provider not in list, fetch fresh
        fetchProviders();
      }
    });
    
    _socket.onAny((event, data) {
      if (event.startsWith('queue-update-')) {
        final updatedProviderId = event.substring('queue-update-'.length);

        // 1. Update Active Queue Screen if applicable
        if (updatedProviderId == _currentProviderId) {
          print('Received real-time update for queue $_currentProviderId');
          fetchQueueStatus(_currentProviderId!);
          
          // Targeted Notification Logic
          if (_currentQueueEntry != null && data['servingNumber'] == _currentQueueEntry!.queueNumber) {
            NotificationService().showNotification(
              'It\'s Your Turn!',
              'Ticket #${_currentQueueEntry!.queueNumber} is now being served!',
            );
          }
        }

        // 2. Update Staff Dashboard if applicable
        if (updatedProviderId == _managedProviderId) {
          print('Received real-time update for managed provider $_managedProviderId');
          fetchQueueStatus(_managedProviderId!);
        }

        // 2. Update History if applicable
        // Check if we have any history items from this provider
        final hasHistoryWithProvider = _history.any((item) {
          final provider = item['providerId'];
          // providerId is populated, so it's a Map. Check _id.
          if (provider is Map) {
             return provider['_id'] == updatedProviderId;
          }
          return false;
        });

        if (hasHistoryWithProvider) {
           print('Updating history for provider $updatedProviderId');
           fetchHistory(silent: true);
        }
      }
    });
  }

  Future<void> requestNotificationPermission() async {
    await NotificationService().requestPermissions();
  }

  Future<void> fetchProviders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allProviders = await _apiService.getProviders();
      _filteredProviders = List.from(_allProviders); // Initial state: show all
    } catch (e) {
      print('Error fetching providers: $e');
      _allProviders = [];
      _filteredProviders = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> fetchHistory({bool silent = false}) async {
    // Try phone first, then email, then guest phone
    final identifier = currentUserPhone ?? currentUserEmail ?? _guestPhone;
    if (identifier == null) return;
    
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _history = await _apiService.getHistory(identifier);
    } catch (e) {
      print('Error fetching history: $e');
      if (!silent) _history = [];
    } finally {
      if (!silent) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // Filter Logic
  void filterProviders({String query = '', String? category}) {
    _filteredProviders = _allProviders.where((provider) {
      final matchesQuery = provider.name.toLowerCase().contains(query.toLowerCase()) || 
                           provider.city.toLowerCase().contains(query.toLowerCase());
      
      final matchesCategory = category == null || category == 'All' || provider.category == category;

      return matchesQuery && matchesCategory;
    }).toList();
    
    notifyListeners();
  }

  Future<void> fetchQueueStatus(String providerId) async {
    _currentProviderId = providerId;
    
    try {
      _queueStatus = await _apiService.getQueueStatus(providerId);
    } catch (e) {
      print('Error fetching queue status: $e');
      _queueStatus = null;
    }

    notifyListeners();
  }

  Future<QueueEntry> joinQueue({
    required String providerId,
    required String userName,
    required String userPhone,
  }) async {
    try {
      final result = await _apiService.joinQueue(
        providerId: providerId,
        userName: userName,
        userPhone: userPhone,
      );
      
      final queueEntry = QueueEntry.fromJson(result['queueEntry']);
      _currentQueueEntry = queueEntry;
      
      // Find provider name from list to save it
      String providerName = 'Unknown Provider';
      try {
        final provider = _allProviders.firstWhere((p) => p.id == providerId);
        providerName = provider.name;
      } catch (e) {
        // Provider not found in local list
      }
      _currentProviderName = providerName;

      fetchQueueStatus(providerId); 
      _saveQueueToPrefs(providerName);
      requestNotificationPermission();

      // If guest (not logged in), save phone for history
      if (_authToken == null) {
        _guestPhone = userPhone;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('guestPhone', userPhone);
      }

      return queueEntry;
    } catch (e) {
      print('Error joining queue: $e');
      rethrow; 
    }
  }

  Future<void> staffLogin(String email, String password) async {
    try {
      final result = await _apiService.loginStaff(email, password);
      _staffToken = result['token'];
      _managedProviderId = result['_id'];
      _managedProviderName = result['name'];
      _managedProviderQRCode = result['qrCode'];
      _isManagedProviderOpen = result['isOpen'] ?? true;
      _managedProviderAvgTime = result['avgServiceTime'] ?? 10;
      
      // Save staff session to prefs
      await _saveStaffToPrefs();
      
      // Start listening for updates for this provider
      fetchQueueStatus(_managedProviderId!);
      notifyListeners();
    } catch (e) {
      print('Staff Login Error: $e');
      rethrow;
    }
  }

  Future<void> _saveStaffToPrefs() async {
    if (_staffToken == null || _managedProviderId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('staffToken', _staffToken!);
    await prefs.setString('managedProviderId', _managedProviderId!);
    if (_managedProviderName != null) await prefs.setString('managedProviderName', _managedProviderName!);
    if (_managedProviderQRCode != null) await prefs.setString('managedProviderQRCode', _managedProviderQRCode!);
    await prefs.setBool('managedProviderOpen', _isManagedProviderOpen);
    await prefs.setInt('managedProviderAvgTime', _managedProviderAvgTime);
  }

  Future<bool> loadStaffFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('staffToken');
    final providerId = prefs.getString('managedProviderId');
    
    if (token != null && providerId != null) {
      _staffToken = token;
      _managedProviderId = providerId;
      _managedProviderName = prefs.getString('managedProviderName');
      _managedProviderQRCode = prefs.getString('managedProviderQRCode');
      _isManagedProviderOpen = prefs.getBool('managedProviderOpen') ?? true;
      _managedProviderAvgTime = prefs.getInt('managedProviderAvgTime') ?? 10;
      
      // Fetch fresh queue data
      fetchQueueStatus(_managedProviderId!);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> callNextUser() async {
    if (_staffToken == null || _managedProviderId == null) return;
    
    try {
      await _apiService.callNext(_staffToken!, _managedProviderId!);
      fetchQueueStatus(_managedProviderId!);
    } catch (e) {
      print('Call Next Error: $e');
      rethrow;
    }
  }

  Future<void> markAsServed(String entryId) async {
    if (_staffToken == null) return;

    try {
      await _apiService.serve(_staffToken!, entryId);
      fetchQueueStatus(_managedProviderId!);
    } catch (e) {
      print('Serve Error: $e');
      rethrow;
    }
  }

  // Undo Call Next - Reverts accidentally called customer
  Future<void> undoCallNext() async {
    if (_managedProviderId == null) return;
    
    try {
      await ApiService.undoCallNext(_managedProviderId!);
      fetchQueueStatus(_managedProviderId!);
    } catch (e) {
      print('Undo Call Error: $e');
      rethrow;
    }
  }

  // Add Manual Customer - For offline walk-ins
  Future<void> addManualCustomer(String name, String? phone) async {
    if (_managedProviderId == null) return;
    
    try {
      await ApiService.addManualCustomer(
        providerId: _managedProviderId!,
        userName: name,
        userPhone: phone,
      );
      fetchQueueStatus(_managedProviderId!);
    } catch (e) {
      print('Add Manual Customer Error: $e');
      rethrow;
    }
  }

  // Mark Not Present - Moves customer back 5 positions
  Future<void> markNotPresent(String entryId) async {
    try {
      await ApiService.markNotPresent(entryId);
      if (_managedProviderId != null) {
        fetchQueueStatus(_managedProviderId!);
      }
    } catch (e) {
      print('Mark Not Present Error: $e');
      rethrow;
    }
  }

  Future<void> updateSettings(bool isOpen, int avgTime) async {
    if (_staffToken == null) return;

    try {
      await _apiService.updateProviderSettings(
        token: _staffToken!,
        isOpen: isOpen,
        avgServiceTime: avgTime,
      );
      _isManagedProviderOpen = isOpen;
      _managedProviderAvgTime = avgTime;
      notifyListeners();
    } catch (e) {
      print('Update Settings Error: $e');
      rethrow;
    }
  }

  // New Profile Methods
  Future<void> updateProfile({String? name, String? email, String? phone}) async {
    if (_authToken == null) return;
    try {
      final result = await _apiService.updateProfile(
        token: _authToken!,
        name: name,
        email: email,
        phone: phone,
      );
      final user = result['user'];
      currentUserName = user['name'];
      currentUserPhone = user['phone'];
      currentUserEmail = user['email'];
      currentUserAddresses = user['addresses'] ?? [];
      
      await _saveUserToPrefs(currentUserName!, currentUserPhone, _authToken!, currentUserEmail, jsonEncode(currentUserAddresses));
      notifyListeners();
    } catch (e) {
      print('Update Profile Error: $e');
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    if (_authToken == null) return;
    try {
      await _apiService.changePassword(
        token: _authToken!,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      print('Change Password Error: $e');
      rethrow;
    }
  }

  Future<bool> verifyPassword(String password) async {
    if (_authToken == null) return false;
    try {
      return await _apiService.verifyPassword(
        token: _authToken!,
        password: password,
      );
    } catch (e) {
      print('Verify Password Error: $e');
      return false;
    }
  }

  Future<void> addAddress(String label, String address, bool isDefault) async {
    if (_authToken == null) return;
    try {
      currentUserAddresses = await _apiService.addAddress(
        token: _authToken!,
        label: label,
        address: address,
        isDefault: isDefault,
      );
      await _saveUserToPrefs(currentUserName!, currentUserPhone, _authToken!, currentUserEmail, jsonEncode(currentUserAddresses));
      notifyListeners();
    } catch (e) {
      print('Add Address Error: $e');
      rethrow;
    }
  }

  Future<void> deleteAddress(String addressId) async {
    if (_authToken == null) return;
    try {
      currentUserAddresses = await _apiService.deleteAddress(
        token: _authToken!,
        addressId: addressId,
      );
      await _saveUserToPrefs(currentUserName!, currentUserPhone, _authToken!, currentUserEmail, jsonEncode(currentUserAddresses));
      notifyListeners();
    } catch (e) {
      print('Delete Address Error: $e');
      rethrow;
    }
  }
  
  // User Location
  Position? _currentUserLocation;
  Position? get currentUserLocation => _currentUserLocation;

  Future<void> fetchUserLocation() async {
    final locationService = LocationService();
    _currentUserLocation = await locationService.getCurrentLocation();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isSocketInitialized) {
      _socket.disconnect();
    }
    super.dispose();
  }
}