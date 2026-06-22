import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../driver/domain/repositories/driver_repository.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _vehiclePlateController;
  late TextEditingController _licenseController;

  String _selectedVehicleType = 'motorcycle';
  String? _photoUrl;
  File? _newPhotoFile;

  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<HomeBloc>().state.driverProfile;

    _fullNameController = TextEditingController(text: profile?.fullName ?? '');
    _phoneController = TextEditingController(text: profile?.phoneNumber ?? '');
    _vehiclePlateController = TextEditingController(text: profile?.vehiclePlate ?? '');
    _licenseController = TextEditingController(text: profile?.driverLicense ?? '');
    _selectedVehicleType = profile?.vehicleType ?? 'motorcycle';
    _photoUrl = profile?.photoUrl;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _fullNameController.dispose();
    _phoneController.dispose();
    _vehiclePlateController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(AppLocalizations l10n) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.changeAvatar,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryLight),
                title: Text(l10n.takePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _getPhoto(ImageSource.camera, l10n);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryLight),
                title: Text(l10n.selectFromGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _getPhoto(ImageSource.gallery, l10n);
                },
              ),
              if (_photoUrl != null && _photoUrl!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.errorLight),
                  title: Text(l10n.cancel, style: const TextStyle(color: AppColors.errorLight)),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _newPhotoFile = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getPhoto(ImageSource source, AppLocalizations l10n) async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (photo == null) return;

      if (!mounted || _isDisposed) return;

      setState(() {
        _newPhotoFile = File(photo.path);
      });
    } catch (e) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileUpdateFailed)),
      );
    }
  }

  Future<void> _saveProfile(AppLocalizations l10n) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = GetIt.I<DriverRepository>();

      String? uploadedPhotoUrl;

      if (_newPhotoFile != null) {
        uploadedPhotoUrl = await repo.uploadDriverAvatar(_newPhotoFile!.path);
      }

      await repo.updateDriverProfile(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        vehiclePlate: _vehiclePlateController.text.trim(),
        vehicleType: _selectedVehicleType,
        driverLicense: _licenseController.text.trim(),
        photoUrl: uploadedPhotoUrl,
      );

      if (!mounted || _isDisposed) return;

      context.read<HomeBloc>().add(const RefreshAllDataRequested());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileUpdatedSuccess),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted || _isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.profileUpdateFailed),
          backgroundColor: AppColors.errorLight,
        ),
      );
    } finally {
      if (!mounted || _isDisposed) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.primaryDark : AppColors.primaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => _saveProfile(l10n),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    l10n.save,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildAvatarPicker(l10n, primaryColor),
                  const SizedBox(height: 24),
                  _buildFormFields(l10n, isDark, primaryColor),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _saveProfile(l10n),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              l10n.save,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatarPicker(AppLocalizations l10n, Color primaryColor) {
    final hasPhoto = _photoUrl != null && _photoUrl!.isNotEmpty;
    final hasNewFile = _newPhotoFile != null;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _pickPhoto(l10n),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: primaryColor.withValues(alpha: 0.2),
                  backgroundImage: hasNewFile
                      ? FileImage(_newPhotoFile!)
                      : (hasPhoto ? NetworkImage(_photoUrl!) : null),
                  child: !hasPhoto && !hasNewFile
                      ? Icon(Icons.person, size: 60, color: primaryColor)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.changeAvatar,
            style: TextStyle(
              fontSize: 13,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields(
    AppLocalizations l10n,
    bool isDark,
    Color primaryColor,
  ) {
    final textColor = isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight;
    final hintColor = isDark ? Colors.grey[500]! : Colors.grey[400]!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _fullNameController,
              label: l10n.fullNameLabel,
              icon: Icons.person,
              isDark: isDark,
              textColor: textColor,
              hintColor: hintColor,
              primaryColor: primaryColor,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.requiredField;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: l10n.phoneNumberLabel,
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              isDark: isDark,
              textColor: textColor,
              hintColor: hintColor,
              primaryColor: primaryColor,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.requiredField;
                }
                if (value.trim().length < 9) {
                  return l10n.invalidPhoneNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _vehiclePlateController,
              label: l10n.vehiclePlateLabel,
              icon: Icons.directions_car,
              textCapitalization: TextCapitalization.characters,
              isDark: isDark,
              textColor: textColor,
              hintColor: hintColor,
              primaryColor: primaryColor,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty && value.trim().length < 4) {
                  return l10n.invalidVehiclePlate;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildVehicleTypeDropdown(l10n, isDark, textColor, hintColor, primaryColor),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _licenseController,
              label: l10n.driverLicenseLabel,
              icon: Icons.badge,
              textCapitalization: TextCapitalization.characters,
              isDark: isDark,
              textColor: textColor,
              hintColor: hintColor,
              primaryColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required Color textColor,
    required Color hintColor,
    required Color primaryColor,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: hintColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorLight),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildVehicleTypeDropdown(
    AppLocalizations l10n,
    bool isDark,
    Color textColor,
    Color hintColor,
    Color primaryColor,
  ) {
    final items = [
      DropdownMenuItem(
        value: 'motorcycle',
        child: Row(
          children: [
            Icon(Icons.two_wheeler, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(l10n.motorcycle),
          ],
        ),
      ),
      DropdownMenuItem(
        value: 'car',
        child: Row(
          children: [
            Icon(Icons.directions_car, color: primaryColor, size: 20),
            const SizedBox(width: 8),
            Text(l10n.car),
          ],
        ),
      ),
    ];

    return DropdownButtonFormField<String>(
      value: _selectedVehicleType,
      items: items,
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedVehicleType = value);
        }
      },
      decoration: InputDecoration(
        labelText: l10n.vehicleTypeLabel,
        labelStyle: TextStyle(color: hintColor),
        prefixIcon: Icon(Icons.electric_car, color: primaryColor),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: hintColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: TextStyle(color: textColor, fontSize: 15),
      dropdownColor: isDark ? Colors.grey[850] : Colors.white,
      icon: Icon(Icons.arrow_drop_down, color: primaryColor),
    );
  }
}
