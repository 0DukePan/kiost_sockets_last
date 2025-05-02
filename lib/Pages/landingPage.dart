import 'package:animation_wrappers/animation_wrappers.dart';
// import 'package:buy_this_app/buy_this_app.dart';
import 'package:flutter/material.dart';
import 'package:hungerz_kiosk/Pages/login.dart';
import 'package:intl/intl.dart';
import '../Theme/colors.dart';
import 'package:hungerz_kiosk/Pages/home_page.dart';


class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int counter = 0;
  @override
  void initState() {
    super.initState();
    _checkForBuyNow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadedSlideAnimation(
        child:Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.black87,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: AssetImage("assets/spash2.png"),
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 70,
              ),
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (counter == 5) {
                          counter = 0;
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoginUi(),
                              ));
                        }
                        print(counter);
                        counter++;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(5),
                      child: RichText(
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
                                  style: TextStyle(color: Colors.white)),
                              TextSpan(
                                  text: 'KIOSK',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor)),
                            ]),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 70,
                  ),
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('hh:mm').format(DateTime.now()),
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .copyWith(fontSize: 60),
                          ),
                          SizedBox(
                            width: 5,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              DateFormat('a')
                                  .format(DateTime.now())
                                  .toLowerCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(fontSize: 15),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              Spacer(),
              Container(
                alignment: Alignment.bottomCenter,
                height: 120,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 25),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(),
                        ),
                      );
                    },
                    child: Text(
                      "Touch to Explore",
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
      // floatingActionButton: AppConfig.isDemoMode
      //     ? BuyThisApp.button(
      //         AppConfig.appName,
      //         'https://dashboard.vtlabs.dev/projects/envato-referral-buy-link?project_slug=hungerz_flutter',
      //       )
      //     : null,
      // bottomNavigationBar: AppConfig.isDemoMode
      //     ? Container(
      //         padding: const EdgeInsets.all(1),
      //         child: BuyThisApp.developerRowOpus(
      //             Colors.transparent, Theme.of(context).primaryColor),
      //       )
      //     : const SizedBox.shrink(),
    );
  }

  void _checkForBuyNow() async {
    // SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    // if (!sharedPreferences.containsKey("key_buy_this_shown") &&
    //     AppConfig.isDemoMode) {
    //   Future.delayed(Duration(seconds: 10), () async {
    //     if (mounted) {
    //       BuyThisApp.showSubscribeDialog(context);
    //       sharedPreferences.setBool("key_buy_this_shown", true);
    //     }
    //   });
    // }
  }
}
