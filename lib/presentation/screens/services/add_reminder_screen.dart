import 'package:flutter/material.dart';
import '../../../shared/constants/app_theme.dart';

class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _subtitle = TextEditingController();
  final TextEditingController _car = TextEditingController();
  final TextEditingController _mileage = TextEditingController();
  String _priority = 'Medium';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getThemeAwareBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
        title: const Text(
          'Add Reminder',
          style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_title, 'Title', 'Oil Change'),
              const SizedBox(height: 12),
              _buildTextField(_subtitle, 'Subtitle', 'Due in 3 days'),
              const SizedBox(height: 12),
              _buildTextField(_car, 'Car', 'Toyota Camry'),
              const SizedBox(height: 12),
              _buildTextField(_mileage, 'Mileage', '75200 km', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildPriorityPicker(),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Save Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label, String hint, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildPriorityPicker() {
    return DropdownButtonFormField<String>(
      value: _priority,
      decoration: InputDecoration(
        labelText: 'Priority',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: const [
        DropdownMenuItem(value: 'Low', child: Text('Low')),
        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
        DropdownMenuItem(value: 'High', child: Text('High')),
        DropdownMenuItem(value: 'Critical', child: Text('Critical')),
      ],
      onChanged: (v) => setState(() => _priority = v ?? 'Medium'),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'title': _title.text.trim(),
      'subtitle': _subtitle.text.trim(),
      'car': _car.text.trim(),
      'mileage': _mileage.text.trim(),
      'priority': _priority,
    });
  }
}

