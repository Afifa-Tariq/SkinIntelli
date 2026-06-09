part of 'package:skinintelli/main.dart';

extension PreferencesScreenWidgets on _SkinIntelAppState {
  Widget _preferencesScreen() {
    List<String> goals = [
      'Clear Skin',
      'Hydration',
      'Glow',
      'Anti-Aging',
      'Brightening',
      'Even Tone',
    ];
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
              onPressed:
                  () => setState(() => currentScreen = Screen.profileSetup),
            ),
            title: stepIndicator(current: 2, total: 2),
            centerTitle: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Personalize Your Experience',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Help us customize your skincare journey',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppTheme.mutedForeground,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'What are your skincare goals? (Select all that apply)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        goals.map((goal) {
                          bool isSelected = selectedGoals.contains(goal);
                          return FilterChip(
                            label: Text(goal),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  selectedGoals.add(goal);
                                } else {
                                  selectedGoals.remove(goal);
                                }
                              });
                            },
                            selectedColor: AppTheme.primary,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? Colors.white
                                      : AppTheme.foreground,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed:
                        selectedGoals.isEmpty
                            ? null
                            : () {
                              _startSuccessTimer();
                              setState(() => currentScreen = Screen.success);
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Finish Setup',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
