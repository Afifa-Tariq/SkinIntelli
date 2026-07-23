part of 'package:skinintelli/main.dart';

extension AboutScreenWidgets on _SkinIntelAppState {
  Widget _aboutScreen() {
    final features = [
      {
        'icon': Icons.auto_awesome_outlined,
        'title': 'AI-Powered Analysis',
        'description': 'Smart skin recommendations tailored to you',
      },
      {
        'icon': Icons.shield_outlined,
        'title': 'Safe & Secure',
        'description': 'Your data is encrypted and protected',
      },
      {
        'icon': Icons.trending_up_outlined,
        'title': 'Track Progress',
        'description': 'Monitor your skin health journey',
      },
      {
        'icon': Icons.favorite_outline,
        'title': 'Personalized Care',
        'description': 'Customized routines for your skin type',
      },
    ];

    final members = [
      {'name': 'Dr. Sarah Johnson', 'role': 'Dermatologist Advisor'},
      {'name': 'Alex Chen', 'role': 'Lead Developer'},
      {'name': 'Maria Garcia', 'role': 'UX Designer'},
    ];

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
                          'About',
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
                const SizedBox(height: 30),
                _buildAppLogo(),
                _buildMissionCard(),
                _buildSectionHeader('Key Features'),
                ...features.map((feature) => _buildFeatureCard(feature)),
                _buildSectionHeader('Meet the Team'),
                ...members.map((member) => _buildTeamMemberCard(member)),
                _buildSectionHeader('Contact & Links'),
                _buildLinkItem(
                  icon: Icons.mail_outline,
                  label: 'Email Us',
                  subtitle: 'support@skinintel.com',
                  onTap: () {},
                ),
                _buildLinkItem(
                  icon: Icons.description_outlined,
                  label: 'Privacy Policy',
                  onTap: () {},
                ),
                _buildLinkItem(
                  icon: Icons.description_outlined,
                  label: 'Terms of Service',
                  onTap: () {},
                ),
                const SizedBox(height: 24),
                _buildFooter(),
                const SizedBox(height: 32),
              ],
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
          if (menuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => menuOpen = false),
                child: Container(
                  color: Colors.black.withAlpha((0.35 * 255).round()),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppLogo() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.water_drop, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          'SkinIntel',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.02,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your Intelligent Skincare Companion',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: AppTheme.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Version 1.0.0',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildMissionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppTheme.card, AppTheme.primary.withOpacity(0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent.withOpacity(0.15),
            ),
            child: const Icon(
              Icons.track_changes_outlined,
              color: AppTheme.accent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Mission',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Empowering individuals to achieve healthy, radiant skin through personalized AI-driven recommendations and intelligent skincare tracking.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.primary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.foreground,
        ),
      ),
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature['icon'], size: 22, color: AppTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  feature['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.accent],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member['role'],
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkItem({
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foreground,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: AppTheme.mutedForeground,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Made with ❤️ by the SkinIntel Team',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '© 2026 SkinIntel. All rights reserved.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.mutedForeground,
          ),
        ),
      ],
    );
  }
}
