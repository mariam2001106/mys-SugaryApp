import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:mysugaryapp/services/profile_service.dart';
import 'package:mysugaryapp/models/user_profile.dart';
import 'package:flutter/rendering.dart' as fr;


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Controllers for Personal Information
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  
  // Controllers for Health Information
  DiabetesType? _selectedDiabetesType;
  final _currentMedicationController = TextEditingController();
  final _targetGlucoseMinController = TextEditingController();
  final _targetGlucoseMaxController = TextEditingController();
  
  // Carb ratio controller (existing)
  final _carbRatioController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _emergencyContactController.dispose();
    _currentMedicationController.dispose();
    _targetGlucoseMinController.dispose();
    _targetGlucoseMaxController.dispose();
    _carbRatioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final data = await ProfileService().getUserDataFromServer(user.uid);
      if (data != null && mounted) {
        _fullNameController.text = data['displayName']?.toString() ?? '';
        _emailController.text = user.email ?? '';
        _ageController.text = data['age']?.toString() ?? '';
        _weightController.text = data['weight']?.toString() ?? '';
        _heightController.text = data['height']?.toString() ?? '';
        _emergencyContactController.text = data['emergencyContact']?.toString() ?? '';
        _currentMedicationController.text = data['medicationName']?.toString() ?? '';
        _carbRatioController.text = data['carbRatio']?.toString() ?? '';
        
        // Load diabetes type
        final diabetesTypeStr = data['diabetesType'] as String?;
        _selectedDiabetesType = _diabetesTypeFromString(diabetesTypeStr);
        
        // Load glucose ranges
        final glucoseRanges = data['glucoseRanges'] as Map<String, dynamic>?;
        if (glucoseRanges != null) {
          _targetGlucoseMinController.text = glucoseRanges['targetMin']?.toString() ?? '80';
          _targetGlucoseMaxController.text = glucoseRanges['targetMax']?.toString() ?? '130';
        }
      }
    } catch (e) {
      // Ignore errors silently
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  DiabetesType _diabetesTypeFromString(String? v) {
    switch (v) {
      case 'type1':
        return DiabetesType.type1;
      case 'type2':
        return DiabetesType.type2;
      case 'lada':
        return DiabetesType.lada;
      case 'type3':
        return DiabetesType.type3;
      default:
        return DiabetesType.other;
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updates = <String, dynamic>{
        'displayName': _fullNameController.text.trim(),
      };

      // Validate and add age if provided
      final ageText = _ageController.text.trim();
      if (ageText.isNotEmpty) {
        final age = int.tryParse(ageText);
        if (age == null || age < 1 || age > 120) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('setup.age_error'.tr()),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          setState(() {
            _isSaving = false;
          });
          return;
        }
        updates['age'] = age;
      }

      // Validate and add weight if provided
      final weightText = _weightController.text.trim();
      if (weightText.isNotEmpty) {
        final weight = double.tryParse(weightText);
        if (weight == null || weight < 20 || weight > 500) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('setup.weight_error'.tr()),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          setState(() {
            _isSaving = false;
          });
          return;
        }
        updates['weight'] = weight;
      }

      // Validate and add height if provided
      final heightText = _heightController.text.trim();
      if (heightText.isNotEmpty) {
        final height = double.tryParse(heightText);
        if (height == null || height < 50 || height > 300) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('setup.height_error'.tr()),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          setState(() {
            _isSaving = false;
          });
          return;
        }
        updates['height'] = height;
      }

      // Validate and add emergency contact if provided
      final emergencyContact = _emergencyContactController.text.trim();
      if (emergencyContact.isNotEmpty) {
        // Validate: must start with "09" and be exactly 10 digits
        if (!RegExp(r'^09\d{8}$').hasMatch(emergencyContact)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('setup.emergency_contact_error'.tr()),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          setState(() {
            _isSaving = false;
          });
          return;
        }
        updates['emergencyContact'] = emergencyContact;
      }

      // Add diabetes type if selected
      if (_selectedDiabetesType != null) {
        updates['diabetesType'] = _selectedDiabetesType!.name;
      }

      // Add medication if provided
      final medication = _currentMedicationController.text.trim();
      if (medication.isNotEmpty) {
        updates['medicationName'] = medication;
      }

      // Validate and add glucose ranges if provided
      final minText = _targetGlucoseMinController.text.trim();
      final maxText = _targetGlucoseMaxController.text.trim();
      if (minText.isNotEmpty && maxText.isNotEmpty) {
        final min = int.tryParse(minText);
        final max = int.tryParse(maxText);
        if (min == null || max == null || min < 50 || max > 400) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('setup.glucose_range_error'.tr()),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          setState(() {
            _isSaving = false;
          });
          return;
        }
        if (min >= max) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('setup.range_error'.tr()),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          setState(() {
            _isSaving = false;
          });
          return;
        }
        updates['glucoseRanges'] = {
          'targetMin': min,
          'targetMax': max,
          'veryHigh': 250,
          'veryLow': 60,
        };
      }

      // Add carb ratio if provided
      final carbRatioText = _carbRatioController.text.trim();
      if (carbRatioText.isNotEmpty) {
        final carbRatio = double.tryParse(carbRatioText);
        if (carbRatio != null && carbRatio > 0) {
          updates['carbRatio'] = carbRatio;
        }
      }

      await ProfileService().updatePartial(user.uid, updates);
      
      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.profile_updated'.tr()),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.profile_update_error'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: context.locale.languageCode == 'ar'
            ? fr.TextDirection.rtl
            : fr.TextDirection.ltr,
        child: AlertDialog(
          title: Text('profile.logout'.tr()),
          content: Text('profile.confirm_logout'.tr()),
          actions: [
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text('profile.cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: Text('profile.logout'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('profile.logout'.tr())));
      }
    }
  }

  Future<void> _setLocaleAndSave(BuildContext context, String code) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await context.setLocale(Locale(code));
    } catch (_) {}
    try {
      await ProfileService().updatePartial(user.uid, {'locale': code});
    } catch (_) {}
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      enabled: !readOnly && _isEditing,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required DiabetesType? value,
    required void Function(DiabetesType?) onChanged,
  }) {
    return DropdownButtonFormField<DiabetesType>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [
        DropdownMenuItem(value: DiabetesType.type1, child: Text('setup.type1'.tr())),
        DropdownMenuItem(value: DiabetesType.type2, child: Text('setup.type2'.tr())),
        DropdownMenuItem(value: DiabetesType.lada, child: Text('setup.lada'.tr())),
        DropdownMenuItem(value: DiabetesType.type3, child: Text('setup.type3'.tr())),
        DropdownMenuItem(value: DiabetesType.other, child: Text('setup.other'.tr())),
      ],
      onChanged: _isEditing ? onChanged : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: context.locale.languageCode == 'ar'
          ? fr.TextDirection.rtl
          : fr.TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('profile.title'.tr()),
              Text(
                'profile.subtitle'.tr(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ],
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // SECTION 1: Personal Information
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header row with icon, title, and Edit button
                              Row(
                                children: [
                                  Icon(Icons.person, color: cs.primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'profile.personal_information'.tr(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () {
                                            if (_isEditing) {
                                              _saveProfile();
                                            } else {
                                              setState(() {
                                                _isEditing = true;
                                              });
                                            }
                                          },
                                    child: Text(
                                      _isEditing
                                          ? 'profile.save'.tr()
                                          : 'profile.edit'.tr(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Full Name
                              _buildTextField(
                                controller: _fullNameController,
                                label: 'profile.full_name'.tr(),
                              ),
                              const SizedBox(height: 12),
                              
                              // Email (read-only, displayed from Firebase Auth)
                              _buildTextField(
                                controller: _emailController,
                                label: 'profile.email'.tr(),
                                keyboardType: TextInputType.emailAddress,
                                readOnly: true,
                              ),
                              const SizedBox(height: 12),
                              
                              // Age
                              _buildTextField(
                                controller: _ageController,
                                label: 'profile.age'.tr(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Weight
                              _buildTextField(
                                controller: _weightController,
                                label: 'profile.weight'.tr(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Height
                              _buildTextField(
                                controller: _heightController,
                                label: 'profile.height'.tr(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Emergency Contact
                              _buildTextField(
                                controller: _emergencyContactController,
                                label: 'profile.emergency_contact'.tr(),
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // SECTION 2: Health Information
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.medical_information, color: cs.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    'profile.health_information'.tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Diabetes Type
                              _buildDropdownField(
                                label: 'profile.diabetes_type'.tr(),
                                value: _selectedDiabetesType,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDiabetesType = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              
                              // Current Medication
                              _buildTextField(
                                controller: _currentMedicationController,
                                label: 'profile.current_medication'.tr(),
                              ),
                              const SizedBox(height: 12),
                              
                              // Target Glucose Min
                              _buildTextField(
                                controller: _targetGlucoseMinController,
                                label: 'profile.target_glucose_min'.tr(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Target Glucose Max
                              _buildTextField(
                                controller: _targetGlucoseMaxController,
                                label: 'profile.target_glucose_max'.tr(),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Carb Ratio Card (keeping existing functionality)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.food_bank, color: cs.primary),
                                  const SizedBox(width: 12),
                                  Text(
                                    'profile.carb_ratio_title'.tr(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'profile.carb_ratio_description'.tr(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface.withValues(alpha: .7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _carbRatioController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                enabled: _isEditing,
                                decoration: InputDecoration(
                                  labelText: 'profile.carb_ratio_label'.tr(),
                                  hintText: '15',
                                  helperText: 'profile.carb_ratio_example'.tr(),
                                  prefixIcon: Icon(Icons.food_bank, color: cs.primary),
                                  suffixText: 'g',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Language Selection Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'profile.language'.tr(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  FilledButton(
                                    onPressed: () => _setLocaleAndSave(context, 'ar'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          context.locale.languageCode == 'ar'
                                          ? cs.primary
                                          : cs.surface,
                                      foregroundColor:
                                          context.locale.languageCode == 'ar'
                                          ? cs.onPrimary
                                          : cs.onSurface,
                                    ),
                                    child: const Text('العربية'),
                                  ),
                                  FilledButton(
                                    onPressed: () => _setLocaleAndSave(context, 'en'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor:
                                          context.locale.languageCode == 'en'
                                          ? cs.primary
                                          : cs.surface,
                                      foregroundColor:
                                          context.locale.languageCode == 'en'
                                          ? cs.onPrimary
                                          : cs.onSurface,
                                    ),
                                    child: const Text('English'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sign Out Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.error,
                            foregroundColor: cs.onError,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _showSignOutDialog(context),
                          child: Text(
                            'profile.logout'.tr(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
}
