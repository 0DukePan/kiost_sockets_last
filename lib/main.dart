import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hungerz_kiosk/Pages/landingPage.dart'; // Import LandingPage
import 'dart:async'; // Import dart:async for StreamSubscription

import 'Pages/home_page.dart';
import 'Routes/routes.dart';
import 'Theme/style.dart';
import 'Services/socket_service.dart';
// import 'Services/api_service.dart'; // ApiService might not be needed directly here
import 'Config/app_config.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Not needed directly here

// GlobalKey for potential navigation needs from outside build context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.landscapeRight,
  //   DeviceOrientation.landscapeLeft,
  // ]);
  
  // Initialize Socket service 
  // No need for retry logic here, SocketService handles reconnection
  try {
     print("Main: Initializing SocketService...");
     await SocketService().initialize(); 
     print("Main: SocketService initialization process started.");
  } catch (e) {
     print("Main: Error during initial SocketService setup: $e");
     // App can still run, SocketService might reconnect or show error state
  }
  
  runApp(Phoenix(child: HungerzKiosk()));
}

// // Removed old initializeServices function
// Future<void> initializeServices() async { ... }

class HungerzKiosk extends StatefulWidget {
  @override
  _HungerzKioskState createState() => _HungerzKioskState();
}

class _HungerzKioskState extends State<HungerzKiosk> {
   final SocketService _socketService = SocketService();
   StreamSubscription? _errorSubscription;
   StreamSubscription? _sessionEndedSubscription;

   @override
   void initState() {
      super.initState();
      _listenToSocketEvents();
   }

   void _listenToSocketEvents() {
      // Listen for critical errors to show snackbar
      _errorSubscription = _socketService.onError.listen((errorMsg) {
         if (navigatorKey.currentContext != null) {
            // Check for specific errors if needed
            if (errorMsg.contains('API Registration failed') || errorMsg.contains('Connection Failed')) {
               ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                  SnackBar(content: Text(errorMsg), duration: Duration(seconds: 4), backgroundColor: Colors.red[600]),
               );
            }
             // Avoid showing every minor error as a snackbar
             print("Socket Error Listener in main: $errorMsg"); 
         }
      });

       // Listen for session end to potentially navigate back to landing/idle screen
      _sessionEndedSubscription = _socketService.onSessionEnded.listen((data) {
         print("Main: Session ended event received: $data");
         // Example: Navigate back to LandingPage when session ends
          if (navigatorKey.currentState != null) {
            // Show message about bill
             String billMessage = "Session ended.";
             if (data.containsKey('bill') && data['bill'] is Map) {
               final bill = data['bill'];
               billMessage += " Bill total: ${bill['total']} DZD.";
             }
             ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
               SnackBar(content: Text(billMessage), duration: Duration(seconds: 5)),
             );

            // Navigate back to the initial/landing page
            navigatorKey.currentState!.pushAndRemoveUntil(
               MaterialPageRoute(builder: (_) => LandingPage()), // Or your idle/QR screen
               (Route<dynamic> route) => false, // Remove all previous routes
            );
         }
      });

       // Optional: Listen for connection status if needed globally
       _socketService.onConnected.listen((isConnected) {
          print("Main: Socket Connection Status: $isConnected");
          // Optionally show a global indicator or message
       });

       // Optional: Listen for table registration success
       _socketService.onTableRegistered.listen((data) {
          print("Main: Table registered event: $data");
          // Maybe show a confirmation
           if (navigatorKey.currentContext != null && data.containsKey('success') && data['success'] == true) {
               ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                  SnackBar(content: Text("Device registered successfully."), duration: Duration(seconds: 2), backgroundColor: Colors.green[600]),
               );
           }
       });
   }

   @override
   void dispose() {
      _errorSubscription?.cancel();
      _sessionEndedSubscription?.cancel();
      // Note: SocketService().dispose() should ideally be called when the entire app is closing,
      // which is harder to determine reliably. Singleton might live for the app lifetime.
      super.dispose();
   }

   @override
   Widget build(BuildContext context) {
      return MaterialApp(
         navigatorKey: navigatorKey, // Assign the global key
         theme: appTheme,
         // Start on HomePage as the initial setup happens in main/SocketService
         // HomePage should handle showing loading/connection status initially
         home: LandingPage(), // Start with LandingPage, HomePage will be pushed
         routes: PageRoutes().routes(),
         // Optional: Add a builder to provide SocketService via InheritedWidget/Provider if needed in many places
         // builder: (context, child) => SocketProvider(service: _socketService, child: child!) 
      );
   }
}
