import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:hungerz_kiosk/Components/entryField.dart';
import '../Theme/colors.dart';
import 'landingPage.dart';

class MobileInput extends StatefulWidget {
  @override
  _MobileInputState createState() => _MobileInputState();
}

class _MobileInputState extends State<MobileInput> {
  final TextEditingController _controller = TextEditingController();
  String? isoCode;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      color: Colors.white,
      child: Row(
        children: <Widget>[
          CountryCodePicker(
            onChanged: (value) {
              isoCode = value.code;
            },
            builder: (value) => buildButton(value),
            initialSelection: '+1',
            textStyle: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: blackColor),
            showFlag: false,
            showFlagDialog: true,
            favorite: ['+91', 'US'],
          ),
          SizedBox(
            width: 10.0,
          ),
          //takes phone number as input
          Expanded(
            child: EntryField(
              controller: _controller,
              keyboardType: TextInputType.number,
              readOnly: false,
              hint: "Enter Mobile Number",
              maxLength: 10,
              border: InputBorder.none,
            ),
          ),
          //if phone number is valid, button gets enabled and takes to register screen
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Text(
                "Continue",
                style: Theme.of(context)
                    .textTheme
                    .labelLarge!
                    .copyWith(color: Colors.white),
              ),
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => LandingPage()));
            },
          ),
        ],
      ),
    );
  }

  buildButton(CountryCode? isoCode) {
    return Row(
      children: <Widget>[
        Text(
          '$isoCode',
          style:
              Theme.of(context).textTheme.bodyLarge!.copyWith(color: blackColor),
        ),
      ],
    );
  }
}
