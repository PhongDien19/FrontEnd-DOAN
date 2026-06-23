import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import 'test_history_screen.dart';

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
    if (!auth.isAuthenticated) return;

    setState(() {
      _isLoadingHistory = true;
    });

    final res = await ApiService.getHistory(auth.userId!);

    setState(() {
      _isLoadingHistory = false;
      if (res['success'] == true) {
        _history = res['history'] ?? [];
      }
    });
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

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

  void _viewTestDetails(dynamic session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF191922),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final questions = session['questions'] as List<dynamic>;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E6072),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  session['testName'] ?? 'Chi tiết bài trắc nghiệm',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Mã phiên: ${session['sessionId']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF888B9B),
                  ),
                ),
                const Divider(color: Color(0xFF2C2C3E), height: 24),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final q = questions[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F13),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2C2C3E)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Câu ${index + 1}: ${q['questionText']}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Đã trả lời: ',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF888B9B),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF6C63FF,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    q['userAnswer'] ?? 'Chưa trả lời',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF6C63FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.06),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Bar override
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Hồ Sơ & Lịch Sử',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      auth.isAuthenticated
                          ? IconButton(
                              icon: Icon(
                                _isEditing
                                    ? Icons.close_rounded
                                    : Icons.edit_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_isEditing) {
                                    _initFields(); // Reset fields
                                  }
                                  _isEditing = !_isEditing;
                                });
                              },
                            )
                          : const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Avatar Info
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(
                            0xFF6C63FF,
                          ).withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 40,
                            color: Color(0xFF6C63FF),
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
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          auth.currentUser?['email'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF888B9B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Edit or View Profile Form
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
                            style: const TextStyle(color: Colors.white),
                            dropdownColor: const Color(0xFF191922),
                            decoration: InputDecoration(
                              labelText: 'Trình độ học vấn',
                              labelStyle: const TextStyle(
                                color: Color(0xFF7A7C93),
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.school_outlined,
                                color: Color(0xFF7A7C93),
                              ),
                              filled: true,
                              fillColor: const Color(0xFF191922),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF2C2C3E),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6C63FF),
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
                              if (val != null)
                                setState(() => _educationLevel = val);
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
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
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

                  // Test History Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lịch Sử Làm Bài',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (!_isLoadingHistory)
                        Text(
                          '${_history.length} bài đã làm',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF888B9B),
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
      style: TextStyle(color: enabled ? Colors.white : const Color(0xFF888B9B)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF7A7C93), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF7A7C93)),
        filled: true,
        fillColor: enabled ? const Color(0xFF191922) : const Color(0xFF121216),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1E1E24)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2C2C3E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
      ),
      validator: (val) =>
          val == null || val.trim().isEmpty ? 'Không được để trống' : null,
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Gần đây';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return 'Gần đây';
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
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
        ),
      );
    }

    if (_history.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          color: const Color(0xFF191922),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2C2C3E)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              size: 40,
              color: Color(0xFF5E6072),
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có lịch sử làm bài',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF888B9B),
              ),
            ),
          ],
        ),
      );
    }

    // Sắp xếp theo ngày gần nhất và lấy tối đa 3 mục preview
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

            // Lấy score và xác định màu của badge score
            final score = session['score'] != null
                ? double.tryParse(session['score'].toString())
                : null;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF191922),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2C2C3E)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(
                    0xFF6C63FF,
                  ).withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.assessment_rounded,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                title: Text(
                  testName,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
                          color: isCompleted ? Colors.green : Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngày làm: $dateStr',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF5E6072),
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
                                      ? const Color(0xFF00F5A0)
                                      : const Color(0xFFFFB74D))
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          score.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: score > 3
                                ? const Color(0xFF00F5A0)
                                : const Color(0xFFFFB74D),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF888B9B),
                    ),
                  ],
                ),
                onTap: () => _viewTestDetails(session),
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
              side: const BorderSide(color: Color(0xFF6C63FF)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Xem tất cả lịch sử',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6C63FF),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
