import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final bool isLoading;
  final String? hintText;

  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onSearch,
    this.isLoading = false,
    this.hintText,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: TextField(
        controller: widget.controller,
        onSubmitted: widget.onSearch,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search for books...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
          ),
          suffixIcon: _buildSuffixIcon(),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isLoading) {
      return Padding(
        padding: EdgeInsets.all(12.w),
        child: SizedBox(
          width: 20.w,
          height: 20.h,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.controller.text.isNotEmpty) {
      return IconButton(
        onPressed: () {
          widget.controller.clear();
          widget.onSearch('');
        },
        icon: const Icon(Icons.clear),
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      );
    }

    return null;
  }
}