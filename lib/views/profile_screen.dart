import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  String _educationLevel = 'Đại học';

  final List<String> _educationOptions = [
    'Học sinh THCS',
    'Học sinh THPT',
    'Cao đẳng',
    'Đại học',
    'Sinh viên năm nhất',
    'Đã đi làm',
  ];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _fullNameController.text = auth.fullName;
    _hobbyController.text = auth.hobby;
    _locationController.text = auth.userProfile?['location']?.toString() ?? '';
    if (auth.educationLevel.isNotEmpty) {
      _educationLevel = auth.educationLevel;
      if (!_educationOptions.contains(_educationLevel)) {
        _educationOptions.add(_educationLevel);
      }
    }
    if (auth.userProfile?['age'] != null) {
      _ageController.text = auth.userProfile!['age'].toString();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _hobbyController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _save(ProfileViewModel vm, AuthProvider auth) async {
    final success = await vm.updateProfile(
      auth,
      fullName: _fullNameController.text.trim(),
      educationLevel: _educationLevel,
      hobby: _hobbyController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      location: _locationController.text.trim(),
      onError: (msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      },
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Hồ Sơ Cá Nhân',
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<ProfileViewModel>(
        builder: (context, vm, child) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(Responsive.s(context, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                SizedBox(height: Responsive.s(context, 16)),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Tuổi',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                SizedBox(height: Responsive.s(context, 16)),
                DropdownButtonFormField<String>(
                  initialValue: _educationLevel,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Trình độ',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  items: _educationOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _educationLevel = val);
                  },
                ),
                SizedBox(height: Responsive.s(context, 16)),
                TextFormField(
                  controller: _locationController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Khu vực sinh sống',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                SizedBox(height: Responsive.s(context, 16)),
                TextFormField(
                  controller: _hobbyController,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Sở thích cá nhân',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                SizedBox(height: Responsive.s(context, 28)),
                SizedBox(
                  height: Responsive.s(context, 48),
                  child: ElevatedButton(
                    onPressed: vm.isSaving ? null : () => _save(vm, auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: vm.isSaving
                        ? const CircularProgressIndicator(
                            color: AppColors.textPrimary,
                          )
                        : const Text(
                            'LƯU THÔNG TIN',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
