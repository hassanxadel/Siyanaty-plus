import 'dart:io';
import 'package:siyanaty_plus/shared/utils/custom_snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/screen_with_nav_bar.dart';
import '../../../services/car_service.dart';
import '../../../services/car_health_service.dart';
import '../../../services/reminder_service.dart';
import '../../../models/car_health_score.dart';
import '../../../models/backup_car.dart';
import '../../../models/backup_reminder.dart';
import 'package:image_picker/image_picker.dart';
import 'reminders_screen.dart';


class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  final CarService _carService = CarService();
  final CarHealthService _carHealthService = CarHealthService();
  final Map<int, CarHealthScore> _carHealthScores = {};
  List<BackupCar> _cars = [];
  List<BackupCar> _filteredCars = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCars() async {
    try {
      final cars = await _carService.getAllCars();
      if (!mounted) return;
      setState(() {
        _cars = cars;
        _isLoading = false;
      });
      _applyFilters();
      _loadHealthScores(cars);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      AppSnackbar.show(
        context,
        SnackBar(
          content: Text('Failed to load cars: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Loads each car's health score the same way the Home carousel does, so the
  /// badge colours match. Scores fill in as they arrive.
  Future<void> _loadHealthScores(List<BackupCar> cars) async {
    for (final car in cars) {
      if (car.id == null) continue;
      try {
        final score = await _carHealthService.calculateHealthScore(car);
        if (!mounted) return;
        setState(() => _carHealthScores[car.id!] = score);
      } catch (_) {
        // A single car's health failing shouldn't block the list.
      }
    }
  }

  void _applyFilters() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredCars = _cars;
      } else {
        _filteredCars = _cars.where((car) {
          final searchLower = _searchQuery.toLowerCase();
          return car.brand.toLowerCase().contains(searchLower) ||
                 car.model.toLowerCase().contains(searchLower) ||
                 car.year.toString().contains(searchLower) ||
                 (car.licensePlate.toLowerCase().contains(searchLower)) ||
                 (car.vin.toLowerCase().contains(searchLower)) ||
                 (car.color.toLowerCase().contains(searchLower));
        }).toList();
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _navigateToCarDetails(BackupCar car) {
    showDialog(
      context: context,
      builder: (context) => CarDetailsDialog(
        car: car,
        onEdit: () => _showEditCarDialog(car),
        onDelete: () => _confirmAndDeleteCar(car),
      ),
    );
  }

  void _showEditCarDialog(BackupCar car) {
    // Note: CarDetailsDialog already pops, so we don't need to pop again
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => EditCarForm(
        car: car,
        onCarUpdated: _loadCars,
      ),
    );
  }

  /// Shows the iOS confirmation, then deletes if the user agrees. Shared by the
  /// swipe action and the car details dialog.
  Future<void> _confirmAndDeleteCar(BackupCar car) async {
    if (await _confirmDeleteDialog(car)) {
      await _performDelete(car);
    }
  }

  Future<bool> _confirmDeleteDialog(BackupCar car) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('Delete ${car.brand} ${car.model}?'),
        content: const Text(
          '\nThis car, with its maintenance records and reminders, will be '
          'affected. This can’t be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Swipe-to-delete: removes the card from the list synchronously (required by
  /// [Dismissible]), deletes in the background, and restores on failure.
  Future<void> _deleteSwiped(BackupCar car) async {
    setState(() {
      _cars.removeWhere((c) => c.id == car.id);
      _filteredCars.removeWhere((c) => c.id == car.id);
      if (car.id != null) _carHealthScores.remove(car.id);
    });
    try {
      final result = await _carService.deleteCar(car.id!);
      if (!mounted) return;
      if (result.isSuccess) {
        AppSnackbar.show(
          context,
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      } else {
        await _loadCars(); // restore from the database
        if (mounted) {
          AppSnackbar.show(
            context,
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      await _loadCars();
      if (mounted) {
        AppSnackbar.show(
          context,
          SnackBar(
            content: Text('Error deleting car: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performDelete(BackupCar car) async {
    try {
      final result = await _carService.deleteCar(car.id!);
      if (!mounted) return;
      if (result.isSuccess) {
        await _loadCars();
        if (mounted) {
          AppSnackbar.show(
            context,
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } else {
        AppSnackbar.show(
          context,
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          SnackBar(
            content: Text('Error deleting car: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHeader() {
    // Standard app page header — kept per the app-wide header rule. Uses a
    // minHeight (not a fixed height) so large text grows instead of overflowing.
    return Container(
      constraints: const BoxConstraints(minHeight: 200),
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
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    tooltip: 'Back',
                    icon: const Icon(CupertinoIcons.back,
                        color: Colors.white, size: 28),
                  ),
                  const Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'My Cars',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.lightBackground,
                          fontFamily: 'Orbitron',
                          shadows: [
                            Shadow(
                                color: Colors.black45,
                                blurRadius: 8,
                                offset: Offset(0, 3)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Balances the back button so the title stays centered; the
                  // add action lives in the centered button below.
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Manage your vehicles',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontFamily: 'Orbitron',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Standard centered "Add <X>" button: width 170, under the
              // subtitle. Reuse this design + place on every screen with an add
              // action (see header-add-button memory).
              _buildAddCarButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCarButton() {
    return Semantics(
      button: true,
      label: 'Add new car',
      child: Container(
        width: 170,
        height: 45,
        decoration: AppTheme.primaryButtonDecoration(),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showAddCarSheet();
            },
            child: const Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Add New Car',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithNavBar(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundGreen,
        body: Column(
          children: [
            _buildHeader(),
            if (!_isLoading && _cars.isNotEmpty) _buildSearchField(),
            Expanded(
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: _loadCars),
                  if (_isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: CupertinoActivityIndicator(color: Colors.white),
                      ),
                    )
                  else if (_filteredCars.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildCarCard(_filteredCars[index], index),
                          ),
                          childCount: _filteredCars.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: CupertinoSearchTextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        placeholder: 'Search by brand, model, plate…',
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'Orbitron',
          fontSize: 15,
        ),
        placeholderStyle: TextStyle(
          color: Colors.white.withOpacity(0.5),
          fontFamily: 'Orbitron',
          fontSize: 15,
        ),
        backgroundColor: Colors.white.withOpacity(0.08),
        prefixIcon:
            Icon(CupertinoIcons.search, color: Colors.white.withOpacity(0.6)),
        itemColor: Colors.white.withOpacity(0.6),
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchQuery.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? CupertinoIcons.search : CupertinoIcons.car_detailed,
              size: 72,
              color: AppTheme.lightBackground.withOpacity(0.6),
            ),
            const SizedBox(height: 18),
            Text(
              isSearching ? 'No cars found' : 'No cars yet',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightBackground,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isSearching
                  ? 'Try a different search term.'
                  : 'Add your first car to start tracking\nmaintenance and services.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.white.withOpacity(0.7),
                fontFamily: 'Orbitron',
              ),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Add your first car',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showAddCarSheet();
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      decoration: AppTheme.primaryButtonDecoration(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 13),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.add,
                              size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Add your first car',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Orbitron',
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCarCard(BackupCar car, int index) {
    final score = car.id != null ? _carHealthScores[car.id] : null;
    final status = score?.healthStatus ?? 'unknown';
    final healthColor = Color(CarHealthScore.getHealthColor(status));
    final healthLabel = CarHealthScore.getHealthStatusDisplay(status);
    final plate = car.licensePlate.trim().isEmpty ? '—' : car.licensePlate;

    void openDetails() {
      HapticFeedback.lightImpact();
      _navigateToCarDetails(car);
    }

    return Dismissible(
      key: ValueKey(car.id ?? index),
      // Swipe right → Edit (snaps back); swipe left → Delete (confirmed first).
      background: _swipeBg(
        align: Alignment.centerLeft,
        color: AppTheme.infoBlue,
        icon: CupertinoIcons.pencil,
        label: 'Edit',
      ),
      secondaryBackground: _swipeBg(
        align: Alignment.centerRight,
        color: AppTheme.errorColor,
        icon: CupertinoIcons.delete,
        label: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _showEditCarDialog(car);
          return false;
        }
        return _confirmDeleteDialog(car);
      },
      onDismissed: (_) => _deleteSwiped(car),
      child: _carCardBody(
          car, plate, healthColor, healthLabel, score, openDetails),
    );
  }

  Widget _swipeBg({
    required Alignment align,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: align,
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _carCardBody(BackupCar car, String plate, Color healthColor,
      String healthLabel, CarHealthScore? score, VoidCallback openDetails) {
    return Container(
      decoration: AppTheme.carCardDecoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: openDetails,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, c) {
                final imgSize = (c.maxWidth * 0.26).clamp(72.0, 104.0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _carImage(car, imgSize),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${car.brand} ${car.model}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontFamily: 'Orbitron',
                                      ),
                                    ),
                                  ),
                                  const Icon(CupertinoIcons.chevron_right,
                                      size: 16,
                                      color: AppTheme.lightBackground),
                                ],
                              ),
                              const SizedBox(height: 2),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${car.year} · ${car.color}',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: Colors.white.withOpacity(0.7),
                                    fontFamily: 'Orbitron',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(child: _spec('Plate', plate)),
                                  Expanded(
                                    child: _spec(
                                        'Mileage', '${car.mileage} km'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _healthBadge(score, healthColor, healthLabel),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                        height: 1, color: Colors.white.withOpacity(0.08)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _carLink('Service reminders', CupertinoIcons.bell,
                          () => _showCarReminders(car)),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _carImage(BackupCar car, double size) {
    final hasImage = car.imagePath != null &&
        car.imagePath!.isNotEmpty &&
        File(car.imagePath!).existsSync();
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: hasImage
            ? Image.file(File(car.imagePath!), fit: BoxFit.cover)
            : Container(
                color: Colors.white.withOpacity(0.06),
                child: Icon(CupertinoIcons.car_detailed,
                    size: size * 0.42, color: Colors.white.withOpacity(0.5)),
              ),
      ),
    );
  }

  /// Small yellow label over a white value; the value scales down so long
  /// numbers never overflow on a narrow card.
  Widget _spec(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.lightBackground,
                fontWeight: FontWeight.w500,
                fontFamily: 'Orbitron')),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              maxLines: 1,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Orbitron')),
        ),
      ],
    );
  }

  /// Health dot + label in the health colour — the sanctioned exception to the
  /// "no green text" rule, matching the Home carousel badge.
  Widget _healthBadge(CarHealthScore? score, Color color, String label) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            score != null
                ? '$label · ${score.overallScore.round()}'
                : 'Health —',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Orbitron'),
          ),
        ),
      ],
    );
  }

  /// Clean yellow text button with an icon — no pill background.
  Widget _carLink(String label, IconData icon, VoidCallback onTap) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: AppTheme.lightBackground),
                const SizedBox(width: 5),
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.lightBackground,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Orbitron')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCarReminders(BackupCar car) async {
    final reminderService = ReminderService();
    
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<ReminderOperationResult>(
        future: reminderService.getRemindersByCar(car.id!),
        builder: (context, snapshot) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.backgroundGreen,
                    AppTheme.darkAccentGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.secondaryGreen.withOpacity(0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: AppTheme.secondaryGreen.withOpacity(0.3),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.secondaryGreen.withOpacity(0.5),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.secondaryGreen.withOpacity(0.25),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.build_circle,
                          color: AppTheme.secondaryGreen,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Service Reminders',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Orbitron',
                                color: AppTheme.lightBackground,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${car.brand} ${car.model}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.lightBackground.withOpacity(0.7),
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGreen.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.secondaryGreen.withOpacity(0.35),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.lightBackground,
                            size: 20,
                          ),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Hairline divider under the header
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.secondaryGreen.withOpacity(0.5),
                          AppTheme.secondaryGreen.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content
                  Flexible(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(
                            child: CircularProgressIndicator(color: AppTheme.secondaryGreen),
                          )
                        : snapshot.hasError || !snapshot.hasData || snapshot.data!.reminders == null || snapshot.data!.reminders!.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(18),
                                      decoration: BoxDecoration(
                                        color: AppTheme.secondaryGreen.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.secondaryGreen.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.notifications_none,
                                        size: 40,
                                        color: AppTheme.secondaryGreen.withOpacity(0.8),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'No reminders for this car',
                                      style: TextStyle(
                                        color: AppTheme.lightBackground.withOpacity(0.85),
                                        fontFamily: 'Orbitron',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Add service reminders to keep track\nof maintenance schedules',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.lightBackground.withOpacity(0.5),
                                        fontFamily: 'Orbitron',
                                        fontSize: 11,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: snapshot.data!.reminders!.length > 5
                                    ? 5
                                    : snapshot.data!.reminders!.length,
                                itemBuilder: (context, index) {
                                  final reminder = snapshot.data!.reminders![index];
                                  return _buildReminderItem(reminder);
                                },
                              ),
                  ),

                  const SizedBox(height: 18),

                  // View All Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryGreen.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.secondaryGreen.withOpacity(0.7),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryGreen.withOpacity(0.3),
                          blurRadius: 18,
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SmartRemindersScreen(),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'View All Reminders',
                                style: TextStyle(
                                  color: AppTheme.secondaryGreen,
                                  fontFamily: 'Orbitron',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 14,
                                color: AppTheme.secondaryGreen,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReminderItem(BackupReminder reminder) {
    Color statusColor;
    IconData statusIcon;
    
    switch (reminder.status) {
      case ReminderStatus.overdue:
        statusColor = Colors.red;
        statusIcon = Icons.warning;
        break;
      case ReminderStatus.upcoming:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case ReminderStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGreen.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.45),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: statusColor.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(
              statusIcon,
              color: statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    fontFamily: 'Orbitron',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  reminder.targetDate != null
                      ? '${reminder.targetDate!.day}/${reminder.targetDate!.month}/${reminder.targetDate!.year}'
                      : reminder.targetMileage != null
                          ? '${reminder.targetMileage} km'
                          : 'No date set',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              reminder.status.name.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCarSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddCarForm(onCarAdded: _loadCars),
    );
  }
}

class CarDetailsDialog extends StatelessWidget {
  final BackupCar car;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CarDetailsDialog({
    super.key,
    required this.car,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(context.r(20)),
          constraints: BoxConstraints(
            maxWidth: context.r(480),
            maxHeight: context.screenHeight * 0.95,
          ),
          // Matches AppDialogPanel so this card is visually part of the same
          // family as every other pop-up in the app.
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(context.responsiveBorderRadius(24)),
            border: Border.all(
              color: AppTheme.secondaryGreen.withOpacity(0.6),
              width: 1,
            ),
            boxShadow: AppTheme.glowShadow(elevated: true),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header — same structure as the Service Reminders card:
            // glowing thumbnail chip, title + subtitle, raised close button.
            Row(
              children: [
                Container(
                  width: 72,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.secondaryGreen.withOpacity(0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.secondaryGreen.withOpacity(0.25),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: car.imagePath != null && car.imagePath!.isNotEmpty
                        ? Image.file(
                            File(car.imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                IconData(0xe800, fontFamily: 'MyFlutterApp'),
                                color: AppTheme.secondaryGreen,
                                size: 24,
                              );
                            },
                          )
                        : const Icon(
                            IconData(0xe800, fontFamily: 'MyFlutterApp'),
                            color: AppTheme.secondaryGreen,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${car.brand} ${car.model}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron',
                          color: AppTheme.lightBackground,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${car.year} · ${car.color}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.lightBackground.withOpacity(0.7),
                          fontFamily: 'Orbitron',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGreen.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.secondaryGreen.withOpacity(0.35),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.lightBackground,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Hairline divider under the header
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondaryGreen.withOpacity(0.5),
                    AppTheme.secondaryGreen.withOpacity(0.0),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Details section with modern styling
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGreen.withOpacity(0.55),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.secondaryGreen.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildModernDetailRow('Mileage', '${car.mileage} km', Icons.speed, Colors.blue),
                  _buildModernDetailRow('Color', car.color, Icons.color_lens, Colors.purple),
                  _buildModernDetailRow('Fuel Type', car.fuelType, Icons.local_gas_station, Colors.orange),
                  _buildModernDetailRow('Engine', car.engineCC + (car.turbo ? ' Turbo' : ''), Icons.build, Colors.red),
                  _buildModernDetailRow('VIN', car.vin, Icons.qr_code, Colors.cyan),
                  _buildModernDetailRow('Added', _formatDate(car.createdAt), Icons.calendar_today, Colors.green),
                  if (car.updatedAt != car.createdAt)
                    _buildModernDetailRow('Last Updated', _formatDate(car.updatedAt), Icons.update, Colors.teal),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Modern action buttons
            Column(
              children: [
                // Top row - Edit and Delete
                Row(
                  children: [
                    Expanded(
                      child: _buildModernButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        color: AppTheme.secondaryGreen,
                        onPressed: () {
                          if (context.mounted) {
                            Navigator.pop(context);
                            onEdit();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernButton(
                        icon: Icons.delete_rounded,
                        label: 'Delete',
                        color: AppDialog.destructive,
                        onPressed: () {
                          if (context.mounted) {
                            Navigator.pop(context);
                            onDelete();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              
              ],
            ),
          ],
        ), // Column
      ), // Container
      ), // SingleChildScrollView
    ); // Dialog
  }

  Widget _buildModernDetailRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.lightBackground.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Orbitron',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.lightBackground,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Orbitron',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Pill action matching the "View All Reminders" button on the Service
  /// Reminders card — tinted fill, glowing rim, accent-coloured label.
  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: AppTheme.glowButtonDecoration(accent: color),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 17),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      fontFamily: 'Orbitron',
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class EditCarForm extends StatefulWidget {
  final BackupCar car;
  final VoidCallback onCarUpdated;
  
  const EditCarForm({super.key, required this.car, required this.onCarUpdated});
  
  @override
  State<EditCarForm> createState() => _EditCarFormState();
}

class _EditCarFormState extends State<EditCarForm> {
  final CarService _carService = CarService();
  late String make;
  late String model;
  late String year;
  late String mileage;
  late String color;
  late String fuelType;
  late String engineCc;
  late bool turbo;
  late String license;
  late String vin;
  late String imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current car data
    make = widget.car.brand;
    model = widget.car.model;
    year = widget.car.year.toString();
    mileage = widget.car.mileage.toString();
    color = widget.car.color;
    fuelType = widget.car.fuelType;
    engineCc = widget.car.engineCC;
    turbo = widget.car.turbo;
    license = widget.car.licensePlate;
    vin = widget.car.vin;
    imagePath = widget.car.imagePath ?? '';
    
    // Check if the image file actually exists
    _checkImageExists();
  }
  
  Future<void> _checkImageExists() async {
    if (imagePath.isNotEmpty) {
      final exists = await File(imagePath).exists();
      if (mounted && !exists) {
        setState(() {
          // Clear the path if image doesn't exist (restored from cloud without local file)
          imagePath = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
        final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: media.viewInsets.bottom + 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Edit Car', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text('* Required fields', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(label: 'Brand*', initialValue: make, onChanged: (v) => make = v)),
                const SizedBox(width: 12),
                Expanded(child: _field(label: 'Model*', initialValue: model, onChanged: (v) => model = v)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(label: 'Year (optional)', initialValue: year, keyboard: TextInputType.number, onChanged: (v) => year = v)),
                const SizedBox(width: 12),
                Expanded(child: _field(label: 'Mileage (optional)', initialValue: mileage, keyboard: TextInputType.number, onChanged: (v) => mileage = v)),
              ],
            ),
                  const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(label: 'Color (optional)', initialValue: color, onChanged: (v) => color = v)),
                const SizedBox(width: 12),
                Expanded(child: _field(label: 'Fuel Type (optional)', initialValue: fuelType, onChanged: (v) => fuelType = v)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(label: 'Engine CC (optional)', initialValue: engineCc, keyboard: TextInputType.number, onChanged: (v) => engineCc = v)),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      const Text('Turbo', style: TextStyle(fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Switch(
                        value: turbo,
                        onChanged: (v) {
                          setState(() { turbo = v; });
                        },
                        activeColor: AppTheme.backgroundGreen,
                        activeTrackColor: AppTheme.lightBackground,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(label: 'License Plate (optional)', initialValue: license, onChanged: (v) => license = v)),
                const SizedBox(width: 12),
                Expanded(child: _field(label: 'VIN (optional)', initialValue: vin, onChanged: (v) => vin = v)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    imagePath.isEmpty ? 'No image selected' : 'Image selected: ${imagePath.split('/').last}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'Orbitron', fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (picked != null) {
                      setState(() {
                        imagePath = picked.path;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.backgroundGreen,
                          AppTheme.darkAccentGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.secondaryGreen.withOpacity(0.6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryGreen.withOpacity(0.3),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo, size: 20, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Pick Image', style: TextStyle(fontFamily: 'Orbitron', fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              child: Container(
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.backgroundGreen,
                          AppTheme.darkAccentGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.secondaryGreen.withOpacity(0.6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryGreen.withOpacity(0.3),
                          blurRadius: 18,
                        ),
                      ],
                    ),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  setState(() {
                    _isLoading = true;
                  });
                  // Only require brand and model as minimum
                  if (make.isEmpty || model.isEmpty) {
                    setState(() {
                      _isLoading = false;
                    });
                    AppSnackbar.show(context, 
                      const SnackBar(
                        content: Text('Please fill in at least Brand and Model'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  try {
                    // Update car using CarService
                    final result = await _carService.updateCar(
                      id: widget.car.id!,
                      brand: make,
                      model: model,
                      year: int.tryParse(year) ?? DateTime.now().year,
                      mileage: int.tryParse(mileage) ?? 0,
                      color: color.isEmpty ? 'Not specified' : color,
                      fuelType: fuelType.isEmpty ? 'Not specified' : fuelType,
                      engineCC: engineCc.isEmpty ? 'Not specified' : engineCc,
                      turbo: turbo,
                      licensePlate: license.isEmpty ? 'Not specified' : license,
                      vin: vin.isEmpty ? 'VIN${DateTime.now().millisecondsSinceEpoch}' : vin,
                      imagePath: imagePath.isEmpty ? null : imagePath,
                    );
                    
                    Navigator.pop(context);
                    
                    if (result.isSuccess) {
                      // Call the callback to reload cars list
                      widget.onCarUpdated();
                      
                      if (mounted) {
                        AppSnackbar.show(context, 
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        AppSnackbar.show(context, 
                          SnackBar(
                            content: Text(result.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context);
                      AppSnackbar.show(context, 
                        SnackBar(
                          content: Text('Error updating car: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                  child: _isLoading 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Update Car', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    TextInputType? keyboard,
    required Function(String) onChanged,
    String? initialValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
            color: AppTheme.lightBackground.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondaryGreen.withOpacity(0.25),
                blurRadius: 14,
              ),
            ],
          ),
          child: TextFormField(
            initialValue: initialValue,
            keyboardType: keyboard,
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: AppTheme.lightBackground,
            ),
            decoration: InputDecoration(
              filled: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.secondaryGreen.withOpacity(0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppTheme.secondaryGreen.withOpacity(0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.secondaryGreen,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class AddCarForm extends StatefulWidget {
  final VoidCallback onCarAdded;
  
  const AddCarForm({super.key, required this.onCarAdded});
  
  @override
  State<AddCarForm> createState() => _AddCarFormState();
}

class _AddCarFormState extends State<AddCarForm> {
  final CarService _carService = CarService();
  String make = '';
  String model = '';
  String year = '';
  String mileage = '';
  String color = '';
  String fuelType = '';
  String engineCc = '';
  bool turbo = false;
  String license = '';
  String vin = '';
  String imagePath = '';
  bool _isLoading = false;
  
  // Error states for inline validation
  String? _makeError;
  String? _modelError;
  String? _yearError;
  String? _mileageError;
  String? _vinError;
  String? _licensePlateError;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: media.viewInsets.bottom + 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                  const SizedBox(height: 12),
                const Text('Add New Car', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 8),
                Text('* Required fields', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(
                      label: 'Brand*', 
                      onChanged: (v) {
                        make = v;
                        if (_makeError != null) setState(() => _makeError = null);
                      },
                      errorText: _makeError,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _field(
                      label: 'Model*', 
                      onChanged: (v) {
                        model = v;
                        if (_modelError != null) setState(() => _modelError = null);
                      },
                      errorText: _modelError,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(
                      label: 'Year (optional)', 
                      keyboard: TextInputType.number, 
                      onChanged: (v) {
                        year = v;
                        if (_yearError != null) setState(() => _yearError = null);
                      },
                      errorText: _yearError,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _field(
                      label: 'Mileage (optional)', 
                      keyboard: TextInputType.number, 
                      onChanged: (v) {
                        mileage = v;
                        if (_mileageError != null) setState(() => _mileageError = null);
                      },
                      errorText: _mileageError,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(label: 'Color (optional)', onChanged: (v) => color = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(label: 'Fuel Type (optional)', onChanged: (v) => fuelType = v)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(label: 'Engine CC (optional)', keyboard: TextInputType.number, onChanged: (v) => engineCc = v)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          const Text('Turbo', style: TextStyle(fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 12),
                          Switch(
                            value: turbo,
                            onChanged: (v) {
                              setState(() { turbo = v; });
                            },
                            activeColor: AppTheme.backgroundGreen,
                            activeTrackColor: AppTheme.lightBackground,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _field(
                      label: 'License Plate (optional)', 
                      onChanged: (v) {
                        license = v;
                        if (_licensePlateError != null) setState(() => _licensePlateError = null);
                      },
                      errorText: _licensePlateError,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _field(
                      label: 'VIN (optional)', 
                      onChanged: (v) {
                        vin = v;
                        if (_vinError != null) setState(() => _vinError = null);
                      },
                      errorText: _vinError,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        imagePath.isEmpty ? 'No image selected' : imagePath,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Orbitron', fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                        if (picked != null) {
                          setState(() {
                            imagePath = picked.path;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.backgroundGreen,
                          AppTheme.darkAccentGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.secondaryGreen.withOpacity(0.6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryGreen.withOpacity(0.3),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Pick Image', style: TextStyle(fontFamily: 'Orbitron', fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ], 
                ),
                const SizedBox(height: 16),
                SizedBox(  
                  child: Container(
                      decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.backgroundGreen,
                          AppTheme.darkAccentGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.secondaryGreen.withOpacity(0.6),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryGreen.withOpacity(0.3),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      // Clear previous errors
                      setState(() {
                        _makeError = null;
                        _modelError = null;
                        _yearError = null;
                        _mileageError = null;
                        _vinError = null;
                        _licensePlateError = null;
                      });
                      
                      // Validate fields
                      bool hasError = false;
                      
                      if (make.isEmpty) {
                        setState(() => _makeError = 'Brand is required');
                        hasError = true;
                      }
                      
                      if (model.isEmpty) {
                        setState(() => _modelError = 'Model is required');
                        hasError = true;
                      }
                      
                      // Validate year format if provided
                      if (year.isNotEmpty) {
                        final yearInt = int.tryParse(year);
                        if (yearInt == null || yearInt < 1900 || yearInt > DateTime.now().year + 1) {
                          setState(() => _yearError = 'Invalid year (1900-${DateTime.now().year + 1})');
                          hasError = true;
                        }
                      }
                      
                      // Validate mileage format if provided
                      if (mileage.isNotEmpty) {
                        final mileageInt = int.tryParse(mileage);
                        if (mileageInt == null || mileageInt < 0) {
                          setState(() => _mileageError = 'Invalid mileage');
                          hasError = true;
                        }
                      }
                      
                      // Validate VIN format if provided (must be 17 characters)
                      if (vin.isNotEmpty && vin.length != 17) {
                        setState(() => _vinError = 'VIN must be exactly 17 characters');
                        hasError = true;
                      }
                      
                      if (hasError) {
                        return; // Don't close form, just show errors
                      }
                      
                      setState(() {
                        _isLoading = true;
                      });
                      
                      try {
                        // Save to backup system using CarService
                        final result = await _carService.addCar(
                          brand: make,
                          model: model,
                          year: int.tryParse(year) ?? DateTime.now().year,
                          mileage: int.tryParse(mileage) ?? 0,
                          color: color.isEmpty ? 'Not specified' : color,
                          fuelType: fuelType.isEmpty ? 'Not specified' : fuelType,
                          engineCC: engineCc.isEmpty ? 'Not specified' : engineCc,
                          turbo: turbo,
                          licensePlate: license.isEmpty ? 'Not specified' : license,
                          vin: vin.isEmpty ? 'VIN${DateTime.now().millisecondsSinceEpoch}' : vin,
                          imagePath: imagePath.isEmpty ? null : imagePath,
                        );
                        
                        if (result.isSuccess) {
                          Navigator.pop(context);
                          // Call the callback to reload cars list
                          widget.onCarAdded();
                          
                          if (mounted) {
                            AppSnackbar.show(context, 
                              SnackBar(
                                content: Text(result.message),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          }
                        } else {
                          // Check for specific field errors from the service
                          if (result.message.toLowerCase().contains('vin')) {
                            setState(() => _vinError = result.message);
                          } else if (result.message.toLowerCase().contains('license')) {
                            setState(() => _licensePlateError = result.message);
                          } else if (result.message.toLowerCase().contains('year')) {
                            setState(() => _yearError = result.message);
                          } else if (result.message.toLowerCase().contains('mileage')) {
                            setState(() => _mileageError = result.message);
                          } else {
                            // Generic error - show snackbar but don't close
                            if (mounted) {
                              AppSnackbar.show(context, 
                                SnackBar(
                                  content: Text(result.message),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          AppSnackbar.show(context, 
                            SnackBar(
                              content: Text('Error adding car: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                    
                    style: ElevatedButton.styleFrom(
                      
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                   
                      child: _isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Car', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                  const SizedBox(height: 8),
              ],
            ),
          ),
        );
  }

  Widget _field({
    required String label,
    TextInputType? keyboard,
    required Function(String) onChanged,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : null,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.backgroundGreen,
                AppTheme.darkAccentGreen,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (hasError ? Colors.red : AppTheme.secondaryGreen)
                    .withOpacity(0.25),
                blurRadius: 14,
              ),
            ],
          ),
          child: TextFormField(
            keyboardType: keyboard,
            onChanged: onChanged,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              color: AppTheme.lightBackground,
            ),
            decoration: InputDecoration(
              filled: false,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : AppTheme.secondaryGreen.withOpacity(0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: hasError
                      ? Colors.red
                      : AppTheme.secondaryGreen.withOpacity(0.4),
                  width: hasError ? 1.5 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: hasError ? Colors.red : AppTheme.secondaryGreen,
                  width: 1.5,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        if (hasError) ...[
            const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 10,
              color: Colors.red,
            ),
          ),
        ],
      ],
    );
  }

} 