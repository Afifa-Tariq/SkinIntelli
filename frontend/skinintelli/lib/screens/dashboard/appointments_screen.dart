part of 'package:skinintelli/main.dart';

extension AppointmentsScreenWidgets on _SkinIntelAppState {
  Widget _appointmentsScreen() {
    return AppointmentsScreen(
      onBack: () => setState(() => currentScreen = Screen.dashboard),
    );
  }
}
