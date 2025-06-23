import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpTextFieldComponent extends StatefulWidget {
  final FocusNode focusNode;
  final bool isPassword;
  final ValueChanged<String> onChanged;
  final String? errorText; // Add errorText property
  const OtpTextFieldComponent({
    super.key,
    required this.focusNode,
    required this.isPassword,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<OtpTextFieldComponent> createState() => _OtpTextFieldComponentState();
}

class _OtpTextFieldComponentState extends State<OtpTextFieldComponent> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: widget.errorText != null ? 110 : 90, // Adjust height for error
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            width: 50,
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
                    padding: const EdgeInsets.all(10),
                    child: TextFormField(
                      textInputAction: TextInputAction.next,
                      maxLengthEnforcement: MaxLengthEnforcement.enforced,
                      textAlign: TextAlign.center,
                      focusNode: widget.focusNode,
                      inputFormatters: [LengthLimitingTextInputFormatter(1)],
                      keyboardType: TextInputType.number,
                      onChanged: widget.onChanged,
                      obscureText: widget.isPassword,
                      decoration: InputDecoration(
                        hintText: '-',
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
