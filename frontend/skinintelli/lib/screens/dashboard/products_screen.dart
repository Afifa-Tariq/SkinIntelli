part of 'package:skinintelli/main.dart';

extension ProductsScreenWidgets on _SkinIntelAppState {
  Future<Map<String, dynamic>> _loadRecommendations() async {
    final response = await ApiService.getRecommendations(
      filter: {'category': 'serum'},
    );
    if (response['statusCode'] == 200) {
      final body = response['body'];
      final rawProducts = body['products'];
      final products = <Map<String, dynamic>>[];
      if (rawProducts is List) {
        for (final item in rawProducts) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(
              item as Map<dynamic, dynamic>,
            );
            if (!(map['is_blocked'] as bool? ?? false)) {
              products.add(map);
            }
          }
        }
      }
      return {'products': products, 'message': null};
    }

    if ((response['statusCode'] ?? 0) == 404) {
      return {
        'products': <Map<String, dynamic>>[],
        'message':
            'Complete your skin profile to see personalized product recommendations.',
      };
    }

    return {
      'products': <Map<String, dynamic>>[],
      'message':
          response['body']?['message'] ?? 'Unable to load recommendations.',
    };
  }

  Widget _productsScreen() {
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
                          'Products',
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
                  'Recommended Products',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, dynamic>>(
                  future: _loadRecommendations(),
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
                        {'products': <Map<String, dynamic>>[], 'message': null};
                    final products =
                        (data['products'] as List<Map<String, dynamic>>?) ??
                        const <Map<String, dynamic>>[];
                    final message = data['message'] as String?;

                    if (message != null && message.isNotEmpty) {
                      return Container(
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

                    if (products.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          'No personalized products available right now.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children:
                          products.map((product) {
                            final finalScore =
                                (product['final_score'] as num?)?.toDouble() ??
                                0.0;
                            final normalizedRating = (finalScore / 20.0).clamp(
                              0.0,
                              5.0,
                            );
                            final explanation =
                                product['explanation']?.toString() ??
                                'Personalized recommendation';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppTheme.background,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.auto_awesome,
                                      color: AppTheme.primary,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name']?.toString() ??
                                              'Product',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.foreground,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          explanation,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppTheme.mutedForeground,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Row(
                                              children: List.generate(5, (
                                                index,
                                              ) {
                                                return Icon(
                                                  index <
                                                          normalizedRating
                                                              .floor()
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: AppTheme.accent,
                                                  size: 16,
                                                );
                                              }),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              normalizedRating.toStringAsFixed(
                                                1,
                                              ),
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.foreground,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              'Score ${finalScore.toStringAsFixed(0)}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
