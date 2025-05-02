import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/menu_item.dart'; // Import the model
import '../Config/app_config.dart'; // Import AppConfig

class ApiService {
  // Use baseUrl from AppConfig
  final String _baseUrl = AppConfig.baseUrl;

  // Cache to store menu items by category
  final Map<String, List<MenuItem>> _menuItemsCache = {};

  // Fetch menu items by category name
  Future<List<MenuItem>> getMenuItemsByCategory(String categoryName) async {
    // Check if the items for this category are already in cache
    if (_menuItemsCache.containsKey(categoryName)) {
      print("Returning cached items for category: $categoryName");
      return _menuItemsCache[categoryName]!;
    }

    // URL encode the category name in case it has spaces or special characters
    final encodedCategoryName = Uri.encodeComponent(categoryName);
    // Corrected endpoint path assuming routes are like /api/menu-items/...
    final Uri uri = Uri.parse('$_baseUrl/menu-items/category/$encodedCategoryName'); 

    try {
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Use the static parser from the MenuItem model which handles the nested structure
        final items = MenuItem.parseMenuItems(response.body);
        // Cache the results
        _menuItemsCache[categoryName] = items;
        return items;
      } else {
        // Handle server errors (e.g., 404 Not Found, 500 Internal Server Error)
        print("Error fetching items: ${response.statusCode} - ${response.reasonPhrase}");
        print("Response body for items: ${response.body}");
        // Throw an exception to be caught in the UI layer
        throw Exception('Failed to load menu items for category $categoryName (Status code: ${response.statusCode})');
      }
    } catch (e) {
      // Handle network errors or parsing errors
      print("Network or parsing error fetching items: $e");
      // Re-throw the exception
      throw Exception('Failed to load menu items. Check network connection and backend status.');
    }
  }

  // Clear cache for a specific category or all categories
  void clearCache({String? categoryName}) {
    if (categoryName != null) {
      _menuItemsCache.remove(categoryName);
    } else {
      _menuItemsCache.clear();
    }
  }

  // Fetch all unique category names (Assuming backend endpoint exists)
  Future<List<String>> getAllCategories() async {
    // Assuming the endpoint is /api/menu-items/categories or similar
    final Uri uri = Uri.parse('$_baseUrl/menu-items/categories'); // Adjust if needed
    print("Fetching categories from: $uri");

    try {
      final response = await http.get(uri);
      print("Response status code for categories: ${response.statusCode}");

      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        // Adjust parsing based on actual backend response structure
        // Example structure: { "categories": ["Burger", "Pizza", ...] }
        if (parsed is Map<String, dynamic> && parsed.containsKey('categories')) {
          final List<dynamic> categoryList = parsed['categories'];
          // Ensure all elements are strings
          return categoryList.map((category) => category.toString()).toList(); 
        } else {
          // Handle case where backend might return a simple list: ["Burger", "Pizza"]
          if (parsed is List) {
             return parsed.map((category) => category.toString()).toList();
          }
          print("Error: Unexpected JSON structure for categories: $parsed");
          throw Exception('Failed to parse categories: Unexpected JSON structure');
        }
      } else {
        print("Error fetching categories: ${response.statusCode} - ${response.reasonPhrase}");
        print("Response body for categories: ${response.body}");
        throw Exception('Failed to load categories (Status code: ${response.statusCode})');
      }
    } catch (e) {
      print("Network or parsing error fetching categories: $e");
      throw Exception('Failed to load categories. Check network connection and backend status.');
    }
  }

  // Create an order in the backend (Modified for Kiosk Flow)
  Future<Map<String, dynamic>> createOrder({
    // String? userId, // Removed userId
    required List<MenuItem> items,
    required String orderType,
    required String? tableId, // Added tableId (device ID)
    // String? sessionId, // Removed sessionId
  }) async {
    final Uri uri = Uri.parse('$_baseUrl/orders');
    
    // Format items as required by the backend
    final formattedItems = items.map((item) => {
      'menuItemId': item.id,
      'quantity': item.count,
      // Add specialInstructions if your MenuItem model supports it
    }).toList();
    
    // Create request body 
    final Map<String, dynamic> requestBody = {
      'items': formattedItems,
      'orderType': orderType, // e.g., "Dine In" or "Take Away"
      'tableId': tableId,     // Pass the device ID as tableId
      // No userId or sessionId needed for this flow
    };
    
    print("ApiService: Sending order to server: ${jsonEncode(requestBody)}");
    
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      
      print("ApiService: Order response status: ${response.statusCode}");
      print("ApiService: Order response body: ${response.body}");
      
      if (response.statusCode == 201) {
         final responseBody = jsonDecode(response.body);
         // Ensure the response contains the expected structure
         if (responseBody is Map<String, dynamic> && responseBody.containsKey('order')) {
             return responseBody; // Return the full response which includes the order details
         } else {
             throw Exception('Failed to create order: Invalid response format from server.');
         }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception('Failed to create order: ${errorBody['message'] ?? 'Unknown error'} (Status: ${response.statusCode})');
      }
    } catch (e) {
      print("ApiService: Error creating order: $e");
      // Rethrow specific error or a generic one
      throw Exception('Failed to create order. Check network connection and backend status. Error: $e');
    }
  }
  
  // Register device with table using the specific backend endpoint
  Future<Map<String, dynamic>> registerDeviceWithTable(String tableDeviceId) async {
    // Use the correct endpoint from table.route.js
    final Uri uri = Uri.parse('$_baseUrl/tables/register-device-with-table'); 
    print("ApiService: Registering device $tableDeviceId at $uri");
    
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    String requestBody = jsonEncode({'tableId': tableDeviceId});
    http.Response? response; // Declare response outside try

    try {
      // --- Inner Try for HTTP Post ---
      try {
         response = await http.post(
           uri,
           headers: headers,
           body: requestBody,
         ).timeout(Duration(seconds: 10)); // Add a timeout
      } catch (networkError) {
          print("ApiService: Network Error during device registration POST: $networkError");
          // Return an error map instead of throwing
          return {
            'success': false,
            'message': 'Network Error: Failed to connect to server. $networkError'
          };
      }
      // --- End Inner Try ---
      
      // --- Log Full Response Details REGARDLESS of status code ---
      print("ApiService: Raw Registration Response Status: ${response?.statusCode}");
      print("ApiService: Raw Registration Response Body: ${response?.body}");
      // --- End Logging ---
      
      if (response != null && response.statusCode == 200) {
        final decodedBody = jsonDecode(response.body);
         if (decodedBody is Map<String, dynamic>) {
            print("ApiService: Device registration successful (Status 200).");
            return decodedBody; // Return successful response
         } else {
            print("ApiService: Error - Invalid success response format (Status 200).");
            // Return an error map
            return {
              'success': false,
              'message': 'API Error: Invalid response format from server on success.'
            };
         }
      } else {
         // Handle non-200 status codes
         String errorMessage = 'Unknown error';
         int? statusCode = response?.statusCode;
         try {
            // Try to decode error message from body
            final errorBody = jsonDecode(response?.body ?? '{}');
            if (errorBody is Map && errorBody.containsKey('message')) {
               errorMessage = errorBody['message'];
            } else {
               errorMessage = response?.reasonPhrase ?? 'Failed to register device';
            }
         } catch (e) {
            // Handle cases where the error response body is not JSON
            errorMessage = response?.reasonPhrase ?? 'Failed to register device (non-JSON error body)';
         }
         print("ApiService: Error - Device registration failed. Status: $statusCode, Message: $errorMessage");
         // Return an error map
         return {
           'success': false,
           'message': 'API Error: $errorMessage (Status: $statusCode)'
         };
      }
    } catch (e) {
      // Catch potential JSON decoding errors or other unexpected errors
      print("ApiService: Unexpected Error during device registration processing: $e");
      // Return an error map
      return {
        'success': false,
        'message': 'App Error: Unexpected error processing registration response. $e'
      };
    }
  }

  // Potential future methods:
  // Future<List<MenuItem>> getAllMenuItems() async { ... }
  // Future<MenuItem> getMenuItemDetails(String itemId) async { ... }
} 