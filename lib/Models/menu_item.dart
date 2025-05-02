import 'dart:convert';

class MenuItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? image; // Cloudinary URL or null
  final String category;
  // final Map<String, dynamic>? dietaryInfo; // Define specific fields if needed
  // final Map<String, dynamic>? healthInfo; // Define specific fields if needed
  final bool isPopular;
  final int? preparationTime;
  // final List<dynamic>? addons; // Define specific addon structure if needed
  bool isVeg; // Derived or defaulted - Need logic if not directly from backend

  // UI State - Not from backend
  int count;
  bool isSelected;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.image,
    required this.category,
    // this.dietaryInfo,
    // this.healthInfo,
    required this.isPopular,
    this.preparationTime,
    // this.addons,
    required this.isVeg, // Add requirement
    this.count = 0,
    this.isSelected = false,
  });

  // Factory constructor to parse JSON from backend
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    // Basic type checking and default values
    final priceValue = json['price'];
    double price = 0.0;
    if (priceValue is num) {
      price = priceValue.toDouble();
    } else if (priceValue is String) {
      price = double.tryParse(priceValue) ?? 0.0;
    }
    
    // Determine isVeg - Placeholder logic: Assume non-veg unless specified otherwise.
    // You might need to adjust this based on your actual `dietaryInfo` structure.
    bool isVeg = false; 
    if (json['dietaryInfo'] is Map && json['dietaryInfo']['vegetarian'] == true) {
      isVeg = true;
    }

    return MenuItem(
      id: json['id'] as String? ?? '', // Handle potential null id
      name: json['name'] as String? ?? 'Unnamed Item', // Handle potential null name
      description: json['description'] as String?,
      price: price,
      image: json['image'] as String?, // Image URL can be null
      category: json['category'] as String? ?? 'Uncategorized', // Handle potential null category
      // dietaryInfo: json['dietaryInfo'] as Map<String, dynamic>?,
      // healthInfo: json['healthInfo'] as Map<String, dynamic>?,
      isPopular: json['isPopular'] as bool? ?? false,
      preparationTime: json['preparationTime'] as int?,
      // addons: json['addons'] as List<dynamic>?,
      isVeg: isVeg, // Assign derived value
      // count and isSelected default to 0/false
    );
  }

  // Helper to parse a list of menu items
  static List<MenuItem> parseMenuItems(String responseBody) {
    try {
      final parsed = json.decode(responseBody);
      // Check if the response has the expected 'menuItems' key
      if (parsed is Map<String, dynamic> && parsed.containsKey('menuItems')) {
         final List<dynamic> itemsList = parsed['menuItems'];
         return itemsList
          .map<MenuItem>((json) => MenuItem.fromJson(json as Map<String, dynamic>))
          .toList();
      } else {
        // Handle unexpected response format
        print("Error: Unexpected JSON structure received: $parsed");
        return []; 
      }
    } catch (e) {
       print("Error parsing menu items JSON: $e");
       print("Response body: $responseBody");
       return [];
    }
  }
} 