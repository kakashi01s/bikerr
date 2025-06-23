import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TextFieldComponent extends StatefulWidget {
  final String? hint;
  final FocusNode focusNode;
  final bool isPassword;
  final ValueChanged<String> onChanged;
  final String label;
  final String? svgAsset;
  final String? errorText; // Add errorText property

  const TextFieldComponent({
    super.key,
    this.hint,
    required this.focusNode,
    required this.isPassword,
    required this.onChanged,
    required this.label,
    this.svgAsset,
    this.errorText, // Initialize errorText
  });

  @override
  State<TextFieldComponent> createState() => _TextFieldComponentState();
}

class _TextFieldComponentState extends State<TextFieldComponent> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: widget.errorText != null ? 110 : 90, // Adjust height for error
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Text(widget.label, style: textTheme.labelSmall)]),
          SizedBox(height: 5),
          Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color:
                    widget.errorText != null
                        ? Colors
                            .red // Show red border on error
                        : AppColors.hintColor,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: TextFormField(
                      focusNode: widget.focusNode,
                      onChanged: widget.onChanged,
                      obscureText: widget.isPassword,
                      decoration: InputDecoration(
                        hintText: 'Enter ${widget.label}',
                        hintStyle: textTheme.displaySmall,
                        border: InputBorder.none,
                        errorText: widget.errorText, // Display error text here
                        errorStyle: TextStyle(color: Colors.red, fontSize: 12),
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                      style: textTheme.labelSmall,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child:
                      widget.svgAsset != null
                          ? SvgPicture.asset(widget.svgAsset!)
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (widget.errorText != null) // Display error message below TextField
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 5),
              child: Text(
                widget.errorText!,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
