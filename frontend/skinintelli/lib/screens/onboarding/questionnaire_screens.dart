part of 'package:skinintelli/main.dart';

extension QuestionnaireScreenWidgets on _SkinIntelAppState {
  Widget _qSkinTypeScreen() => _buildQuestionStep(
    title: 'Select Your Skin Type',
    currentStep: 1,
    totalSteps: 4,
    onBack: () => setState(() => currentScreen = Screen.success),
    onNext: () => setState(() => currentScreen = Screen.qSkinConcerns),
    canNext: qSkinType.isNotEmpty,
    options: ['Dry', 'Oily', 'Combination', 'Sensitive', 'Normal', 'Not Sure'],
    selected: qSkinType,
    onSelect: (v) => setState(() => qSkinType = v),
  );

  Widget _qSkinConcernsScreen() {
    List<String> concerns = [
      'Acne',
      'Dark Spots',
      'Wrinkles',
      'Redness',
      'Dryness',
      'Open Pores',
      'Pigmentation',
      'Dull Skin',
      'Others',
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
              onPressed: () => setState(() => currentScreen = Screen.qSkinType),
            ),
            title: stepIndicator(current: 2, total: 4),
            centerTitle: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Select Your Skin Concerns',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can select multiple concerns',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppTheme.mutedForeground,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        concerns.map((c) {
                          bool isSel = qSkinConcerns.contains(c);
                          return FilterChip(
                            label: Text(c),
                            selected: isSel,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  qSkinConcerns.add(c);
                                } else {
                                  qSkinConcerns.remove(c);
                                }
                              });
                            },
                            selectedColor: AppTheme.primary,
                            checkmarkColor: Colors.white,
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed:
                        qSkinConcerns.isNotEmpty
                            ? () => setState(
                              () => currentScreen = Screen.qAllergies,
                            )
                            : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: AppTheme.mutedForeground,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Widget _qAllergiesScreen() {
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
                  () => setState(() => currentScreen = Screen.qSkinConcerns),
            ),
            title: stepIndicator(current: 3, total: 4),
            centerTitle: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Enter Your Allergy Concerns',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us about any skin allergies or sensitivities',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppTheme.mutedForeground,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    maxLines: 5,
                    onChanged: (v) => setState(() => qAllergies = v),
                    decoration: InputDecoration(
                      hintText:
                          'Write your skin concerns and allergies here...',
                      filled: true,
                      fillColor: AppTheme.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    enabled: !qNotSureAllergies,
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: qNotSureAllergies,
                        onChanged:
                            (val) => setState(
                              () => qNotSureAllergies = val ?? false,
                            ),
                        activeColor: AppTheme.primary,
                      ),
                      const Text('Not Sure', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed:
                        (qAllergies.isNotEmpty || qNotSureAllergies)
                            ? () => setState(
                              () => currentScreen = Screen.qEnvironment,
                            )
                            : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: AppTheme.mutedForeground,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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

  Widget _qEnvironmentScreen() => _buildQuestionStep(
    title: 'Select Your Living Environment',
    currentStep: 4,
    totalSteps: 4,
    onBack: () => setState(() => currentScreen = Screen.qAllergies),
    onNext: () {
      setState(() => currentScreen = Screen.qCompletion);
      _submitQuestionnaire();
    },
    canNext: qEnvironment.isNotEmpty,
    options: [
      'Urban',
      'Sub Urban',
      'Rural',
      'Humid Area',
      'Dry Climate',
      'Polluted Area',
      'Not Sure',
    ],
    selected: qEnvironment,
    onSelect: (v) => setState(() => qEnvironment = v),
  );

  Widget _qCompletionScreen() {
    if (qCompletionProcessing) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Analyzing Your Skin Profile',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Processing your information to create personalized recommendations...',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (qCompletionMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                Text(
                  'Unable to generate recommendations',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  qCompletionMessage,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading ? null : () => _submitQuestionnaire(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: AppTheme.primary,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (qCompletionReady) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Your Skin Profile is Ready!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Here are your personalized recommendations',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Recommended Ingredients',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (qCompletionIngredients.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    'No ingredient recommendations are available right now.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                )
              else
                Column(
                  children:
                      qCompletionIngredients.map((ingredient) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _recommendationCard(
                            icon: Icons.opacity,
                            title:
                                ingredient['name']?.toString() ?? 'Ingredient',
                            subtitle: ingredient['benefit']?.toString() ?? '',
                          ),
                        );
                      }).toList(),
                ),
              const SizedBox(height: 24),
              Text(
                'Recommended Products',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (qCompletionProducts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    'No product recommendations are available right now.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                )
              else
                Column(
                  children:
                      qCompletionProducts.map((product) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _recommendationCard(
                            icon: Icons.shopping_bag,
                            title: product['name']?.toString() ?? 'Product',
                            subtitle: product['explanation']?.toString() ?? '',
                          ),
                        );
                      }).toList(),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed:
                    () => setState(() => currentScreen = Screen.dashboard),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Continue to Dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analyzing Your Skin Profile',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Processing your information to create personalized recommendations...',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppTheme.mutedForeground,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionStep({
    required String title,
    required int currentStep,
    required int totalSteps,
    required VoidCallback onBack,
    required VoidCallback onNext,
    required bool canNext,
    required List<String> options,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
              onPressed: onBack,
            ),
            title: stepIndicator(current: currentStep, total: totalSteps),
            centerTitle: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Help us understand your skin better',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: AppTheme.mutedForeground,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Column(
                    children:
                        options.map((option) {
                          final isSelected = selected == option;
                          return GestureDetector(
                            onTap: () => onSelect(option),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 18,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? AppTheme.primary
                                        : AppTheme.card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.transparent
                                          : AppTheme.border,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withAlpha(
                                      ((isSelected ? 0.12 : 0.06) * 255)
                                          .round(),
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : AppTheme.foreground,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(
                                          (0.3 * 255).round(),
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: canNext ? onNext : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: AppTheme.primary,
                      disabledBackgroundColor: AppTheme.mutedForeground,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
