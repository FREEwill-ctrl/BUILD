import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';

class StatsCard extends StatefulWidget {
  final int totalTodos;
  final int completedTodos;
  final int pendingTodos;

  const StatsCard({
    super.key,
    required this.totalTodos,
    required this.completedTodos,
    required this.pendingTodos,
  });

  @override
  State<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<StatsCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _scaleController;
  late Animation<double> _progressAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _scaleController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completionRate = widget.totalTodos > 0 ? (widget.completedTodos / widget.totalTodos) : 0.0;
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);
    final completedPerDay = todoProvider.completedPerDay;
    final maxCompleted = completedPerDay.values.isNotEmpty ? completedPerDay.values.reduce((a, b) => a > b ? a : b) : 1;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusXL),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppConstants.spacing8),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.radiusM),
                          ),
                          child: Icon(
                            Icons.analytics_rounded,
                            color: AppConstants.primaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacing12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Statistics',
                                style: AppConstants.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Your productivity overview',
                                style: AppConstants.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.spacing12,
                            vertical: AppConstants.spacing4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCompletionRateColor(completionRate).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppConstants.radiusL),
                          ),
                          child: Text(
                            '${(completionRate * 100).toInt()}%',
                            style: AppConstants.labelMedium.copyWith(
                              color: _getCompletionRateColor(completionRate),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacing24),

                    // Progress Bar with Animation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Completion Rate',
                              style: AppConstants.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${widget.completedTodos}/${widget.totalTodos}',
                              style: AppConstants.bodySmall.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppConstants.spacing8),
                        AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppConstants.radiusS),
                                color: theme.colorScheme.outline.withOpacity(0.1),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppConstants.radiusS),
                                child: LinearProgressIndicator(
                                  value: completionRate * _progressAnimation.value,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getCompletionRateColor(completionRate),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacing24),

                    // Statistics Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.task_alt_rounded,
                            label: 'Total',
                            value: widget.totalTodos.toString(),
                            color: AppConstants.primaryColor,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacing12),
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.check_circle_rounded,
                            label: 'Completed',
                            value: widget.completedTodos.toString(),
                            color: AppConstants.successColor,
                            theme: theme,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacing12),
                        Expanded(
                          child: _buildStatItem(
                            icon: Icons.pending_actions_rounded,
                            label: 'Pending',
                            value: widget.pendingTodos.toString(),
                            color: AppConstants.warningColor,
                            theme: theme,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacing24),

                    // Priority Distribution
                    _buildPriorityDistribution(todoProvider, theme),

                    const SizedBox(height: AppConstants.spacing24),

                    // Weekly Activity Chart
                    _buildWeeklyChart(completedPerDay, maxCompleted, theme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: color.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            value,
            style: AppConstants.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppConstants.spacing4),
          Text(
            label,
            style: AppConstants.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityDistribution(TodoProvider provider, ThemeData theme) {
    final lowCount = provider.todos.where((todo) => todo.priority == Priority.low).length;
    final mediumCount = provider.todos.where((todo) => todo.priority == Priority.medium).length;
    final highCount = provider.todos.where((todo) => todo.priority == Priority.high).length;
    final total = lowCount + mediumCount + highCount;

    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority Distribution',
          style: AppConstants.titleSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppConstants.spacing12),
        Row(
          children: [
            _buildPriorityItem(
              color: AppConstants.lowPriorityColor,
              label: 'Low',
              count: lowCount,
              total: total,
              theme: theme,
            ),
            const SizedBox(width: AppConstants.spacing8),
            _buildPriorityItem(
              color: AppConstants.mediumPriorityColor,
              label: 'Medium',
              count: mediumCount,
              total: total,
              theme: theme,
            ),
            const SizedBox(width: AppConstants.spacing8),
            _buildPriorityItem(
              color: AppConstants.highPriorityColor,
              label: 'High',
              count: highCount,
              total: total,
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityItem({
    required Color color,
    required String label,
    required int count,
    required int total,
    required ThemeData theme,
  }) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacing12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(AppConstants.radiusM),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppConstants.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  count.toString(),
                  style: AppConstants.labelMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacing8),
            AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, child) {
                return Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: color.withOpacity(0.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: percentage * _progressAnimation.value,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(Map<String, int> completedPerDay, int maxCompleted, ThemeData theme) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now();
    final chartData = <String, int>{};

    // Generate last 7 days
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey = '${date.month}/${date.day}';
      chartData[days[(date.weekday - 1) % 7]] = completedPerDay[dateKey] ?? 0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completed per Day (7 days)',
              style: AppConstants.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              'Max: $maxCompleted',
              style: AppConstants.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacing16),
        SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.entries.map((entry) {
              final height = maxCompleted > 0 ? (entry.value / maxCompleted) * 60 : 0.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 24,
                        height: height * _progressAnimation.value,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppConstants.primaryColor,
                              AppConstants.primaryColor.withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppConstants.radiusS),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    entry.key,
                    style: AppConstants.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    entry.value.toString(),
                    style: AppConstants.labelSmall.copyWith(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getCompletionRateColor(double rate) {
    if (rate >= 0.8) return AppConstants.successColor;
    if (rate >= 0.5) return AppConstants.primaryColor;
    if (rate >= 0.3) return AppConstants.warningColor;
    return AppConstants.errorColor;
  }
}
