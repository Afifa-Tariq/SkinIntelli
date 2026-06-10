part of 'package:skinintelli/main.dart';

extension ProductsScreenWidgets on _SkinIntelAppState {
  Widget _productsScreen() {
    final List<Map<String, dynamic>> products = [
      {
        'name': 'Hydrating Moisturizer',
        'brand': 'SkinCare Pro',
        'rating': 4.8,
        'price': '\$45.99',
        'icon': Icons.water_drop,
      },
      {
        'name': 'Vitamin C Serum',
        'brand': 'Bright Skin',
        'rating': 4.9,
        'price': '\$38.50',
        'icon': Icons.star,
      },
      {
        'name': 'Gentle Cleanser',
        'brand': 'Pure Essence',
        'rating': 4.7,
        'price': '\$22.99',
        'icon': Icons.bubble_chart,
      },
      {
        'name': 'Retinol Night Cream',
        'brand': 'Anti-Age Elite',
        'rating': 4.9,
        'price': '\$65.00',
        'icon': Icons.nights_stay,
      },
      {
        'name': 'Sunscreen SPF 50',
        'brand': 'UV Shield',
        'rating': 4.8,
        'price': '\$32.99',
        'icon': Icons.wb_sunny,
      },
      {
        'name': 'Exfoliating Toner',
        'brand': 'Glow Up',
        'rating': 4.6,
        'price': '\$28.50',
        'icon': Icons.autorenew,
      },
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
                ...products.map((product) {
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
                            product['icon'],
                            color: AppTheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product['name'],
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.foreground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                product['brand'],
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Row(
                                    children: List.generate(5, (index) {
                                      return Icon(
                                        index < product['rating'].floor()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: AppTheme.accent,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${product['rating']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.foreground,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    product['price'],
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
                              onPressed: () => setState(() => menuOpen = false),
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
                        const Spacer(),
                        ElevatedButton(
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
                      ],
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
