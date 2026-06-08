part of 'package:skinintelli/main.dart';

extension SignUpScreenWidgets on _SkinIntelAppState {
  Widget _signUpScreen() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: () => setState(() => currentScreen = Screen.welcome),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Account',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign up to get started with SkinIntel',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: signUpFullNameCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person_outline),
                labelText: 'Full Name',
                hintText: 'Enter your full name',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: signUpEmailCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined),
                labelText: 'Email',
                hintText: 'your.email@example.com',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: signUpPasswordCtrl,
              obscureText: !showPassword,
              onChanged: calculatePasswordStrength,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                labelText: 'Password',
                hintText: 'Create a strong password',
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
            ),
            if (passwordStrength > 0) ...[
              const SizedBox(height: 8),
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
              const SizedBox(height: 4),
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
            ],
            const SizedBox(height: 16),
            TextField(
              controller: signUpConfirmPasswordCtrl,
              obscureText: !showConfirmPassword,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline),
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
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
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: agreeTerms,
                  onChanged: (val) => setState(() => agreeTerms = val ?? false),
                  activeColor: AppTheme.accent,
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'I agree to the ',
                      children: [
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ],
            ),
            if (!agreeTerms) ...[
              const SizedBox(height: 4),
              Text(
                'You must agree to the terms before creating an account.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.accent,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Tooltip(
              message:
                  agreeTerms
                      ? ''
                      : 'Please agree to the Terms & Conditions to continue',
              child: ElevatedButton(
                onPressed: _submitSignUp,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white.withAlpha(180),
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: AppTheme.mutedForeground,
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: GoogleFonts.poppins(color: AppTheme.mutedForeground),
                ),
                TextButton(
                  onPressed: () => setState(() => currentScreen = Screen.login),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
