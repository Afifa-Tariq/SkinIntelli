part of 'package:skinintelli/main.dart';

extension SkinAnalysisScreenWidgets on _SkinIntelAppState {
  Widget _skinAnalysisScreen() {
    return _SkinAnalysisFlowScreen(
      onBack: () => setState(() => currentScreen = Screen.preferences),
      onContinue: () => setState(() => currentScreen = Screen.qSkinType),
    );
  }
}

class _SkinAnalysisFlowScreen extends StatefulWidget {
  const _SkinAnalysisFlowScreen({
    required this.onBack,
    required this.onContinue,
  });

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  State<_SkinAnalysisFlowScreen> createState() =>
      _SkinAnalysisFlowScreenState();
}

class _SkinAnalysisFlowScreenState extends State<_SkinAnalysisFlowScreen> {
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isAnalyzing = false;
  bool _awaitingCameraReview = false;
  String _cameraModeLabel = 'Front camera';
  Map<String, dynamic>? _analysisResult;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      XFile? picked;

      if (source == ImageSource.camera) {
        picked = await _pickCameraImageWithFallback();
      } else {
        picked = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1024,
          maxHeight: 1024,
        );
      }

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
        _analysisResult = null;
        _errorMessage = null;
        _awaitingCameraReview = source == ImageSource.camera;
      });

      if (source == ImageSource.gallery) {
        await _analyzeImage();
      }
    } catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _errorMessage =
                'Permission or camera access is blocked. Please allow camera/gallery access in your device settings and try again.',
      );
    }
  }

  Future<XFile?> _pickCameraImageWithFallback() async {
    final result = await Navigator.of(context).push<_CameraCaptureResult>(
      MaterialPageRoute(
        builder: (_) => const _CameraCaptureScreen(preferFront: true),
        fullscreenDialog: true,
      ),
    );

    if (result == null) return null;

    if (mounted) {
      setState(
        () =>
            _cameraModeLabel =
                result.isFrontCamera ? 'Front camera' : 'Rear camera',
      );
    }

    return XFile(result.path);
  }

  Future<void> _confirmCameraReview() async {
    setState(() {
      _awaitingCameraReview = false;
    });
    await _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null || _selectedImageBytes == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final uri = Uri.parse(
        '${AppTheme.backendBaseUrl}/api/skin/analyze-and-recommend',
      );
      final request =
          http.MultipartRequest('POST', uri)
            ..headers['Authorization'] = 'Bearer ${ApiService.accessToken}'
            ..files.add(
              http.MultipartFile.fromBytes(
                'image',
                _selectedImageBytes!,
                filename: _selectedImage!.name.isNotEmpty
                    ? _selectedImage!.name
                    : 'selfie.jpg',
              ),
            )
            ..fields['top_n'] = '5';

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout:
            () => throw Exception('Request timed out. Check your connection.'),
      );

      final response = await http.Response.fromStream(streamedResponse);
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          setState(() {
            _analysisResult = data;
            _isAnalyzing = false;
          });
          return;
        }

        throw Exception('Unexpected server response.');
      }

      final decoded = jsonDecode(response.body);
      final message =
          decoded is Map && decoded['error'] != null
              ? decoded['error'].toString()
              : 'Analysis failed. Please try again.';

      setState(() {
        _errorMessage = message;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Connection error: ${e.toString()}';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary),
          onPressed: widget.onBack,
        ),
        title: Text(
          'Skin Analysis',
          style: GoogleFonts.poppins(
            color: AppTheme.foreground,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildImagePreview(),
              const SizedBox(height: 20),
              if (_awaitingCameraReview) _buildCameraReviewCard(),
              if (!_isAnalyzing &&
                  _analysisResult == null &&
                  !_awaitingCameraReview)
                _buildPickerButtons(),
              if (_isAnalyzing) _buildLoadingState(),
              if (_errorMessage != null) _buildError(),
              if (!_isAnalyzing &&
                  _analysisResult == null &&
                  !_awaitingCameraReview) ...[
                const SizedBox(height: 16),
                _buildSkipButton(),
              ],
              if (_analysisResult != null) ...[
                const SizedBox(height: 20),
                _buildAnalysisResult(),
                const SizedBox(height: 16),
                _buildContinueButton(),
                const SizedBox(height: 12),
                _buildSkipButton(),
                const SizedBox(height: 12),
                _buildRetryButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Column(
    children: [
      Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.accent]),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.face_retouching_natural,
          size: 46,
          color: Colors.white,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        'AI Skin Analysis',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppTheme.foreground,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Take a selfie or upload a photo to help us personalize your routine.',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppTheme.mutedForeground,
          height: 1.5,
        ),
      ),
    ],
  );

  Widget _buildImagePreview() {
    if (_selectedImageBytes == null) {
      return Container(
        height: 230,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add_a_photo_rounded,
                size: 52,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'Tap below to take or upload a photo',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.memory(
        _selectedImageBytes!,
        height: 280,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildCameraReviewCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppTheme.border, width: 1.2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Camera review',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            _cameraModeLabel,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Review your selfie before sending it for AI skin analysis.',
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _confirmCameraReview,
                icon: const Icon(Icons.check_circle_rounded),
                label: Text(
                  'Use this photo',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _selectedImageBytes = null;
                    _awaitingCameraReview = false;
                    _cameraModeLabel = 'Front camera';
                  });
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'Retake',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary, width: 1.5),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildPickerButtons() => Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () => _pickImage(ImageSource.camera),
          icon: const Icon(Icons.camera_alt_rounded),
          label: Text(
            'Take Selfie',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _pickImage(ImageSource.gallery),
          icon: const Icon(Icons.photo_library_rounded),
          label: Text(
            'Gallery',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.primary, width: 1.5),
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildLoadingState() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primary.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          strokeWidth: 3,
        ),
        const SizedBox(height: 18),
        Text(
          'Analyzing your skin...',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Our AI is checking your skin type and concerns.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: AppTheme.mutedForeground,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );

  Widget _buildError() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEEF2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red.shade200),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: Colors.red),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            _errorMessage!,
            style: GoogleFonts.poppins(color: Colors.red, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _buildAnalysisResult() {
    final analysis =
        _analysisResult!['skin_analysis'] is Map
            ? _analysisResult!['skin_analysis'] as Map<String, dynamic>
            : _analysisResult!;

    final confidence =
        analysis['confidence'] is int ? analysis['confidence'] as int : 0;
    final skinType = analysis['skin_type']?.toString() ?? 'Unknown';
    final concerns =
        (analysis['concerns'] as List?)?.map((e) => e.toString()).toList() ??
        <String>[];
    final features =
        analysis['detected_features'] is Map
            ? Map<String, dynamic>.from(analysis['detected_features'] as Map)
            : <String, dynamic>{};
    final notes = analysis['analysis_notes']?.toString() ?? '';
    final quality =
        _analysisResult!['image_quality']?.toString() ?? 'acceptable';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Analysis Complete',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.foreground,
                ),
              ),
              const Spacer(),
              _confidenceBadge(confidence),
            ],
          ),
          if (quality == 'poor') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1D6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Image quality is low. Results may be less accurate.',
                      style: GoogleFonts.poppins(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          _resultRow(
            'Skin Type',
            skinType.toUpperCase(),
            Icons.face_rounded,
            AppTheme.primary,
          ),
          const SizedBox(height: 10),
          _resultRow(
            'Sensitivity',
            (analysis['sensitivity_level']?.toString() ?? 'low').toUpperCase(),
            Icons.spa_rounded,
            AppTheme.accent,
          ),
          const SizedBox(height: 16),
          if (concerns.isNotEmpty) ...[
            Text(
              'Detected Concerns',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.foreground,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: concerns.map((c) => _concernChip(c)).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (features.isNotEmpty) ...[
            Text(
              'What Was Detected',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppTheme.foreground,
              ),
            ),
            const SizedBox(height: 8),
            ...features.entries
                .where((entry) => entry.value == true)
                .map((entry) => _featureRow(_formatFeatureName(entry.key))),
            const SizedBox(height: 12),
          ],
          if (notes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      notes,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _confidenceBadge(int confidence) {
    final color =
        confidence >= 75
            ? AppTheme.primary
            : confidence >= 50
            ? Colors.orange
            : AppTheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color),
      ),
      child: Text(
        '$confidence% confident',
        style: GoogleFonts.poppins(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, IconData icon, Color color) =>
      Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              color: AppTheme.mutedForeground,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      );

  Widget _concernChip(String concern) => Chip(
    label: Text(
      _formatFeatureName(concern),
      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.foreground),
    ),
    backgroundColor: const Color(0xFFEAF7EF),
    side: const BorderSide(color: AppTheme.primary),
    padding: const EdgeInsets.symmetric(horizontal: 4),
  );

  Widget _featureRow(String name) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        const Icon(Icons.circle, size: 7, color: AppTheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppTheme.foreground,
            ),
          ),
        ),
      ],
    ),
  );

  String _formatFeatureName(String key) => key
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) {
        if (w.isEmpty) return w;
        return '${w[0].toUpperCase()}${w.substring(1)}';
      })
      .join(' ');

  Widget _buildContinueButton() => ElevatedButton.icon(
    onPressed: widget.onContinue,
    icon: const Icon(Icons.arrow_forward_rounded),
    label: Text(
      'Continue to Questionnaire',
      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  Widget _buildSkipButton() => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: widget.onContinue,
      icon: const Icon(Icons.skip_next_rounded, color: AppTheme.primary),
      label: Text(
        'Skip for now',
        style: GoogleFonts.poppins(
          color: AppTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primary,
        side: const BorderSide(color: AppTheme.primary, width: 1.5),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );

  Widget _buildRetryButton() => TextButton.icon(
    onPressed:
        () => setState(() {
          _selectedImage = null;
          _selectedImageBytes = null;
          _analysisResult = null;
          _errorMessage = null;
          _isAnalyzing = false;
        }),
    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
    label: Text(
      'Retake Photo',
      style: GoogleFonts.poppins(
        color: AppTheme.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
