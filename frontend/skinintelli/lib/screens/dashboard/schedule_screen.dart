part of 'package:skinintelli/main.dart';

extension ScheduleScreenWidgets on _SkinIntelAppState {
  Map<String, dynamic> _scheduleDataFromRoutine(
    Map<String, dynamic> routine,
  ) {
    final morningSteps = <Map<String, dynamic>>[];
    final nightSteps = <Map<String, dynamic>>[];
    final reminders = <String>{};
    final rawItems = routine['items'];

    if (rawItems is List) {
      for (final rawItem in rawItems) {
        if (rawItem is! Map) continue;
        final item = Map<String, dynamic>.from(rawItem);
        final rawProduct = item['product'];
        final product =
            rawProduct is Map
                ? Map<String, dynamic>.from(rawProduct)
                : <String, dynamic>{};
        final time = (item['time_of_day'] ?? item['time'] ?? '')
            .toString()
            .toUpperCase();
        final notes = item['notes']?.toString().trim() ?? '';
        final step = int.tryParse(
          (item['step_order'] ?? item['step'] ?? '').toString(),
        );

        final scheduleStep = <String, dynamic>{
          'step': step,
          'time': time,
          'product': product['name']?.toString() ?? 'Product',
          'category': product['category']?.toString() ?? '',
          'reminder': notes,
        };

        if (time == 'AM' || time == 'BOTH') morningSteps.add(scheduleStep);
        if (time == 'PM' || time == 'BOTH') nightSteps.add(scheduleStep);
        if (notes.isNotEmpty) {
          reminders.addAll(
            notes
                .split(' | ')
                .map((reminder) => reminder.trim())
                .where((reminder) => reminder.isNotEmpty),
          );
        }
      }
    } else {
      final rawMorning = routine['morning_steps'];
      final rawNight = routine['night_steps'];
      if (rawMorning is List) {
        morningSteps.addAll(
          rawMorning.whereType<Map>().map(
            (step) => Map<String, dynamic>.from(step),
          ),
        );
      }
      if (rawNight is List) {
        nightSteps.addAll(
          rawNight.whereType<Map>().map(
            (step) => Map<String, dynamic>.from(step),
          ),
        );
      }
      final rawReminders = routine['reminders'];
      if (rawReminders is List) {
        reminders.addAll(
          rawReminders
              .whereType<String>()
              .map((reminder) => reminder.trim())
              .where((reminder) => reminder.isNotEmpty),
        );
      }
    }

    return {
      'morning_steps': morningSteps,
      'night_steps': nightSteps,
      'reminders': reminders.toList(),
      'message':
          morningSteps.isEmpty && nightSteps.isEmpty
              ? 'Your active routine has no scheduled steps yet.'
              : null,
    };
  }

  String _scheduleErrorMessage(dynamic body, String fallback) {
    if (body is! Map) return fallback;
    final message = body['message']?.toString();
    if (message == 'NO_SKIN_PROFILE') {
      return 'Complete your skin profile before generating a schedule.';
    }
    if (message == 'NO_RECOMMENDATIONS') {
      return 'No recommended products are available to build your schedule.';
    }
    return message == null || message.isEmpty ? fallback : message;
  }

  Future<Map<String, dynamic>> _loadRoutinePayload() async {
    final activeRoutineResponse = await ApiService.getActiveRoutine();
    if (activeRoutineResponse['statusCode'] == 200 &&
        activeRoutineResponse['body'] is Map) {
      return _scheduleDataFromRoutine(
        Map<String, dynamic>.from(
          activeRoutineResponse['body'] as Map<dynamic, dynamic>,
        ),
      );
    }

    if (activeRoutineResponse['statusCode'] != 404) {
      return {
        'morning_steps': <Map<String, dynamic>>[],
        'night_steps': <Map<String, dynamic>>[],
        'reminders': <String>[],
        'message': _scheduleErrorMessage(
          activeRoutineResponse['body'],
          'Unable to load your routine. Check your connection and try again.',
        ),
      };
    }

    final recommendationsResponse = await ApiService.getRecommendations(
      topN: 8,
    );

    if (recommendationsResponse['statusCode'] != 200 ||
        recommendationsResponse['body'] is! Map) {
      return {
        'morning_steps': <Map<String, dynamic>>[],
        'night_steps': <Map<String, dynamic>>[],
        'reminders': <String>[],
        'message': _scheduleErrorMessage(
          recommendationsResponse['body'],
          'Unable to load recommendations. Check your connection and try again.',
        ),
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

    if (routineResponse['statusCode'] == 201 &&
        routineResponse['body'] is Map) {
      final responseBody = Map<String, dynamic>.from(
        routineResponse['body'] as Map<dynamic, dynamic>,
      );
      final routine = responseBody['routine'];
      if (routine is Map) {
        return _scheduleDataFromRoutine(
          Map<String, dynamic>.from(routine),
        );
      }
      return _scheduleDataFromRoutine(responseBody);
    }

    return {
      'morning_steps': <Map<String, dynamic>>[],
      'night_steps': <Map<String, dynamic>>[],
      'reminders': <String>[],
      'message': _scheduleErrorMessage(
        routineResponse['body'],
        'Unable to generate your routine. Check the backend and try again.',
      ),
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
        future: _scheduleRoutineFuture ??= _loadRoutinePayload(),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _scheduleRoutineFuture =
                                      _loadRoutinePayload();
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
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
                                  morningSteps
                                      .map(
                                        (task) => _scheduleStepCard(
                                          task,
                                          accentColor: AppTheme.primary,
                                          icon: Icons.stars,
                                        ),
                                      )
                                      .toList(),
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
                                  nightSteps
                                      .map(
                                        (task) => _scheduleStepCard(
                                          task,
                                          accentColor: const Color(0xFF4F46E5),
                                          icon: Icons.nightlight_round,
                                        ),
                                      )
                                      .toList(),
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
