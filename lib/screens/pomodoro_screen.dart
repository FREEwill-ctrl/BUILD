import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pomodoro_provider.dart';
import '../utils/constants.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({Key? key}) : super(key: key);

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _pulseController.repeat(reverse: true);
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1C1B1F),
                    AppConstants.primaryColor.withOpacity(0.1),
                    AppConstants.secondaryColor.withOpacity(0.1),
                  ]
                : [
                    const Color(0xFFFFFBFE),
                    AppConstants.primaryColor.withOpacity(0.02),
                    AppConstants.secondaryColor.withOpacity(0.02),
                  ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacing20),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(AppConstants.radiusM),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: AppConstants.spacing16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus Timer',
                            style: AppConstants.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Stay productive with Pomodoro',
                            style: AppConstants.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Timer Content
              Expanded(
                child: Consumer<PomodoroProvider>(
                  builder: (context, pomodoroProvider, child) {
                    return Padding(
                      padding: const EdgeInsets.all(AppConstants.spacing20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Session Type Card
                          AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppConstants.spacing20,
                                    vertical: AppConstants.spacing12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getSessionColor(pomodoroProvider.sessionType).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(AppConstants.radiusXL),
                                    border: Border.all(
                                      color: _getSessionColor(pomodoroProvider.sessionType).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _getSessionIcon(pomodoroProvider.sessionType),
                                        color: _getSessionColor(pomodoroProvider.sessionType),
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppConstants.spacing8),
                                      Text(
                                        _getSessionName(pomodoroProvider.sessionType),
                                        style: AppConstants.titleMedium.copyWith(
                                          color: _getSessionColor(pomodoroProvider.sessionType),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: AppConstants.spacing48),

                          // Circular Timer
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: pomodoroProvider.state == PomodoroState.running
                                    ? _pulseAnimation.value
                                    : 1.0,
                                child: Container(
                                  width: 280,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getSessionColor(pomodoroProvider.sessionType).withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Background Circle
                                      Container(
                                        width: 280,
                                        height: 280,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: theme.colorScheme.surface,
                                          border: Border.all(
                                            color: theme.colorScheme.outline.withOpacity(0.1),
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      
                                      // Progress Circle
                                      SizedBox(
                                        width: 260,
                                        height: 260,
                                        child: CircularProgressIndicator(
                                          value: _getProgress(pomodoroProvider),
                                          strokeWidth: 8,
                                          backgroundColor: theme.colorScheme.outline.withOpacity(0.1),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _getSessionColor(pomodoroProvider.sessionType),
                                          ),
                                          strokeCap: StrokeCap.round,
                                        ),
                                      ),
                                      
                                      // Timer Text
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            pomodoroProvider.formattedTime,
                                            style: AppConstants.displayMedium.copyWith(
                                              fontWeight: FontWeight.w300,
                                              color: theme.colorScheme.onSurface,
                                              letterSpacing: -2,
                                            ),
                                          ),
                                          const SizedBox(height: AppConstants.spacing8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppConstants.spacing12,
                                              vertical: AppConstants.spacing4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getSessionColor(pomodoroProvider.sessionType).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(AppConstants.radiusS),
                                            ),
                                            child: Text(
                                              '${pomodoroProvider.pomodoroCount} completed',
                                              style: AppConstants.bodySmall.copyWith(
                                                color: _getSessionColor(pomodoroProvider.sessionType),
                                                fontWeight: FontWeight.w600,
                                              ),
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

                          const SizedBox(height: AppConstants.spacing48),

                          // Control Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (pomodoroProvider.state != PomodoroState.running) ...[
                                _buildControlButton(
                                  icon: Icons.play_arrow_rounded,
                                  label: 'Start',
                                  onPressed: pomodoroProvider.startTimer,
                                  isPrimary: true,
                                  color: _getSessionColor(pomodoroProvider.sessionType),
                                ),
                              ] else ...[
                                _buildControlButton(
                                  icon: Icons.pause_rounded,
                                  label: 'Pause',
                                  onPressed: pomodoroProvider.pauseTimer,
                                  isPrimary: true,
                                  color: AppConstants.warningColor,
                                ),
                              ],
                              
                              const SizedBox(width: AppConstants.spacing16),
                              
                              if (pomodoroProvider.state == PomodoroState.paused) ...[
                                _buildControlButton(
                                  icon: Icons.play_arrow_rounded,
                                  label: 'Resume',
                                  onPressed: pomodoroProvider.resumeTimer,
                                  isPrimary: false,
                                  color: _getSessionColor(pomodoroProvider.sessionType),
                                ),
                                const SizedBox(width: AppConstants.spacing16),
                              ],
                              
                              _buildControlButton(
                                icon: Icons.stop_rounded,
                                label: 'Stop',
                                onPressed: pomodoroProvider.stopTimer,
                                isPrimary: false,
                                color: AppConstants.errorColor,
                              ),
                            ],
                          ),

                          const SizedBox(height: AppConstants.spacing40),

                          // Session Info Cards
                          _buildSessionInfoCards(pomodoroProvider, theme),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return AnimatedContainer(
      duration: AppConstants.shortAnimation,
      child: isPrimary
          ? FilledButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing24,
                  vertical: AppConstants.spacing16,
                ),
                textStyle: AppConstants.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacing24,
                  vertical: AppConstants.spacing16,
                ),
                textStyle: AppConstants.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
    );
  }

  Widget _buildSessionInfoCards(PomodoroProvider provider, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            icon: Icons.timer_outlined,
            title: 'Session',
            value: _getSessionName(provider.sessionType),
            color: _getSessionColor(provider.sessionType),
            theme: theme,
          ),
        ),
        const SizedBox(width: AppConstants.spacing12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.check_circle_outline,
            title: 'Completed',
            value: '${provider.pomodoroCount}',
            color: AppConstants.successColor,
            theme: theme,
          ),
        ),
        const SizedBox(width: AppConstants.spacing12),
        Expanded(
          child: _buildInfoCard(
            icon: Icons.trending_up_rounded,
            title: 'Status',
            value: _getStatusText(provider.state),
            color: _getStatusColor(provider.state),
            theme: theme,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
            title,
            style: AppConstants.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppConstants.spacing4),
          Text(
            value,
            style: AppConstants.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _getProgress(PomodoroProvider provider) {
    final totalSeconds = provider.sessionType == SessionType.pomodoro
        ? 25 * 60
        : provider.sessionType == SessionType.shortBreak
            ? 5 * 60
            : 15 * 60;
    return 1 - (provider.secondsRemaining / totalSeconds);
  }

  Color _getSessionColor(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.pomodoro:
        return AppConstants.primaryColor;
      case SessionType.shortBreak:
        return AppConstants.successColor;
      case SessionType.longBreak:
        return AppConstants.accentColor;
    }
  }

  IconData _getSessionIcon(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.pomodoro:
        return Icons.work_outline_rounded;
      case SessionType.shortBreak:
        return Icons.coffee_outlined;
      case SessionType.longBreak:
        return Icons.spa_outlined;
    }
  }

  String _getSessionName(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.pomodoro:
        return 'Focus Time';
      case SessionType.shortBreak:
        return 'Short Break';
      case SessionType.longBreak:
        return 'Long Break';
    }
  }

  String _getStatusText(PomodoroState state) {
    switch (state) {
      case PomodoroState.idle:
        return 'Ready';
      case PomodoroState.running:
        return 'Active';
      case PomodoroState.paused:
        return 'Paused';
    }
  }

  Color _getStatusColor(PomodoroState state) {
    switch (state) {
      case PomodoroState.idle:
        return AppConstants.primaryColor;
      case PomodoroState.running:
        return AppConstants.successColor;
      case PomodoroState.paused:
        return AppConstants.warningColor;
    }
  }
}


