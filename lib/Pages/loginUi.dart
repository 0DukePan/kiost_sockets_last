// import 'package:flutter/material.dart';
// import 'package:flutter/cupertino.dart';

// import 'mobileInput.dart';

// //first page that takes phone number as input for verification
// class LoginUi extends StatelessWidget {
//   static const String id = 'phone_number';
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         //used for scrolling when keyboard pops up
//         child: Container(
//           height: MediaQuery.of(context).size.height,
//           decoration: BoxDecoration(
//               color: Colors.black,
//               image: DecorationImage(
//                   image: AssetImage(
//                     "assets/spash.png",
//                   ),
//                   fit: BoxFit.cover)),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.end,
//             mainAxisSize: MainAxisSize.max,
//             children: <Widget>[
//               SizedBox(
//                 height: 70,
//               ),
//               Container(
//                 padding: EdgeInsets.all(5),
//                 child: RichText(
//                   text: TextSpan(
//                       style: Theme.of(context).textTheme.titleMedium.copyWith(
//                           letterSpacing: 2, fontWeight: FontWeight.bold),
//                       children: <TextSpan>[
//                         TextSpan(
//                             text: 'HUNGERZ',
//                             style: TextStyle(color: Colors.white)),
//                         TextSpan(
//                             text: 'KIOSK',
//                             style: TextStyle(
//                                 color: Theme.of(context).primaryColor)),
//                       ]),
//                 ),
//               ),
//               Spacer(),
//               MobileInput(),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
