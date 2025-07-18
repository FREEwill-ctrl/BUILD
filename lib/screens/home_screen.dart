import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo_model.dart';
import '../providers/todo_provider.dart';
import '../utils/constants.dart';
import '../widgets/task_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/priority_chip.dart';
import '../widgets/celebration_widget.dart';
import 'add_task_screen.dart';
import 'edit_task_screen.dart';
import 'pomodoro_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(ThemeMode)? onThemeModeChanged;
  final ThemeMode? currentThemeMode;
  const HomeScreen({Key? key, this.onThemeModeChanged, this.currentThemeMode}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _showStats = true;
  late AnimationController _headerAnimationController;
  late AnimationController _statsAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _statsAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    _statsAnimationController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );
    _statsAnimation = CurvedAnimation(
      parent: _statsAnimationController,
      curve: Curves.easeOutCubic,
    );

    _headerAnimationController.forward();
    if (_showStats) _statsAnimationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TodoProvider>().loadTodos();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Beautiful App Bar with Gradient
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: AnimatedBuilder(
              animation: _headerAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - _headerAnimation.value)),
                  child: Opacity(
                    opacity: _headerAnimation.value,
                    child: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    AppConstants.primaryColor.withOpacity(0.1),
                                    AppConstants.secondaryColor.withOpacity(0.1),
                                  ]
                                : [
                                    AppConstants.primaryColor.withOpacity(0.05),
                                    AppConstants.secondaryColor.withOpacity(0.05),
                                  ],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacing20,
                              vertical: AppConstants.spacing16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getGreeting(),
                                            style: AppConstants.bodyMedium.copyWith(
                                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            AppConstants.appName,
                                            style: AppConstants.headlineSmall.copyWith(
                                              color: theme.colorScheme.onSurface,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _buildHeaderButton(
                                          icon: Icons.timer_outlined,
                                          tooltip: 'Pomodoro Timer',
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) => const PomodoroScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: AppConstants.spacing8),
                                        _buildThemeMenu(),
                                        const SizedBox(width: AppConstants.spacing8),
                                        _buildHeaderButton(
                                          icon: _showStats ? Icons.visibility_off : Icons.visibility,
                                          tooltip: _showStats ? 'Hide Stats' : 'Show Stats',
                                          onPressed: () {
                                            setState(() {
                                              _showStats = !_showStats;
                                              if (_showStats) {
                                                _statsAnimationController.forward();
                                              } else {
                                                _statsAnimationController.reverse();
                                              }
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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
          
          // Content
          SliverToBoxAdapter(
            child: Consumer<TodoProvider>(
              builder: (context, todoProvider, child) {
                if (todoProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppConstants.spacing48),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Stats Card with Animation
                    if (_showStats)
                      AnimatedBuilder(
                        animation: _statsAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * _statsAnimation.value),
                            child: Opacity(
                              opacity: _statsAnimation.value,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacing20,
                                  vertical: AppConstants.spacing8,
                                ),
                                child: StatsCard(
                                  totalTodos: todoProvider.totalTodos,
                                  completedTodos: todoProvider.completedTodos,
                                  pendingTodos: todoProvider.pendingTodos,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    // Search Bar with Enhanced Design
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing20,
                        vertical: AppConstants.spacing16,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search tasks...',
                            hintStyle: AppConstants.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                            prefixIcon: Container(
                              padding: const EdgeInsets.all(AppConstants.spacing12),
                              child: Icon(
                                Icons.search_rounded,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      todoProvider.searchTodos('');
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacing20,
                              vertical: AppConstants.spacing16,
                            ),
                          ),
                          onChanged: (value) {
                            todoProvider.searchTodos(value);
                          },
                        ),
                      ),
                    ),

                    // Priority Filter with Enhanced Design
                    Container(
                      height: 60,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacing20),
                        children: [
                          // All filter with special design
                          Container(
                            margin: const EdgeInsets.only(right: AppConstants.spacing8),
                            child: FilterChip(
                              selected: todoProvider.filterPriority == null,
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.dashboard_rounded,
                                    size: 16,
                                    color: todoProvider.filterPriority == null
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  const SizedBox(width: AppConstants.spacing4),
                                  Text('All'),
                                ],
                              ),
                              onSelected: (_) => todoProvider.filterByPriority(null),
                              backgroundColor: theme.colorScheme.surface,
                              selectedColor: theme.colorScheme.primary,
                              checkmarkColor: theme.colorScheme.onPrimary,
                              labelStyle: AppConstants.labelMedium.copyWith(
                                color: todoProvider.filterPriority == null
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // Priority filters
                          ...Priority.values.map((priority) => Container(
                                margin: const EdgeInsets.only(right: AppConstants.spacing8),
                                child: PriorityChip(
                                  priority: priority,
                                  isSelected: todoProvider.filterPriority == priority,
                                  onTap: () => todoProvider.filterByPriority(priority),
                                ),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacing16),

                    // Task List
                    todoProvider.todos.isEmpty
                        ? _buildEmptyState(context)
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.spacing20,
                            ),
                            itemCount: todoProvider.todos.length,
                            itemBuilder: (context, index) {
                              final todo = todoProvider.todos[index];
                              return AnimatedContainer(
                                duration: AppConstants.shortAnimation,
                                child: TaskCard(
                                  todo: todo,
                                  onTap: () => _showTaskDetails(context, todo),
                                  onToggleComplete: () {
                                    final wasCompleted = todo.isCompleted;
                                    todoProvider.toggleTodoComplete(todo);

                                    // Show celebration if task was just completed
                                    if (!wasCompleted && !todo.isCompleted) {
                                      Future.delayed(
                                          const Duration(milliseconds: 300), () {
                                        if (mounted) {
                                          showCelebration(context);
                                        }
                                      });
                                    }
                                  },
                                  onEdit: () => _editTask(context, todo),
                                  onDelete: () =>
                                      _deleteTask(context, todo, todoProvider),
                                ),
                              );
                            },
                          ),
                    
                    // Bottom padding for FAB
                    const SizedBox(height: AppConstants.spacing64),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          boxShadow: [
            BoxShadow(
              color: AppConstants.primaryColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _addTask(context),
          elevation: 0,
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          child: const Icon(
            Icons.add_rounded,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        color: theme.colorScheme.onSurface,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildThemeMenu() {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppConstants.radiusM),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: theme.colorScheme.onSurface,
        ),
        tooltip: 'Menu',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        onSelected: (value) {
          final provider = context.read<TodoProvider>();
          switch (value) {
            case 'all':
              provider.clearFilters();
              break;
            case 'completed':
              provider.filterByCompleted(true);
              break;
            case 'pending':
              provider.filterByCompleted(false);
              break;
            case 'theme_light':
              widget.onThemeModeChanged?.call(ThemeMode.light);
              break;
            case 'theme_dark':
              widget.onThemeModeChanged?.call(ThemeMode.dark);
              break;
            case 'theme_system':
              widget.onThemeModeChanged?.call(ThemeMode.system);
              break;
          }
        },
        itemBuilder: (context) => [
          _buildMenuItem('all', 'All Tasks', Icons.list_rounded),
          _buildMenuItem('pending', 'Pending Tasks', Icons.pending_actions_rounded),
          _buildMenuItem('completed', 'Completed Tasks', Icons.check_circle_rounded),
          const PopupMenuDivider(),
          _buildThemeMenuItem('theme_light', 'Light Mode', Icons.light_mode_rounded, ThemeMode.light),
          _buildThemeMenuItem('theme_dark', 'Dark Mode', Icons.dark_mode_rounded, ThemeMode.dark),
          _buildThemeMenuItem('theme_system', 'System Default', Icons.brightness_auto_rounded, ThemeMode.system),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String text, IconData icon) {
    final theme = Theme.of(context);
    
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: AppConstants.spacing12),
          Text(text, style: AppConstants.bodyMedium),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildThemeMenuItem(String value, String text, IconData icon, ThemeMode mode) {
    final theme = Theme.of(context);
    final isSelected = widget.currentThemeMode == mode;
    
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: AppConstants.spacing12),
          Text(
            text,
            style: AppConstants.bodyMedium.copyWith(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<TodoProvider>();

    String message;
    String subtitle;
    IconData iconData;

    if (provider.searchQuery.isNotEmpty) {
      message = 'No tasks found';
      subtitle = 'Try adjusting your search or filters';
      iconData = Icons.search_off_rounded;
    } else if (provider.filterPriority != null ||
        provider.filterCompleted != null) {
      message = 'No tasks match your filters';
      subtitle = 'Try clearing filters or add new tasks';
      iconData = Icons.filter_list_off_rounded;
    } else {
      message = 'No tasks yet';
      subtitle = 'Tap the + button to add your first task';
      iconData = Icons.task_alt_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacing24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusXXL),
            ),
            child: Icon(
              iconData,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppConstants.spacing24),
          Text(
            message,
            style: AppConstants.titleLarge.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            subtitle,
            style: AppConstants.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _addTask(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTaskScreen(),
      ),
    );
  }

  void _editTask(BuildContext context, Todo todo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTaskScreen(todo: todo),
      ),
    );
  }

  void _deleteTask(BuildContext context, Todo todo, TodoProvider provider) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusL),
          ),
          title: Text(
            'Delete Task',
            style: AppConstants.titleLarge.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${todo.title}"?',
            style: AppConstants.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppConstants.labelLarge.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            FilledButton(
                             onPressed: () {
                 provider.deleteTodo(todo.id!);
                 Navigator.of(context).pop();
               },
              style: FilledButton.styleFrom(
                backgroundColor: AppConstants.errorColor,
              ),
              child: Text(
                'Delete',
                style: AppConstants.labelLarge.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTaskDetails(BuildContext context, Todo todo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.radiusXL),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing24),
                    
                    // Task details content
                    Text(
                      todo.title,
                      style: AppConstants.headlineSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (todo.description.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.spacing16),
                      Text(
                        todo.description,
                        style: AppConstants.bodyLarge,
                      ),
                    ],
                    const SizedBox(height: AppConstants.spacing24),
                    
                    // Task metadata
                    Wrap(
                      spacing: AppConstants.spacing8,
                      runSpacing: AppConstants.spacing8,
                      children: [
                        PriorityChip(
                          priority: todo.priority,
                          isSelected: true,
                          onTap: () {},
                        ),
                        if (todo.dueDate != null)
                          Chip(
                            label: Text(
                              'Due: ${todo.dueDate!.day}/${todo.dueDate!.month}/${todo.dueDate!.year}',
                            ),
                            avatar: Icon(Icons.calendar_today, size: 16),
                          ),
                        Chip(
                          label: Text(todo.isCompleted ? 'Completed' : 'Pending'),
                          avatar: Icon(
                            todo.isCompleted ? Icons.check_circle : Icons.pending,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.spacing32),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _editTask(context, todo);
                            },
                            icon: Icon(Icons.edit),
                            label: Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacing16),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              context.read<TodoProvider>().toggleTodoComplete(todo);
                              Navigator.pop(context);
                            },
                            icon: Icon(todo.isCompleted ? Icons.undo : Icons.check),
                            label: Text(todo.isCompleted ? 'Mark Pending' : 'Mark Complete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
