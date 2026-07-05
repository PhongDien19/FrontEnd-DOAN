import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import 'test_history_screen.dart';
import 'login_screen.dart';

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
      _educationLevel = p['educationLevel'] ?? 'Đại học';
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
          const SnackBar(
            content: Text('Cập nhật hồ sơ thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Lỗi cập nhật. Vui lòng thử lại!'),
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
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Đăng xuất',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng không?',
            style: GoogleFonts.inter(color: const Color(0xFF4B5563)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Hủy',
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Đăng xuất',
                style: GoogleFonts.inter(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
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
          MaterialPageRoute(builder: (context) => const LoginScreen()),
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
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      auth.isAuthenticated
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    color: Color(0xFF1F2937),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 48),
                              ],
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF1F2937),
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                      Text(
                        'Hồ Sơ & Lịch Sử',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      auth.isAuthenticated
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isEditing
                                        ? Icons.close_rounded
                                        : Icons.edit_rounded,
                                    color: const Color(0xFF1F2937),
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
                                  icon: const Icon(
                                    Icons.logout_rounded,
                                    color: Color(0xFFEF4444),
                                  ),
                                  onPressed: _handleLogout,
                                ),
                              ],
                            )
                          : const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          auth.fullName.isNotEmpty
                              ? auth.fullName
                              : 'Thành viên',
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          auth.currentUser?['email'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

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
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Công việc mục tiêu / Ngành mong muốn',
                          controller: _targetJobController,
                          enabled: _isEditing,
                          icon: Icons.work_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                        if (_isEditing)
                          DropdownButtonFormField<String>(
                            initialValue: _educationLevel,
                            style: const TextStyle(color: Color(0xFF1F2937)),
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              labelText: 'Trình độ học vấn',
                              labelStyle: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.school_outlined,
                                color: Color(0xFF9CA3AF),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                            items: ['Cấp 2', 'Cấp 3', 'Đại học', 'Sau Đại học']
                                .map(
                                  (lvl) => DropdownMenuItem(
                                    value: lvl,
                                    child: Text(lvl),
                                  ),
                                )
                                .toList(),
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
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Sở thích & Điểm mạnh',
                          controller: _hobbyController,
                          enabled: _isEditing,
                          icon: Icons.favorite_border_rounded,
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF59E0B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Lưu thay đổi',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lịch Sử Làm Bài',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      if (!_isLoadingHistory)
                        Text(
                          '${_history.length} bài đã làm',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

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
        color: enabled ? const Color(0xFF1F2937) : const Color(0xFF4B5563),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có lịch sử làm bài',
              style: GoogleFonts.outfit(
                fontSize: 14,
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
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(
                    0xFFF59E0B,
                  ).withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.assessment_rounded,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                title: Text(
                  testName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$questionsCount câu hỏi • ${isCompleted ? 'Đã hoàn thành' : 'Chưa hoàn thành'}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isCompleted
                              ? Colors.green
                              : Colors.amber.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngày làm: $dateStr',
                        style: GoogleFonts.inter(
                          fontSize: 11,
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (score > 3
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFF59E0B))
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          score.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: score > 3
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
                // THAY ĐỔI: Nhấn vào item sẽ chuyển ngay sang màn hình TestHistoryScreen và mở bài test này
                onTap: () {
                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  if (auth.userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TestHistoryScreen(
                          userId: auth.userId!,
                          initialSessionId: session['sessionId']?.toString(),
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
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (auth.userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TestHistoryScreen(userId: auth.userId!),
                  ),
                );
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Xem tất cả lịch sử',
              style: GoogleFonts.outfit(
                fontSize: 14,
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
