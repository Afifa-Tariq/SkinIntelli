part of 'package:skinintelli/main.dart';

extension SkinProfileWidgets on _SkinIntelAppState {
  Widget _skinProfile() {
    final String skinConcern =
        qSkinConcerns.isNotEmpty ? qSkinConcerns.first : 'No concern selected';
    final String skinType = qSkinType.isNotEmpty ? qSkinType : 'Not selected';
    final String environment =
        qEnvironment.isNotEmpty ? qEnvironment : 'Not selected';

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

                // ── Header Row ──
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
                      'My Skin Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
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
                const SizedBox(height: 20),

                // ── Profile Card with Gradient ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userFullName.isNotEmpty
                                      ? _userFullName
                                      : 'User',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Skin Type: $skinType',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '85',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Score',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children:
                            qSkinConcerns
                                .take(3)
                                .map(
                                  (concern) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      concern,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Skin Progress Tracking ──
                Text(
                  'Skin Progress Tracking',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _progressWeekCard('Week 1', '+10%'),
                    const SizedBox(width: 10),
                    _progressWeekCard('Week 4', '+20%'),
                    const SizedBox(width: 10),
                    _progressWeekCard('Week 8', '+30%'),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Skin Concerns Tabs ──
                Text(
                  'Skin Concerns',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _concernTab(Icons.auto_fix_high, 'Acne', true),
                      const SizedBox(width: 10),
                      _concernTab(Icons.water_drop, 'Hydration', false),
                      const SizedBox(width: 10),
                      _concernTab(Icons.wb_sunny, 'Brightening', false),
                      const SizedBox(width: 10),
                      _concernTab(Icons.access_time, 'Anti-aging', false),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── AI Recommendations ──
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'AI Recommendations',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _aiProductCard('Niacinamide Serum', 4.8, 'Morning & Night', [
                  'Reduces Acne',
                  'Controls Oil',
                ]),
                const SizedBox(height: 10),
                _aiProductCard(
                  'Salicylic Acid Cleanser',
                  4.7,
                  'Morning & Night',
                  ['Unclogs Pores', 'Exfoliates'],
                ),
                const SizedBox(height: 24),

                // ── Recommended Ingredients ──
                Text(
                  'Recommended Ingredients',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: [
                    _ingredientCard(
                      Icons.shield,
                      'Niacinamide',
                      'Anti-inflammatory',
                    ),
                    _ingredientCard(
                      Icons.science,
                      'Salicylic Acid',
                      'Exfoliation',
                    ),
                    _ingredientCard(
                      Icons.water_drop,
                      'Hyaluronic Acid',
                      'Hydration',
                    ),
                    _ingredientCard(Icons.wb_sunny, 'Vitamin C', 'Brightening'),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Today's Skincare Tip ──
                Text(
                  "Today's Skincare Tip",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 12),
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
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: AppTheme.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Daily Tip',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Apply sunscreen 15-20 minutes before going outside for maximum protection. Reapply every 2 hours.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: Progress Week Card ──
  Widget _progressWeekCard(String week, String progress) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withAlpha((0.06 * 255).round()),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(Icons.camera_alt, color: AppTheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              week,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_upward, color: AppTheme.accent, size: 14),
                Text(
                  progress,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper: Concern Tab ──
  Widget _concernTab(IconData icon, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.accent.withOpacity(0.1) : AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? AppTheme.accent : AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? AppTheme.accent : AppTheme.mutedForeground,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppTheme.accent : AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper: AI Product Card ──
  Widget _aiProductCard(
    String name,
    double rating,
    String usage,
    List<String> benefits,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withAlpha((0.06 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.star, color: const Color(0xFFFBBF24), size: 16),
              const SizedBox(width: 4),
              Text(
                rating.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foreground,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                usage,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                benefits
                    .map(
                      (b) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          b,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  // ── Helper: Ingredient Card ──
  Widget _ingredientCard(IconData icon, String name, String benefit) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            benefit,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
