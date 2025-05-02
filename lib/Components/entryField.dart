import 'package:flutter/material.dart';

import '../Theme/colors.dart';

class EntryField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? image;
  final String? initialValue;
  final bool? readOnly;
  final TextInputType? keyboardType;
  final int? maxLength;
  final int? maxLines;
  final String? hint;
  final InputBorder? border;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Function? onTap;
  final TextCapitalization? textCapitalization;

  EntryField({
    this.controller,
    this.label,
    this.image,
    this.initialValue,
    this.readOnly,
    this.keyboardType,
    this.maxLength,
    this.hint,
    this.border,
    this.maxLines,
    this.suffixIcon,
    this.onTap,
    this.textCapitalization,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      child: TextFormField(
        textCapitalization: textCapitalization ?? TextCapitalization.sentences,
        cursorColor: blackColor,
        onTap: onTap as void Function()?,
        autofocus: false,
        controller: controller,
        initialValue: initialValue,
        style: Theme.of(context).textTheme.bodySmall,
        readOnly: readOnly ?? false,
        keyboardType: keyboardType,
        minLines: 1,
        maxLength: maxLength,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: prefixIcon ?? null,
          suffixIcon: suffixIcon,
          labelText: label,
          hintText: hint,
          hintStyle:
              Theme.of(context).textTheme.bodyLarge!.copyWith(color: blackColor),
          border: border,
          counter: Offstage(),
          icon: (image != null)
              ? ImageIcon(
                  AssetImage(image!),
                  color: buttonColor,
                  size: 20.0,
                )
              : null,
        ),
      ),
    );
  }
}
