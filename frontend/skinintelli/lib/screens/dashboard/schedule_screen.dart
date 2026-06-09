part of 'package:skinintelli/main.dart';

extension ScheduleScreenWidgets on _SkinIntelAppState {
  Widget _scheduleScreen() {
    final List<String> days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final List<Map<String, dynamic>> morningTasks = [
      {'id': 1, 'name': 'Cleanser', 'icon': Icons.opacity, 'completed': true},
      {'id': 2, 'name': 'Toner', 'icon': Icons.air, 'completed': true},
      {'id': 3, 'name': 'Serum', 'icon': Icons.star, 'completed': false},
      {
        'id': 4,
        'name': 'Moisturizer',
        'icon': Icons.opacity,
        'completed': false,
      },
      {
        'id': 5,
        'name': 'Sunscreen',
        'icon': Icons.wb_sunny,
        'completed': false,
      },
    ];

    final List<Map<String, dynamic>> nightTasks = [
      {'id': 6, 'name': 'Cleanser', 'icon': Icons.opacity, 'completed': true},
      {'id': 7, 'name': 'Toner', 'icon': Icons.air, 'completed': false},
      {
        'id': 8,
        'name': 'Serum',
        'icon': Icons.nightlight_round,
        'completed': false,
      },
      {
        'id': 9,
        'name': 'Moisturizer',
        'icon': Icons.opacity,
        'completed': false,
      },
    ];

    int completedMorning = morningTasks.where((t) => t['completed']).length;
    int completedNight = nightTasks.where((t) => t['completed']).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap:
                          () =>
                              setState(() => currentScreen = Screen.dashboard),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      'Weekly Skin Schedule',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    GestureDetector(
                      onTap:
                          () => setState(() => currentScreen = Screen.profile),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.edit, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Day Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        days.map((day) {
                          bool isSelected = _selectedScheduleDay == day;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedScheduleDay = day);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? AppTheme.primary
                                        : AppTheme.card,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    isSelected
                                        ? Border.all(color: AppTheme.primary)
                                        : Border.all(color: AppTheme.border),
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: AppTheme.primary.withAlpha(
                                              (0.25 * 255).round(),
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                        : [
                                          BoxShadow(
                                            color: AppTheme.primary.withAlpha(
                                              (0.06 * 255).round(),
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                              ),
                              child: Text(
                                day.substring(0, 3),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : AppTheme.foreground,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // Morning Routine
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFA500,
                                ).withAlpha((0.15 * 255).round()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.wb_sunny,
                                color: Color(0xFFFFA500),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Morning Routine',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.foreground,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$completedMorning/${morningTasks.length} Done',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children:
                          morningTasks.map((task) {
                            bool completed = task['completed'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      completed
                                          ? AppTheme.accent.withAlpha(
                                            (0.08 * 255).round(),
                                          )
                                          : AppTheme.card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        completed
                                            ? AppTheme.accent.withAlpha(
                                              (0.2 * 255).round(),
                                            )
                                            : AppTheme.border,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withAlpha(
                                        (0.06 * 255).round(),
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color:
                                            completed
                                                ? AppTheme.accent
                                                : Colors.transparent,
                                        border:
                                            completed
                                                ? null
                                                : Border.all(
                                                  color: AppTheme.border,
                                                  width: 2,
                                                ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child:
                                          completed
                                              ? const Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Colors.white,
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withAlpha(
                                          (0.1 * 255).round(),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        task['icon'],
                                        color: AppTheme.primary,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        task['name'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              completed
                                                  ? AppTheme.mutedForeground
                                                  : AppTheme.foreground,
                                          decoration:
                                              completed
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Night Routine
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF4F46E5,
                                ).withAlpha((0.15 * 255).round()),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.nightlight_round,
                                color: Color(0xFF4F46E5),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Night Routine',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.foreground,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$completedNight/${nightTasks.length} Done',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children:
                          nightTasks.map((task) {
                            bool completed = task['completed'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      completed
                                          ? AppTheme.accent.withAlpha(
                                            (0.08 * 255).round(),
                                          )
                                          : AppTheme.card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color:
                                        completed
                                            ? AppTheme.accent.withAlpha(
                                              (0.2 * 255).round(),
                                            )
                                            : AppTheme.border,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withAlpha(
                                        (0.06 * 255).round(),
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color:
                                            completed
                                                ? AppTheme.accent
                                                : Colors.transparent,
                                        border:
                                            completed
                                                ? null
                                                : Border.all(
                                                  color: AppTheme.border,
                                                  width: 2,
                                                ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child:
                                          completed
                                              ? const Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Colors.white,
                                              )
                                              : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withAlpha(
                                          (0.1 * 255).round(),
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        task['icon'],
                                        color: AppTheme.primary,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        task['name'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              completed
                                                  ? AppTheme.mutedForeground
                                                  : AppTheme.foreground,
                                          decoration:
                                              completed
                                                  ? TextDecoration.lineThrough
                                                  : TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Weekly Progress
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha((0.08 * 255).round()),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primary.withAlpha((0.1 * 255).round()),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Weekly Progress',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.foreground,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'You\'ve completed 68% of your routine this week',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: 0.68,
                          minHeight: 8,
                          backgroundColor: AppTheme.primary.withAlpha(
                            (0.15 * 255).round(),
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: AppTheme.card,
                border: Border(top: BorderSide(color: AppTheme.border)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha((0.05 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _bottomNavItem(
                    Icons.dashboard,
                    'Dashboard',
                    currentScreen == Screen.dashboard,
                    () => setState(() => currentScreen = Screen.dashboard),
                  ),
                  _bottomNavItem(
                    Icons.schedule,
                    'Schedule',
                    currentScreen == Screen.schedule,
                    () => setState(() => currentScreen = Screen.schedule),
                  ),
                  _bottomNavItem(
                    Icons.person,
                    'Profile',
                    currentScreen == Screen.profile,
                    () => setState(() => currentScreen = Screen.profile),
                  ),
                  _bottomNavItem(
                    Icons.settings,
                    'Settings',
                    currentScreen == Screen.skinProfile,
                    () => setState(() => currentScreen = Screen.skinProfile),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AppTheme.accent : AppTheme.mutedForeground,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? AppTheme.accent : AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
