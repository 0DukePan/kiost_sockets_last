import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:hungerz_kiosk/Components/textfield.dart';
import 'package:hungerz_kiosk/Pages/verification.dart';

class LoginUi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadedSlideAnimation(
        child:SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height - 90,
                padding: EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  children: [
                    Spacer(),
                    Container(
                      padding: EdgeInsets.all(5),
                      child: Row(
                        children: [
                          RichText(
                            text: TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.bold),
                                children: <TextSpan>[
                                  TextSpan(
                                      text: 'HUNGERZ',
                                      style: TextStyle(color: Colors.black)),
                                  TextSpan(
                                      text: 'KIOSK',
                                      style: TextStyle(
                                          color:
                                              Theme.of(context).primaryColor)),
                                ]),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Enter your registered phone number to start!",
                          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                              fontSize: 16,
                              color: Colors.blueGrey.shade700,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_android,
                          color: Theme.of(context).primaryColor,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text("Phone Number",
                            style: TextStyle(color: Colors.grey[600]))
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.only(left: 35),
                      child: Column(
                        children: [
                          EntryField("+1 984 596 4521"),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "We\'ll send a verification code",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    Spacer(),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Verification(),
                      ));
                },
                child: Container(
                  alignment: Alignment.bottomCenter,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(10)),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).primaryColor,
                        Colors.white,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 25),
                    child: Text(
                      "Continue",
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge!
                          .copyWith(fontSize: 20),
                    ),
                  ),
                ),
              )
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
