import 'package:flutter/material.dart';

class EntryField extends StatelessWidget {
  final String title;
  EntryField(this.title);
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
          prefixStyle: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(color: Colors.black),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
          hintText: title,
          hintStyle: Theme.of(context)
              .textTheme
              .bodyLarge!
              .copyWith(color: Colors.black, fontSize: 17)),
    );
  }
}
