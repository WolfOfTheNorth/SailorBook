import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/test_helpers.dart';

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
      key: const Key('search-bar-container'),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        key: const Key('search-input-field'),
        controller: widget.controller,
        onSubmitted: widget.onSearch,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search for books...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
          ).withTestId('search-icon', label: 'Search Icon'),
          suffixIcon: _buildSuffixIcon(),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
        ),
        textInputAction: TextInputAction.search,
      ).asTestTextField('search-field', label: 'Search Input Field'),
    ).withTestId('search-bar-container', label: 'Search Bar');
  }

  Widget? _buildSuffixIcon() {
    if (widget.isLoading) {
      return Padding(
        padding: EdgeInsets.all(12.w),
        child: SizedBox(
          key: const Key('search-loading'),
          width: 20.w,
          height: 20.h,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ).withTestId('search-loading', label: 'Search Loading'),
      );
    }

    if (widget.controller.text.isNotEmpty) {
      return IconButton(
        key: const Key('search-clear-btn'),
        onPressed: () {
          widget.controller.clear();
          widget.onSearch('');
        },
        icon: const Icon(Icons.clear),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
      ).asTestButton('search-clear-btn', label: 'Clear Search');
    }

    return null;
  }
}