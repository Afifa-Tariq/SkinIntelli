part of 'package:skinintelli/main.dart';

extension DashboardScreenWidgets on _SkinIntelAppState {
  Widget _dashboardScreen() {
    final String skinConcern =
        qSkinConcerns.isNotEmpty ? qSkinConcerns.first : 'No concern selected';
    final String skinType = qSkinType.isNotEmpty ? qSkinType : 'Not selected';
    final String environment =
        qEnvironment.isNotEmpty ? qEnvironment : 'Not selected';

    Widget statCard(String value, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => menuOpen = true),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.menu, color: Colors.black87),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'SkinIntel',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                        Text(
                          'Dashboard',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap:
                          () => setState(() => currentScreen = Screen.profile),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.person, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Good Morning ✨',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Let\'s check your skin today',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statCard('12', 'Day Streak'),
                    const SizedBox(width: 12),
                    statCard('8', 'Products Tried'),
                    const SizedBox(width: 12),
                    statCard('88', 'Skin Score'),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Skin Progress',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your skin is improving',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Icon(
                              Icons.trending_up,
                              color: AppTheme.primary,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: 0.9,
                                  strokeWidth: 11,
                                  color: AppTheme.accent,
                                  backgroundColor: AppTheme.primary.withAlpha(
                                    (0.15 * 255).round(),
                                  ),
                                ),
                                Text(
                                  '90%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _progressRow(
                                  'Hydration',
                                  'Good',
                                  AppTheme.primary,
                                ),
                                const SizedBox(height: 10),
                                _progressRow(
                                  'Clarity',
                                  'Improving',
                                  AppTheme.accent,
                                ),
                                const SizedBox(height: 10),
                                _progressRow(
                                  'Texture',
                                  'Good',
                                  AppTheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Routine',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'April 14, 2026',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed:
                                () => setState(
                                  () => currentScreen = Screen.schedule,
                                ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(50, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'View Full Schedule',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _routineItem(
                        'Morning',
                        'Cleanser + Vitamin C',
                        Icons.wb_sunny,
                        const Color(0xFFFFA500),
                        AppTheme.primary,
                      ),
                      const SizedBox(height: 12),
                      _routineItem(
                        'Night',
                        'Moisturizer + Retinol',
                        Icons.nightlight_round,
                        const Color(0xFF4F46E5),
                        AppTheme.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Skin Profile',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _profileDetailRow('Skin Type', skinType),
                      const SizedBox(height: 10),
                      _profileDetailRow('Concern', skinConcern),
                      const SizedBox(height: 10),
                      _profileDetailRow('Environment', environment),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // ── Side Drawer ──
          if (menuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => menuOpen = false),
                child: Container(
                  color: Colors.black.withAlpha((0.35 * 255).round()),
                ),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: 0,
            bottom: 0,
            left: menuOpen ? 0 : -280,
            child: SizedBox(
              width: 280,
              child: Material(
                elevation: 16,
                color: AppTheme.card,
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primary,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userFullName.isNotEmpty
                                          ? _userFullName
                                          : 'User',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                    Text(
                                      registeredEmail,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppTheme.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed:
                                    () => setState(() => menuOpen = false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _drawerItem(
                            Icons.dashboard,
                            'Dashboard',
                            currentScreen == Screen.dashboard,
                            () => setState(() {
                              currentScreen = Screen.dashboard;
                              menuOpen = false;
                            }),
                          ),
                          const SizedBox(height: 10),
                          _drawerItem(
                            Icons.schedule,
                            'My Schedule',
                            currentScreen == Screen.schedule,
                            () => setState(() {
                              currentScreen = Screen.schedule;
                              menuOpen = false;
                            }),
                          ),
                          const SizedBox(height: 10),
                          _drawerItem(
                            Icons.grass,
                            'Ingredients',
                            currentScreen == Screen.ingredients,
                            () => setState(() {
                              currentScreen = Screen.ingredients;
                              menuOpen = false;
                            }),
                          ),
                          const SizedBox(height: 10),
                          _drawerItem(
                            Icons.inventory_2,
                            'Products',
                            currentScreen == Screen.products,
                            () => setState(() {
                              currentScreen = Screen.products;
                              menuOpen = false;
                            }),
                          ),
                          const SizedBox(height: 10),
                          _drawerItem(
                            Icons.settings,
                            'Recommendations',
                            currentScreen == Screen.skinProfile,
                            () => setState(() {
                              currentScreen = Screen.skinProfile;
                              menuOpen = false;
                            }),
                          ),
                          const SizedBox(height: 10),
                          _drawerItem(
                            Icons.settings,
                            'Settings',
                            currentScreen == Screen.profile,
                            () => setState(() {
                              currentScreen = Screen.profile;
                              menuOpen = false;
                            }),
                          ),
                          const SizedBox(height: 10),
                          _drawerItem(
                            Icons.info_outline,
                            'About',
                            currentScreen == Screen.about,
                            () => setState(() {
                              currentScreen = Screen.about;
                              menuOpen = false;
                            }),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ElevatedButton(
                              onPressed: () => setState(() => menuOpen = false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
