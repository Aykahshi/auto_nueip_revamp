import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import '../../../../core/extensions/theme_extensions.dart';

/// A reusable dropdown search field using DropdownButton2.
class DropdownSearchField<T> extends StatelessWidget {
  /// The label text for the dropdown.
  final String label;

  /// The hint text for the search field within the dropdown.
  final String hint;

  /// The icon to display next to the label/hint.
  final IconData icon;

  /// The list of items to display in the dropdown.
  final List<T> items;

  /// The currently selected item.
  final T? selectedItem;

  /// A function to convert an item of type T to its string representation.
  final String Function(T) itemAsString;

  /// Callback function when the selected item changes.
  final ValueChanged<T?> onChanged;

  /// Optional controller for the search text field.
  final TextEditingController? searchController;

  /// A builder function to display when the search yields no results.
  final Widget Function(BuildContext, String?) emptyBuilder;

  /// The animation delay for the dropdown field.
  final Duration delay;

  /// Creates a dropdown search field.
  const DropdownSearchField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.items,
    required this.selectedItem,
    required this.itemAsString,
    required this.onChanged,
    required this.searchController,
    required this.emptyBuilder,
    required this.delay,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<T>(
        isExpanded: true,
        // --- Button Customization --- Use selectedItemBuilder for better control
        selectedItemBuilder:
            selectedItem == null
                ? null // Show hint if nothing is selected
                : (context) {
                  // Only build selected item display if an item IS selected
                  return items.map((item) {
                    // This map is a bit inefficient as it rebuilds all for selection,
                    // but DropdownButton2 requires a list here.
                    // We rely on `value` property to show the correct one.
                    return _buildSelectedItemDisplay(context, item);
                  }).toList();
                },
        hint: _buildHintDisplay(context), // Use helper for hint
        items:
            items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item, // Use the object itself as value
                    child: Text(
                      itemAsString(item),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: context.sp(
                          14,
                        ), // Smaller font in dropdown list
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
        value: selectedItem, // The currently selected object
        onChanged: (value) {
          onChanged(value);
          // Optionally trigger setState in parent if needed via callback
        },
        buttonStyleData: ButtonStyleData(
          padding: EdgeInsets.symmetric(
            vertical: context.h(0),
            horizontal: 0,
          ), // Reduced padding
          height: context.h(48), // Match text field height better
          elevation: 0, // Flat button
        ),
        iconStyleData: IconStyleData(
          icon: Icon(
            Icons.arrow_forward_ios_rounded,
            size: context.r(16),
            color: context.colorScheme.outline.withValues(alpha: 0.7),
          ),
          openMenuIcon: Icon(
            // Change icon when open
            Icons.arrow_drop_down_rounded,
            size: context.r(24),
            color: context.colorScheme.primary,
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          maxHeight: context.h(250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(context.r(12)),
            color:
                context
                    .colorScheme
                    .surfaceContainerLowest, // Use distinct color
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          offset: const Offset(0, 2), // Adjust dropdown position slightly
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: WidgetStateProperty.all(6),
            thumbVisibility: WidgetStateProperty.all(true),
          ),
        ),
        menuItemStyleData: MenuItemStyleData(
          height: context.h(40),
          padding: EdgeInsets.symmetric(horizontal: context.w(16)),
        ),
        // Add Search feature only if controller is provided (Stable Version API)
        dropdownSearchData:
            searchController != null
                ? DropdownSearchData(
                  searchController: searchController,
                  searchInnerWidgetHeight: context.h(50),
                  searchInnerWidget: Padding(
                    // Use Padding for consistent spacing
                    padding: EdgeInsets.only(
                      top: context.h(8),
                      bottom: context.h(4),
                      right: context.w(8),
                      left: context.w(8),
                    ),
                    child: TextFormField(
                      controller: searchController,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: context.sp(14),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: context.w(10),
                          vertical: context.h(10),
                        ),
                        hintText: '$hint...',
                        hintStyle: context.textTheme.bodySmall?.copyWith(
                          fontSize: context.sp(14),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(context.r(8)),
                          borderSide: BorderSide(
                            color: context.colorScheme.outline.withValues(
                              alpha: 0.4,
                            ),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          // Highlight border when focused
                          borderRadius: BorderRadius.circular(context.r(8)),
                          borderSide: BorderSide(
                            color: context.colorScheme.primary,
                          ),
                        ),
                        prefixIcon: Icon(Icons.search, size: context.r(18)),
                      ),
                    ),
                  ),
                  searchMatchFn: (item, searchValue) {
                    // Match against the string representation of the item
                    // item is DropdownMenuItem<T>, access value via item.value
                    if (item.value == null) return false;
                    return itemAsString(
                      item.value as T,
                    ).toLowerCase().contains(searchValue.toLowerCase());
                  },
                  // Use emptyBuilder passed from the parent
                  // Note: DropdownButton2 v2.3.9 removed `noResultsWidget`
                  // We might need to handle empty search results differently if needed,
                  // potentially by filtering `items` before passing them in.
                )
                : null,
        // Clear search field when dropdown is closed
        onMenuStateChange: (isOpen) {
          if (!isOpen && searchController != null) {
            searchController?.clear();
          }
        },
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.1);
  }

  /// Helper to build the display for the selected item.
  Widget _buildSelectedItemDisplay(BuildContext context, T item) {
    return Row(
      children: [
        Icon(
          icon,
          size: context.r(20),
          color: context.colorScheme.secondary, // Consistent color
        ),
        Gap(context.w(16)),
        Expanded(
          child: Text(
            itemAsString(item), // Display string representation
            style: context.textTheme.bodyLarge?.copyWith(
              fontSize: context.sp(16),
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w500, // Indicate selection
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Helper to build the display for the hint.
  Widget _buildHintDisplay(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: context.r(20), color: context.colorScheme.secondary),
        Gap(context.w(16)),
        Expanded(
          child: Text(
            label, // Show label as hint when nothing selected
            style: context.textTheme.bodyLarge?.copyWith(
              fontSize: context.sp(16),
              color: context.colorScheme.outline,
              fontWeight: FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
