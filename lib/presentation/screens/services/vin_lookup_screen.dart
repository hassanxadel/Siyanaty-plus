import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import '../../../services/vin_decoder_service.dart';
import '../../../services/car_service.dart' as car_logic;
import '../../../shared/constants/app_theme.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/screen_with_nav_bar.dart';

/// Page-level flow state. Each state has its own designed view — no missing
/// loading / error / empty states.
enum _VinState { idle, loading, success, error }

/// Human-friendly error buckets mapped from the decoder's exception strings.
enum _VinError { notFound, noInternet, timeout, rateLimit, server }

/// A single decoded field, rendered as an inset-grouped list row.
class _VinField {
  final String label;
  final String value;
  final IconData icon;
  const _VinField(this.label, this.value, this.icon);
}

/// Uppercases, strips the three letters a VIN never contains (I, O, Q) and any
/// other non-alphanumeric, and caps length at 17 — so typing *and* pasting a
/// lowercase/spaced VIN both clean up correctly. Pure and testable.
String cleanVin(String input) {
  final cleaned =
      input.toUpperCase().replaceAll(RegExp(r'[^A-HJ-NPR-Z0-9]'), '');
  return cleaned.length > 17 ? cleaned.substring(0, 17) : cleaned;
}

class _VinInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = cleanVin(newValue.text);
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

class VinLookupScreen extends StatefulWidget {
  const VinLookupScreen({super.key});

  @override
  State<VinLookupScreen> createState() => _VinLookupScreenState();
}

class _VinLookupScreenState extends State<VinLookupScreen> {
  final TextEditingController _vinController = TextEditingController();
  final FocusNode _vinFocus = FocusNode();
  final VinDecoderService _vinService = VinDecoderService();
  final car_logic.CarService _carService = car_logic.CarService();

  _VinState _state = _VinState.idle;
  _VinError _errorKind = _VinError.server;
  Map<String, dynamic>? _vehicleInfo;
  bool _isSaving = false;

  static const int _vinLength = 17;

  bool get _isValid => _vinController.text.length == _vinLength;

  @override
  void dispose() {
    _vinController.dispose();
    _vinFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithNavBar(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGreen,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputCard(),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOutCubic,
                      switchOutCurve: Curves.easeInOutCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SizeTransition(
                          sizeFactor: animation,
                          axisAlignment: -1,
                          child: child,
                        ),
                      ),
                      child: _buildStateBody(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header (kept consistent with the app's other screens; title centred)
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.backgroundGreen,
            AppTheme.darkAccentGreen,
            AppTheme.primaryGreen,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back',
                    icon: const Icon(CupertinoIcons.back,
                        color: Colors.white, size: 28),
                  ),
                  // Trailing box mirrors the leading IconButton width so the
                  // title stays optically centred.
                  const Expanded(
                    child: Text(
                      'VIN Lookup',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Decode your Vehicle Identification Number',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Input card
  // ---------------------------------------------------------------------------

  BoxDecoration _cardDecoration() => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkAccentGreen, AppTheme.backgroundGreen],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.glowShadow(),
      );

  Widget _buildInputCard() {
    final count = _vinController.text.length;
    final showLengthHint = count > 0 && count < _vinLength;
    final loading = _state == _VinState.loading;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your VIN',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your 17-character Vehicle Identification Number.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.lightBackground.withOpacity(0.7),
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _vinController,
            focusNode: _vinFocus,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.visiblePassword, // uppercase, no autofill
            onChanged: (_) => setState(() {
              // Editing the VIN invalidates any shown result/error.
              if (_state != _VinState.loading) {
                _state = _VinState.idle;
                _vehicleInfo = null;
              }
            }),
            onSubmitted: (_) {
              if (_isValid && !loading) _lookupVin();
            },
            inputFormatters: [_VinInputFormatter()],
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 18,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. 1HGCM82633A004352',
              hintStyle: TextStyle(
                color: AppTheme.lightBackground.withOpacity(0.4),
                fontFamily: 'monospace',
                letterSpacing: 1,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: AppTheme.backgroundGreen.withOpacity(0.4),
              counterText: '',
              prefixIcon: const Icon(CupertinoIcons.barcode,
                  color: AppTheme.secondaryGreen),
              suffixIcon: _vinController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: () => setState(() {
                        _vinController.clear();
                        _state = _VinState.idle;
                        _vehicleInfo = null;
                      }),
                      icon: const Icon(CupertinoIcons.clear_circled_solid,
                          color: Colors.white54, size: 20),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: AppTheme.primaryGreen.withOpacity(0.5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: AppTheme.primaryGreen.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppTheme.secondaryGreen, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  showLengthHint ? 'Keep going — VINs are 17 characters' : '',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.costHighlight.withOpacity(0.9),
                    fontFamily: 'Orbitron',
                  ),
                ),
              ),
              Text(
                '$count/$_vinLength',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Orbitron',
                  color: _isValid
                      ? AppTheme.secondaryGreen
                      : AppTheme.lightBackground.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLookupButton(loading),
        ],
      ),
    );
  }

  Widget _buildLookupButton(bool loading) {
    final enabled = _isValid && !loading;
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: 'Look up VIN',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? _lookupVin : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: enabled
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryGreen, AppTheme.darkAccentGreen],
                      )
                    : null,
                color: enabled ? null : AppTheme.darkAccentGreen.withOpacity(0.4),
                borderRadius: BorderRadius.circular(14),
                boxShadow: enabled
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: loading
                  ? const Center(
                      child: CupertinoActivityIndicator(color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          color: enabled
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lookup VIN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Orbitron',
                            color: enabled
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // State body: idle / loading / success / error
  // ---------------------------------------------------------------------------

  Widget _buildStateBody() {
    switch (_state) {
      case _VinState.idle:
        return _buildIdle();
      case _VinState.loading:
        return _buildLoading();
      case _VinState.success:
        return _buildResults();
      case _VinState.error:
        return _buildError();
    }
  }

  Widget _buildIdle() {
    return Container(
      key: const ValueKey('idle'),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Icon(
              CupertinoIcons.doc_text_viewfinder,
              size: 56,
              color: AppTheme.secondaryGreen.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Where to find your VIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildHintRow(CupertinoIcons.car_detailed,
              'Lower corner of the windshield, driver\'s side'),
          const SizedBox(height: 12),
          _buildHintRow(
              CupertinoIcons.doc_plaintext, 'Driver\'s door jamb sticker'),
          const SizedBox(height: 12),
          _buildHintRow(CupertinoIcons.doc_text,
              'Vehicle registration or insurance papers'),
        ],
      ),
    );
  }

  Widget _buildHintRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.secondaryGreen, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.lightBackground.withOpacity(0.85),
              fontFamily: 'Orbitron',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      key: const ValueKey('loading'),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const CupertinoActivityIndicator(color: Colors.white, radius: 16),
          const SizedBox(height: 14),
          Text(
            'Looking up your VIN…',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.lightBackground.withOpacity(0.85),
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 20),
          // Skeleton rows to hint at the shape of the result.
          ...List.generate(4, (_) => _buildSkeletonRow()),
        ],
      ),
    );
  }

  Widget _buildSkeletonRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.secondaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: AppTheme.lightBackground.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 40),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.lightBackground.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    final (icon, title, message) = _errorContent(_errorKind);
    return Container(
      key: const ValueKey('error'),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppDialog.destructive),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.lightBackground.withOpacity(0.8),
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: _buildPillButton(
              label: 'Retry',
              icon: CupertinoIcons.arrow_clockwise,
              accent: AppTheme.secondaryGreen,
              onTap: _isValid ? _lookupVin : null,
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, String) _errorContent(_VinError kind) {
    switch (kind) {
      case _VinError.noInternet:
        return (
          CupertinoIcons.wifi_slash,
          'No internet connection',
          'Check your connection and try again.'
        );
      case _VinError.timeout:
        return (
          CupertinoIcons.clock,
          'Request timed out',
          'The lookup took too long. Please try again.'
        );
      case _VinError.notFound:
        return (
          CupertinoIcons.search,
          'VIN not found',
          'We couldn\'t find a vehicle for this VIN. Double-check the number and try again.'
        );
      case _VinError.rateLimit:
        return (
          CupertinoIcons.hourglass,
          'Too many requests',
          'Please wait a few minutes before looking up another VIN.'
        );
      case _VinError.server:
        return (
          CupertinoIcons.exclamationmark_triangle,
          'Lookup unavailable',
          'The VIN service is temporarily unavailable. Please try again shortly.'
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Success — inset grouped results
  // ---------------------------------------------------------------------------

  Widget _buildResults() {
    final info = _vehicleInfo!;
    String v(String key) => (info[key] ?? '').toString().trim();

    final vehicle = <_VinField>[
      _VinField('Make', v('make'), CupertinoIcons.car_detailed),
      _VinField('Model', v('model'), CupertinoIcons.car_fill),
      _VinField('Year', v('year'), CupertinoIcons.calendar),
      _VinField('Body Style', v('bodyStyle'), CupertinoIcons.cube_box),
    ];
    final engine = <_VinField>[
      _VinField('Engine', v('engine'), CupertinoIcons.gauge),
      _VinField('Fuel Type', v('fuelType'), CupertinoIcons.flame),
      _VinField('Transmission', v('transmission'), CupertinoIcons.gear_alt),
    ];
    final identifier = <_VinField>[
      _VinField('VIN', v('vin'), CupertinoIcons.barcode),
    ];

    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroup('Vehicle', vehicle),
        _buildGroup('Engine & Drivetrain', engine),
        _buildGroup('Identifier', identifier, alwaysShow: true),
        const SizedBox(height: 8),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildGroup(String title, List<_VinField> fields,
      {bool alwaysShow = false}) {
    final visible =
        fields.where((f) => alwaysShow || f.value.isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryGreen,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.darkAccentGreen, AppTheme.backgroundGreen],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.secondaryGreen.withOpacity(0.25),
                width: 1,
              ),
              boxShadow: AppTheme.glowShadow(),
            ),
            child: Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  _buildResultRow(visible[i]),
                  if (i != visible.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      indent: 52,
                      color: AppTheme.secondaryGreen.withOpacity(0.15),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(_VinField field) {
    final display = field.value.isEmpty ? '—' : field.value;
    return Semantics(
      label: '${field.label}: $display',
      child: InkWell(
        onLongPress: field.value.isEmpty ? null : () => _copy(field.value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(field.icon, size: 20, color: AppTheme.secondaryGreen),
              const SizedBox(width: 16),
              Text(
                field.label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.lightBackground.withOpacity(0.7),
                  fontFamily: 'Orbitron',
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  display,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: field.label == 'VIN' ? 'monospace' : 'Orbitron',
                  ),
                ),
              ),
              if (field.label == 'VIN' && field.value.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copy(field.value),
                  child: const Icon(CupertinoIcons.doc_on_doc,
                      size: 18, color: AppTheme.secondaryGreen),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: _buildPillButton(
        label: _isSaving ? 'Saving…' : 'Save as My Car',
        icon: CupertinoIcons.car_fill,
        accent: AppTheme.primaryGreen,
        filled: true,
        busy: _isSaving,
        onTap: _isSaving ? null : _saveVehicleToCars,
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required Color accent,
    required VoidCallback? onTap,
    bool filled = false,
    bool busy = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: filled && onTap != null
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryGreen, AppTheme.darkAccentGreen],
                  )
                : null,
            color: filled
                ? (onTap == null ? AppTheme.darkAccentGreen.withOpacity(0.4) : null)
                : accent.withOpacity(0.16),
            border: filled
                ? null
                : Border.all(color: accent.withOpacity(0.5), width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                const CupertinoActivityIndicator(color: Colors.white)
              else
                Icon(icon, color: filled ? Colors.white : accent, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: filled ? Colors.white : accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lookup / save logic
  // ---------------------------------------------------------------------------

  Future<void> _lookupVin() async {
    if (!_isValid || _state == _VinState.loading) return;
    _vinFocus.unfocus();
    final vin = _vinController.text.trim();

    setState(() => _state = _VinState.loading);
    HapticFeedback.lightImpact();

    try {
      final decoded = await _vinService.decodeVin(vin);
      if (!mounted) return;
      setState(() {
        _vehicleInfo = {
          'vin': decoded.vin.isNotEmpty ? decoded.vin : vin,
          'make': decoded.make,
          'model': decoded.model,
          'year': int.tryParse(decoded.year) ?? decoded.year,
          'engine': decoded.engine,
          'transmission': decoded.transmission,
          'bodyStyle': decoded.bodyStyle,
          'fuelType': decoded.fuelType,
        };
        _state = _VinState.success;
      });
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorKind = _classifyError(e.toString());
        _state = _VinState.error;
      });
      HapticFeedback.heavyImpact();
    }
  }

  _VinError _classifyError(String error) {
    final e = error.toLowerCase();
    if (e.contains('429') || e.contains('rate limit')) return _VinError.rateLimit;
    if (e.contains('404') || e.contains('no vin data')) return _VinError.notFound;
    if (e.contains('timeout') || e.contains('timed out')) return _VinError.timeout;
    if (e.contains('network') || e.contains('connectivity') ||
        e.contains('socket')) {
      return _VinError.noInternet;
    }
    return _VinError.server;
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.selectionClick();
    _showMessage('Copied');
  }

  Future<void> _saveVehicleToCars() async {
    final info = _vehicleInfo;
    if (info == null) {
      _showMessage('No vehicle info to save');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final vin = (info['vin'] ?? '').toString();

      if (vin.isNotEmpty && vin != 'Not specified') {
        final existingCar = await _carService.getCarByVin(vin);
        if (existingCar != null) {
          if (!mounted) return;
          setState(() => _isSaving = false);
          _showConfirmUpdateDialog(info, existingCar);
          return;
        }
      }

      String licensePlate;
      if (vin.isNotEmpty && vin != 'Not specified') {
        licensePlate = 'VIN-${vin.substring(vin.length - 6)}';
      } else {
        licensePlate =
            'VIN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      }

      final result = await _carService.addCar(
        brand: (info['make'] ?? 'Unknown').toString().isEmpty
            ? 'Unknown'
            : (info['make']).toString(),
        model: (info['model'] ?? 'Unknown').toString().isEmpty
            ? 'Unknown'
            : (info['model']).toString(),
        year: (info['year'] is int) ? info['year'] as int : DateTime.now().year,
        mileage: 0,
        color: 'Not specified',
        fuelType: (info['fuelType'] ?? 'Not specified').toString().isEmpty
            ? 'Not specified'
            : (info['fuelType']).toString(),
        engineCC: (info['engine'] ?? 'Not specified').toString().isEmpty
            ? 'Not specified'
            : (info['engine']).toString(),
        turbo: false,
        licensePlate: licensePlate,
        vin: vin.isNotEmpty
            ? vin
            : 'VIN-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (result.isSuccess) {
        _showSuccessDialog();
      } else {
        if (result.message.toLowerCase().contains('already exists') ||
            result.message.toLowerCase().contains('duplicate')) {
          _showMessage(
              'This vehicle is already in your garage. Check "My Cars" to view it.');
        } else {
          _showMessage(result.message);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('already exists') || errorMsg.contains('duplicate')) {
        _showMessage(
            'This vehicle is already in your garage. You can update it from "My Cars".');
      } else {
        _showMessage('Failed to save car. Please try again.');
      }
    }
  }

  void _showConfirmUpdateDialog(Map<String, dynamic> newInfo, dynamic existingCar) {
    AppDialog.custom<void>(
      context,
      title: 'Vehicle Already Exists',
      message: 'This vehicle is already in your garage:',
      icon: Icons.info_outline,
      closeLabel: 'OK',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glowFieldDecoration(),
            child: Column(
              children: [
                Text(
                  '${existingCar.brand} ${existingCar.model}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryGreen,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Year: ${existingCar.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.lightBackground.withOpacity(0.75),
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'You can view and manage this vehicle in "My Cars".',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppTheme.lightBackground.withOpacity(0.65),
              fontFamily: 'Orbitron',
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    HapticFeedback.mediumImpact();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (dialogContext) => AppDialogPanel(
        title: 'Vehicle Saved!',
        message:
            'The vehicle has been successfully added to your garage. You can now view and manage it in "My Cars".',
        icon: Icons.check_circle_outline,
        actions: [
          AppDialogAction(
            label: 'Got it!',
            filled: true,
            onTap: () {
              Navigator.of(dialogContext).pop();
              _vinController.clear();
              setState(() {
                _vehicleInfo = null;
                _state = _VinState.idle;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    AppSnackbar.show(
      context,
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
