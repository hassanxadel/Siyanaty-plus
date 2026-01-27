import 'dart:io';
import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../services/car_service.dart';
import '../../../services/car_health_service.dart';
import '../../../services/expense_service.dart';
import '../../../models/backup_car.dart';
import '../../../models/car_health_score.dart';
import '../../../models/expense.dart';
import '../../widgets/screen_with_nav_bar.dart';

/// Car Health Dashboard Screen
/// Displays health scores, analytics, and insights for all cars
class CarHealthDashboardScreen extends StatefulWidget {
  const CarHealthDashboardScreen({super.key});

  @override
  State<CarHealthDashboardScreen> createState() => _CarHealthDashboardScreenState();
}

class _CarHealthDashboardScreenState extends State<CarHealthDashboardScreen> {
  final CarService _carService = CarService();
  final CarHealthService _healthService = CarHealthService();
  final ExpenseService _expenseService = ExpenseService();
  
  List<BackupCar> _cars = [];
  final Map<int, CarHealthScore> _healthScores = {};
  final Map<int, List<Expense>> _expenses = {};
  bool _isLoading = true;
  BackupCar? _selectedCar;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      _cars = await _carService.getAllCars();
      
      // Calculate health scores for all cars
      for (var car in _cars) {
        if (car.id != null) {
          final score = await _healthService.calculateHealthScore(car);
          _healthScores[car.id!] = score;
          
          // Load expenses
          final expenses = await _expenseService.getExpensesByCar(car.id!);
          _expenses[car.id!] = expenses;
        }
      }
      
      if (_cars.isNotEmpty) {
        _selectedCar = _cars.first;
      }
    } catch (e) {
      debugPrint('[CarHealthDashboard] Error loading data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWithNavBar(
      child: Scaffold(
        backgroundColor: AppTheme.getThemeAwareBackground(context),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryGreen,
        backgroundColor: AppTheme.getThemeAwareBackground(context),
        child: Column(
          children: [
            _buildHeaderWithBackground(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                  : _cars.isEmpty
                      ? _buildEmptyState()
                      : _buildContent(),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildHeaderWithBackground() {
    return Container(
      width: double.infinity,
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
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Car Health Dashboard',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Monitor your vehicle\'s health',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadData,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.health_and_safety_outlined,
            size: 100,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Cars Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getThemeAwareTextColor(context),
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a car to see health insights',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCarSelector(),
          const SizedBox(height: 24),
          if (_selectedCar != null && _selectedCar!.id != null) ...[
            _buildHealthScoreCard(),
            const SizedBox(height: 16),
            _buildRecommendationsCard(),
            const SizedBox(height: 16),
            _buildExpenseSummaryCard(),
            const SizedBox(height: 16),
            _buildQuickActions(),
          ],
        ],
      ),
    );
  }

  Widget _buildCarSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.darkAccentGreen, AppTheme.backgroundGreen],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Select Vehicle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showCarSelectionDialog(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  // Car image
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _selectedCar != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _selectedCar!.imagePath != null && _selectedCar!.imagePath!.isNotEmpty
                                ? Image.file(
                                    File(_selectedCar!.imagePath!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.directions_car,
                                        color: Colors.white,
                                        size: 24,
                                      );
                                    },
                                  )
                                : const Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          )
                        : const Icon(
                            Icons.directions_car,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCar != null
                              ? '${_selectedCar!.brand} ${_selectedCar!.model}'
                              : 'Select a car',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Orbitron',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedCar != null
                              ? 'Year: ${_selectedCar!.year}'
                              : 'Tap to choose vehicle',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontFamily: 'Orbitron',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCarSelectionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.getThemeAwareCardBackground(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Vehicle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
                color: AppTheme.getThemeAwareTextColor(context),
              ),
            ),
            const SizedBox(height: 16),
            ..._cars.map((car) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_car,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  title: Text(
                    '${car.brand} ${car.model}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron',
                      color: AppTheme.getThemeAwareTextColor(context),
                    ),
                  ),
                  subtitle: Text(
                    'Year: ${car.year}',
                    style: TextStyle(
                      color: AppTheme.getThemeAwareTextColor(context)
                          .withOpacity(0.7),
                    ),
                  ),
                  trailing: _selectedCar == car
                      ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCar = car;
                    });
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    final carId = _selectedCar!.id!;
    final healthScore = _healthScores[carId];
    
    if (healthScore == null) {
      return const SizedBox();
    }

    Color scoreColor;
    String scoreLabel;

    if (healthScore.overallScore >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
    } else if (healthScore.overallScore >= 60) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
    } else if (healthScore.overallScore >= 40) {
      scoreColor = Colors.deepOrange;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Poor';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.darkAccentGreen,
            AppTheme.backgroundGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Health Score',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: healthScore.overallScore / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${healthScore.overallScore.toInt()}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Orbitron',
                    ),
                  ),
                  Text(
                    scoreLabel,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontFamily: 'Orbitron',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricDetail(
                'Maintenance',
                '${healthScore.details['maintenance_count'] ?? 0}',
                Icons.build,
                Colors.white,
              ),
              _buildMetricDetail(
                'Avg. Mileage',
                '${(healthScore.details['avg_mileage_per_year'] ?? 0).toInt()} km/yr',
                Icons.speed,
                Colors.white,
              ),
              _buildMetricDetail(
                'Years',
                '${healthScore.details['car_age_years'] ?? 0}',
                Icons.calendar_today,
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDetail(String label, double score, IconData icon) {
    Color scoreColor;
    if (score >= 80) {
      scoreColor = Colors.green;
    } else if (score >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          '${score.toInt()}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: scoreColor,
            fontFamily: 'Orbitron',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDetail(String label, String value, IconData icon, Color valueColor) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontFamily: 'Orbitron',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final carId = _selectedCar!.id!;
    final healthScore = _healthScores[carId];
    
    if (healthScore == null || healthScore.recommendations.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getThemeAwareCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getThemeAwareTextColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...healthScore.recommendations.map((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.arrow_right,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rec,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getThemeAwareTextColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildExpenseSummaryCard() {
    final carId = _selectedCar!.id!;
    final expenses = _expenses[carId] ?? [];
    
    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getThemeAwareCardBackground(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No expense data available',
            style: TextStyle(
              color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.6),
            ),
          ),
        ),
      );
    }

    final total = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final thisMonth = expenses.where((e) {
      final now = DateTime.now();
      return e.date.year == now.year && e.date.month == now.month;
    }).fold<double>(0, (sum, expense) => sum + expense.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getThemeAwareCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.attach_money,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Expense Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getThemeAwareTextColor(context),
                  fontFamily: 'Orbitron',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildExpenseDetail('Total', '\$${total.toStringAsFixed(2)}'),
              _buildExpenseDetail('This Month', '\$${thisMonth.toStringAsFixed(2)}'),
              _buildExpenseDetail('Entries', '${expenses.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseDetail(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
            fontFamily: 'Orbitron',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.getThemeAwareTextColor(context),
            fontFamily: 'Orbitron',
          ),
        ),
          const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Add Expense',
                Icons.add_circle_outline,
                () => _showAddExpenseDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'View Reports',
                Icons.analytics_outlined,
                () => _showComingSoon('Reports feature'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.darkAccentGreen,
              AppTheme.backgroundGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Orbitron',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExpenseDialog() {
    // TODO: Implement add expense dialog
    _showComingSoon('Add expense feature');
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon!',
          style: const TextStyle(fontFamily: 'Orbitron'),
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}

