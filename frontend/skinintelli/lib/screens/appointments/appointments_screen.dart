part of 'package:skinintelli/main.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Dermatologist> _dermatologists = [];
  bool _isLoading = true;
  bool _permissionDenied = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadNearbyDermatologists();
  }

  Future<void> _loadNearbyDermatologists() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
      _statusMessage = null;
    });

    final hasPermission = await DermatologistService.requestLocationPermission();
    if (!hasPermission) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
        _statusMessage = 'Location access is required to search for nearby dermatologists.';
      });
      return;
    }

    final position = await DermatologistService.getCurrentPosition();
    if (position == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = 'We could not access your current location.';
      });
      return;
    }

    final doctors = await DermatologistService.getNearbyDermatologists(
      lat: position.latitude,
      lng: position.longitude,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _dermatologists = doctors;
      if (doctors.isEmpty) {
        _statusMessage = 'No dermatologists were found near your location.';
      }
    });
  }

  Future<void> _openPhone(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWebsite(String website) async {
    final uri = Uri.parse(website);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDirections(Dermatologist doctor) async {
    final query = Uri.encodeComponent('${doctor.name} ${doctor.address}');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _doctorCard(Dermatologist doctor) {
    final hasWebsite = (doctor.website ?? '').trim().isNotEmpty;
    final hasPhone = (doctor.phoneNumber ?? '').trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_hospital, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.address,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (doctor.rating != null)
                _chip(
                  icon: Icons.star_rounded,
                  label: '${doctor.rating!.toStringAsFixed(1)} (${doctor.totalRatings})',
                  color: const Color(0xFFFFC857),
                ),
              if (doctor.isOpenNow != null)
                _chip(
                  icon: doctor.isOpenNow! ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  label: doctor.isOpenNow! ? 'Open now' : 'Closed now',
                  color: doctor.isOpenNow! ? const Color(0xFF4CAF50) : const Color(0xFFE57C23),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (hasPhone)
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _openPhone(doctor.phoneNumber!),
                    icon: const Icon(Icons.call_rounded),
                    label: const Text('Call'),
                  ),
                ),
              if (hasWebsite)
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _openWebsite(doctor.website!),
                    icon: const Icon(Icons.language_rounded),
                    label: const Text('Website'),
                  ),
                ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _openDirections(doctor),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Map'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
                onPressed: widget.onBack,
              )
            : null,
        title: Text(
          'Nearby Dermatologists',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadNearbyDermatologists,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _permissionDenied || (_statusMessage != null && _dermatologists.isEmpty)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off_rounded,
                            size: 56,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _statusMessage ?? 'No dermatologists available.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton.icon(
                            onPressed: _loadNearbyDermatologists,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.location_on_rounded, color: AppTheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Results are based on your live location and Google Places.',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ..._dermatologists.map(_doctorCard),
                    ],
                  ),
      ),
    );
  }
}
