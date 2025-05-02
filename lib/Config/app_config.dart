class AppConfig {
  static final String appName = "Hungerz Kiosk - Table App";
  static final bool isDemoMode = true;
  
  // Base server URL - shared across all connections
  // Using your actual IP address from ipconfig
  static final String serverUrl = "http://10.0.2.2:5000";
  
  // Socket.IO server URL - Make sure this matches your server configuration
  static final String socketServerUrl = "$serverUrl";
  
  // API base URL for HTTP requests
  static final String baseUrl = "$serverUrl/api";
}
