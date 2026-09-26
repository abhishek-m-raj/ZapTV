import 'package:flutter/material.dart';
import 'package:custom_tv_text_field/custom_tv_text_field.dart';

class CustomTvTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String prefixText;
  final TextInputType keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final GlobalKey<CustomTVTextFieldState>? fieldKey;
  final bool isFocused;

  const CustomTvTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.prefixText = "",
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.fieldKey,
    this.isFocused = false,
  });

  @override
  State<CustomTvTextField> createState() => _CustomTvTextFieldState();
}

class _CustomTvTextFieldState extends State<CustomTvTextField> {
  @override
  Widget build(BuildContext context) {
    KeyboardType kbType = KeyboardType.alphabetic;
    TextFieldType tfType = TextFieldType.other;

    if (widget.keyboardType == TextInputType.number || widget.keyboardType == TextInputType.phone) {
      kbType = KeyboardType.numeric;
    }
    
    if (widget.labelText.toLowerCase().contains("phone") || widget.labelText.toLowerCase().contains("mobile")) {
      tfType = TextFieldType.phone;
    }

    return CustomTVTextField(
      key: widget.fieldKey,
      controller: widget.controller,
      hint: widget.labelText,
      isFocused: widget.isFocused,
      keyboardType: kbType,
      textFieldType: tfType,
      backgroundColor: Colors.grey[900],
      focusedBorderColor: Theme.of(context).colorScheme.primary,
      borderRadius: 12,
      prefixIcon: widget.prefixText.isNotEmpty 
          ? Container(
              padding: const EdgeInsets.only(left: 8.0, right: 4.0, top: 14.0),
              child: Text(widget.prefixText, style: const TextStyle(color: Colors.white70, fontSize: 16)),
            )
          : null,
    );
  }
}
