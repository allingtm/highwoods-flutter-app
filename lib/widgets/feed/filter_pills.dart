import 'package:flutter/material.dart';
import '../../models/post_category.dart';
import '../../theme/app_theme.dart';

/// Horizontal scrolling category filter chips
class FilterPills extends StatelessWidget {
  const FilterPills({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final PostCategory? selectedCategory;
  final void Function(PostCategory?) onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: tokens.spacingLg),
        children: [
          // "All" chip
          _FilterChip(
            label: 'All',
            icon: Icons.grid_view_rounded,
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          SizedBox(width: tokens.spacingSm),
          // Category chips
          ...PostCategory.values.map((category) {
            return Padding(
              padding: EdgeInsets.only(right: tokens.spacingSm),
              child: _FilterChip(
                label: category.displayName,
                icon: category.icon,
                color: category.color,
                isSelected: selectedCategory == category,
                onTap: () => onCategorySelected(category),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final theme = Theme.of(context);

    final effectiveColor = color ?? theme.colorScheme.primary;

    return Material(
      color: isSelected
          ? effectiveColor.withValues(alpha: 0.15)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(tokens.radiusXl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusXl),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spacingMd,
            vertical: tokens.spacingSm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radiusXl),
            border: isSelected
                ? Border.all(color: effectiveColor, width: 1.5)
                : null,
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected
                      ? effectiveColor
                      : theme.colorScheme.onSurfaceVariant,
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: isSelected
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: tokens.spacingSm),
                            Text(
                              label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: effectiveColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
