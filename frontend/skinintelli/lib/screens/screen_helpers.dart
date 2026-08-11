part of 'package:skinintelli/main.dart';

extension ScreenHelpers on _SkinIntelAppState {
  Widget stepIndicator({required int current, required int total}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: index < current ? 32 : 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: index < current ? AppTheme.primary : AppTheme.border,
          ),
        );
      }),
    );
  }

  Widget _recommendationCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha((0.12 * 255).round()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.mutedForeground,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _routineItem(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    Color badgeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withAlpha((0.16 * 255).round()),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: badgeColor.withAlpha((0.16 * 255).round()),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.chevron_right,
              color: AppTheme.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileDetailRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.7 * 255).round()),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.mutedForeground,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color:
              active
                  ? AppTheme.primary.withAlpha((0.12 * 255).round())
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: active ? AppTheme.accent : AppTheme.mutedForeground,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? AppTheme.primary : AppTheme.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileInput({
    required String label,
    required String hintText,
    IconData? prefixIcon,
    String? errorText,
    bool readOnly = false,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            errorText: errorText,
          ),
        ),
      ],
    );
  }

  Widget _strengthBar({required int level, required int strength}) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: strength >= level ? _strengthColor() : AppTheme.border,
      ),
    );
  }

  Color _strengthColor() {
    if (passwordStrength == 100) return Colors.green;
    if (passwordStrength >= 75) return Colors.orange;
    if (passwordStrength >= 50) return Colors.yellow;
    return Colors.red;
  }

  // ---------------------------------------------------------------------
  // Recommendation explanation rendering, shared by the Products and
  // Skin Profile screens so both present the same rich, readable card
  // instead of one of them falling back to a raw Map.toString().
  // ---------------------------------------------------------------------

  Map<String, dynamic> _coerceExplanationMap(dynamic explanation) {
    if (explanation is Map) {
      return Map<String, dynamic>.from(explanation);
    }

    if (explanation is String) {
      try {
        final decoded = jsonDecode(explanation);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return {'summary': explanation};
      }
    }

    return const <String, dynamic>{};
  }

  String _summaryFromExplanation(Map<String, dynamic> explanation) {
    final pieces = <String>[];
    final skinTypeMatch = explanation['skin_type_match']?.toString();
    if (skinTypeMatch != null && skinTypeMatch.isNotEmpty) {
      pieces.add(skinTypeMatch);
    }

    final concernTargeting = explanation['concern_targeting'];
    if (concernTargeting is List && concernTargeting.isNotEmpty) {
      final firstConcern = concernTargeting.first?.toString();
      if (firstConcern != null && firstConcern.isNotEmpty) {
        pieces.add(firstConcern);
      }
    }

    final confidenceScore = explanation['confidence_score'];
    if (confidenceScore != null) {
      pieces.add('Confidence $confidenceScore%');
    }

    return pieces.isNotEmpty
        ? pieces.join(' • ')
        : 'Personalized recommendation';
  }

  List<Widget> _detailWidgetsFromExplanation(Map<String, dynamic> explanation) {
    final widgets = <Widget>[];
    final orderedEntries = <String, dynamic>{
      'skin_type_match': explanation['skin_type_match'],
      'concern_targeting': explanation['concern_targeting'],
      'safety_summary': explanation['safety_summary'],
      'conflict_exclusions': explanation['conflict_exclusions'],
      'confidence_breakdown': explanation['confidence_breakdown'],
      'priority_reason': explanation['priority_reason'],
      'scientific_reasoning': explanation['scientific_reasoning'],
      'expected_benefits': explanation['expected_benefits'],
    };

    for (final entry in orderedEntries.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }

      if (value is List && value.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelForExplanationKey(entry.key),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                ...value.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      item.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (value is String && value.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _labelForExplanationKey(entry.key),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return widgets;
  }

  String _labelForExplanationKey(String key) {
    switch (key) {
      case 'skin_type_match':
        return 'Skin type match';
      case 'concern_targeting':
        return 'Concern targeting';
      case 'safety_summary':
        return 'Safety summary';
      case 'conflict_exclusions':
        return 'Conflicts excluded';
      case 'confidence_breakdown':
        return 'Confidence breakdown';
      case 'priority_reason':
        return 'Why this priority';
      case 'scientific_reasoning':
        return 'Scientific reasoning';
      case 'expected_benefits':
        return 'Expected benefits';
      default:
        return key
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }

  Widget _priorityBadge(String? priority) {
    final normalized = (priority ?? '').toUpperCase();
    final Color color;
    final String label;
    switch (normalized) {
      case 'HIGH':
        color = AppTheme.primary;
        label = 'Top pick';
        break;
      case 'MEDIUM':
        color = Colors.orange;
        label = 'Good fit';
        break;
      case 'LOW':
        color = AppTheme.mutedForeground;
        label = 'Worth trying';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha((0.4 * 255).round())),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _matchChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.accent.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.primary,
        ),
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Full recommendation card for a product returned by the recommendation
  /// engine: name, match rating, priority badge, which of the user's
  /// concerns it addresses, and an expandable "why" section built from the
  /// engine's explanation object.
  Widget _productRecommendationCard(Map<String, dynamic> product) {
    final finalScore = (product['final_score'] as num?)?.toDouble() ?? 0.0;
    final normalizedRating = (finalScore / 20.0).clamp(0.0, 5.0);
    final explanationMap = _coerceExplanationMap(product['explanation']);
    final explanationSummary = _summaryFromExplanation(explanationMap);
    final detailWidgets = _detailWidgetsFromExplanation(explanationMap);
    final priority = explanationMap['recommendation_priority']?.toString();
    final matchedConcerns =
        (product['matched_concerns'] as List?)
            ?.map((e) => _titleCase(e.toString()))
            .toList() ??
        const <String>[];

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product['name']?.toString() ?? 'Product',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ),
                    _priorityBadge(priority),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  explanationSummary,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                if (matchedConcerns.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children:
                        matchedConcerns
                            .map((c) => _matchChip('For $c'))
                            .toList(),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < normalizedRating.floor()
                              ? Icons.star
                              : Icons.star_border,
                          color: AppTheme.accent,
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      normalizedRating.toStringAsFixed(1),
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
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    title: Text(
                      'Why this recommendation?',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                    ),
                    children: detailWidgets,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Recommendation card for an ingredient: what it is, why it was picked
  /// for this user (their specific concern where possible), its known
  /// functions, and a plain-language safety/evidence line.
  Widget _ingredientRecommendationCard(Map<String, dynamic> ingredient) {
    final name = ingredient['name']?.toString() ?? 'Ingredient';
    final category = ingredient['category']?.toString();
    final benefit =
        ingredient['benefit']?.toString() ?? "Supports your skin's needs.";
    final whyRecommended = ingredient['why_recommended']?.toString();
    final isConcernMatch =
        whyRecommended != null &&
        whyRecommended.toLowerCase().startsWith('targets your');
    final functions =
        (ingredient['functions'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final safetyNote = ingredient['safety_note']?.toString();
    final source = ingredient['source']?.toString();

    final footerParts = <String>[
      if (safetyNote != null && safetyNote.isNotEmpty) safetyNote,
      if (source != null && source.isNotEmpty) 'Source: $source',
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha((0.12 * 255).round()),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.opacity,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                      ),
                    ),
                    if (category != null && category.isNotEmpty)
                      Text(
                        category,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              if (isConcernMatch)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Best match',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            benefit,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppTheme.foreground,
              height: 1.4,
            ),
          ),
          if (functions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  functions
                      .map(
                        (f) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            f,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
          if (footerParts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 13,
                  color: AppTheme.mutedForeground,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    footerParts.join('  •  '),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
