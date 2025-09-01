import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';
import '../../../shared/services/notification_service.dart';

class OBDDashboardScreen extends StatefulWidget {
  const OBDDashboardScreen({super.key});

  @override
  State<OBDDashboardScreen> createState() => _OBDDashboardScreenState();
}

class _OBDDashboardScreenState extends State<OBDDashboardScreen> {
  bool _isConnected = false;
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    // Wrap existing content with Scaffold to add bottom nav bar
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderWithBackground(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildConnectionCard(),
                  const SizedBox(height: 16),
                  _buildConnectionInstructions(),
                  const SizedBox(height: 16),
                  if (_isConnected) _buildRealTimeDataSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderWithBackground() {
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
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        // If no previous route, try to navigate to root
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'OBD-II Diagnostics',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Orbitron',
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isConnected ? Icons.bluetooth_connected : Icons.bluetooth),
                    onPressed: _toggleConnection,
                    color: _isConnected ? AppTheme.lightBackground : Colors.white70,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Monitor your vehicle\'s health in real-time',
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

  Widget _buildConnectionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
            size: 48,
            color: _isConnected ? AppTheme.successColor : AppTheme.darkAccentGreen,
          ),
          const SizedBox(height: 16),
          Text(
            _isConnected ? 'OBD-II Adapter Connected' : 'No OBD-II Connection',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.getThemeAwareTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isConnected 
                ? 'Device: ELM327 Bluetooth\nVehicle: 2020 Toyota Camry'
                : 'Connect your OBD-II adapter to get started',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 14,
              color: AppTheme.getThemeAwareTextColor(context).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isScanning ? null : _toggleConnection,
            icon: _isScanning 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_isConnected ? Icons.bluetooth_disabled : Icons.bluetooth_searching),
            label: Text(
              _isScanning 
                  ? 'Scanning...' 
                  : _isConnected 
                      ? 'Disconnect' 
                      : 'Scan & Connect',
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isConnected ? AppTheme.errorColor : AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Real-Time Engine Data',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildDataCard('RPM', '2,150', 'rpm', Icons.rotate_right, AppTheme.primaryGreen),
            _buildDataCard('Speed', '65', 'mph', Icons.speed, AppTheme.secondaryGreen),
            _buildDataCard('Engine Temp', '192°F', 'Normal', Icons.thermostat, AppTheme.successColor),
            _buildDataCard('Fuel Level', '75%', 'Good', Icons.local_gas_station, AppTheme.primaryGreen),
            _buildDataCard('Battery', '12.6V', 'Healthy', Icons.battery_full, AppTheme.successColor),
            _buildDataCard('Throttle', '25%', 'Position', Icons.tune, AppTheme.secondaryGreen),
          ],
        ),
      ],
    );
  }

  Widget _buildDataCard(String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            unit,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 10,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticCodesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Diagnostic Trouble Codes',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ElevatedButton(
                onPressed: _scanForCodes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryGreen,
                  foregroundColor: AppTheme.backgroundGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'Scan',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCodeItem('P0171', 'System Too Lean (Bank 1)', 'Pending', AppTheme.warningColor),
          _buildCodeItem('B1001', 'Battery Voltage Low', 'Active', AppTheme.errorColor),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: AppTheme.successColor, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '2 diagnostic codes found. Tap on any code for detailed information.',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeItem(String code, String description, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              code,
              style: TextStyle(
                fontFamily: 'OrbitronCondensed',
                fontWeight: FontWeight.w700,
                color: statusColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildHealthScoreSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Health Score',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Health',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.82,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successColor),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '82% - Good Condition',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 14,
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.successColor.withOpacity(0.1),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '82',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.successColor,
                        ),
                      ),
                      Text(
                        'SCORE',
                        style: TextStyle(
                          fontFamily: 'OrbitronCondensed',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHealthCategory('Engine', 0.85, AppTheme.successColor),
          _buildHealthCategory('Transmission', 0.78, AppTheme.warningColor),
          _buildHealthCategory('Emissions', 0.90, AppTheme.successColor),
          _buildHealthCategory('Electrical', 0.75, AppTheme.warningColor),
        ],
      ),
    );
  }

  Widget _buildHealthCategory(String category, double score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              category,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: score,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(score * 100).toInt()}%',
            style: TextStyle(
              fontFamily: 'OrbitronCondensed',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionInstructions() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = AppTheme.darkGray.withOpacity(0.3);
    final Color primaryText = isDark ? AppTheme.lightBackground : Colors.black87;
    final Color secondaryText = isDark ? AppTheme.lightBackground : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            size: 48,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'How to Connect OBD-II Adapter',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _buildInstructionStep('1', 'Locate your vehicle\'s OBD-II port (usually under dashboard)'),
          _buildInstructionStep('2', 'Plug in your Bluetooth OBD-II adapter'),
          _buildInstructionStep('3', 'Turn on your vehicle\'s ignition'),
          _buildInstructionStep('4', 'Tap "Scan & Connect" above'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : AppTheme.darkAccentGreen.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppTheme.secondaryGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Compatible with ELM327 Bluetooth adapters. Available at auto parts stores.',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color stepText = isDark ? AppTheme.lightBackground : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 14,
                color: stepText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleConnection() {
    if (_isConnected) {
      // Disconnect
      setState(() {
        _isConnected = false;
      });
      NotificationService.instance.showErrorNotification(
        context,
        message: 'OBD-II adapter disconnected',
      );
    } else {
      // Simulate scanning and connecting
      setState(() {
        _isScanning = true;
      });
      
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _isScanning = false;
          _isConnected = true;
        });
        NotificationService.instance.showSuccessNotification(
          context,
          message: 'OBD-II adapter connected successfully!',
        );
      });
    }
  }

  void _scanForCodes() {
    NotificationService.instance.showInfoNotification(
      context,
      message: 'Scanning for diagnostic codes...',
    );
  }
}