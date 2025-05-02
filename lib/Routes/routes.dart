import 'package:flutter/material.dart';
import 'package:hungerz_kiosk/Pages/landingPage.dart';

import '../Pages/home_page.dart';

class PageRoutes {
  static const String homePage = 'home_page';
  static const String landingPage = 'landingPage';
  // static const String itemInfoPage = 'item_info';

  Map<String, WidgetBuilder> routes() {
    return {
      homePage: (context) => HomePage(),
      landingPage: (context) => LandingPage(),
      // itemInfoPage: (context) => ItemInfoPage(),
    };
  }
}
