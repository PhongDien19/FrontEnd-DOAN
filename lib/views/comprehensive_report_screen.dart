import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_provider.dart';
import '../utils/pdf_export_service.dart';
import '../utils/responsive.dart';
import '../viewmodels/comprehensive_report_viewmodels.dart';
import 'chat_screen.dart';

class ComprehensiveReportScreen extends StatefulWidget {
  const ComprehensiveReportScreen({super.key});

  @override
  State<ComprehensiveReportScreen> createState() =>
      _ComprehensiveReportScreenState();
}

class _ComprehensiveReportScreenState extends State<ComprehensiveReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      context.read<ComprehensiveReportViewModel>().fetchReport(auth);
    });
  }

  void _exportPdf(
    BuildContext context,
    AuthProvider auth,
    Map<String, dynamic> report,
  ) async {
    final userName = auth.fullName.isNotEmpty ? auth.fullName : 'Người dùng';
    final reportDate = DateFormat('dd/MM/yyyy').format(DateTime.now());

    final rawAssessments = report['assessments'] as List? ?? [];
    final List<Map<String, dynamic>> assessments = rawAssessments.map((item) {
      if (item is Map<String, dynamic>) return item;
      return <String, dynamic>{};
    }).toList();

    final overallAnalysis =
        report['overallAnalysis']?.toString() ??
        report['summary']?.toString() ??
        'Chưa có phân tích chi tiết.';

    final rawSuggestions =
        report['careerSuggestions'] ?? report['recommendedCareers'] ?? [];
    final List<String> careerSuggestions = (rawSuggestions is List)
        ? rawSuggestions.map((e) => e.toString()).toList()
        : [];

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang tạo và xuất file PDF...'),
        backgroundColor: Color(0xFF6C63FF),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      await PdfExportService.exportComprehensiveReport(
        context: context,
        userName: userName,
        reportDate: reportDate,
        assessments: assessments,
        overallAnalysis: overallAnalysis,
        careerSuggestions: careerSuggestions,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xuất file PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
          'Báo Cáo Hướng Nghiệp AI',
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Consumer<ComprehensiveReportViewModel>(
            builder: (context, vm, child) {
              if (vm.report == null || vm.isLoading) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFF00F5A0),
                ),
                tooltip: 'Xuất PDF',
                onPressed: () => _exportPdf(context, auth, vm.report!),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Tải lại',
            onPressed: () {
              context.read<ComprehensiveReportViewModel>().fetchReport(auth);
            },
          ),
        ],
      ),
      body: Consumer<ComprehensiveReportViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return _buildLoadingState(context);
          }

          if (vm.errorMessage != null) {
            return _buildErrorState(context, vm, auth);
          }

          if (vm.report == null) {
            return _buildEmptyState(context, vm, auth);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.s(context, 20),
              vertical: Responsive.s(context, 16),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: Responsive.contentMaxWidth(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserOverviewHeader(context, auth),
                    SizedBox(height: Responsive.s(context, 20)),
                    _buildOverallAnalysisCard(context, vm.report!),
                    SizedBox(height: Responsive.s(context, 20)),
                    _buildPillarsAssessmentSection(context, vm.report!),
                    SizedBox(height: Responsive.s(context, 20)),
                    _buildCareerSuggestionsSection(context, vm.report!),
                    SizedBox(height: Responsive.s(context, 20)),
                    _buildActionableAdviceCard(context, vm.report!),
                    SizedBox(height: Responsive.s(context, 24)),
                    _buildBottomActionButtons(context, auth, vm.report!),
                    SizedBox(height: Responsive.s(context, 24)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- TRẠNG THÁI LOADING / ERROR / EMPTY ---

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
          ),
          SizedBox(height: Responsive.s(context, 16)),
          Text(
            'AI đang tổng hợp dữ liệu 4 trụ cột...',
            style: TextStyle(
              color: const Color(0xFF888B9B),
              fontSize: Responsive.font(context, 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ComprehensiveReportViewModel vm,
    AuthProvider auth,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(Responsive.s(context, 24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: Responsive.s(context, 64),
              color: const Color(0xFFFFB74D),
            ),
            SizedBox(height: Responsive.s(context, 16)),
            Text(
              'Chưa Thể Hiển Thị Báo Cáo',
              style: TextStyle(
                fontSize: Responsive.font(context, 18),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: Responsive.s(context, 8)),
            Text(
              vm.errorMessage ?? 'Có lỗi xảy ra khi tải báo cáo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.font(context, 13),
                color: const Color(0xFF888B9B),
              ),
            ),
            SizedBox(height: Responsive.s(context, 24)),
            ElevatedButton.icon(
              onPressed: () => vm.fetchReport(auth),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử Lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.s(context, 24),
                  vertical: Responsive.s(context, 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ComprehensiveReportViewModel vm,
    AuthProvider auth,
  ) {
    return Center(
      child: Text(
        'Không tìm thấy dữ liệu báo cáo.',
        style: TextStyle(
          color: Colors.white,
          fontSize: Responsive.font(context, 14),
        ),
      ),
    );
  }

  // --- THÀNH PHẦN GIAO DIỆN CHÍNH ---

  Widget _buildUserOverviewHeader(BuildContext context, AuthProvider auth) {
    final targetJobText = auth.targetJob.isNotEmpty
        ? auth.targetJob
        : "Chưa xác định";
    final eduLevelText = auth.educationLevel.isNotEmpty
        ? auth.educationLevel
        : "Tự do";

    return Container(
      padding: EdgeInsets.all(Responsive.s(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFF191922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: Responsive.s(context, 24),
            backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            child: Icon(
              Icons.person_rounded,
              color: const Color(0xFF6C63FF),
              size: Responsive.s(context, 26),
            ),
          ),
          SizedBox(width: Responsive.s(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.fullName.isNotEmpty
                      ? auth.fullName
                      : 'Học Viên Hướng Nghiệp',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: Responsive.s(context, 4)),
                Text(
                  'Mục tiêu: $targetJobText • Trình độ: $eduLevelText',
                  style: TextStyle(
                    fontSize: Responsive.font(context, 12),
                    color: const Color(0xFF888B9B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallAnalysisCard(
    BuildContext context,
    Map<String, dynamic> report,
  ) {
    final analysis =
        report['overallAnalysis']?.toString() ??
        report['summary']?.toString() ??
        'AI đang tính toán bức tranh tổng quan cho bạn...';

    return Container(
      padding: EdgeInsets.all(Responsive.s(context, 20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withValues(alpha: 0.2),
            const Color(0xFF191922),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Color(0xFF00F5A0)),
              SizedBox(width: Responsive.s(context, 8)),
              Text(
                'Phân Tích Tổng Quan Từ AI',
                style: TextStyle(
                  fontSize: Responsive.font(context, 16),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.s(context, 12)),
          Text(
            analysis,
            style: TextStyle(
              fontSize: Responsive.font(context, 13),
              color: const Color(0xFFD1D5DB),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarsAssessmentSection(
    BuildContext context,
    Map<String, dynamic> report,
  ) {
    final rawList = report['assessments'] as List? ?? [];

    if (rawList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kết Quả Chi Tiết 4 Trụ Cột',
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: Responsive.s(context, 12)),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rawList.length,
          separatorBuilder: (context, index) =>
              SizedBox(height: Responsive.s(context, 10)),
          itemBuilder: (context, index) {
            final item = rawList[index] as Map<String, dynamic>? ?? {};
            final title = item['title']?.toString() ?? 'Trụ cột ${index + 1}';
            final score = item['score']?.toString() ?? 'N/A';
            final interpretation =
                item['interpretation']?.toString() ?? 'Chưa có thông tin.';

            return Container(
              padding: EdgeInsets.all(Responsive.s(context, 16)),
              decoration: BoxDecoration(
                color: const Color(0xFF191922),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: Responsive.font(context, 14),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF1A416),
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.s(context, 10),
                          vertical: Responsive.s(context, 4),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Điểm: $score',
                          style: TextStyle(
                            fontSize: Responsive.font(context, 12),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Responsive.s(context, 8)),
                  Text(
                    interpretation,
                    style: TextStyle(
                      fontSize: Responsive.font(context, 12),
                      color: const Color(0xFF9CA3AF),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCareerSuggestionsSection(
    BuildContext context,
    Map<String, dynamic> report,
  ) {
    final rawSuggestions =
        report['careerSuggestions'] ?? report['recommendedCareers'] ?? [];
    final List<String> suggestions = (rawSuggestions is List)
        ? rawSuggestions.map((e) => e.toString()).toList()
        : [];

    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gợi Ý Nghề Nghiệp Phù Hợp',
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: Responsive.s(context, 12)),
        Wrap(
          spacing: Responsive.s(context, 8),
          runSpacing: Responsive.s(context, 8),
          children: suggestions.map((career) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.s(context, 14),
                vertical: Responsive.s(context, 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF191922),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00F5A0).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.work_outline_rounded,
                    color: Color(0xFF00F5A0),
                    size: 16,
                  ),
                  SizedBox(width: Responsive.s(context, 6)),
                  Text(
                    career,
                    style: TextStyle(
                      fontSize: Responsive.font(context, 13),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionableAdviceCard(
    BuildContext context,
    Map<String, dynamic> report,
  ) {
    final advice =
        report['actionPlan']?.toString() ??
        report['additionalInsights']?.toString() ??
        'Hãy bắt đầu trau dồi các kỹ năng cốt lõi và tham vấn cố vấn AI để xây dựng lộ trình chi tiết từng tháng.';

    return Container(
      padding: EdgeInsets.all(Responsive.s(context, 16)),
      decoration: BoxDecoration(
        color: const Color(0xFF191922),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: Color(0xFFF1A416),
              ),
              SizedBox(width: Responsive.s(context, 8)),
              Text(
                'Lộ Trình & Lời Khuyên',
                style: TextStyle(
                  fontSize: Responsive.font(context, 14),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.s(context, 10)),
          Text(
            advice,
            style: TextStyle(
              fontSize: Responsive.font(context, 13),
              color: const Color(0xFF9CA3AF),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionButtons(
    BuildContext context,
    AuthProvider auth,
    Map<String, dynamic> report,
  ) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: Responsive.s(context, 48),
          child: ElevatedButton.icon(
            onPressed: () {
              final rawSuggestions =
                  report['careerSuggestions'] ??
                  report['recommendedCareers'] ??
                  [];
              final List<String> careers = (rawSuggestions is List)
                  ? rawSuggestions.map((e) => e.toString()).toList()
                  : [];

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    initialContext: {
                      'recommendedCareers': careers,
                      'overallAnalysis':
                          report['overallAnalysis']?.toString() ?? '',
                    },
                  ),
                ),
              );
            },
            icon: const Icon(Icons.forum_rounded),
            label: const Text('Hỏi Thêm Cố Vấn AI Về Báo Cáo Này'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        SizedBox(height: Responsive.s(context, 10)),
        SizedBox(
          width: double.infinity,
          height: Responsive.s(context, 48),
          child: OutlinedButton.icon(
            onPressed: () => _exportPdf(context, auth, report),
            icon: const Icon(Icons.download_rounded, color: Color(0xFF00F5A0)),
            label: const Text(
              'Tải Xuất File Báo Cáo PDF',
              style: TextStyle(color: Color(0xFF00F5A0)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00F5A0), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
