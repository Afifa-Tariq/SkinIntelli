part of 'package:skinintelli/main.dart';

extension IngredientsScreenWidgets on _SkinIntelAppState {
  Widget _ingredientsScreen() {
    final recommendationsFuture = _loadDashboardRecommendations();

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
                          'Ingredients',
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
                Text(
                  'Key Ingredients',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>>(
                  future: recommendationsFuture,
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
                          'products': <Map<String, dynamic>>[],
                          'ingredients': <Map<String, dynamic>>[],
                          'message': null,
                        };
                    final ingredients =
                        (data['ingredients'] as List<dynamic>?)
                            ?.cast<Map<String, dynamic>>() ??
                        const <Map<String, dynamic>>[];
                    final message = data['message'] as String?;

                    if (message != null && message.isNotEmpty) {
                      return Container(
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
                      );
                    }

                    if (ingredients.isEmpty) {
                      return Container(
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
                      );
                    }

                    return Column(
                      children:
                          ingredients.map((ingredient) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _recommendationCard(
                                icon: Icons.opacity,
                                title: ingredient['name']?.toString() ?? '',
                                subtitle:
                                    ingredient['benefit']?.toString() ?? '',
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 40),
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
}
