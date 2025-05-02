import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:hungerz_kiosk/Models/menu_item.dart';
import 'package:hungerz_kiosk/Theme/colors.dart';
import 'package:hungerz_kiosk/Components/custom_circular_button.dart';

class ItemInfoPage extends StatefulWidget {
  final MenuItem menuItem;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  ItemInfoPage({
    required this.menuItem,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  _ItemInfoPageState createState() => _ItemInfoPageState();
}

class FoodItem {
  String image;
  String name;
  bool isVeg;
  String price;

  FoodItem(this.image, this.name, this.isVeg, this.price);
}

class _ItemInfoPageState extends State<ItemInfoPage> {
  List<FoodItem> foodItems = [
    FoodItem('assets/food items/food1.jpg', 'Veg Sandwich', true, '5.00'),
    FoodItem('assets/food items/food2.jpg', 'Shrips Rice', true, '3.00'),
    FoodItem('assets/food items/food3.jpg', 'Cheese Bread', true, '4.00'),
    FoodItem('assets/food items/food4.jpg', 'Veg Cheeswich', true, '3.50'),
    FoodItem('assets/food items/food5.jpg', 'Margherita Pizza', true, '4.50'),
    FoodItem('assets/food items/food6.jpg', 'Veg Manchau', true, '2.50'),
    FoodItem('assets/food items/food7.jpg', 'Spring Noodle', true, '3.00'),
    FoodItem('assets/food items/food8.jpg', 'Veg Mix Pizza', true, '5.00'),
  ];

  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.menuItem.price * widget.menuItem.count;

    return Scaffold(
      body: SafeArea(
          child: Column(
            children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.0),
                children: [
                  FadedScaleAnimation(
                    child: ClipRRect(
                       borderRadius: BorderRadius.circular(10),
                       child: widget.menuItem.image != null && widget.menuItem.image!.isNotEmpty
                          ? Image.network(
                              widget.menuItem.image!, 
                              fit: BoxFit.cover,
                              height: 200,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(height: 200, width: double.infinity, color: Colors.grey[300], child: Icon(Icons.broken_image, color: Colors.grey[600], size: 60));
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(height: 200, width: double.infinity, alignment: Alignment.center, child: CircularProgressIndicator(value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
                              },
                            )
                          : Container(height: 200, width: double.infinity, color: Colors.grey[300], child: Icon(Icons.image_not_supported, color: Colors.grey[600], size: 60)),
                    ),
                    scaleDuration: Duration(milliseconds: 600),
                    fadeDuration: Duration(milliseconds: 600),
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.menuItem.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Image.asset(
                        widget.menuItem.isVeg ? 'assets/ic_veg.png' : 'assets/ic_nonveg.png',
                        height: 20,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  if (widget.menuItem.description != null && widget.menuItem.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        "Description",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                    ),
                  if (widget.menuItem.description != null && widget.menuItem.description!.isNotEmpty)
                        Text(
                      widget.menuItem.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                        ),
                  SizedBox(height: 16),
                ],
              ),
            ),

            Divider(height: 1, thickness: 0.5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      buildIconButton(Icons.remove, widget.onDecrement),
                      SizedBox(width: 16),
                      Text(
                        widget.menuItem.count.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 16),
                      buildIconButton(Icons.add, widget.onIncrement),
                    ],
                  ),
                  Text(
                    "Total: ${totalPrice.toStringAsFixed(2)} DZD",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                      ],
                    ),
                  ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: CustomButton(
                onTap: () {
                  Navigator.pop(context);
                },
                title: Text(
                  "Close",
                   style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
                bgColor: buttonColor,
                borderRadius: 8,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildIconButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300)
      ),
        child: Icon(
            icon,
          color: Theme.of(context).primaryColor,
          size: 20,
          ),
      ),
    );
  }
}
