import 'package:flutter/material.dart';

import '../Theme/colors.dart';

class ColorButton extends StatelessWidget {
  final String title;
  ColorButton(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: 150,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Center(
          child: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge!.copyWith(fontSize: 18),
      )),
    );
  }
}
