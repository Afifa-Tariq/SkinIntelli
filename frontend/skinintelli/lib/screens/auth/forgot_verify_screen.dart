part of 'package:skinintelli/main.dart';

extension ForgotVerifyScreenWidgets on _SkinIntelAppState {
  Widget _forgotVerifyScreen() {
    List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed:
              () => setState(() => currentScreen = Screen.forgotPassword),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accent.withAlpha((0.15 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.email_outlined,
                size: 40,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Verify Your Email',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ve sent a 6-digit code to your email address',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppTheme.mutedForeground,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextField(
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    keyboardType: TextInputType.number,
                    focusNode: focusNodes[i],
                    onChanged: (val) {
                      setState(() => otpValues[i] = val);
                      if (val.isNotEmpty && i < 5) {
                        focusNodes[i + 1].requestFocus();
                      }
                    },
                    decoration: const InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Didn\'t receive code? ',
                  style: GoogleFonts.poppins(color: AppTheme.mutedForeground),
                ),
                if (resendTimer > 0)
                  Text(
                    'Resend in ${resendTimer}s',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  )
                else
                  GestureDetector(
                    onTap: startResendTimer,
                    child: Text(
                      'Resend Code',
                      style: GoogleFonts.poppins(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: isLoading ? null : _submitVerifyResetOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Verify',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
