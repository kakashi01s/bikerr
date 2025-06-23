import 'package:bikerr/core/theme.dart';
import 'package:flutter/material.dart';

class SearchBarComponent extends StatelessWidget {
  final TextEditingController? searchController; // Make it optional

  const SearchBarComponent({super.key, this.searchController});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        alignment: Alignment.center,
        height: 50,
        child: TextField(
          controller: searchController, // Use the provided controller
          style:
              textTheme.displaySmall?.copyWith(
                color: Colors.white,
              ) ?? // Apply hint style and force white color
              const TextStyle(
                color: Colors.white,
              ), // Fallback if displaySmall is null
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: textTheme.displaySmall,
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            fillColor: AppColors.buttonbgColor,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10.0),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15.0,
            ), // Adjust this value for vertical centering
          ),
        ),
      ),
    );
  }
}
