part of 'package:skinintelli/main.dart';

extension ScheduleScreenWidgets on _SkinIntelAppState {
  Future<Map<String, dynamic>> _loadRoutinePayload() async {
    final recommendationsResponse = await ApiService.getRecommendations(
      filter: {'category': 'serum'},
    );

    if (recommendationsResponse['statusCode'] != 200 ||
        recommendationsResponse['body'] is! Map) {
      return {
        'morning_steps': <Map<String, dynamic>>[],
        'night_steps': <Map<String, dynamic>>[],
        'reminders': <String>[],
        'message':
            recommendationsResponse['body']?['message'] ??
            'Unable to load your routine right now.',
      };
    }

    final recommendationsBody = Map<String, dynamic>.from(
      recommendationsResponse['body'] as Map<dynamic, dynamic>,
    );
    final rawProducts = recommendationsBody['products'];
    final recommendations = <Map<String, dynamic>>[];

    if (rawProducts is List) {
      for (final item in rawProducts) {
        if (item is Map) {
          recommendations.add(Map<String, dynamic>.from(item));
        }
      }
    }

    if (recommendations.isEmpty) {
      return {
        'morning_steps': <Map<String, dynamic>>[],
        'night_steps': <Map<String, dynamic>>[],
        'reminders': <String>[],
        'message':
            'No product recommendations are available to build a routine.',
      };
    }

    final routineResponse = await ApiService.generateRoutine(
      recommendations: recommendations,
    );

    if (routineResponse['statusCode'] == 200 &&
        routineResponse['body'] is Map) {
      return Map<String, dynamic>.from(
        routineResponse['body'] as Map<dynamic, dynamic>,
      );
    }

    return {
      'morning_steps': <Map<String, dynamic>>[],
      'night_steps': <Map<String, dynamic>>[],
      'reminders': <String>[],
      'message':
          routineResponse['body']?['message'] ??
          'Unable to generate your routine right now.',
    };
  }

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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadRoutinePayload(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final data =
              snapshot.data ??
              {
                'morning_steps': <Map<String, dynamic>>[],
                'night_steps': <Map<String, dynamic>>[],
                'reminders': <String>[],
                'message': null,
              };

          final morningSteps = <Map<String, dynamic>>[];
          final nightSteps = <Map<String, dynamic>>[];
          final reminders = <String>[];

          final rawMorning = data['morning_steps'];
          final rawNight = data['night_steps'];
          final rawReminders = data['reminders'];

          if (rawMorning is List) {
            for (final item in rawMorning) {
              if (item is Map) {
                morningSteps.add(Map<String, dynamic>.from(item));
              }
            }
          }

          if (rawNight is List) {
            for (final item in rawNight) {
              if (item is Map) {
                nightSteps.add(Map<String, dynamic>.from(item));
              }
            }
          }

          if (rawReminders is List) {
            for (final item in rawReminders) {
              if (item is String) {
                reminders.add(item);
              }
            }
          }

          final message = data['message']?.toString();
          final morningCount = morningSteps.length;
          final nightCount = nightSteps.length;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap:
                              () => setState(
                                () => currentScreen = Screen.dashboard,
                              ),
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
                              () => setState(
                                () => currentScreen = Screen.profile,
                              ),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                                            ? Border.all(
                                              color: AppTheme.primary,
                                            )
                                            : Border.all(
                                              color: AppTheme.border,
                                            ),
                                    boxShadow:
                                        isSelected
                                            ? [
                                              BoxShadow(
                                                color: AppTheme.primary
                                                    .withAlpha(
                                                      (0.25 * 255).round(),
                                                    ),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                            : [
                                              BoxShadow(
                                                color: AppTheme.primary
                                                    .withAlpha(
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
                    if (message != null && message.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          message,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      )
                    else ...[
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
                                '$morningCount/${morningCount > 0 ? morningCount : 1} Done',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (morningSteps.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                'No morning steps generated yet.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            )
                          else
                            Column(
                              children:
                                  morningSteps.map((task) {
                                    final name =
                                        task['product']?.toString() ??
                                        'Product';
                                    final reminder =
                                        task['reminder']?.toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.card,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.border,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                border: Border.all(
                                                  color: AppTheme.border,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary
                                                    .withAlpha(
                                                      (0.1 * 255).round(),
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.stars,
                                                color: AppTheme.primary,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          AppTheme.foreground,
                                                    ),
                                                  ),
                                                  if (reminder != null &&
                                                      reminder.isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 4,
                                                          ),
                                                      child: Text(
                                                        reminder,
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 11.5,
                                                          color:
                                                              AppTheme
                                                                  .mutedForeground,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            ),
                          const SizedBox(height: 20),
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
                                '$nightCount/${nightCount > 0 ? nightCount : 1} Done',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (nightSteps.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                'No night steps generated yet.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            )
                          else
                            Column(
                              children:
                                  nightSteps.map((task) {
                                    final name =
                                        task['product']?.toString() ??
                                        'Product';
                                    final reminder =
                                        task['reminder']?.toString();
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppTheme.card,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.border,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: Colors.transparent,
                                                border: Border.all(
                                                  color: AppTheme.border,
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primary
                                                    .withAlpha(
                                                      (0.1 * 255).round(),
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.nightlight_round,
                                                color: AppTheme.primary,
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color:
                                                          AppTheme.foreground,
                                                    ),
                                                  ),
                                                  if (reminder != null &&
                                                      reminder.isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 4,
                                                          ),
                                                      child: Text(
                                                        reminder,
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 11.5,
                                                          color:
                                                              AppTheme
                                                                  .mutedForeground,
                                                        ),
                                                      ),
                                                    ),
                                                ],
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
                      if (reminders.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(
                              (0.08 * 255).round(),
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppTheme.primary.withAlpha(
                                (0.1 * 255).round(),
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Routine Reminders',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.foreground,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...reminders.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    item,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.mutedForeground,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 100),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
