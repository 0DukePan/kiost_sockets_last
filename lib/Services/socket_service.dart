import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart'; // Added for UniqueKey

import '../Config/app_config.dart';
import '../Services/api_service.dart'; // Import ApiService

class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isInitialized = false;
  String? _tableId; // Unique ID for this device/table (usually the device ID)
  String? _dbTableId; // MongoDB _id for the table entry in the backend
  String? _sessionId; // Current active session ID
  bool _isConnecting = false; // Prevent multiple initialization attempts
  Timer? _reconnectTimer;

  // Stream controllers for various events
  final _onConnectedController = StreamController<bool>.broadcast();
  final _onErrorController = StreamController<String>.broadcast();
  final _onTableRegisteredController = StreamController<Map<String, dynamic>>.broadcast();
  final _onSessionStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _onNewOrderController = StreamController<Map<String, dynamic>>.broadcast(); // For potential future use
  final _onSessionEndedController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams
  Stream<bool> get onConnected => _onConnectedController.stream;
  Stream<String> get onError => _onErrorController.stream;
  Stream<Map<String, dynamic>> get onTableRegistered => _onTableRegisteredController.stream;
  Stream<Map<String, dynamic>> get onSessionStarted => _onSessionStartedController.stream;
  Stream<Map<String, dynamic>> get onNewOrder => _onNewOrderController.stream; // For potential future use
  Stream<Map<String, dynamic>> get onSessionEnded => _onSessionEndedController.stream;

  // Getters for current state
  String? get tableId => _tableId; // Device's unique ID used for registration
  String? get dbTableId => _dbTableId; // Backend MongoDB _id
  String? get sessionId => _sessionId;
  bool get isConnected => _socket?.connected ?? false;
  bool get isConnecting => _isConnecting; // Expose the connecting state

  // Initialize socket connection and register device
  Future<void> initialize() async {
    if (_isInitialized || _isConnecting) {
        print('SocketService: Already initialized or initializing.');
        return;
    }
    _isConnecting = true;
    print('SocketService: Initializing...');

    try {
      // 1. Get Device ID (used as tableId for registration)
      _tableId = await _getTableOrDeviceId();
      print('SocketService: Using Table/Device ID: $_tableId');

      // 2. Register Device with Backend API
      // This ensures the table exists in the backend before socket connection.
      try {
        final apiService = ApiService();
        final registrationResponse = await apiService.registerDeviceWithTable(_tableId!);
        print('SocketService: API Registration Response: $registrationResponse');
        
        // Store the MongoDB _id if returned
        if (registrationResponse.containsKey('table') && 
            registrationResponse['table'] is Map && 
            registrationResponse['table']['id'] != null) {
            _dbTableId = registrationResponse['table']['id'];
            print('SocketService: Stored DB Table ID: $_dbTableId');
        } else {
             print('SocketService: Warning - DB Table ID not found in registration response.');
        }

        // Check if a session was automatically started and store its ID
        if (registrationResponse.containsKey('session') && 
            registrationResponse['session'] != null && 
            registrationResponse['session'] is Map &&
            registrationResponse['session']['id'] != null) {
            _sessionId = registrationResponse['session']['id'];
             print('SocketService: Session automatically started via API registration. Session ID: $_sessionId');
             // Emit session started event locally since the backend might only emit via socket on initial connection
             _onSessionStartedController.add(Map<String, dynamic>.from(registrationResponse['session']));
        } else {
             print('SocketService: No session automatically started during API registration.');
             // Ensure session ID is null if not provided
             _sessionId = null;
        }
      } catch (e) {
         print('SocketService: API Device Registration failed: $e. Will attempt socket connection anyway.');
        _onErrorController.add('API Registration failed: $e');
         _isConnecting = false; // Allow re-attempt later
         // Stop initialization if API registration fails, as the table might not exist
         // return; // <<< REMOVED THIS RETURN
      }

      // 3. Connect to Socket Server --- TEMPORARILY COMMENTED OUT ---
      // print('SocketService: Connecting to Socket Server: ${AppConfig.socketServerUrl}');
      // _socket = IO.io(AppConfig.socketServerUrl, <String, dynamic>{
      //   'transports': ['websocket'],
      //   'autoConnect': false, // We manually connect
      //   'reconnection': true,
      //   'reconnectionDelay': 2000,
      //   'reconnectionAttempts': 5,
      //    // Optional: Send tableId in query if backend needs it immediately
      //    // 'query': {'clientType': 'table_app', 'tableId': _tableId}
      // });
      //
      // _setupSocketListeners();
      // _socket!.connect(); // Start connection attempt
      // --- END TEMPORARY COMMENT OUT ---

      // --- UNCOMMENT THE FOLLOWING BLOCK ---
      print('SocketService: Connecting to Socket Server: ${AppConfig.socketServerUrl}');
      _socket = IO.io(AppConfig.socketServerUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false, // We manually connect
        'reconnection': true,
        'reconnectionDelay': 2000,
        'reconnectionAttempts': 5,
         // Optional: Send tableId in query if backend needs it immediately
         // 'query': {'clientType': 'table_app', 'tableId': _tableId}
      });

      _setupSocketListeners();
      _socket!.connect(); // Start connection attempt
      // --- END UNCOMMENT BLOCK --- 

      _isInitialized = true; // Mark as initialized (connection happens async)

    } catch (e) {
      _onErrorController.add('Failed to initialize SocketService: $e');
      print('SocketService: Initialization error: $e');
       _scheduleReconnect(); // Schedule reconnect on initial failure
    } finally {
       _isConnecting = false;
    }
  }

  // Get existing table/device ID from storage or generate a new one
  Future<String> _getTableOrDeviceId() async {
      final prefs = await SharedPreferences.getInstance();
      String? storedId = prefs.getString('tableDeviceId'); // Use a specific key

      if (storedId != null && storedId.isNotEmpty) {
          print("SocketService: Found stored tableDeviceId: $storedId");
          return storedId;
      } else {
          print("SocketService: No stored tableDeviceId found. Generating new device ID.");
          String deviceId = await _generateDeviceId();
          await prefs.setString('tableDeviceId', deviceId);
          print("SocketService: Generated and stored new device ID: $deviceId");
          return deviceId;
      }
  }


  // Generate a unique device ID based on platform
  Future<String> _generateDeviceId() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String uniqueId = 'unknown_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString()}'; // Fallback
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        String? webId = prefs.getString('webDeviceId');
        if (webId == null) {
          webId = 'web_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString()}';
          await prefs.setString('webDeviceId', webId);
        }
        uniqueId = webId;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        uniqueId = "android_${androidInfo.id}"; // Use Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        uniqueId = "ios_${iosInfo.identifierForVendor ?? '${UniqueKey().toString()}'}"; // Use identifierForVendor
      } else if (Platform.isLinux) {
         final linuxInfo = await deviceInfoPlugin.linuxInfo;
         uniqueId = "linux_${linuxInfo.machineId ?? '${UniqueKey().toString()}'}";
      } else if (Platform.isMacOS) {
           final macInfo = await deviceInfoPlugin.macOsInfo;
           uniqueId = "macos_${macInfo.systemGUID ?? '${UniqueKey().toString()}'}";
      } else if (Platform.isWindows) {
          final windowsInfo = await deviceInfoPlugin.windowsInfo;
          // windowsInfo.deviceId might require specific permissions or registry access
          // Using computerName as a fallback if deviceId is empty
          uniqueId = "windows_${windowsInfo.deviceId.isNotEmpty ? windowsInfo.deviceId : windowsInfo.computerName}";
      }
    } catch (e) {
      print("SocketService: Error getting device ID: $e");
      // Keep the fallback ID
    }
    print("SocketService: Generated Device ID: $uniqueId");
    return uniqueId;
  }


  // Setup event listeners for socket events
  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('SocketService: Connected successfully. Socket ID: ${_socket?.id}');
      _onConnectedController.add(true);
      _cancelReconnect(); // Cancel any pending reconnect timers

      // Register table with the backend via socket event
      if (_tableId != null) {
        _registerTableWithSocket(_tableId!);
      } else {
         print("SocketService: Error - Table ID is null, cannot register with socket.");
         _onErrorController.add("Table ID missing, cannot register.");
      }
    });

    _socket?.onConnectError((error) {
      print('SocketService: Connection Error: $error');
      _onErrorController.add('Connection Failed: $error');
      _onConnectedController.add(false);
      _scheduleReconnect(); // Schedule reconnect on connection error
    });

    _socket?.onDisconnect((reason) {
      print('SocketService: Disconnected. Reason: $reason');
      _onConnectedController.add(false);
      _onErrorController.add('Disconnected');
       // Only schedule reconnect if it wasn't a manual disconnect
      if (reason != 'io client disconnect') {
           _scheduleReconnect();
      }
    });

    _socket?.onError((error) {
      print('SocketService: General Socket Error: $error');
      _onErrorController.add('Socket Error: $error');
      // Potentially schedule reconnect depending on the error type
    });

    // Listen for backend confirmation of table registration via socket
    _socket?.on('table_registered', (data) {
      print('SocketService: Received table_registered: $data');
      if (data is Map) {
         final eventData = Map<String, dynamic>.from(data);
         // Store/Update the MongoDB _id if provided
         if (eventData.containsKey('tableData') && eventData['tableData'] is Map && eventData['tableData'].containsKey('id')) {
            _dbTableId = eventData['tableData']['id'];
            print('SocketService: Stored/Updated DB Table ID from socket event: $_dbTableId');
         }
         _onTableRegisteredController.add(eventData);
      } else {
         print('SocketService: Warning - Received non-map data for table_registered: $data');
      }
    });

    // Listen for session start (e.g., initiated by customer app scan in the future)
    _socket?.on('session_started', (data) {
      print('SocketService: Received session_started: $data');
      if (data is Map) {
        final sessionData = Map<String, dynamic>.from(data);
        // Ensure sessionId is present and not null before updating
        if(sessionData.containsKey('sessionId') && sessionData['sessionId'] != null){
             _sessionId = sessionData['sessionId']; // Store session ID
             print('SocketService: Session started via socket. Session ID: $_sessionId');
            _onSessionStartedController.add(sessionData);
        } else {
             print('SocketService: Warning - session_started event received without a valid sessionId.');
        }
      } else {
          print('SocketService: Warning - Received non-map data for session_started: $data');
      }
    });

     // Listen for new orders added to this table's session (maybe useful for UI updates)
    _socket?.on('new_order', (data) {
      print('SocketService: Received new_order: $data');
       if (data is Map) {
         _onNewOrderController.add(Map<String, dynamic>.from(data));
       } else {
            print('SocketService: Warning - Received non-map data for new_order: $data');
       }
    });

    // Listen for session end confirmation from backend
    _socket?.on('session_ended', (data) {
      print('SocketService: Received session_ended: $data');
      if (data is Map) {
        final sessionData = Map<String, dynamic>.from(data);
        print('SocketService: Session ended via socket. Clearing session ID.');
        _sessionId = null; // Clear session ID
        _onSessionEndedController.add(sessionData);
         // UI should listen to this stream and react (e.g., navigate, show message)
      } else {
          print('SocketService: Warning - Received non-map data for session_ended: $data');
      }
    });

     // Listen for generic errors from the server communicated via socket
     _socket?.on('error', (data) {
        print('SocketService: Received server error event: $data');
        String errorMessage = 'Unknown server error';
        if (data is Map && data.containsKey('message')) {
            errorMessage = data['message'];
        } else if (data is String) {
            errorMessage = data;
        }
         _onErrorController.add('Server Error: $errorMessage');
     });
  }

  // Emit table registration event to the socket server
  void _registerTableWithSocket(String tableIdToRegister) {
    if (!isConnected) {
      _onErrorController.add('Socket not connected, cannot register');
      print('SocketService: Cannot register table, socket not connected.');
      return;
    }
    print('SocketService: Emitting register_table event for tableId: $tableIdToRegister');
    _socket?.emit('register_table', {
      'tableId': tableIdToRegister, 
      // If your backend 'register_table' listener expects the DB ID, you might need
      // to wait for the API call to finish and store _dbTableId first, or adjust the backend.
      // For now, assuming backend uses the provided tableId (device ID) to find/link.
    });
  }

   // --- Reconnection Logic ---
   void _scheduleReconnect() {
       // Don't schedule if already connecting or timer is active
       if (_isConnecting || (_reconnectTimer != null && _reconnectTimer!.isActive)) return; 

       print("SocketService: Scheduling reconnect attempt in 5 seconds...");
       _reconnectTimer = Timer(Duration(seconds: 5), () {
           print("SocketService: Attempting to reconnect...");
           if (_socket != null && !_socket!.connected) {
               _isConnecting = true; // Mark as connecting during the attempt
               _socket!.connect(); // Try connecting again
               // Reset connecting flag after a short delay, assuming connect() is async 
               // This is a simplification; robust logic might use connection events.
               Future.delayed(Duration(seconds: 2), () => _isConnecting = false);
           }
            _reconnectTimer = null; // Allow scheduling again after attempt
       });
   }

    void _cancelReconnect() {
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
         print("SocketService: Reconnect timer cancelled.");
    }

  // --- Public Methods ---

  // Method called by UI to end the current session
  void endCurrentSession() {
    if (!isConnected) {
      _onErrorController.add('Socket not connected, cannot end session');
       print('SocketService: Cannot end session, socket not connected.');
      return;
    }
    if (_sessionId == null) {
      _onErrorController.add('No active session to end');
       print('SocketService: Cannot end session, no active session ID.');
      // Maybe show a message to the user
      return;
    }
    if (_tableId == null) {
       _onErrorController.add('Table ID missing, cannot end session');
        print('SocketService: Cannot end session, table ID is null.');
       return;
    }

    print('SocketService: Emitting end_session for sessionId: $_sessionId, tableId: $_tableId');
    _socket?.emit('end_session', {
      'sessionId': _sessionId,
      'tableId': _tableId, // Send the table's unique ID (device ID)
    });
    // The actual clearing of _sessionId happens when the 'session_ended' event is received
  }

  // Method to potentially notify backend explicitly after order creation (using API).
  // Currently redundant if backend's createOrder emits to kitchen.
  void notifyOrderPlaced(String orderId) {
     if (!isConnected) {
         _onErrorController.add('Socket not connected, cannot notify order placed');
         print('SocketService: Cannot notify order placed, socket not connected.');
         return;
     }
     if (_sessionId == null || _tableId == null) {
         print('SocketService: Skipping order_placed emit - session or table ID missing.');
         return; // Cannot notify without session context
     }
     print('SocketService: Emitting order_placed for orderId: $orderId, sessionId: $_sessionId, tableId: $_tableId');
     // Note: Ensure your backend 'order_placed' listener handles this correctly if used.
     _socket?.emit('order_placed', {
         'orderId': orderId,
         'sessionId': _sessionId,
         'tableId': _tableId, // Device ID
     });
  }


  // Reinitialize connection manually (e.g., from UI button)
  Future<void> manualReconnect() async {
     print("SocketService: Manual reconnect requested.");
     _cancelReconnect();
     if (_socket != null && _socket!.connected) {
         print("SocketService: Already connected.");
         _onErrorController.add("Already connected");
         return;
     }
     if (_isConnecting) {
         print("SocketService: Already attempting to connect.");
          _onErrorController.add("Connection attempt in progress...");
         return;
     }

     _onErrorController.add("Attempting manual reconnect...");
     // If socket exists but isn't connected, try connecting it
     if (_socket != null) {
          _isConnecting = true;
          print("SocketService: Attempting manual connect...");
          _socket!.connect();
           // Reset connecting flag after a delay
           Future.delayed(Duration(seconds: 3), () => _isConnecting = false);
     } else {
         // If socket is null, try full re-initialization
         print("SocketService: Socket instance is null, attempting full re-initialization...");
         _isInitialized = false; // Reset initialization flag
          await initialize(); // Try full initialization again
     }
  }

  // Disconnect and clean up resources
  void dispose() {
     print("SocketService: Disposing...");
    _cancelReconnect();
    _socket?.off('connect');
    _socket?.off('connect_error');
    _socket?.off('disconnect');
    _socket?.off('error');
    _socket?.off('table_registered');
    _socket?.off('session_started');
    _socket?.off('new_order');
    _socket?.off('session_ended');
    _socket?.disconnect(); // Manually disconnect
    _socket?.dispose();
    _socket = null; // Ensure socket is nullified

    // Close stream controllers if they haven't been already
    if (!_onConnectedController.isClosed) _onConnectedController.close();
    if (!_onErrorController.isClosed) _onErrorController.close();
    if (!_onTableRegisteredController.isClosed) _onTableRegisteredController.close();
    if (!_onSessionStartedController.isClosed) _onSessionStartedController.close();
    if (!_onNewOrderController.isClosed) _onNewOrderController.close();
    if (!_onSessionEndedController.isClosed) _onSessionEndedController.close();

     _isInitialized = false; // Mark as not initialized
     _isConnecting = false;
     print("SocketService: Disposed.");
  }
}
