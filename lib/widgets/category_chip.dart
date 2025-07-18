import 'package:flutter/material.dart';
import '../models/category_model.dart' as CategoryModel;

class CategoryChip extends StatelessWidget {
  final CategoryModel.Category category;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showIcon;
  final double size;

  const CategoryChip({
    Key? key,
    required this.category,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.showIcon = true,
    this.size = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              category.icon,
              size: 16 * size,
              color: isSelected ? colorScheme.onPrimary : category.colorValue,
            ),
            SizedBox(width: 4 * size),
          ],
          Text(
            category.name,
            style: TextStyle(
              fontSize: 12 * size,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? colorScheme.onPrimary : null,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      onDeleted: onDelete,
      deleteIcon: onDelete != null 
          ? Icon(Icons.close, size: 16 * size)
          : null,
      backgroundColor: category.colorValue.withOpacity(0.1),
      selectedColor: category.colorValue,
      checkmarkColor: colorScheme.onPrimary,
      side: BorderSide(
        color: category.colorValue.withOpacity(isSelected ? 1.0 : 0.3),
        width: 1,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class CategorySelector extends StatelessWidget {
  final List<CategoryModel.Category> categories;
  final CategoryModel.Category? selectedCategory;
  final ValueChanged<CategoryModel.Category?> onChanged;
  final bool allowNone;
  final String? noneLabel;

  const CategorySelector({
    Key? key,
    required this.categories,
    this.selectedCategory,
    required this.onChanged,
    this.allowNone = true,
    this.noneLabel = 'No Category',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (allowNone)
          FilterChip(
            label: Text(noneLabel!),
            selected: selectedCategory == null,
            onSelected: (_) => onChanged(null),
            backgroundColor: Colors.grey.withOpacity(0.1),
            selectedColor: Colors.grey,
          ),
        ...categories.map((category) => CategoryChip(
          category: category,
          isSelected: selectedCategory?.id == category.id,
          onTap: () => onChanged(category),
        )),
      ],
    );
  }
}

class CategoryGrid extends StatelessWidget {
  final List<CategoryModel.Category> categories;
  final ValueChanged<CategoryModel.Category> onCategoryTap;
  final ValueChanged<CategoryModel.Category>? onCategoryLongPress;
  final CategoryModel.Category? selectedCategory;
  final int crossAxisCount;

  const CategoryGrid({
    Key? key,
    required this.categories,
    required this.onCategoryTap,
    this.onCategoryLongPress,
    this.selectedCategory,
    this.crossAxisCount = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = selectedCategory?.id == category.id;
        
        return Material(
          elevation: isSelected ? 4 : 1,
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? category.colorValue 
              : category.colorValue.withOpacity(0.1),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onCategoryTap(category),
            onLongPress: onCategoryLongPress != null 
                ? () => onCategoryLongPress!(category)
                : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    category.icon,
                    size: 24,
                    color: isSelected 
                        ? Colors.white 
                        : category.colorValue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? Colors.white 
                            : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}