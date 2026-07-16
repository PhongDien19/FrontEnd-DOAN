import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../utils/responsive.dart';
import 'test_history_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _targetJobController = TextEditingController();
  final _hobbyController = TextEditingController();
  static const List<String> _educationLevels = [
    'Cấp 2',
    'Cấp 3',
    'Cao đẳng',
    'Đại học',
    'Sau Đại học',
  ];
  String _educationLevel = 'Đại học';

  bool _isEditing = false;
  bool _isLoadingHistory = true;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _initFields();
    _fetchHistory();
  }

  void _initFields() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.userProfile != null) {
      final p = auth.userProfile!;
      _fullNameController.text = p['fullName'] ?? '';
      _targetJobController.text = p['targetJob'] ?? '';
      _hobbyController.text = p['interests'] ?? p['hobby'] ?? '';
      final serverEdu = p['educationLevel']?.toString();
      _educationLevel = (serverEdu != null && _educationLevels.contains(serverEdu))
          ? serverEdu
          : 'Đại học';
    }
  }

  void _fetchHistory() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      return;
    }

    setState(() {
      _isLoadingHistory = true;
    });

    final res = await ApiService.getHistory(auth.userId!);

    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
        if (res['success'] == true) {
          _history = res['history'] ?? [];
        }
      });
    }
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final res = await auth.updateProfile(
      fullName: _fullNameController.text.trim(),
      targetJob: _targetJobController.text.trim(),
      educationLevel: _educationLevel,
      hobby: _hobbyController.text.trim(),
    );

    if (mounted) {
      if (res['success'] == true) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cập nhật hồ sơ thành công!',
              style: TextStyle(fontSize: Responsive.font(context, 14)),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ?? 'Lỗi cập nhật. Vui lòng thử lại!',
              style: TextStyle(fontSize: Responsive.font(context, 14)),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              Responsive.s(context, 20),
            ),
          ),
          title: Text(
            'Đăng xuất',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: Responsive.font(context, 18),
              color: const Color(0xFF1F2937),
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
            style: TextStyle(
              fontSize: Responsive.font(context, 14),
              color: const Color(0xFF4B5563),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.font(context, 14),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Đăng xuất',
                style: TextStyle(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.font(context, 14),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.logout();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          Positioned(
            top: -Responsive.s(context, 50),
            right: -Responsive.s(context, 50),
            child: Container(
              width: Responsive.s(context, 250),
              height: Responsive.s(context, 250),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(Responsive.s(context, 24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: const Color(0xFF1F2937),
                          size: Responsive.s(context, 24),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: Responsive.s(context, 8)),
                      Expanded(
                        child: Text(
                          'Hồ Sơ & Lịch Sử',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 18),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (auth.isAuthenticated) ...[
                        IconButton(
                          icon: Icon(
                            _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                            color: const Color(0xFF1F2937),
                            size: Responsive.s(context, 24),
                          ),
                          onPressed: () {
                            setState(() {
                              if (_isEditing) {
                                _initFields();
                              }
                              _isEditing = !_isEditing;
                            });
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.logout_rounded,
                            color: const Color(0xFFEF4444),
                            size: Responsive.s(context, 24),
                          ),
                          onPressed: _handleLogout,
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: Responsive.s(context, 28)),

                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: Responsive.s(context, 40),
                          backgroundColor: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person_rounded,
                            size: Responsive.s(context, 40),
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        SizedBox(height: Responsive.s(context, 16)),
                        Text(
                          auth.fullName.isNotEmpty
                              ? auth.fullName
                              : 'Thành viên',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 18),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          auth.currentUser?['email'] ?? '',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 13),
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 36)),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInputField(
                          label: 'Họ và tên',
                          controller: _fullNameController,
                          enabled: _isEditing,
                          icon: Icons.person_outline_rounded,
                        ),
                        SizedBox(height: Responsive.s(context, 16)),
                        _buildInputField(
                          label: 'Công việc mục tiêu / Ngành mong muốn',
                          controller: _targetJobController,
                          enabled: _isEditing,
                          icon: Icons.work_outline_rounded,
                        ),
                        SizedBox(height: Responsive.s(context, 16)),
                        if (_isEditing)
                          DropdownButtonFormField<String>(
                            initialValue: _educationLevel,
                            style: TextStyle(
                              color: const Color(0xFF1F2937),
                              fontSize: Responsive.font(context, 14),
                            ),
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              labelText: 'Trình độ học vấn',
                              labelStyle: TextStyle(
                                color: const Color(0xFF6B7280),
                                fontSize: Responsive.font(context, 13),
                              ),
                              prefixIcon: Icon(
                                Icons.school_outlined,
                                color: const Color(0xFF9CA3AF),
                                size: Responsive.s(context, 22),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  Responsive.s(context, 16),
                                ),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  Responsive.s(context, 16),
                                ),
                                borderSide: const BorderSide(
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                            items: _educationLevels.map(
                              (lvl) => DropdownMenuItem(
                                value: lvl,
                                child: Text(
                                  lvl,
                                  style: TextStyle(
                                    fontSize: Responsive.font(context, 14),
                                  ),
                                ),
                              ),
                            ).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _educationLevel = val);
                              }
                            },
                          )
                        else
                          _buildInputField(
                            label: 'Trình độ học vấn',
                            controller: TextEditingController(
                              text: _educationLevel,
                            ),
                            enabled: false,
                            icon: Icons.school_outlined,
                          ),
                        SizedBox(height: Responsive.s(context, 16)),
                        _buildInputField(
                          label: 'Sở thích & Điểm mạnh',
                          controller: _hobbyController,
                          enabled: _isEditing,
                          icon: Icons.favorite_border_rounded,
                        ),
                        if (_isEditing) ...[
                          SizedBox(height: Responsive.s(context, 24)),
                          ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              padding: EdgeInsets.symmetric(
                                vertical: Responsive.s(context, 16),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Responsive.s(context, 16),
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Lưu thay đổi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.font(context, 16),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 36)),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lịch Sử Làm Bài',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 18),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      if (!_isLoadingHistory)
                        Text(
                          '${_history.length} bài đã làm',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 12),
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: Responsive.s(context, 16)),

                  _buildHistoryList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      style: TextStyle(
        color: enabled
            ? const Color(0xFF1F2937)
            : const Color(0xFF4B5563),
        fontSize: Responsive.font(context, 14),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: const Color(0xFF6B7280),
          fontSize: Responsive.font(context, 13),
        ),
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF9CA3AF),
          size: Responsive.s(context, 22),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            Responsive.s(context, 16),
          ),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            Responsive.s(context, 16),
          ),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            Responsive.s(context, 16),
          ),
          borderSide: const BorderSide(color: Color(0xFFF59E0B)),
        ),
      ),
      validator: (val) =>
          val == null || val.trim().isEmpty ? 'Không được để trống' : null,
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) {
      return 'Gần đây';
    }
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) {
      return 'Gần đây';
    }
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    return '$day/$month/$year';
  }

  Widget _buildHistoryList() {
    if (_isLoadingHistory) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Responsive.s(context, 24)),
          child: const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: Responsive.s(context, 32)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            Responsive.s(context, 20),
          ),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: Responsive.s(context, 40),
              color: const Color(0xFF9CA3AF),
            ),
            SizedBox(height: Responsive.s(context, 12)),
            Text(
              'Chưa có lịch sử làm bài',
              style: TextStyle(
                fontSize: Responsive.font(context, 14),
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    final sortedHistory = List.from(_history);
    sortedHistory.sort((a, b) {
      final aDate =
          DateTime.tryParse(a['createdAt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          DateTime.tryParse(b['createdAt'] ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    final previewHistory = sortedHistory.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: previewHistory.length,
          itemBuilder: (context, index) {
            final session = previewHistory[index];
            final testName = session['testName'] ?? 'Bài test hướng nghiệp';
            final isCompleted = session['isCompleted'] ?? true;
            final questions = session['questions'] as List<dynamic>? ?? [];
            final questionsCount = questions.length;
            final dateStr = _formatDate(session['createdAt']);

            final score = session['score'] != null
                ? double.tryParse(session['score'].toString())
                : null;

            return Container(
              margin: EdgeInsets.only(
                bottom: Responsive.s(context, 12),
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  Responsive.s(context, 16),
                ),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: Responsive.s(context, 16),
                  vertical: Responsive.s(context, 8),
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(
                    0xFFF59E0B,
                  ).withValues(alpha: 0.1),
                  child: Icon(
                    Icons.assessment_rounded,
                    color: const Color(0xFFF59E0B),
                    size: Responsive.s(context, 22),
                  ),
                ),
                title: Text(
                  testName,
                  style: TextStyle(
                    fontSize: Responsive.font(context, 14),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(
                    top: Responsive.s(context, 4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$questionsCount câu hỏi • ${isCompleted ? 'Đã hoàn thành' : 'Chưa hoàn thành'}',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 11),
                          color: isCompleted
                              ? Colors.green
                              : Colors.amber.shade700,
                        ),
                      ),
                      SizedBox(height: Responsive.s(context, 4)),
                      Text(
                        'Ngày làm: $dateStr',
                        style: TextStyle(
                          fontSize: Responsive.font(context, 11),
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (score != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.s(context, 8),
                          vertical: Responsive.s(context, 4),
                        ),
                        decoration: BoxDecoration(
                          color: (score > 3
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B))
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            Responsive.s(context, 8),
                          ),
                        ),
                        child: Text(
                          score.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: Responsive.font(context, 12),
                            fontWeight: FontWeight.bold,
                            color: score > 3
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                      SizedBox(width: Responsive.s(context, 8)),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      color: const Color(0xFF9CA3AF),
                      size: Responsive.s(context, 24),
                    ),
                  ],
                ),
                onTap: () {
                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  if (auth.userId != null) {
                    final edu = auth
                            .userProfile?['educationLevel']
                            ?.toString()
                            .toLowerCase() ??
                        '';
                    final isStudent =
                        edu.contains('học sinh') ||
                        edu.contains('thpt') ||
                        edu.contains('thcs');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TestHistoryScreen(
                          userId: auth.userId!,
                          userRole: isStudent ? 'student' : 'worker',
                          initialSessionId:
                              session['sessionId']?.toString(),
                          educationLevel: session['educationLevel']
                                  ?.toString() ??
                              auth.userProfile?['educationLevel'],
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          },
        ),
        if (_history.length > 3) ...[
          SizedBox(height: Responsive.s(context, 8)),
          OutlinedButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              if (auth.userId != null) {
                final edu = auth.userProfile?['educationLevel']
                        ?.toString()
                        .toLowerCase() ??
                    '';
                final isStudent = edu.contains('học sinh') ||
                    edu.contains('thpt') ||
                    edu.contains('thcs');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TestHistoryScreen(
                      userId: auth.userId!,
                      userRole: isStudent ? 'student' : 'worker',
                      educationLevel: auth.userProfile?['educationLevel'],
                    ),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: Responsive.s(context, 14),
              ),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  Responsive.s(context, 14),
                ),
              ),
            ),
            child: Text(
              'Xem tất cả lịch sử',
              style: TextStyle(
                fontSize: Responsive.font(context, 14),
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ],
    );
  }
}