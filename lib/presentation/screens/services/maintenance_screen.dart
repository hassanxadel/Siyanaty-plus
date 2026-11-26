import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/screen_with_nav_bar.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../models/backup_maintenance.dart';
import '../../../models/backup_reminder.dart';
import '../../../models/backup_car.dart';
import '../../../services/maintenance_service.dart';
import '../../../services/car_service.dart';

/// Single source of truth for category presentation. Every maintenance type
/// maps to exactly one monochrome icon here; [MaintenanceType.displayName]
/// supplies the label. Unknown values already default to `mechanics` in
/// [BackupMaintenance.fromMap], so nothing is ever left uncategorised.
extension MaintenanceTypeUi on MaintenanceType {
  IconData get icon {
    switch (this) {
      case MaintenanceType.mechanics:
        return CupertinoIcons.wrench_fill;
      case MaintenanceType.electrical:
        return CupertinoIcons.bolt_fill;
      case MaintenanceType.suspension:
        return CupertinoIcons.car_detailed;
      case MaintenanceType.others:
        return CupertinoIcons.ellipsis_circle_fill;
    }
  }
}

enum _MaintSort {
  recentlyDone,
  nameAZ,
  cost;

  String get label {
    switch (this) {
      case _MaintSort.recentlyDone:
        return 'Recently Done';
      case _MaintSort.nameAZ:
        return 'Name A–Z';
      case _MaintSort.cost:
        return 'Cost';
    }
  }
}

/// Screen for displaying and managing vehicle maintenance records.
class MaintenanceRecordsScreen extends StatefulWidget {
  const MaintenanceRecordsScreen({super.key});

  @override
  State<MaintenanceRecordsScreen> createState() =>
      _MaintenanceRecordsScreenState();
}

class _MaintenanceRecordsScreenState extends State<MaintenanceRecordsScreen> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  final CarService _carService = CarService();
  final TextEditingController _searchController = TextEditingController();

  static const _accent = AppTheme.primaryGreen; // the single accent color

  List<MaintenanceWithInfo> _all = [];
  List<MaintenanceWithInfo> _filtered = [];
  MaintenanceType? _selectedType; // null = All
  _MaintSort _sort = _MaintSort.recentlyDone;
  String _searchQuery = '';
  double _totalCost = 0.0;
  int _carCount = 0;
  bool _isLoading = true;

  static const _prefFilter = 'maint_filter_type';
  static const _prefSort = 'maint_sort';

  @override
  void initState() {
    super.initState();
    _restorePrefsThenLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _restorePrefsThenLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final f = prefs.getString(_prefFilter);
      final s = prefs.getString(_prefSort);
      _selectedType = (f == null || f == 'all')
          ? null
          : MaintenanceType.values
              .where((t) => t.name == f)
              .cast<MaintenanceType?>()
              .firstWhere((t) => true, orElse: () => null);
      if (s != null) {
        _sort = _MaintSort.values.firstWhere((e) => e.name == s,
            orElse: () => _MaintSort.recentlyDone);
      }
    } catch (_) {
      // Prefs are a convenience; ignore failures and use defaults.
    }
    await _loadMaintenance();
  }

  Future<void> _savePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefFilter, _selectedType?.name ?? 'all');
      await prefs.setString(_prefSort, _sort.name);
    } catch (_) {}
  }

  Future<void> _loadMaintenance() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final list = await _maintenanceService.getAllMaintenanceWithInfo();
      final totalCost = await _maintenanceService.getTotalMaintenanceCost();
      final cars = await _carService.getAllCars();
      if (!mounted) return;
      setState(() {
        _all = list;
        _totalCost = totalCost;
        _carCount = cars.length;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _toast('Error loading maintenance records');
    }
  }

  int _countOf(MaintenanceType? type) => type == null
      ? _all.length
      : _all.where((m) => m.maintenance.type == type).length;

  void _applyFilters() {
    var list = _all;
    if (_selectedType != null) {
      list = list.where((m) => m.maintenance.type == _selectedType).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) {
        return m.maintenance.title.toLowerCase().contains(q) ||
            m.maintenance.description.toLowerCase().contains(q) ||
            (m.maintenance.mechanicName?.toLowerCase().contains(q) ?? false) ||
            m.reminderDisplayName.toLowerCase().contains(q) ||
            m.carDisplayName.toLowerCase().contains(q);
      }).toList();
    }
    list = _sorted(list);
    setState(() => _filtered = list);
  }

  List<MaintenanceWithInfo> _sorted(List<MaintenanceWithInfo> list) {
    final out = List<MaintenanceWithInfo>.from(list);
    switch (_sort) {
      case _MaintSort.recentlyDone:
        out.sort((a, b) =>
            b.maintenance.maintenanceDate.compareTo(a.maintenance.maintenanceDate));
        break;
      case _MaintSort.nameAZ:
        out.sort((a, b) => a.maintenance.title
            .toLowerCase()
            .compareTo(b.maintenance.title.toLowerCase()));
        break;
      case _MaintSort.cost:
        out.sort((a, b) => b.maintenance.cost.compareTo(a.maintenance.cost));
        break;
    }
    return out;
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ScreenWithNavBar(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGreen,
        body: Column(
          children: [
            _buildHeader(),
            _buildFilterChips(),
            _buildSearchField(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CupertinoActivityIndicator(color: Colors.white))
                  : _filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 170,
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
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(CupertinoIcons.back,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Maintenance',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sort',
                    icon: const Icon(CupertinoIcons.arrow_up_arrow_down,
                        color: Colors.white, size: 22),
                    onPressed: _showSortSheet,
                  ),
                  IconButton(
                    tooltip: 'Add maintenance record',
                    icon: const Icon(CupertinoIcons.add,
                        color: Colors.white, size: 26),
                    onPressed: () => _showAddForm(initialType: _selectedType),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Total cost summary (the only status the data supports).
              Text(
                'Total spent  ·  EGP ${_totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final items = <MapEntry<MaintenanceType?, String>>[
      const MapEntry(null, 'All'),
      ...MaintenanceType.values.map((t) => MapEntry(t, t.displayName)),
    ];
    return Container(
      height: 46,
      margin: const EdgeInsets.only(top: 12),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final type = items[i].key;
          final label = items[i].value;
          final selected = _selectedType == type;
          return _FilterChip(
            label: label,
            count: _countOf(type),
            icon: type?.icon ?? CupertinoIcons.square_grid_2x2,
            selected: selected,
            accent: _accent,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedType = type);
              _applyFilters();
              _savePrefs();
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: 'Search maintenance',
        style: const TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
        placeholderStyle: TextStyle(
            color: Colors.white.withOpacity(0.5), fontFamily: 'Orbitron'),
        backgroundColor: AppTheme.darkAccentGreen.withOpacity(0.5),
        itemColor: Colors.white70,
        onChanged: (v) {
          setState(() => _searchQuery = v);
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadMaintenance,
      color: _accent,
      backgroundColor: AppTheme.darkAccentGreen,
      child: _selectedType == null && _searchQuery.isEmpty
          ? _buildGroupedList()
          : _buildFlatList(_filtered),
    );
  }

  /// "All" with no search → iOS grouped sections by category (empty hidden).
  Widget _buildGroupedList() {
    final sections = <Widget>[];
    for (final type in MaintenanceType.values) {
      final items =
          _sorted(_all.where((m) => m.maintenance.type == type).toList());
      if (items.isEmpty) continue;
      sections.add(_sectionHeader('${type.displayName} · ${items.length}'));
      sections.addAll(items.map(_buildRow));
    }
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: sections,
    );
  }

  Widget _buildFlatList(List<MaintenanceWithInfo> items) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildRow(items[i]),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          letterSpacing: 1.1,
          fontWeight: FontWeight.bold,
          color: _accent,
          fontFamily: 'Orbitron',
        ),
      ),
    );
  }

  Widget _buildRow(MaintenanceWithInfo info) {
    final m = info.maintenance;
    return Dismissible(
      key: ValueKey('maint_${m.id}'),
      direction: DismissDirection.horizontal,
      // Swipe right → Edit (never actually dismisses); swipe left → Delete.
      background: _swipeBg(
          align: Alignment.centerLeft,
          icon: CupertinoIcons.pencil,
          label: 'Edit',
          color: _accent),
      secondaryBackground: _swipeBg(
          align: Alignment.centerRight,
          icon: CupertinoIcons.trash,
          label: 'Delete',
          color: AppDialog.destructive),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          _showEditForm(m);
          return false;
        }
        return _confirmDelete(m);
      },
      onDismissed: (_) => _deleteRecord(m),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.glowCardDecoration(radius: 16, accent: _accent),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDetails(info),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Monochrome category badge (neutral fill, no per-type color).
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.12), width: 1),
                    ),
                    child: Icon(m.type.icon,
                        color: AppTheme.lightBackground, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _rowSubtitle(info),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'EGP ${m.cost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(CupertinoIcons.chevron_forward,
                          size: 14, color: Colors.white.withOpacity(0.4)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _rowSubtitle(MaintenanceWithInfo info) {
    final date = DateFormat('MMM dd, yyyy').format(info.maintenance.maintenanceDate);
    // Show the car only when the user has more than one.
    if (_carCount > 1 && info.carDisplayName.trim().isNotEmpty) {
      return '${info.carDisplayName}  ·  $date';
    }
    return date;
  }

  Widget _swipeBg({
    required Alignment align,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      alignment: align,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final filteredLabel = _selectedType?.displayName.toLowerCase();
    final msg = _searchQuery.isNotEmpty
        ? 'No records match your search'
        : _selectedType != null
            ? 'No $filteredLabel records yet'
            : 'No maintenance records yet';
    return ListView(
      // ListView so pull-to-refresh still works on the empty state.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 80),
        Icon(CupertinoIcons.wrench,
            size: 64, color: Colors.white.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text(msg,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Orbitron')),
        const SizedBox(height: 20),
        Center(
          child: CupertinoButton(
            color: _accent,
            borderRadius: BorderRadius.circular(14),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            onPressed: () => _showAddForm(initialType: _selectedType),
            child: const Text('Add Record',
                style: TextStyle(
                    fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sort / details / delete / forms
  // ---------------------------------------------------------------------------

  void _showSortSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Sort by'),
        actions: _MaintSort.values.map((s) {
          final active = s == _sort;
          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.selectionClick();
              setState(() => _sort = s);
              _applyFilters();
              _savePrefs();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(s.label),
                if (active) ...[
                  const SizedBox(width: 8),
                  const Icon(CupertinoIcons.checkmark_alt, size: 18),
                ],
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showDetails(MaintenanceWithInfo info) {
    showDialog(
      context: context,
      builder: (_) => MaintenanceDetailsDialog(
        maintenanceWithInfo: info,
        onEdit: () {
          Navigator.pop(context);
          _showEditForm(info.maintenance);
        },
        onDelete: () async {
          Navigator.pop(context);
          if (await _confirmDelete(info.maintenance)) {
            _deleteRecord(info.maintenance);
          }
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BackupMaintenance m) async {
    final ok = await AppDialog.show(
      context,
      title: 'Delete Maintenance Record',
      message:
          'Are you sure you want to delete "${m.title}"? This action cannot be undone.',
      icon: Icons.delete_outline,
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    return ok == true;
  }

  Future<void> _deleteRecord(BackupMaintenance m) async {
    HapticFeedback.mediumImpact();
    final result = await _maintenanceService.deleteMaintenance(m.id!);
    if (!mounted) return;
    _toast(result.message);
    if (result.success) _loadMaintenance();
  }

  Future<void> _showAddForm({MaintenanceType? initialType}) async {
    HapticFeedback.lightImpact();
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMaintenanceForm(initialType: initialType),
    );
    if (added == true && mounted) {
      _toast('Maintenance record added');
      _loadMaintenance();
    }
  }

  Future<void> _showEditForm(BackupMaintenance m) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditMaintenanceForm(maintenance: m),
    );
    if (updated == true && mounted) {
      _toast('Maintenance record updated');
      _loadMaintenance();
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Orbitron')),
        backgroundColor: AppTheme.darkAccentGreen,
      ),
    );
  }
}

/// Capsule filter chip: selected = filled accent, unselected = neutral.
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppTheme.lightBackground;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, $count records',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? accent : Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? accent : Colors.white.withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: fg),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: fg,
                      fontFamily: 'Orbitron',
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: TextStyle(
                        color: fg,
                        fontFamily: 'Orbitron',
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Add Maintenance form (iOS modal sheet) with conditional Car field.
// =============================================================================
class AddMaintenanceForm extends StatefulWidget {
  final MaintenanceType? initialType;
  const AddMaintenanceForm({super.key, this.initialType});

  @override
  State<AddMaintenanceForm> createState() => _AddMaintenanceFormState();
}

class _AddMaintenanceFormState extends State<AddMaintenanceForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _mechanicController = TextEditingController();
  final _invoiceController = TextEditingController();

  final MaintenanceService _maintenanceService = MaintenanceService();
  final CarService _carService = CarService();

  DateTime _selectedDate = DateTime.now();
  late MaintenanceType _selectedType;
  BackupReminder? _selectedReminder;
  BackupCar? _selectedCar;
  List<BackupReminder> _reminders = [];
  List<BackupCar> _cars = [];
  bool _loadingLinks = true;
  bool _saving = false;
  bool _showCarError = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? MaintenanceType.mechanics;
    _loadLinks();
    _titleController.addListener(_refresh);
    _costController.addListener(_refresh);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _mechanicController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _loadLinks() async {
    final reminders = await _maintenanceService.getAvailableReminders();
    final cars = await _carService.getAllCars();
    if (!mounted) return;
    setState(() {
      // Only active (not completed) reminders can anchor a new record.
      _reminders = reminders.where((r) => !r.isCompleted).toList();
      _cars = cars;
      _selectedReminder = null; // default: standalone
      // Single car → preselect so the user still sees it but needn't pick.
      _selectedCar = cars.length == 1 ? cars.first : null;
      _loadingLinks = false;
    });
  }

  bool get _costValid {
    final c = double.tryParse(_costController.text.trim());
    return c != null && c >= 0;
  }

  bool get _isValid {
    if (_titleController.text.trim().isEmpty) return false;
    if (!_costValid) return false;
    // Must resolve to a car: either a reminder (carries its car) or a picked car.
    if (_selectedReminder == null && _selectedCar == null) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      margin: EdgeInsets.only(top: media.padding.top + 40),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _navBar(
            title: 'Add Record',
            onSave: _isValid && !_saving ? _save : null,
            saving: _saving,
          ),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, media.viewInsets.bottom + 24),
              child: _loadingLinks
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: CupertinoActivityIndicator(color: Colors.white))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _groupLabel('DETAILS'),
                        _group([
                          _textRow(
                              label: 'Title', controller: _titleController),
                          _divider(),
                          _pickerRow(
                            label: 'Category',
                            value: _selectedType.displayName,
                            icon: _selectedType.icon,
                            onTap: _pickType,
                          ),
                        ]),
                        _groupLabel('LINK'),
                        _group([
                          _pickerRow(
                            label: 'Reminder',
                            value: _selectedReminder?.title ??
                                'Without a reminder',
                            icon: CupertinoIcons.bell,
                            onTap: _pickReminder,
                          ),
                          // Conditional Car field: only when no reminder.
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOutCubic,
                            child: _selectedReminder != null
                                ? const SizedBox(width: double.infinity)
                                : Column(
                                    children: [
                                      _divider(),
                                      _carField(),
                                    ],
                                  ),
                          ),
                        ]),
                        if (_selectedReminder == null && _showCarError)
                          _footnoteError('Please choose a car for this record.'),
                        _groupLabel('SERVICE'),
                        _group([
                          _dateRow(),
                          _divider(),
                          _textRow(
                            label: 'Cost (EGP)',
                            controller: _costController,
                            keyboard: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                          _divider(),
                          _textRow(
                              label: 'Workshop',
                              controller: _mechanicController,
                              optional: true),
                          _divider(),
                          _textRow(
                              label: 'Invoice #',
                              controller: _invoiceController,
                              optional: true),
                        ]),
                        _groupLabel('NOTES'),
                        _group([
                          _textRow(
                            label: 'Description',
                            controller: _descriptionController,
                            optional: true,
                            maxLines: 3,
                          ),
                        ]),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carField() {
    if (_cars.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'No cars yet. Add a car first to log standalone maintenance.',
                style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                    fontSize: 12),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onPressed: () => Navigator.pop(context),
              child: const Text('Add Car',
                  style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontFamily: 'Orbitron',
                      fontSize: 13)),
            ),
          ],
        ),
      );
    }
    return _pickerRow(
      label: 'Car',
      value: _selectedCar == null ? 'Select a car' : _carLabel(_selectedCar!),
      icon: CupertinoIcons.car_detailed,
      onTap: _pickCar,
      muted: _selectedCar == null,
    );
  }

  String _carLabel(BackupCar c) {
    final plate = c.licensePlate.trim();
    final base = '${c.brand} ${c.model} (${c.year})';
    final showPlate = plate.isNotEmpty &&
        plate != 'Not specified' &&
        !plate.startsWith('VIN-');
    return showPlate ? '$base · $plate' : base;
  }

  Future<void> _pickType() async {
    final picked = await _showPicker<MaintenanceType>(
      title: 'Category',
      options: MaintenanceType.values,
      selected: _selectedType,
      labelOf: (t) => t.displayName,
      iconOf: (t) => t.icon,
    );
    if (picked != null) setState(() => _selectedType = picked.value);
  }

  Future<void> _pickReminder() async {
    // null sentinel option = "Without a reminder".
    final options = <BackupReminder?>[null, ..._reminders];
    final picked = await _showPicker<BackupReminder?>(
      title: 'Related Reminder',
      options: options,
      selected: _selectedReminder,
      labelOf: (r) => r?.title ?? 'Without a reminder',
      subtitleOf: (r) =>
          r == null ? 'Standalone maintenance' : r.description,
      iconOf: (r) => r == null ? CupertinoIcons.nosign : CupertinoIcons.bell,
      allowNull: true,
    );
    // Distinguish "picked null" from "dismissed": _showPicker returns a
    // wrapper only on an actual tap.
    if (picked == null) return; // dismissed
    setState(() {
      final reminder = picked.value;
      _selectedReminder = reminder;
      if (reminder != null) {
        // Reminder carries its own car; discard any manual pick.
        _selectedCar = null;
      } else {
        // Switching to standalone: start empty (single-car preselect aside).
        _selectedCar = _cars.length == 1 ? _cars.first : null;
      }
      _showCarError = false;
    });
  }

  Future<void> _pickCar() async {
    if (_cars.isEmpty) return;
    final picked = await _showPicker<BackupCar>(
      title: 'Select Car',
      options: _cars,
      selected: _selectedCar,
      labelOf: _carLabel,
      iconOf: (_) => CupertinoIcons.car_detailed,
    );
    if (picked != null) {
      setState(() {
        _selectedCar = picked.value;
        _showCarError = false;
      });
    }
  }

  Future<void> _pickDate() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: AppTheme.darkAccentGreen,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done',
                    style: TextStyle(color: AppTheme.primaryGreen)),
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: const CupertinoThemeData(brightness: Brightness.dark),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (d) => setState(() => _selectedDate = d),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_isValid) {
      setState(() => _showCarError =
          _selectedReminder == null && _selectedCar == null);
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    try {
      final result = await _maintenanceService.addMaintenance(
        reminderId: _selectedReminder?.id,
        carId: _selectedReminder == null ? _selectedCar?.id : null,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        cost: double.parse(_costController.text.trim()),
        maintenanceDate: _selectedDate,
        type: _selectedType,
        mechanicName: _mechanicController.text.trim().isEmpty
            ? null
            : _mechanicController.text.trim(),
        invoiceNumber: _invoiceController.text.trim().isEmpty
            ? null
            : _invoiceController.text.trim(),
      );
      if (!mounted) return;
      if (result.success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _saving = false);
        _formError(result.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _formError('Could not save the record. Please try again.');
    }
  }

  void _formError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg, style: const TextStyle(fontFamily: 'Orbitron')),
          backgroundColor: AppDialog.destructive),
    );
  }

  // Shared UI bits ------------------------------------------------------------

  Widget _navBar(
      {required String title, VoidCallback? onSave, required bool saving}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          CupertinoButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white70, fontFamily: 'Orbitron')),
          ),
          Expanded(
            child: Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
          CupertinoButton(
            onPressed: onSave,
            child: saving
                ? const CupertinoActivityIndicator(color: Colors.white)
                : Text('Save',
                    style: TextStyle(
                        color: onSave == null
                            ? Colors.white30
                            : AppTheme.primaryGreen,
                        fontFamily: 'Orbitron',
                        fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _groupLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
        child: Text(text,
            style: const TextStyle(
                color: AppTheme.primaryGreen,
                fontFamily: 'Orbitron',
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.bold)),
      );

  Widget _group(List<Widget> children) => Container(
        decoration: AppTheme.glowCardDecoration(
            radius: 14, accent: AppTheme.primaryGreen),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );

  Widget _divider() => Divider(
      height: 1, thickness: 1, color: Colors.white.withOpacity(0.07));

  Widget _footnoteError(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
        child: Text(text,
            style: const TextStyle(
                color: AppDialog.destructive,
                fontFamily: 'Orbitron',
                fontSize: 11)),
      );

  Widget _textRow({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboard,
    bool optional = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                optional ? label : '$label *',
                style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboard,
              maxLines: maxLines,
              style:
                  const TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
              cursorColor: AppTheme.primaryGreen,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: optional ? 'Optional' : 'Required',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerRow({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool muted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.lightBackground),
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: muted ? Colors.white38 : Colors.white,
                      fontFamily: 'Orbitron',
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 6),
              Icon(CupertinoIcons.chevron_forward,
                  size: 14, color: Colors.white.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateRow() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickDate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              const Icon(CupertinoIcons.calendar,
                  size: 18, color: AppTheme.lightBackground),
              const SizedBox(width: 12),
              const Text('Date *',
                  style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                      fontSize: 13)),
              const SizedBox(width: 6),
              Icon(CupertinoIcons.chevron_forward,
                  size: 14, color: Colors.white.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  /// Generic dark picker sheet with checkmarks. Returns a `_Picked<T>` wrapper
  /// on selection (so a selected `null` is distinguishable from dismissal).
  Future<_Picked<T>?> _showPicker<T>({
    required String title,
    required List<T> options,
    required T? selected,
    required String Function(T) labelOf,
    required IconData Function(T) iconOf,
    String Function(T)? subtitleOf,
    bool allowNull = false,
  }) {
    return showModalBottomSheet<_Picked<T>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.backgroundGreen, AppTheme.darkAccentGreen],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title,
                  style: const TextStyle(
                      color: AppTheme.lightBackground,
                      fontFamily: 'Orbitron',
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                children: options.map((opt) {
                  final isSel = opt == selected;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppTheme.primaryGreen.withOpacity(0.25)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSel
                              ? AppTheme.primaryGreen
                              : Colors.white.withOpacity(0.12),
                          width: 1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            Navigator.pop(ctx, _Picked<T>(opt)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(iconOf(opt),
                                  color: AppTheme.lightBackground, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(labelOf(opt),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: AppTheme.lightBackground,
                                            fontFamily: 'Orbitron',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600)),
                                    if (subtitleOf != null &&
                                        subtitleOf(opt).isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(subtitleOf(opt),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: AppTheme.lightBackground
                                                  .withOpacity(0.6),
                                              fontFamily: 'Orbitron',
                                              fontSize: 11)),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSel)
                                const Icon(CupertinoIcons.checkmark_alt,
                                    color: AppTheme.primaryGreen, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper so a picker can return a selected value of `null` distinctly from
/// the sheet being dismissed (which returns `null` from showModalBottomSheet).
class _Picked<T> {
  final T value;
  const _Picked(this.value);
}

// =============================================================================
// Edit Maintenance form — keeps the existing reminder/car link unchanged.
// =============================================================================
class EditMaintenanceForm extends StatefulWidget {
  final BackupMaintenance maintenance;
  const EditMaintenanceForm({super.key, required this.maintenance});

  @override
  State<EditMaintenanceForm> createState() => _EditMaintenanceFormState();
}

class _EditMaintenanceFormState extends State<EditMaintenanceForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _mechanicController = TextEditingController();
  final _invoiceController = TextEditingController();
  final MaintenanceService _maintenanceService = MaintenanceService();

  late DateTime _selectedDate;
  late MaintenanceType _selectedType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.maintenance;
    _titleController.text = m.title;
    _descriptionController.text = m.description;
    _costController.text = m.cost.toStringAsFixed(0);
    _mechanicController.text = m.mechanicName ?? '';
    _invoiceController.text = m.invoiceNumber ?? '';
    _selectedDate = m.maintenanceDate;
    _selectedType = m.type;
    _titleController.addListener(_refresh);
    _costController.addListener(_refresh);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _mechanicController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  bool get _isValid {
    if (_titleController.text.trim().isEmpty) return false;
    final c = double.tryParse(_costController.text.trim());
    return c != null && c >= 0;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
      margin: EdgeInsets.only(top: media.padding.top + 40),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
            ),
            child: Row(
              children: [
                CupertinoButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel',
                      style: TextStyle(
                          color: Colors.white70, fontFamily: 'Orbitron')),
                ),
                const Expanded(
                  child: Text('Edit Record',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Orbitron',
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
                CupertinoButton(
                  onPressed: _isValid && !_saving ? _save : null,
                  child: _saving
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text('Save',
                          style: TextStyle(
                              color: _isValid
                                  ? AppTheme.primaryGreen
                                  : Colors.white30,
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, media.viewInsets.bottom + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _group([
                    _textRow(label: 'Title', controller: _titleController),
                    _divider(),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _pickType,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              Icon(_selectedType.icon,
                                  size: 18, color: AppTheme.lightBackground),
                              const SizedBox(width: 12),
                              const Text('Category',
                                  style: TextStyle(
                                      color: AppTheme.primaryGreen,
                                      fontFamily: 'Orbitron',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(_selectedType.displayName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Orbitron',
                                      fontSize: 13)),
                              const SizedBox(width: 6),
                              Icon(CupertinoIcons.chevron_forward,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.4)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _group([
                    _dateRow(),
                    _divider(),
                    _textRow(
                        label: 'Cost (EGP)',
                        controller: _costController,
                        keyboard: const TextInputType.numberWithOptions(
                            decimal: true)),
                    _divider(),
                    _textRow(
                        label: 'Workshop',
                        controller: _mechanicController,
                        optional: true),
                    _divider(),
                    _textRow(
                        label: 'Invoice #',
                        controller: _invoiceController,
                        optional: true),
                  ]),
                  const SizedBox(height: 16),
                  _group([
                    _textRow(
                        label: 'Description',
                        controller: _descriptionController,
                        optional: true,
                        maxLines: 3),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickType() async {
    final picked = await showModalBottomSheet<MaintenanceType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.backgroundGreen, AppTheme.darkAccentGreen],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('Category',
                style: TextStyle(
                    color: AppTheme.lightBackground,
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...MaintenanceType.values.map((t) {
              final sel = t == _selectedType;
              return ListTile(
                leading: Icon(t.icon, color: AppTheme.lightBackground),
                title: Text(t.displayName,
                    style: const TextStyle(
                        color: AppTheme.lightBackground,
                        fontFamily: 'Orbitron')),
                trailing: sel
                    ? const Icon(CupertinoIcons.checkmark_alt,
                        color: AppTheme.primaryGreen)
                    : null,
                onTap: () => Navigator.pop(ctx, t),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _selectedType = picked);
  }

  Future<void> _pickDate() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: AppTheme.darkAccentGreen,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done',
                    style: TextStyle(color: AppTheme.primaryGreen)),
              ),
            ),
            Expanded(
              child: CupertinoTheme(
                data: const CupertinoThemeData(brightness: Brightness.dark),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _selectedDate,
                  maximumDate: DateTime.now(),
                  onDateTimeChanged: (d) => setState(() => _selectedDate = d),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    try {
      final result = await _maintenanceService.updateMaintenance(
        maintenanceId: widget.maintenance.id!.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        cost: double.parse(_costController.text.trim()),
        maintenanceDate: _selectedDate,
        type: _selectedType,
        mechanicName: _mechanicController.text.trim().isEmpty
            ? null
            : _mechanicController.text.trim(),
        invoiceNumber: _invoiceController.text.trim().isEmpty
            ? null
            : _invoiceController.text.trim(),
      );
      if (!mounted) return;
      if (result.success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.message),
            backgroundColor: AppDialog.destructive));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Could not update the record.'),
          backgroundColor: AppDialog.destructive));
    }
  }

  Widget _group(List<Widget> children) => Container(
        decoration: AppTheme.glowCardDecoration(
            radius: 14, accent: AppTheme.primaryGreen),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );

  Widget _divider() => Divider(
      height: 1, thickness: 1, color: Colors.white.withOpacity(0.07));

  Widget _dateRow() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickDate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              const Icon(CupertinoIcons.calendar,
                  size: 18, color: AppTheme.lightBackground),
              const SizedBox(width: 12),
              const Text('Date *',
                  style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textRow({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboard,
    bool optional = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(optional ? label : '$label *',
                  style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboard,
              maxLines: maxLines,
              style:
                  const TextStyle(color: Colors.white, fontFamily: 'Orbitron'),
              cursorColor: AppTheme.primaryGreen,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: optional ? 'Optional' : 'Required',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Details dialog — monochrome (single accent), reuses the app dialog language.
// =============================================================================
class MaintenanceDetailsDialog extends StatelessWidget {
  final MaintenanceWithInfo maintenanceWithInfo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MaintenanceDetailsDialog({
    super.key,
    required this.maintenanceWithInfo,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final m = maintenanceWithInfo.maintenance;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 800),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundGreen, AppTheme.darkAccentGreen],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.6), width: 1),
          boxShadow: AppTheme.glowShadow(
              accent: AppTheme.primaryGreen, elevated: true),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15), width: 1),
                  ),
                  child: Icon(m.type.icon,
                      color: AppTheme.lightBackground, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Orbitron',
                              color: AppTheme.lightBackground)),
                      const SizedBox(height: 3),
                      Text(
                        '${m.type.displayName} · ${DateFormat('MMM dd, yyyy').format(m.maintenanceDate)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.lightBackground.withOpacity(0.7),
                            fontFamily: 'Orbitron'),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(CupertinoIcons.xmark,
                      color: AppTheme.lightBackground, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGreen.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: Column(
                children: [
                  _row('Cost', 'EGP ${m.cost.toStringAsFixed(2)}',
                      CupertinoIcons.money_dollar),
                  _row('Car', maintenanceWithInfo.carDisplayName,
                      CupertinoIcons.car_detailed),
                  _row('Reminder', maintenanceWithInfo.reminderDisplayName,
                      CupertinoIcons.bell),
                  if (m.description.isNotEmpty)
                    _row('Description', m.description,
                        CupertinoIcons.doc_text),
                  if (m.mechanicName != null && m.mechanicName!.isNotEmpty)
                    _row('Workshop', m.mechanicName!, CupertinoIcons.person),
                  if (m.invoiceNumber != null && m.invoiceNumber!.isNotEmpty)
                    _row('Invoice', m.invoiceNumber!,
                        CupertinoIcons.doc_plaintext),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _button(
                        CupertinoIcons.pencil, 'Edit', AppTheme.primaryGreen,
                        onEdit)),
                const SizedBox(width: 12),
                Expanded(
                    child: _button(CupertinoIcons.trash, 'Delete',
                        AppDialog.destructive, onDelete)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.lightBackground),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.lightBackground.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Orbitron')),
                const SizedBox(height: 2),
                Text(value.isEmpty ? '—' : value,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.lightBackground,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Orbitron')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _button(IconData icon, String label, Color color, VoidCallback onTap) {
    return Container(
      decoration: AppTheme.glowButtonDecoration(accent: color),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 17),
                const SizedBox(width: 8),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        fontFamily: 'Orbitron')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
