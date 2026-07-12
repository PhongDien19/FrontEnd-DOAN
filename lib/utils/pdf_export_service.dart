import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class PdfExportService {
  static final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _fileNameDateFormat = DateFormat('yyyyMMdd_HHmmss');

  static Future<void> exportSurveyReport({
    required BuildContext context,
    required String title,
    required String userName,
    required String testType,
    required String date,
    required Map<String, dynamic> scores,
    required Map<String, dynamic> interpretations,
    String? careerRecommendations,
    String? additionalInsights,
  }) async {
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );
    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(title),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildInfoSection(userName, testType, date),
          pw.SizedBox(height: 20),
          _buildScoresSection(scores),
          pw.SizedBox(height: 20),
          _buildInterpretationsSection(interpretations),
          if (careerRecommendations != null) ...[
            pw.SizedBox(height: 20),
            _buildRecommendationsSection(careerRecommendations),
          ],
          if (additionalInsights != null) ...[
            pw.SizedBox(height: 20),
            _buildInsightsSection(additionalInsights),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'BaoCao_${testType}_$date.pdf',
    );

    // Also save to Downloads folder
    await _saveToDownloads(
      pdf: pdf,
      fileName: 'BaoCao_${testType}_${_fileNameDateFormat.format(DateTime.now())}.pdf',
    );
  }

  static Future<void> exportComprehensiveReport({
    required BuildContext context,
    required String userName,
    required String reportDate,
    required List<Map<String, dynamic>> assessments,
    required String overallAnalysis,
    required List<String> careerSuggestions,
  }) async {
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );
    final pdf = pw.Document(theme: theme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Báo Cáo Tổng Hợp 4 Trụ Cột'),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildInfoSection(userName, 'Đánh giá toàn diện', reportDate),
          pw.SizedBox(height: 20),
          _buildComprehensiveAssessments(assessments),
          pw.SizedBox(height: 20),
          _buildOverallAnalysis(overallAnalysis),
          pw.SizedBox(height: 20),
          _buildCareerSuggestions(careerSuggestions),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'BaoCaoTongHop_$reportDate.pdf',
    );

    // Also save to Downloads folder
    await _saveToDownloads(
      pdf: pdf,
      fileName: 'BaoCaoTongHop_${_fileNameDateFormat.format(DateTime.now())}.pdf',
    );
  }

  static Future<void> exportTestHistory({
    required BuildContext context,
    required String userName,
    required List<Map<String, dynamic>> historyItems,
  }) async {
    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();
    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );
    final pdf = pw.Document(theme: theme);
    final now = _dateFormat.format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Lịch Sử Bài Khảo Sát'),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildInfoSection(userName, 'Lịch sử', now),
          pw.SizedBox(height: 20),
          _buildHistoryTable(historyItems),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'LichSuKhaoSat_$now.pdf',
    );

    // Also save to Downloads folder
    await _saveToDownloads(
      pdf: pdf,
      fileName: 'LichSuKhaoSat_${_fileNameDateFormat.format(DateTime.now())}.pdf',
    );
  }

  static Future<void> _saveToDownloads({
    required pw.Document pdf,
    required String fileName,
  }) async {
    try {
      final directory = await _getDownloadsDirectory();
      if (directory == null) return;

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Show success message (optional, can be removed if not needed)
      debugPrint('PDF saved to: ${file.path}');
    } catch (e) {
      debugPrint('Error saving PDF to Downloads: $e');
    }
  }

  static Future<Directory?> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // For Android 10+, we need to use MediaStore or request permissions
      // For simplicity, we'll use the app's external storage directory
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        // Create a "Downloads" folder if it doesn't exist
        final downloadsDir = Directory('${directory.path}/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      }
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // For desktop platforms, use the system's downloads directory
      final homeDir = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (homeDir != null) {
        final downloadsDir = Directory('$homeDir/Downloads');
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      }
    }
    return null;
  }

  static pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.amber, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Hướng Nghiệp AI',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.amber800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey800,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.amber50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.amber),
            ),
            child: pw.Text(
              'BÁO CÁO CHÍNH THỨC',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Doc: ${_dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Trang ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoSection(String userName, String testType, String date) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Người dùng:', userName),
                pw.SizedBox(height: 6),
                _buildInfoRow('Loại bài:', testType),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Ngày tạo:', date),
                pw.SizedBox(height: 6),
                _buildInfoRow('Hệ thống:', 'Hướng Nghiệp AI'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildScoresSection(Map<String, dynamic> scores) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Điểm Số'),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.amber50),
              children: [
                _buildTableHeader('Tiêu chí'),
                _buildTableHeader('Điểm'),
                _buildTableHeader('Mức đánh giá'),
              ],
            ),
            ...scores.entries.map((entry) {
              final score = entry.value;
              final level = _getScoreLevel(score);
              return pw.TableRow(
                children: [
                  _buildTableCell(entry.key),
                  _buildTableCell(score.toString()),
                  _buildTableCell(level),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInterpretationsSection(Map<String, dynamic> interpretations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Giải Thích Chi Tiết'),
        pw.SizedBox(height: 10),
        ...interpretations.entries.map((entry) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 8),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  entry.key,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  entry.value.toString(),
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildRecommendationsSection(String recommendations) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Đề Xuất Nghề Nghiệp'),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.amber50,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.amber200),
          ),
          child: pw.Text(
            recommendations,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInsightsSection(String insights) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Nhận Định Bổ Sung'),
        pw.SizedBox(height: 10),
        pw.Text(
          insights,
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
        ),
      ],
    );
  }

  static pw.Widget _buildComprehensiveAssessments(List<Map<String, dynamic>> assessments) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Kết Quả 4 Trụ Cột'),
        pw.SizedBox(height: 10),
        ...assessments.map((assessment) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.amber200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  assessment['title'] ?? '',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.amber800,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Điểm: ${assessment['score'] ?? 'N/A'}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  assessment['interpretation'] ?? '',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildOverallAnalysis(String analysis) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Phân Tích Tổng Quan'),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.blue50,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.blue200),
          ),
          child: pw.Text(
            analysis,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildCareerSuggestions(List<String> suggestions) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Gợi Ý Nghề Nghiệp'),
        pw.SizedBox(height: 10),
        ...suggestions.asMap().entries.map((entry) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
              border: pw.Border.all(color: PdfColors.grey200),
            ),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 24,
                  height: 24,
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.amber,
                    shape: pw.BoxShape.circle,
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '${entry.key + 1}',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Text(
                    entry.value,
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildHistoryTable(List<Map<String, dynamic>> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.amber50),
          children: [
            _buildTableHeader('Ngày'),
            _buildTableHeader('Loại'),
            _buildTableHeader('Điểm'),
            _buildTableHeader('Trạng thái'),
          ],
        ),
        ...items.map((item) {
          return pw.TableRow(
            children: [
              _buildTableCell(item['date'] ?? ''),
              _buildTableCell(item['type'] ?? ''),
              _buildTableCell(item['score'] ?? ''),
              _buildTableCell(item['status'] ?? ''),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blueGrey800,
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
      ),
    );
  }

  static String _getScoreLevel(dynamic score) {
    try {
      final numericScore = double.tryParse(score.toString().replaceAll('%', '')) ?? 0;
      if (numericScore >= 80) return 'Xuất sắc';
      if (numericScore >= 70) return 'Tốt';
      if (numericScore >= 60) return 'Khá';
      if (numericScore >= 50) return 'Trung bình';
      return 'Cần cải thiện';
    } catch (e) {
      return 'N/A';
    }
  }
}
