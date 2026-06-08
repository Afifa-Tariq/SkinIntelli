part of 'package:skinintelli/main.dart';

extension ResetPasswordScreenWidgets on _SkinIntelAppState {
  Widget _resetPasswordScreen() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: () => setState(() => currentScreen = Screen.forgotVerify),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha((0.15 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Reset Password',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new strong password for your account',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: resetNewPasswordCtrl,
              obscureText: !showPassword,
              onChanged: calculatePasswordStrength,
              decoration: InputDecoration(
                labelText: 'New Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _strengthBar(level: 25, strength: passwordStrength),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _strengthBar(level: 50, strength: passwordStrength),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _strengthBar(level: 75, strength: passwordStrength),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _strengthBar(level: 100, strength: passwordStrength),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              passwordStrength == 100
                  ? 'Strong password'
                  : passwordStrength >= 75
                  ? 'Good password'
                  : passwordStrength >= 50
                  ? 'Fair password'
                  : 'Weak password',
              style: TextStyle(fontSize: 12, color: _strengthColor()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetConfirmPasswordCtrl,
              obscureText: !showConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed:
                      () => setState(
                        () => showConfirmPassword = !showConfirmPassword,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: isLoading ? null : _submitResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Reset Password',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
