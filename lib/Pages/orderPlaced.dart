import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:hungerz_kiosk/Pages/landingPage.dart';

class OrderPlaced extends StatefulWidget {
  // Add parameters to receive order details
  final String? orderId;
  final int? orderNumber;
  final double? totalAmount;

  OrderPlaced({
    this.orderId,
    this.orderNumber,
    this.totalAmount,
  });

  @override
  _OrderPlacedState createState() => _OrderPlacedState();
}

class _OrderPlacedState extends State<OrderPlaced> {
  @override
  // void initState() {
  //   super.initState();
  //   Future.delayed(Duration(seconds: 5), () {
  //     Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) => LandingPage(),
  //         ));
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // Use a default value or the passed orderNumber
    String displayOrderNumber = widget.orderNumber?.toString() ?? "23";
    
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: FadedSlideAnimation(
        child:Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    "You\'ve got great taste!",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 20),
                  ),
                ],
              ),
              Spacer(),
              FadedScaleAnimation(
              child:  Container(
                  width: 250,
                  child: Image(
                    image: AssetImage("assets/order confirmed.png"),
                  ),
                ),
                scaleDuration: Duration(milliseconds: 600),
                fadeDuration: Duration(milliseconds: 600),              ),
              Spacer(),
              Column(
                children: [
                  Text(
                    "Your Order Number is",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 20,
                        letterSpacing: 2,
                        color: Colors.blueGrey.shade700),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    // Use the order number from backend or the default
                    displayOrderNumber,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 50,
                        letterSpacing: 3,
                        color: Colors.blueGrey.shade700),
                  ),
                ],
              ),
              if (widget.totalAmount != null) ...[
                SizedBox(height: 10),
                Text(
                  "Total: ${widget.totalAmount!.toStringAsFixed(2)} DZD",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade700),
                ),
              ],
              Spacer(),
              Column(
                children: [
                  Text(
                    "Pay at the counter when your order is ready!",
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium!
                        .copyWith(fontSize: 13),
                  ),
                ],
              ),
              Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LandingPage(),
                      ));
                },
                child: Text("Home",
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 20,
                        letterSpacing: 2,
                        color: Theme.of(context).primaryColor)),
              ),
              Spacer(),
            ],
          ),
        ),
        beginOffset: Offset(0.0, 0.3),
        endOffset: Offset(0, 0),
        slideCurve: Curves.linearToEaseOut,
      ),
    );
  }
}
