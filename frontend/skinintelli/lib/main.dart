import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/api_service.dart';
import 'utils/constants.dart';

part 'screens/splash_screen.dart';
part 'screens/welcome_screen.dart';
part 'screens/auth/signup_screen.dart';
part 'screens/auth/login_screen.dart';
part 'screens/auth/verify_email_screen.dart';
part 'screens/auth/forgot_password_screen.dart';
part 'screens/auth/forgot_verify_screen.dart';
part 'screens/auth/reset_password_screen.dart';
part 'screens/auth/reset_success_screen.dart';
part 'screens/onboarding/profile_setup_screen.dart';
part 'screens/onboarding/preferences_screen.dart';
part 'screens/onboarding/success_screen.dart';
part 'screens/onboarding/questionnaire_screens.dart';
part 'screens/dashboard/dashboard_screen.dart';
part 'screens/dashboard/profile_screen.dart';
part 'screens/screen_helpers.dart';

void main() {
  runApp(const SkinIntelApp());
}

enum Screen {
  splash,
  welcome,
  signup,
  verifyEmail,
  profileSetup,
  preferences,
  success,
  qSkinType,
  qSkinConcerns,
  qAllergies,
  qEnvironment,
  qCompletion,
  login,
  forgotPassword,
  forgotVerify,
  resetPassword,
  resetSuccess,
  dashboard,
  profile,
}

class SkinIntelApp extends StatefulWidget {
  const SkinIntelApp({super.key});

  @override
  State<SkinIntelApp> createState() => _SkinIntelAppState();
}

class _SkinIntelAppState extends State<SkinIntelApp>
    with TickerProviderStateMixin {
  Screen currentScreen = Screen.splash;

  bool agreeTerms = false;
  int passwordStrength = 0;
  bool showPassword = false;
  bool showConfirmPassword = false;
  List<String> otpValues = List.filled(6, '');
  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());
  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  int resendTimer = 0;
  Timer? resendTimerObj;

  String selectedGender = '';
  List<String> selectedGoals = [];
  String _userFullName = '';

  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool isLoading = false;
  final TextEditingController signUpFullNameCtrl = TextEditingController();
  final TextEditingController signUpEmailCtrl = TextEditingController();
  final TextEditingController signUpPasswordCtrl = TextEditingController();
  final TextEditingController signUpConfirmPasswordCtrl =
      TextEditingController();
  final TextEditingController loginEmailCtrl = TextEditingController();
  final TextEditingController loginPasswordCtrl = TextEditingController();
  final TextEditingController profileFullNameCtrl = TextEditingController();
  final TextEditingController profileUsernameCtrl = TextEditingController();
  final TextEditingController forgotEmailCtrl = TextEditingController();
  final TextEditingController resetNewPasswordCtrl = TextEditingController();
  final TextEditingController resetConfirmPasswordCtrl =
      TextEditingController();

  String qSkinType = '';
  List<String> qSkinConcerns = [];
  String qAllergies = '';
  bool qNotSureAllergies = false;
  String qEnvironment = '';
  bool menuOpen = false;
  bool qCompletionProcessing = false;
  bool qCompletionReady = false;

  String registeredEmail = '';
  String _resetToken = '';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && currentScreen == Screen.splash) {
        setState(() => currentScreen = Screen.welcome);
      }
    });
  }

  void startResendTimer() {
    if (resendTimerObj != null) resendTimerObj!.cancel();
    for (final ctrl in otpControllers) {
      ctrl.clear();
    }
    setState(() {
      otpValues = List.filled(6, '');
      resendTimer = 30;
    });
    resendTimerObj = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendTimer <= 1) {
        timer.cancel();
        if (mounted) setState(() => resendTimer = 0);
      } else {
        if (mounted) setState(() => resendTimer--);
      }
    });
  }

  void _startSuccessTimer() {
    Timer(const Duration(seconds: 2), () {
      if (mounted && currentScreen == Screen.success) {
        setState(() => currentScreen = Screen.qSkinType);
      }
    });
  }

  void _startQCompletionTimer() {
    if (mounted) {
      setState(() {
        qCompletionProcessing = true;
        qCompletionReady = false;
      });
    }
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          qCompletionProcessing = false;
          qCompletionReady = true;
        });
      }
    });
  }

  void calculatePasswordStrength(String pwd) {
    int strength = 0;
    if (pwd.length >= 8) strength += 25;
    if (pwd.contains(RegExp(r'[a-z]')) && pwd.contains(RegExp(r'[A-Z]'))) {
      strength += 25;
    }
    if (pwd.contains(RegExp(r'[0-9]'))) strength += 25;
    if (pwd.contains(RegExp(r'[^a-zA-Z0-9]'))) strength += 25;
    setState(() => passwordStrength = strength);
  }

  void _loadUserProfile(dynamic user) {
    if (user is! Map) return;
    if (user['full_name'] != null) _userFullName = user['full_name'].toString();
    if (user['skin_type'] != null) qSkinType = user['skin_type'].toString();
    if (user['environment'] != null) {
      qEnvironment = user['environment'].toString();
    }
    if (user['skin_concerns'] is List) {
      qSkinConcerns = List<String>.from(user['skin_concerns'] as List);
    }
    if (user['goals'] is List) {
      selectedGoals = List<String>.from(user['goals'] as List);
    }
  }

  void _setLoading(bool value) {
    if (mounted) setState(() => isLoading = value);
  }

  void _showMessage(String message, {bool isError = false}) {
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.primary,
      ),
    );
  }

  Future<void> _submitSignUp() async {
    if (isLoading) return;
    if (!agreeTerms) {
      _showMessage(
        'Please agree to the Terms & Conditions to continue.',
        isError: true,
      );
      return;
    }
    final fullName = signUpFullNameCtrl.text.trim();
    final email = signUpEmailCtrl.text.trim();
    final password = signUpPasswordCtrl.text;
    final confirmPassword = signUpConfirmPasswordCtrl.text;

    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showMessage('Please complete all fields.', isError: true);
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Passwords do not match.', isError: true);
      return;
    }

    _setLoading(true);
    final response = await ApiService.register(fullName, email, password);
    _setLoading(false);

    final statusCode = response['statusCode'] as int;
    final body = response['body'];
    if (statusCode == 201) {
      final body201 = response['body'];
      if (body201 is Map) {
        ApiService.accessToken = body201['access_token']?.toString() ?? '';
        ApiService.refreshToken = body201['refresh_token']?.toString() ?? '';
        _loadUserProfile(body201['user']);
        profileFullNameCtrl.text = fullName;
        if (_userFullName.isEmpty) _userFullName = fullName;
      }
      _showMessage('Account created successfully.');
      setState(() => currentScreen = Screen.profileSetup);
    } else {
      final raw =
          body is Map && body['message'] != null
              ? body['message'].toString()
              : '';
      final message =
          raw == 'EMAIL_EXISTS'
              ? 'An account with this email already exists. Please log in.'
              : raw == 'MISSING_FIELDS'
              ? 'Please fill in all fields.'
              : raw.isNotEmpty
              ? raw
              : 'Signup failed. Please try again.';
      _showMessage(message, isError: true);
    }
  }

  Future<void> _submitVerifyOtp() async {
    if (isLoading) return;
    final otp = otpValues.join().trim();
    if (otp.length != 6) {
      _showMessage('Please enter the 6-digit code.', isError: true);
      return;
    }
    if (registeredEmail.isEmpty) {
      _showMessage('Missing email. Please sign up again.', isError: true);
      setState(() => currentScreen = Screen.signup);
      return;
    }
    _setLoading(true);
    final response = await ApiService.verifyEmail(registeredEmail, otp);
    _setLoading(false);

    final statusCode = response['statusCode'] as int;
    final body = response['body'];
    if (statusCode == 200 && body is Map) {
      ApiService.accessToken = body['access_token']?.toString() ?? '';
      ApiService.refreshToken = body['refresh_token']?.toString() ?? '';
      _loadUserProfile(body['user']);
      profileFullNameCtrl.text = signUpFullNameCtrl.text.trim();
      if (_userFullName.isEmpty) _userFullName = signUpFullNameCtrl.text.trim();
      _showMessage('Email verified successfully.');
      setState(() => currentScreen = Screen.profileSetup);
    } else {
      final message =
          body is Map && body['message'] != null
              ? body['message'].toString()
              : 'Verification failed. Please try again.';
      _showMessage(message, isError: true);
    }
  }

  Future<void> _submitLogin() async {
    if (isLoading) return;
    final email = loginEmailCtrl.text.trim();
    final password = loginPasswordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password.', isError: true);
      return;
    }
    _setLoading(true);
    final response = await ApiService.login(email, password);
    _setLoading(false);

    final statusCode = response['statusCode'] as int;
    final body = response['body'];
    if (statusCode == 200 && body is Map) {
      ApiService.accessToken = body['access_token']?.toString() ?? '';
      ApiService.refreshToken = body['refresh_token']?.toString() ?? '';
      registeredEmail = email;
      _loadUserProfile(body['user']);
      _showMessage('Login successful.');
      setState(() => currentScreen = Screen.dashboard);
    } else {
      final message =
          body is Map && body['message'] != null
              ? body['message'].toString()
              : 'Login failed. Please try again.';
      _showMessage(message, isError: true);
    }
  }

  Future<void> _submitProfileSetup() async {
    if (isLoading) return;
    final fullName = profileFullNameCtrl.text.trim();
    final username = profileUsernameCtrl.text.trim();
    if (fullName.isEmpty) {
      _showMessage('Please enter your full name.', isError: true);
      return;
    }
    _setLoading(true);
    final response = await ApiService.updateProfile(
      fullName: fullName,
      username: username.isEmpty ? null : username,
      gender: selectedGender.isEmpty ? null : selectedGender,
    );
    _setLoading(false);

    final statusCode = response['statusCode'] as int;
    final body = response['body'];
    if (statusCode == 200) {
      _showMessage('Profile saved.');
      setState(() => currentScreen = Screen.preferences);
    } else {
      final message =
          body is Map && body['message'] != null
              ? body['message'].toString()
              : 'Unable to save profile.';
      _showMessage(message, isError: true);
    }
  }

  Future<void> _submitQuestionnaire() async {
    if (isLoading) return;
    if (selectedGoals.isEmpty) {
      _showMessage('Please select at least one goal.', isError: true);
      return;
    }
    if (qSkinType.isEmpty || qSkinConcerns.isEmpty || qEnvironment.isEmpty) {
      _showMessage('Please complete all questionnaire steps.', isError: true);
      return;
    }
    _setLoading(true);
    final response = await ApiService.updateQuestionnaire(
      skinType: qSkinType,
      skinConcerns: qSkinConcerns,
      allergies: qAllergies,
      environment: qEnvironment,
      goals: selectedGoals,
    );
    _setLoading(false);

    final statusCode = response['statusCode'] as int;
    if (statusCode == 200) {
      ApiService.createSkinProfile(
        skinType: qSkinType,
        skinConcerns: qSkinConcerns,
        allergies: qAllergies,
        environment: qEnvironment,
        goals: selectedGoals,
      );
      _showMessage('Questionnaire saved.');
      setState(() => currentScreen = Screen.dashboard);
    } else {
      final body = response['body'];
      final message =
          body is Map && body['message'] != null
              ? body['message'].toString()
              : 'Unable to save preferences.';
      _showMessage(message, isError: true);
    }
  }

  Future<void> _submitForgotPassword() async {
    if (isLoading) return;
    final email = forgotEmailCtrl.text.trim();
    if (email.isEmpty) {
      _showMessage('Please enter your email.', isError: true);
      return;
    }
    _setLoading(true);
    final response = await ApiService.forgotPassword(email);
    _setLoading(false);
    final statusCode = response['statusCode'] as int;
    if (statusCode == 0) {
      final body = response['body'];
      final message =
          body is Map && body['message'] != null
              ? body['message'].toString()
              : 'Network error. Check your connection.';
      _showMessage(message, isError: true);
      return;
    }
    _showMessage('If that email exists, a reset code was sent.');
    otpValues = List.filled(6, '');
    startResendTimer();
    setState(() => currentScreen = Screen.forgotVerify);
  }

  Future<void> _submitVerifyResetOtp() async {
    if (isLoading) return;
    final otp = otpValues.join().trim();
    if (otp.length != 6) {
      _showMessage('Please enter the 6-digit code.', isError: true);
      return;
    }
    _setLoading(true);
    final response = await ApiService.verifyResetOtp(
      forgotEmailCtrl.text.trim(),
      otp,
    );
    _setLoading(false);
    final statusCode = response['statusCode'] as int;
    final body = response['body'];
    if (statusCode == 200 && body is Map) {
      _resetToken = body['reset_token']?.toString() ?? '';
      setState(() => currentScreen = Screen.resetPassword);
    } else {
      final message =
          body is Map && body['message'] != null
              ? body['message'].toString()
              : 'Invalid or expired code.';
      _showMessage(message, isError: true);
    }
  }

  Future<void> _submitResetPassword() async {
    if (isLoading) return;
    final newPwd = resetNewPasswordCtrl.text;
    final confirmPwd = resetConfirmPasswordCtrl.text;
    if (newPwd.isEmpty || confirmPwd.isEmpty) {
      _showMessage('Please fill in both password fields.', isError: true);
      return;
    }
    if (newPwd != confirmPwd) {
      _showMessage('Passwords do not match.', isError: true);
      return;
    }
    _setLoading(true);
    final response = await ApiService.resetPassword(_resetToken, newPwd);
    _setLoading(false);
    final statusCode = response['statusCode'] as int;
    final body = response['body'];
    if (statusCode == 200) {
      _showMessage('Password reset successfully.');
      setState(() => currentScreen = Screen.resetSuccess);
    } else {
      final message =
          body is Map && body['message'] != null
              ? body['message'].toString()
              : 'Reset failed. Please try again.';
      _showMessage(message, isError: true);
    }
  }

  @override
  void dispose() {
    resendTimerObj?.cancel();
    for (final node in otpFocusNodes) {
      node.dispose();
    }
    for (final ctrl in otpControllers) {
      ctrl.dispose();
    }
    signUpFullNameCtrl.dispose();
    signUpEmailCtrl.dispose();
    signUpPasswordCtrl.dispose();
    signUpConfirmPasswordCtrl.dispose();
    loginEmailCtrl.dispose();
    loginPasswordCtrl.dispose();
    profileFullNameCtrl.dispose();
    profileUsernameCtrl.dispose();
    forgotEmailCtrl.dispose();
    resetNewPasswordCtrl.dispose();
    resetConfirmPasswordCtrl.dispose();
    super.dispose();
  }

  // Screen widgets are moved to separate files under lib/screens/.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkinIntel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: _messengerKey,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey(currentScreen),
          child: _getCurrentScreen(),
        ),
      ),
    );
  }

  Widget _getCurrentScreen() {
    switch (currentScreen) {
      case Screen.splash:
        return _splashScreen();
      case Screen.welcome:
        return _welcomeScreen();
      case Screen.signup:
        return _signUpScreen();
      case Screen.verifyEmail:
        return _verifyEmailScreen();
      case Screen.profileSetup:
        return _profileSetupScreen();
      case Screen.preferences:
        return _preferencesScreen();
      case Screen.success:
        return _successScreen();
      case Screen.qSkinType:
        return _qSkinTypeScreen();
      case Screen.qSkinConcerns:
        return _qSkinConcernsScreen();
      case Screen.qAllergies:
        return _qAllergiesScreen();
      case Screen.qEnvironment:
        return _qEnvironmentScreen();
      case Screen.qCompletion:
        return _qCompletionScreen();
      case Screen.login:
        return _loginScreen();
      case Screen.forgotPassword:
        return _forgotPasswordScreen();
      case Screen.forgotVerify:
        return _forgotVerifyScreen();
      case Screen.resetPassword:
        return _resetPasswordScreen();
      case Screen.resetSuccess:
        return _resetSuccessScreen();
      case Screen.dashboard:
        return _dashboardScreen();
      case Screen.profile:
        return _profileScreen();
    }
  }
}
