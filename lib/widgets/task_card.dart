import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../utils/constants.dart';
import 'priority_chip.dart';

class TaskCard extends StatefulWidget {
  final Todo todo;
  final VoidCallback onTap;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskCard({
    super.key,
    required this.todo,
    required this.onTap,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.shortAnimation,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Initial animation
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = !widget.todo.isCompleted &&
        (widget.todo.dueDate?.isBefore(DateTime.now()) ?? false);
    final isDueSoon = !widget.todo.isCompleted &&
        widget.todo.dueDate != null &&
        widget.todo.dueDate!.isAfter(DateTime.now()) &&
        widget.todo.dueDate!.difference(DateTime.now()).inDays < 1;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppConstants.spacing12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      boxShadow: [
                        BoxShadow(
                          color: _getPriorityColor(widget.todo.priority).withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.05),
                          blurRadius: 1,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      child: InkWell(
                        onTap: widget.onTap,
                        onTapDown: (_) {
                          setState(() => _isPressed = true);
                        },
                        onTapUp: (_) {
                          setState(() => _isPressed = false);
                        },
                        onTapCancel: () {
                          setState(() => _isPressed = false);
                        },
                        borderRadius: BorderRadius.circular(AppConstants.radiusL),
                        child: AnimatedContainer(
                          duration: AppConstants.quickAnimation,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(AppConstants.radiusL),
                            border: Border.all(
                              color: isOverdue
                                  ? AppConstants.errorColor.withOpacity(0.3)
                                  : isDueSoon
                                      ? AppConstants.warningColor.withOpacity(0.3)
                                      : theme.colorScheme.outline.withOpacity(0.1),
                              width: isOverdue || isDueSoon ? 1.5 : 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppConstants.spacing16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Row
                                Row(
                                  children: [
                                    // Custom Checkbox
                                    GestureDetector(
                                      onTap: widget.onToggleComplete,
                                      child: AnimatedContainer(
                                        duration: AppConstants.shortAnimation,
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: widget.todo.isCompleted
                                                ? AppConstants.successColor
                                                : _getPriorityColor(widget.todo.priority),
                                            width: 2,
                                          ),
                                          color: widget.todo.isCompleted
                                              ? AppConstants.successColor
                                              : Colors.transparent,
                                        ),
                                        child: widget.todo.isCompleted
                                            ? Icon(
                                                Icons.check_rounded,
                                                color: Colors.white,
                                                size: 16,
                                              )
                                            : null,
                                      ),
                                    ),

                                    const SizedBox(width: AppConstants.spacing12),

                                    // Title and Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  widget.todo.title,
                                                  style: AppConstants.titleMedium.copyWith(
                                                    color: widget.todo.isCompleted
                                                        ? theme.colorScheme.onSurface.withOpacity(0.6)
                                                        : theme.colorScheme.onSurface,
                                                    decoration: widget.todo.isCompleted
                                                        ? TextDecoration.lineThrough
                                                        : TextDecoration.none,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: AppConstants.spacing8),
                                              PriorityChip(
                                                priority: widget.todo.priority,
                                                isSelected: false,
                                                onTap: () {},
                                              ),
                                            ],
                                          ),
                                          
                                          if (widget.todo.description.isNotEmpty) ...[
                                            const SizedBox(height: AppConstants.spacing4),
                                            Text(
                                              widget.todo.description,
                                              style: AppConstants.bodySmall.copyWith(
                                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                                decoration: widget.todo.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : TextDecoration.none,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Action Menu
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert_rounded,
                                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                                        size: 20,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                                      ),
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'edit':
                                            widget.onEdit();
                                            break;
                                          case 'delete':
                                            widget.onDelete();
                                            break;
                                          case 'toggle':
                                            widget.onToggleComplete();
                                            break;
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        PopupMenuItem(
                                          value: 'toggle',
                                          child: Row(
                                            children: [
                                              Icon(
                                                widget.todo.isCompleted
                                                    ? Icons.undo_rounded
                                                    : Icons.check_rounded,
                                                size: 18,
                                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                              const SizedBox(width: AppConstants.spacing8),
                                              Text(
                                                widget.todo.isCompleted
                                                    ? 'Mark Pending'
                                                    : 'Mark Complete',
                                                style: AppConstants.bodyMedium,
                                              ),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.edit_rounded,
                                                size: 18,
                                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                                              ),
                                              const SizedBox(width: AppConstants.spacing8),
                                              Text('Edit', style: AppConstants.bodyMedium),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_rounded,
                                                size: 18,
                                                color: AppConstants.errorColor,
                                              ),
                                              const SizedBox(width: AppConstants.spacing8),
                                              Text(
                                                'Delete',
                                                style: AppConstants.bodyMedium.copyWith(
                                                  color: AppConstants.errorColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // Footer Information
                                if (widget.todo.dueDate != null ||
                                    widget.todo.tags.isNotEmpty) ...[
                                  const SizedBox(height: AppConstants.spacing12),
                                  Row(
                                    children: [
                                      // Due Date
                                      if (widget.todo.dueDate != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppConstants.spacing8,
                                            vertical: AppConstants.spacing4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isOverdue
                                                ? AppConstants.errorColor.withOpacity(0.1)
                                                : isDueSoon
                                                    ? AppConstants.warningColor.withOpacity(0.1)
                                                    : theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(AppConstants.radiusS),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 12,
                                                color: isOverdue
                                                    ? AppConstants.errorColor
                                                    : isDueSoon
                                                        ? AppConstants.warningColor
                                                        : theme.colorScheme.primary,
                                              ),
                                              const SizedBox(width: AppConstants.spacing4),
                                              Text(
                                                _formatDueDate(widget.todo.dueDate!),
                                                style: AppConstants.labelSmall.copyWith(
                                                  color: isOverdue
                                                      ? AppConstants.errorColor
                                                      : isDueSoon
                                                          ? AppConstants.warningColor
                                                          : theme.colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const Spacer(),

                                      // Status Indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppConstants.spacing8,
                                          vertical: AppConstants.spacing4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget.todo.isCompleted
                                              ? AppConstants.successColor.withOpacity(0.1)
                                              : theme.colorScheme.outline.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(AppConstants.radiusS),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: widget.todo.isCompleted
                                                    ? AppConstants.successColor
                                                    : theme.colorScheme.outline,
                                              ),
                                            ),
                                            const SizedBox(width: AppConstants.spacing4),
                                            Text(
                                              widget.todo.isCompleted ? 'Done' : 'Pending',
                                              style: AppConstants.labelSmall.copyWith(
                                                color: widget.todo.isCompleted
                                                    ? AppConstants.successColor
                                                    : theme.colorScheme.onSurface.withOpacity(0.6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // Tags
                                if (widget.todo.tags.isNotEmpty) ...[
                                  const SizedBox(height: AppConstants.spacing8),
                                  Wrap(
                                    spacing: AppConstants.spacing4,
                                    runSpacing: AppConstants.spacing4,
                                    children: widget.todo.tags.take(3).map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppConstants.spacing6,
                                          vertical: AppConstants.spacing2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(AppConstants.radiusXS),
                                        ),
                                        child: Text(
                                          tag,
                                          style: AppConstants.labelSmall.copyWith(
                                            color: theme.colorScheme.onPrimaryContainer,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.low:
        return AppConstants.lowPriorityColor;
      case Priority.medium:
        return AppConstants.mediumPriorityColor;
      case Priority.high:
        return AppConstants.highPriorityColor;
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDateDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDateDay == today) {
      return 'Today';
    } else if (dueDateDay == tomorrow) {
      return 'Tomorrow';
    } else if (dueDateDay.isBefore(today)) {
      final difference = today.difference(dueDateDay).inDays;
      return '$difference days ago';
    } else {
      final difference = dueDateDay.difference(today).inDays;
      if (difference <= 7) {
        return DateFormat('EEE').format(dueDate);
      } else {
        return DateFormat('MMM d').format(dueDate);
      }
    }
  }
}

class CompactTaskCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggleComplete;

  const CompactTaskCard({
    Key? key,
    required this.todo,
    required this.onToggleComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: GestureDetector(
        onTap: onToggleComplete,
        child: AnimatedContainer(
          duration: AppConstants.shortAnimation,
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: todo.isCompleted
                  ? AppConstants.successColor
                  : theme.colorScheme.outline,
              width: 2,
            ),
            color: todo.isCompleted
                ? AppConstants.successColor
                : Colors.transparent,
          ),
          child: todo.isCompleted
              ? Image.asset('assets/icons/check.png', width: 16, height: 16, color: Colors.white)
              : null,
        ),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
          color: todo.isCompleted
              ? theme.colorScheme.onSurface.withOpacity(0.6)
              : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: todo.description.isNotEmpty
          ? Text(
              todo.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration:
                    todo.isCompleted ? TextDecoration.lineThrough : null,
              ),
            )
          : null,
      trailing: PriorityChip(priority: todo.priority),
    );
  }
}