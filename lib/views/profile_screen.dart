import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../utils/responsive.dart';
import '../viewmodels/profile_viewmodels.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _fullNameController = TextEditingController();
  final _targetJobController = TextEditingController();
  final _hobbyController = TextEditingController();
  final _ageController = TextEditingController();
  String _educationLevel = 'Đại học';

  final List<String> _educationOptions = [
    'Học sinh THCS',
    'Học sinh THPT',
    'Cao đẳng',
    'Đại học',
    'Đã đi làm',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      _fullNameController.text = auth.fullName;
      _targetJobController.text = auth.targetJob;
      _hobbyController.text = auth.hobby;
      if (auth.educationLevel.isNotEmpty) {
        setState(() => _educationLevel = auth.educationLevel);
      }
      if (auth.userProfile?['age'] != null) {
        _ageController.text = auth.userProfile!['age'].toString();
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _targetJobController.dispose();
    _hobbyController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _save(ProfileViewModel vm, AuthProvider auth) async {
    final success = await vm.updateProfile(
      auth,
      fullName: _fullNameController.text.trim(),
      targetJob: _targetJobController.text.trim(),
      educationLevel: _educationLevel,
      hobby: _hobbyController.text.trim(),
      age: int.tryParse(_ageController.text.trim()),
      onError: (msg) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      },
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật hồ sơ thành công!'),
          backgroundColor: Color(0xFF00F5A0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191922),
        elevation: 0,
        title: Text(
          'Hồ Sơ Cá Nhân',
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
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
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    labelStyle: TextStyle(color: Color(0xFF888B9B)),
                    filled: true,
                    fillColor: Color(0xFF191922),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 16)),
                TextFormField(
                  controller: _targetJobController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Ngành nghề mục tiêu',
                    labelStyle: TextStyle(color: Color(0xFF888B9B)),
                    filled: true,
                    fillColor: Color(0xFF191922),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 16)),
                DropdownButtonFormField<String>(
                  value: _educationLevel,
                  dropdownColor: const Color(0xFF191922),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Trình độ',
                    labelStyle: TextStyle(color: Color(0xFF888B9B)),
                    filled: true,
                    fillColor: Color(0xFF191922),
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
                  controller: _hobbyController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Sở thích cá nhân',
                    labelStyle: TextStyle(color: Color(0xFF888B9B)),
                    filled: true,
                    fillColor: Color(0xFF191922),
                  ),
                ),
                SizedBox(height: Responsive.s(context, 28)),
                SizedBox(
                  height: Responsive.s(context, 48),
                  child: ElevatedButton(
                    onPressed: vm.isSaving ? null : () => _save(vm, auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                    ),
                    child: vm.isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
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
