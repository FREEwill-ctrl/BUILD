import 'package:flutter/material.dart';
import '../models/tag_model.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final double size;

  const TagChip({
    Key? key,
    required this.tag,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.size = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return FilterChip(
      label: Text(
        tag.name,
        style: TextStyle(
          fontSize: 11 * size,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? colorScheme.onSecondary : null,
        ),
      ),
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      onDeleted: onDelete,
      deleteIcon: onDelete != null 
          ? Icon(Icons.close, size: 14 * size)
          : null,
      backgroundColor: tag.colorValue.withOpacity(0.1),
      selectedColor: tag.colorValue,
      checkmarkColor: colorScheme.onSecondary,
      side: BorderSide(
        color: tag.colorValue.withOpacity(isSelected ? 1.0 : 0.3),
        width: 1,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.symmetric(horizontal: 6 * size, vertical: 2 * size),
    );
  }
}

class TagSelector extends StatelessWidget {
  final List<Tag> availableTags;
  final List<Tag> selectedTags;
  final ValueChanged<List<Tag>> onChanged;
  final bool allowMultiple;
  final int? maxTags;

  const TagSelector({
    Key? key,
    required this.availableTags,
    required this.selectedTags,
    required this.onChanged,
    this.allowMultiple = true,
    this.maxTags,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: availableTags.map((tag) {
        final isSelected = selectedTags.any((t) => t.id == tag.id);
        
        return TagChip(
          tag: tag,
          isSelected: isSelected,
          onTap: () => _toggleTag(tag),
        );
      }).toList(),
    );
  }

  void _toggleTag(Tag tag) {
    final currentTags = List<Tag>.from(selectedTags);
    final isSelected = currentTags.any((t) => t.id == tag.id);
    
    if (isSelected) {
      currentTags.removeWhere((t) => t.id == tag.id);
    } else {
      if (!allowMultiple) {
        currentTags.clear();
      }
      
      if (maxTags == null || currentTags.length < maxTags!) {
        currentTags.add(tag);
      }
    }
    
    onChanged(currentTags);
  }
}

class TagCloud extends StatelessWidget {
  final List<Tag> tags;
  final ValueChanged<Tag>? onTagTap;
  final Map<int, int>? tagCounts; // Tag ID -> usage count

  const TagCloud({
    Key? key,
    required this.tags,
    this.onTagTap,
    this.tagCounts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort tags by usage count if available
    final sortedTags = List<Tag>.from(tags);
    if (tagCounts != null) {
      sortedTags.sort((a, b) => 
          (tagCounts![b.id] ?? 0).compareTo(tagCounts![a.id] ?? 0));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: sortedTags.map((tag) {
        final count = tagCounts?[tag.id] ?? 0;
        final size = _calculateSize(count);
        
        return GestureDetector(
          onTap: onTagTap != null ? () => onTagTap!(tag) : null,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8 * size,
              vertical: 4 * size,
            ),
            decoration: BoxDecoration(
              color: tag.colorValue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12 * size),
              border: Border.all(
                color: tag.colorValue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag.name,
                  style: TextStyle(
                    fontSize: 11 * size,
                    fontWeight: FontWeight.w500,
                    color: tag.colorValue,
                  ),
                ),
                if (tagCounts != null && count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4 * size,
                      vertical: 1 * size,
                    ),
                    decoration: BoxDecoration(
                      color: tag.colorValue,
                      borderRadius: BorderRadius.circular(8 * size),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 9 * size,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  double _calculateSize(int count) {
    if (count == 0) return 0.8;
    if (count <= 2) return 1.0;
    if (count <= 5) return 1.2;
    if (count <= 10) return 1.4;
    return 1.6;
  }
}

class TagInput extends StatefulWidget {
  final List<Tag> availableTags;
  final List<Tag> selectedTags;
  final ValueChanged<List<Tag>> onChanged;
  final String hintText;

  const TagInput({
    Key? key,
    required this.availableTags,
    required this.selectedTags,
    required this.onChanged,
    this.hintText = 'Add tags...',
  }) : super(key: key);

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Tag> _filteredTags = [];

  @override
  void initState() {
    super.initState();
    _filteredTags = widget.availableTags;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected tags
        if (widget.selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.selectedTags.map((tag) => TagChip(
              tag: tag,
              isSelected: true,
              onDelete: () => _removeTag(tag),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
        
        // Input field
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _filterTags('');
                    },
                  )
                : null,
          ),
          onChanged: _filterTags,
        ),
        
        // Filtered tags suggestions
        if (_filteredTags.isNotEmpty && _focusNode.hasFocus) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _filteredTags.take(10).map((tag) {
                  final isSelected = widget.selectedTags.any((t) => t.id == tag.id);
                  
                  return TagChip(
                    tag: tag,
                    isSelected: isSelected,
                    onTap: isSelected ? null : () => _addTag(tag),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _filterTags(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTags = widget.availableTags;
      } else {
        _filteredTags = widget.availableTags
            .where((tag) => tag.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _addTag(Tag tag) {
    if (!widget.selectedTags.any((t) => t.id == tag.id)) {
      final updatedTags = [...widget.selectedTags, tag];
      widget.onChanged(updatedTags);
      _controller.clear();
      _filterTags('');
    }
  }

  void _removeTag(Tag tag) {
    final updatedTags = widget.selectedTags.where((t) => t.id != tag.id).toList();
    widget.onChanged(updatedTags);
  }
}