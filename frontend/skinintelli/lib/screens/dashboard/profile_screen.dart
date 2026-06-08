part of 'package:skinintelli/main.dart';

extension ProfileScreenWidgets on _SkinIntelAppState {
  Widget _profileScreen() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: AppTheme.primary,
                    ),
                    onPressed:
                        () => setState(() => currentScreen = Screen.dashboard),
                  ),
                  Text(
                    'Edit Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary, AppTheme.accent],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _profileInput(
                      label: 'Full Name',
                      hintText: 'Your full name',
                      controller: profileFullNameCtrl,
                    ),
                    const SizedBox(height: 16),
                    _profileInput(
                      label: 'Email',
                      hintText:
                          registeredEmail.isNotEmpty
                              ? registeredEmail
                              : 'your@email.com',
                      prefixIcon: Icons.email,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    _profileInput(
                      label: 'Username',
                      hintText: 'Choose a username',
                      controller: profileUsernameCtrl,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: isLoading ? null : () async {
                        final fullName = profileFullNameCtrl.text.trim();
                        final username = profileUsernameCtrl.text.trim();
                        if (fullName.isEmpty) {
                          _showMessage('Full name cannot be empty.', isError: true);
                          return;
                        }
                        _setLoading(true);
                        final res = await ApiService.updateProfile(
                          fullName: fullName,
                          username: username.isNotEmpty ? username : null,
                        );
                        _setLoading(false);
                        final ok = res['statusCode'] == 200;
                        _showMessage(
                          ok
                              ? 'Profile updated.'
                              : (res['body'] is Map && res['body']['message'] != null
                                  ? res['body']['message'].toString()
                                  : 'Update failed. Please try again.'),
                          isError: !ok,
                        );
                        if (ok) _userFullName = fullName;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
