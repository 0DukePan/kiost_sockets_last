import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:hungerz_kiosk/Pages/orderPlaced.dart';
import 'package:hungerz_kiosk/Pages/item_info.dart';
import '../Components/custom_circular_button.dart';
import '../Theme/colors.dart';
import '../Models/menu_item.dart'; // Import MenuItem model
import '../Services/api_service.dart'; // Import ApiService
import '../Services/socket_service.dart';
import 'dart:async'; // Import for Future & StreamSubscription
import 'package:shimmer/shimmer.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Not needed directly

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

// Keep ItemCategory for the hardcoded list driving the UI
class ItemCategory {
  String image;
  String? name;

  ItemCategory(this.image, this.name);
}

class _HomePageState extends State<HomePage> {
  // Service instances
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService(); // Use singleton instance

  // State variables for fetched data, loading, and errors
  List<MenuItem> _displayedItems = [];
  Map<String, List<MenuItem>> _cachedItems = {}; 
  bool _isLoading = false;
  String? _fetchErrorMessage;

  int orderingIndex = 0; // 0 for Take Away, 1 for Dine In
  bool itemSelected = false; // Tracks if any item has count > 0
  MenuItem? _itemForInfoDrawer;
  int drawerCount = 0; // 0 for cart drawer, 1 for item info
  int currentIndex = 0; // For category selection
  PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  // State variables for socket connection and session
  bool _socketConnected = false;
  String? _socketErrorMsg;
  String? _currentSessionId; // Track session ID locally in the page state
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _errorSubscription;
  StreamSubscription? _sessionStartSubscription;
  StreamSubscription? _sessionEndSubscription;

  String? _currentlyFetchingCategory; // Add this line

  final List<ItemCategory> foodCategories = [
    ItemCategory('assets/ItemCategory/burger.png', "burgers"),
    ItemCategory('assets/ItemCategory/pizza.png', "pizzas"),
    ItemCategory('assets/ItemCategory/pates.png', "pates"),
    ItemCategory('assets/ItemCategory/kebbabs.png', "kebabs"),
    ItemCategory('assets/ItemCategory/tacos.png', "tacos"),
    ItemCategory('assets/ItemCategory/poulet.png', "poulet"),
    ItemCategory('assets/ItemCategory/healthy.png', "healthy"),
    ItemCategory('assets/ItemCategory/traditional.png', "traditional"),
    ItemCategory('assets/ItemCategory/dessert.png', "dessert"),
    ItemCategory('assets/ItemCategory/sandwitch.jpg', "sandwich"),
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize local state from SocketService
    _socketConnected = _socketService.isConnected;
    _currentSessionId = _socketService.sessionId;

    // Listen to socket events to update local state
    _listenToSocketEvents();
    
    // Fetch the first category when the page loads
    if (foodCategories.isNotEmpty && foodCategories[0].name != null) {
      _fetchMenuItems(foodCategories[0].name!);
    } else {
       // Handle case where categories might be empty or first category name is null
       setState(() {
          _isLoading = false;
          _fetchErrorMessage = "No categories defined.";
       });
    }
  }

  void _listenToSocketEvents() {
     _connectionSubscription = _socketService.onConnected.listen((isConnected) {
        if (mounted) {
           setState(() {
              _socketConnected = isConnected;
              _socketErrorMsg = isConnected ? null : (_socketErrorMsg ?? 'Disconnected'); // Clear error on connect
           });
        }
     });

     _errorSubscription = _socketService.onError.listen((error) {
         if (mounted) {
            setState(() {
               _socketErrorMsg = error;
               // Potentially set _socketConnected to false depending on error type
               if (error.contains('Connection Failed') || error.contains('Disconnected')){
                  _socketConnected = false;
               }
            });
            // Show snackbar for important errors
             if (error.contains('Failed') || error.contains('Error')){
                 ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(error), duration: Duration(seconds: 3), backgroundColor: Colors.orange[700]),
                 );
             }
         }
     });

     _sessionStartSubscription = _socketService.onSessionStarted.listen((data) {
         if (mounted && data.containsKey('sessionId')) {
            setState(() {
               _currentSessionId = data['sessionId'];
            });
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Session Started: ${_currentSessionId}'), duration: Duration(seconds: 2), backgroundColor: Colors.green[600]),
            );
         }
     });

     _sessionEndSubscription = _socketService.onSessionEnded.listen((data) {
         if (mounted) {
            setState(() {
               _currentSessionId = null; // Clear session ID locally
               _cancelOrder(); // Clear the cart when session ends
            });
             String billMessage = "Session Ended.";
             if (data.containsKey('bill') && data['bill'] is Map) {
               final bill = data['bill'];
               billMessage += " Bill: ${bill['total']} DZD.";
             }
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text(billMessage), duration: Duration(seconds: 5)),
             );
            // Optionally navigate away or reset UI further
            // Consider navigating back to LandingPage or showing a "Session Ended" overlay
         }
     });
  }

  // Method to fetch menu items for a given category NAME
  Future<void> _fetchMenuItems(String categoryName) async {
    print("HomePage: Attempting to fetch items for category: $categoryName"); // Log call
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _fetchErrorMessage = null;
    });

    // --- Add this line ---
    // Immediately mark this category as the one we are now fetching.
    _currentlyFetchingCategory = categoryName;
    // --- End Add ---

    try {
      final items = await _apiService.getMenuItemsByCategory(categoryName);
      print("HomePage: Fetched ${items.length} items for $categoryName"); // Log success
      
      if (!mounted) return;

      // --- Add this check ---
      // Only update state if the result is for the category we are currently interested in.
      if (categoryName != _currentlyFetchingCategory) {
         print("HomePage: Ignoring stale fetch result for $categoryName (current: $_currentlyFetchingCategory)");
         return; // Don't update state with old data
      }
      // --- End Add ---

      setState(() {
        _displayedItems = items;
        // Update local cache only if category doesn't exist or needs refresh
        if (!_cachedItems.containsKey(categoryName)) {
          _cachedItems[categoryName] = items;
        } else {
           // Optional: Merge or replace based on your caching strategy
           _cachedItems[categoryName] = items; 
        }
        _isLoading = false;
        _fetchErrorMessage = null;
        _updateCartStatus(); // Update cart status after fetching
      });
    } catch (e) {
       print("HomePage: Error fetching items for $categoryName: $e"); // Log error
       if (!mounted) return;

       // --- Add this check (optional but good practice) ---
       // Only show error if it's for the currently targeted category
       if (categoryName != _currentlyFetchingCategory) {
            print("HomePage: Ignoring stale fetch error for $categoryName (current: $_currentlyFetchingCategory)");
            return; 
       }
       // --- End Add ---

       setState(() {
        _fetchErrorMessage = "Failed to load items. ${e.toString()}"; 
        _isLoading = false;
        _displayedItems = []; // Clear items on error
        _updateCartStatus();
      });
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error fetching items: $_fetchErrorMessage"), duration: Duration(seconds: 3))
          );
      }
    }
  }

  // --- Helper functions (updateItemState, getAllItemsInCart, etc.) remain the same ---
   void _updateItemState(MenuItem item, Function(MenuItem foundItem) updateAction) {
    // Find the item in the cache and update it
    if (_cachedItems.containsKey(item.category)) {
      var categoryList = _cachedItems[item.category]!;
      int itemIndex = categoryList.indexWhere((cachedItem) => cachedItem.id == item.id);
      
      if (itemIndex != -1) {
        updateAction(categoryList[itemIndex]);
      } else {
        // If not in cache (shouldn't happen with current flow), update the item directly
        updateAction(item);
      }
    } else {
       // If category not even in cache, update item directly
       updateAction(item);
    }
    // Update the displayed list if the modified item is currently displayed
    int displayedIndex = _displayedItems.indexWhere((dispItem) => dispItem.id == item.id);
    if (displayedIndex != -1) {
       // This ensures the UI reflects changes immediately if the item is visible
       // updateAction should have already modified the instance in _displayedItems
       // if it came from the _cachedItems reference.
    }
    _updateCartStatus(); // Recalculate cart status
  }

   List<MenuItem> _getAllItemsInCart() {
    List<MenuItem> itemsInCart = [];
    _cachedItems.values.forEach((categoryItems) {
      itemsInCart.addAll(categoryItems.where((item) => item.count > 0));
    });
    final itemIds = itemsInCart.map((item) => item.id).toSet();
    itemsInCart.retainWhere((item) => itemIds.remove(item.id)); 
    return itemsInCart;
  }

  int calculateTotalItems() {
    int total = 0;
    _cachedItems.values.forEach((categoryItems) {
      total += categoryItems.fold(0, (sum, item) => sum + item.count);
    });
    return total;
  }

  double calculateTotalAmount() {
    double total = 0.0;
     _cachedItems.values.forEach((categoryItems) {
        total += categoryItems.fold(0.0, (sum, item) => sum + item.price * item.count);
     });
     return total;
  }

  void _updateCartStatus() {
    if (mounted) {
      setState(() {
        itemSelected = calculateTotalItems() > 0;
      });
    }
  }

  void _cancelOrder() {
     if(mounted){
        setState(() {
           _cachedItems.forEach((key, itemList) {
             for (var item in itemList) {
               item.count = 0;
               item.isSelected = false;
             }
           });
            _displayedItems.forEach((item) { 
               item.count = 0;
               item.isSelected = false;
            });
           _updateCartStatus(); 
        });
     }
  }

  // --- Callbacks for ItemInfoPage --- 
  void _incrementItemFromInfo(MenuItem item) {
    if(mounted){
       setState(() {
         _updateItemState(item, (foundItem) {
           foundItem.count++;
           foundItem.isSelected = true;
         });
       });
    }
  }

  void _decrementItemFromInfo(MenuItem item) {
    if(mounted){
       setState(() {
         _updateItemState(item, (foundItem) {
           if (foundItem.count > 0) {
             foundItem.count--;
             if (foundItem.count == 0) {
               foundItem.isSelected = false;
             }
           }
         });
       });
    }
  }
  // --- End Callbacks ---

  @override
  Widget build(BuildContext context) {
    final List<MenuItem> itemsInCart = _getAllItemsInCart(); 

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Drawer(
        child: drawerCount == 1
            ? (_itemForInfoDrawer != null
                ? ItemInfoPage(
                    menuItem: _itemForInfoDrawer!,
                    onIncrement: () => _incrementItemFromInfo(_itemForInfoDrawer!),
                    onDecrement: () => _decrementItemFromInfo(_itemForInfoDrawer!),
                  )
                : Center(child: Text("Error: Item data missing.")))
            : cartDrawer(itemsInCart),
      ),
      appBar: AppBar(
         actions: [
           _buildSocketStatusIndicator(), // Add status indicator
           _buildRetryConnectionButton(), // Add retry button
           SizedBox(width: 16),
         ],
        toolbarHeight: 100,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              // Show Table ID if available
              "Table ID: ${_socketService.tableId ?? 'Registering...'}",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontSize: 14, color: Colors.grey[700]),
            ),
             SizedBox(height: 4),
            Text(
              // Show Session ID if active
              "Session: ${_currentSessionId ?? 'Inactive'}", 
              style: Theme.of(context)
                  .textTheme
                  .titleMedium!
                  .copyWith(fontSize: 14, color: _currentSessionId != null ? Colors.blue[700] : Colors.grey[700]),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Scroll to choose your item",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium!
                        .copyWith(fontSize: 13, color: strikeThroughColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xffFFF3C4), 
                  Color(0xffFFFCF0), 
                ],
                stops: [0.0, 0.7],
              ),
            ),
            child: Row(
              children: [
                // Category List View
                Container(
                  width: 90,
                  child: ListView.builder(
                      physics: BouncingScrollPhysics(),
                      itemCount: foodCategories.length,
                      itemBuilder: (context, index) {
                        final category = foodCategories[index];
                        return InkWell(
                          onTap: () {
                             if (category.name != null) {
                              _pageController.animateToPage(
                                index,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                              setState(() {
                                currentIndex = index;
                              });
                              _fetchMenuItems(category.name!);
                             } else {
                                 print("Error: Category name is null at index $index");
                                 ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(content: Text("Invalid category selected."))
                                 );
                             }
                          },
                          child: Container(
                            height: 90,
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: currentIndex == index
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).scaffoldBackgroundColor,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center, 
                              children: [
                                Spacer(),
                                FadedScaleAnimation(
                                  child: Image.asset(
                                    category.image, 
                                    scale: 3.5,
                                    errorBuilder: (context, error, stackTrace) => Icon(Icons.error, size: 30),
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  category.name?.toUpperCase() ?? 'ERR',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                                Spacer(),
                              ],
                            ),
                          ),
                        );
                      }),
                ),
                // PageView for displaying items
                Expanded(
                  child: PageView.builder(
                    physics: BouncingScrollPhysics(),
                    controller: _pageController,
                    itemCount: foodCategories.length, 
                    onPageChanged: (index) {
                      final categoryName = foodCategories[index].name;
                       if (mounted) {
                          setState(() {
                             currentIndex = index;
                          });
                       }
                      if (categoryName != null) {
                        _fetchMenuItems(categoryName); 
                      } else {
                          if (mounted) {
                             setState(() {
                                _isLoading = false;
                                _fetchErrorMessage = "Selected category is invalid.";
                                _displayedItems = [];
                                _updateCartStatus();
                             });
                          }
                      }
                    },
                    itemBuilder: (context, pageIndex) {
                      if (pageIndex == currentIndex) {
                          if (_isLoading) {
                             return _buildLoadingIndicator();
                          }
                          if (_fetchErrorMessage != null) {
                             return _buildErrorDisplay(_fetchErrorMessage!);
                          }
                          if (_displayedItems.isEmpty) {
                             return _buildEmptyCategoryDisplay();
                          }
                          // Render the grid
                          return buildItemGrid(_displayedItems);
                      } else {
                          // Show simple loading for non-active pages
                          return Center(child: CircularProgressIndicator());
                      }
                    }
                  ),
                ),
              ],
            ),
          ),
          // Bottom Bar 
          Align(
             alignment: Alignment.bottomCenter,
             child: Container(
               alignment: Alignment.bottomCenter,
               height: 100,
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                 gradient: LinearGradient(
                   begin: Alignment.bottomCenter,
                   end: Alignment.topCenter,
                   colors: [
                     Theme.of(context).primaryColor,
                     transparentColor,
                   ],
                 ),
               ),
               child: Padding(
                 padding: const EdgeInsets.symmetric(horizontal: 15),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: [
                     // Cancel Order Button
                     if (itemSelected)
                       GestureDetector(
                         onTap: _cancelOrder,
                         child: Text(
                           "Cancel Order",
                           style: Theme.of(context)
                               .textTheme
                               .bodyLarge!
                               .copyWith(fontSize: 17, color: Colors.white),
                         ),
                       ),
                       
                     // End Session Button (Show if session is active)
                     if (_currentSessionId != null)
                         _buildEndSessionButton(), // Add End Session Button
                         
                      Spacer(), // Push review button to the right
                         
                     // Review Order Button (Show if items are selected)
                     if (itemSelected)
                        buildItemsInCartButton(context, calculateTotalItems()),

                     // If nothing selected and no active session, maybe show a message or leave empty
                     if (!itemSelected && _currentSessionId == null) 
                        SizedBox.shrink(), // Or Text("Select items to start")
                        
                   ],
                 ),
               ),
             ),
           )
        ],
      ),
    );
  }

  // -- Build Widgets for PageView states --
  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadedSlideAnimation(
            child: Text("Loading delicious items..."),
            beginOffset: Offset(0.0, 0.3), 
            endOffset: Offset(0, 0),
            slideCurve: Curves.linearToEaseOut, // Add a curve
          ),
          SizedBox(height: 24),
          Shimmer.fromColors(
             baseColor: Colors.grey[300]!,
             highlightColor: Colors.grey[100]!,
             child: GridView.builder(/* ... shimmer grid code ... */
               shrinkWrap: true,
               physics: NeverScrollableScrollPhysics(),
               padding: EdgeInsetsDirectional.only(top: 6, bottom: 100, start: 16, end: 32),
               itemCount: 4, // Show 4 shimmer items
               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                 crossAxisCount: 2,
                 crossAxisSpacing: 16,
                 mainAxisSpacing: 16,
                 childAspectRatio: 0.75,
               ),
               itemBuilder: (context, index) {
                 return Container(
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(10),
                     color: Colors.white,
                   ),
                   // Simplified shimmer item structure
                   child: Column(
                     children: [
                       Expanded(flex: 3, child: Container(color: Colors.white)), // Image area
                       Padding(padding: EdgeInsets.all(8), child: Container(height: 16, color: Colors.white)), // Title
                       Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Container(height: 16, width: 80, color: Colors.white)), // Price
                     ],
                   ),
                 );
               },
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(String message) {
     return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
           SizedBox(height: 16),
           Text("Error: $message", textAlign: TextAlign.center),
           SizedBox(height: 16),
            // Add a retry button for fetch errors
           if (message.contains("Failed to load items"))
              ElevatedButton.icon(
                 icon: Icon(Icons.refresh),
                 label: Text("Retry Fetch"),
                 onPressed: () {
                   if(foodCategories.isNotEmpty && currentIndex < foodCategories.length && foodCategories[currentIndex].name != null){
                     _fetchMenuItems(foodCategories[currentIndex].name!);
                   }
                 },
                 style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
              )
         ],
       ),
     );
  }

  Widget _buildEmptyCategoryDisplay() {
    return Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
           SizedBox(height: 16),
           Text("No items available in this category"),
         ],
       ),
     );
  }
  // -- End Build Widgets --


  // Review Order Button builder
  CustomButton buildItemsInCartButton(BuildContext context, int itemCount) {
    return CustomButton(
      onTap: () {
         if (itemCount > 0) {
            setState(() {
               drawerCount = 0; // Ensure cart drawer is shown
            });
            _scaffoldKey.currentState!.openEndDrawer();
         } else {
             ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text("Your cart is empty."), duration: Duration(seconds: 2))
             );
         }
      },
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      title: Row(
        children: [
          Text(
            "Review Order ($itemCount)",
            style:
                Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 17, color: Colors.white),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white,
          )
        ],
      ),
      bgColor: buttonColor,
    );
  }

  // Item Grid builder (Structure remains similar, ensure correct state usage)
  Widget buildItemGrid(List<MenuItem> itemsToDisplay) {
    return GridView.builder(
      physics: BouncingScrollPhysics(),
      padding:
          EdgeInsetsDirectional.only(top: 6, bottom: 100, start: 16, end: 32),
      itemCount: itemsToDisplay.length, 
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75),
      itemBuilder: (context, index) {
        final item = itemsToDisplay[index];
        // Find the corresponding item in the cache to ensure we modify the correct instance
        MenuItem? cachedItemRef = _cachedItems[item.category]?.firstWhere((ci) => ci.id == item.id, orElse: () => item);
        
        return Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).scaffoldBackgroundColor),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 35,
                child: GestureDetector(
                  onTap: () {
                     if (mounted) {
                        setState(() {
                           _updateItemState(cachedItemRef ?? item, (foundItem) {
                             // Toggle selection logic
                             foundItem.isSelected = !foundItem.isSelected; 
                             if (foundItem.isSelected && foundItem.count == 0) {
                               foundItem.count = 1; // Add one when selecting
                             } else if (!foundItem.isSelected) {
                               foundItem.count = 0; // Reset count when deselecting
                             }
                           });
                        });
                     }
                  },
                  child: Stack(
                    children: [
                      Container(
                           decoration: BoxDecoration(
                           borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                        ),
                        child: ClipRRect(
                           borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                           child: FadedScaleAnimation(
                              child: item.image != null && item.image!.isNotEmpty
                                ? Image.network(
                                    item.image!, 
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(child: CircularProgressIndicator());
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                       return Container(color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[500], size: 40,)); 
                                    },
                                  )
                                : Container(color: Colors.grey[200], child: Icon(Icons.image_not_supported, color: Colors.grey[500], size: 40,)), 
                           ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                            icon: Icon(Icons.info_outline, color: Colors.grey.shade400, size: 18),
                            onPressed: () {
                               if(mounted){
                                  setState(() {
                                     _itemForInfoDrawer = item; 
                                     drawerCount = 1;
                                  });
                                  _scaffoldKey.currentState!.openEndDrawer();
                               }
                            }),
                      ),
                      // Add/Remove Controls Overlay
                      if (item.count > 0) // Show only if count > 0
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container( 
                                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                        onTap: () {
                                           if(mounted){
                                              setState(() {
                                                 _updateItemState(cachedItemRef ?? item, (foundItem) {
                                                    if (foundItem.count > 0) {
                                                       foundItem.count--;
                                                       if (foundItem.count == 0) {
                                                          foundItem.isSelected = false;
                                                       }
                                                    }
                                                 });
                                              });
                                           }
                                        },
                                        child: Icon(Icons.remove, color: Colors.white, size: 24)),
                                    SizedBox(width: 12),
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: Text(
                                        item.count.toString(),
                                        style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    GestureDetector(
                                        onTap: () {
                                           if(mounted){
                                              setState(() {
                                                 _updateItemState(cachedItemRef ?? item, (foundItem) {
                                                   foundItem.count++;
                                                   foundItem.isSelected = true; 
                                                 });
                                              });
                                           }
                                        },
                                        child: Icon(Icons.add, color: Colors.white, size: 24)),
                                  ],
                                ),
                              ),
                            ),
                          )
                    ],
                  ),
                ),
              ),
              // Item Name and Price
              Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Spacer(flex: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Image.asset(
                      item.isVeg ? 'assets/ic_veg.png' : 'assets/ic_nonveg.png',
                      scale: 2.8,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.price.toStringAsFixed(2) + ' DZD',
                        style: TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(flex: 5),
            ],
          ),
        );
      },
    );
  }

  // Cart Drawer (Structure remains similar)
  Widget cartDrawer(List<MenuItem> itemsInCart) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
             // Header
             Padding(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text("My Order", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                     SizedBox(height: 5),
                     Text("Quick Checkout", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                   ],
                ),
             ),
            Expanded(
              child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  itemCount: itemsInCart.length,
                  itemBuilder: (context, index) {
                    final cartItem = itemsInCart[index];
                    MenuItem? cachedCartItemRef = _cachedItems[cartItem.category]?.firstWhere((ci) => ci.id == cartItem.id, orElse: () => cartItem);

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: cartItem.image != null && cartItem.image!.isNotEmpty
                              ? Image.network(cartItem.image!, width: 60, height: 60, fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey[200], child: Icon(Icons.broken_image)),
                                  loadingBuilder: (context, child, prog) => prog == null ? child : Container(width: 60, height: 60, child: Center(child: CircularProgressIndicator())))
                              : Container(width: 60, height: 60, color: Colors.grey[200], child: Icon(Icons.image_not_supported)),
                          ),
                          title: Row(
                             children: [
                               Expanded(child: Text(cartItem.name, style: TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis)),
                               Image.asset(cartItem.isVeg ? 'assets/ic_veg.png' : 'assets/ic_nonveg.png', height: 14),
                             ],
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade300, width: 1)
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                         if(mounted){
                                            setState(() {
                                              _updateItemState(cachedCartItemRef ?? cartItem, (foundItem) {
                                                 if (foundItem.count > 0) foundItem.count--;
                                                 if (foundItem.count == 0) foundItem.isSelected = false;
                                              });
                                            });
                                         }
                                      },
                                      child: Icon(Icons.remove, color: Theme.of(context).primaryColor, size: 18)
                                    ),
                                    SizedBox(width: 10),
                                    Text(cartItem.count.toString(), style: TextStyle(fontSize: 14)),
                                    SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () {
                                        if(mounted){
                                           setState(() {
                                              _updateItemState(cachedCartItemRef ?? cartItem, (foundItem) {
                                                 foundItem.count++;
                                                 foundItem.isSelected = true;
                                              });
                                           });
                                        }
                                      },
                                      child: Icon(Icons.add, color: Theme.of(context).primaryColor, size: 18)
                                    ),
                                  ],
                                ),
                              ),
                              Spacer(),
                              Text(cartItem.price.toStringAsFixed(2) + ' DZD', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500))
                            ],
                          ),
                        ),
                        Divider(thickness: 0.5),
                      ],
                    );
                  }
              ),
            ),
            // Bottom Summary Section
            Container(
               padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(height: 1, thickness: 0.5),
                    Padding(
                     padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
                     child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                           padding: EdgeInsets.only(bottom: 10),
                           child: Text("Choose Ordering Method", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
                        ),
                        orderingMethod() // Keep ordering method selector
                      ],
                    ),
                   ),
                    Divider(height: 1, thickness: 0.5),
                    ListTile(
                      tileColor: Theme.of(context).colorScheme.surface,
                      title: Text("Total Amount", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700)),
                      trailing: Text(
                       calculateTotalAmount().toStringAsFixed(2) + ' DZD',
                       style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.blueGrey.shade900, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    FadedScaleAnimation(
                     child: CustomButton(
                        onTap: () {
                         if (calculateTotalItems() > 0) {
                           // Check connection before placing order
                           if(!_socketConnected){
                              ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text('Cannot place order: Not connected to server.'), backgroundColor: Colors.red[600])
                              );
                              return;
                           }
                           _placeOrder(); // Call updated place order method
                         } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Please add items to your order first.'), duration: Duration(seconds: 2))
                            );
                         }
                        },
                        padding: EdgeInsets.symmetric(vertical: 12),
                        margin: EdgeInsets.symmetric(vertical: 15, horizontal: 60),
                        title: Text("Place Order", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                        bgColor: buttonColor,
                        borderRadius: 8,
                      ),
                   ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // orderingMethod remains the same
  Widget orderingMethod() {
    return Row(
       mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _buildOrderingButton(0, "Take Away", "assets/ic_takeaway.png")),
          SizedBox(width: 10),
          Expanded(child: _buildOrderingButton(1, "Dine In", "assets/ic_dine in.png")),
        ],
    );
  }

   Widget _buildOrderingButton(int index, String title, String imagePath) {
      bool selected = orderingIndex == index;
      return GestureDetector(
         onTap: () => setState(() => orderingIndex = index),
         child: Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
            height: 65,
            decoration: BoxDecoration(
               color: selected ? Color(0xffFFEEC8) : Colors.grey.shade100,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(
                  color: selected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                  width: selected ? 1.5 : 1.0
               ),
            ),
            child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                  Image.asset(imagePath, height: 24),
                  SizedBox(width: 8),
                  Text(title, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
               ],
            ),
         ),
      );
   }

  // --- MODIFIED: Place Order Method ---
  Future<void> _placeOrder() async {
    // Ensure we have items and a table ID
    if (!itemSelected) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select items.")));
      return;
    }
    if (_socketService.tableId == null) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Table not registered. Cannot place order.")));
       return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Placing Order..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final itemsInCart = _getAllItemsInCart();
      final String orderType = orderingIndex == 0 ? 'Take Away' : 'Dine In';
      final String? currentTableId = _socketService.tableId; // Get the device ID used for registration

      // Call ApiService to create the order, passing the tableId (device ID)
      final orderResponse = await _apiService.createOrder(
        items: itemsInCart,
        orderType: orderType,
        tableId: currentTableId,
        // No userId or sessionId sent from tablet
      );
      
      // Close the loading dialog
      Navigator.pop(context); 

      // Backend handles notifying kitchen via socket. 
      // Tablet doesn't need to explicitly emit 'order_placed' for kitchen.
      // Optional: We could call socketService.notifyOrderPlaced(orderId) if other clients need this event.
      // String orderId = orderResponse['order']?['id'] ?? 'unknown';
      // _socketService.notifyOrderPlaced(orderId); 
      
      // Navigate to order placed screen
      String orderIdString = orderResponse['order']?['id']?.toString() ?? '';
      // Attempt to parse an order number (e.g., last 4 digits) - adapt as needed
      int? orderNum = int.tryParse(orderIdString.length > 4 ? orderIdString.substring(orderIdString.length - 4) : orderIdString);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderPlaced(
            orderId: orderIdString,
            orderNumber: orderNum,
            totalAmount: calculateTotalAmount(),
          ),
        ),
      );
      
      // Reset cart after successful order
      _cancelOrder();
      
    } catch (e) {
       // Close the loading dialog on error
       Navigator.pop(context);
       print("Error placing order: $e");
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text("Error placing order: ${e.toString()}"), backgroundColor: Colors.red[600])
       );
    }
  }
  // --- END MODIFIED Place Order ---
  
  // --- MODIFIED: End Session Method ---
  void _endSession() {
    if (_currentSessionId == null) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No active session to end.")));
       return;
    }
    if (!_socketConnected) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Not connected to server. Cannot end session.")));
       return;
    }

     // Show confirmation dialog
     showDialog(
        context: context,
        builder: (BuildContext context) {
           return AlertDialog(
              title: Text("End Session?"),
              content: Text("Are you sure you want to end the current session? This will generate the bill."),
              actions: <Widget>[
                 TextButton(
                    child: Text("Cancel"),
                    onPressed: () => Navigator.of(context).pop(), // Close dialog
                 ),
                 TextButton(
                    child: Text("End Session", style: TextStyle(color: Colors.red)),
                    onPressed: () {
                       Navigator.of(context).pop(); // Close dialog
                       print("HomePage: Calling socketService.endCurrentSession()");
                       _socketService.endCurrentSession(); // Send end_session event via socket
                       // UI update (clearing _currentSessionId, etc.) happens when session_ended event is received
                    },
                 ),
              ],
           );
        },
     );
  }
  // --- END MODIFIED End Session ---
  
  // Button to end session
  Widget _buildEndSessionButton() {
    // Show button only if a session is active
    return _currentSessionId != null
      ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: CustomButton(
             title: Text("End Session", style: TextStyle(color: Colors.white, fontSize: 17)),
             bgColor: Colors.orange[700],
             onTap: _endSession, // Call the modified end session method
             padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
             margin: EdgeInsets.symmetric(vertical: 10),
             borderRadius: 8,
          ),
        )
      : SizedBox.shrink(); // Don't show if no active session
  }
  
  // --- Socket Status Indicators and Helpers ---
  Widget _buildSocketStatusIndicator() {
    IconData icon;
    Color color;
    String text;

    if (_socketService.isConnecting) { 
        icon = Icons.wifi_tethering;
        color = Colors.blue;
        text = 'Connecting...';
    } else if (_socketConnected) {
      icon = Icons.wifi;
      color = Colors.green;
      text = 'Online';
    } else {
      icon = Icons.wifi_off;
      color = Colors.red;
      text = 'Offline';
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        SizedBox(width: 6),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildRetryConnectionButton() {
    // Show retry button only if disconnected and not currently trying to connect
    return (!_socketConnected && !_socketService.isConnecting)
      ? IconButton(
          icon: Icon(Icons.refresh),
          tooltip: 'Retry Connection',
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Attempting to reconnect...'), duration: Duration(seconds: 2))
            );
            await _socketService.manualReconnect();
          },
        )
       : SizedBox.shrink();
  }
  // --- End Socket Status ---
  
  @override
  void dispose() {
    // Cancel all stream subscriptions
    _connectionSubscription?.cancel();
    _errorSubscription?.cancel();
    _sessionStartSubscription?.cancel();
    _sessionEndSubscription?.cancel();
    _pageController.dispose();
    // Note: SocketService itself is a singleton and might not be disposed here.
    super.dispose();
  }
}
