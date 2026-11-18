import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/test_comparison.dart';
import '../models/test_result.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../viewmodels/compare_viewmodel.dart';

class CompareScreen extends StatefulWidget {
  const CompareScreen({super.key});

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompareViewModel>().prepare();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'So Sánh Bài Test',
          style: TextStyle(
            fontSize: Responsive.font(context, 16),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<CompareViewModel>(
        builder: (context, vm, _) {
          if (vm.errorMessage != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(Responsive.s(context, 24)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vm.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    SizedBox(height: Responsive.s(context, 12)),
                    ElevatedButton(
                      onPressed: vm.prepare,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          final c = vm.comparison;
          if (vm.isPreparing || c == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryDark),
            );
          }
          return _buildBody(c);
        },
      ),
    );
  }

  Widget _buildBody(TestComparison c) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.s(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(c),
          _section('Điểm số', c.scores.map(_metricRow).toList()),
          if (c.holland.isNotEmpty)
            _section('Sở thích Holland', [
              if (c.hollandCodeChanged)
                _textRow(
                  'Mã Holland',
                  '${c.before.hollandCode ?? '–'} → ${c.after.hollandCode ?? '–'}',
                ),
              ...c.holland.map(_metricRow),
            ]),
          if (c.before.mbtiType != null || c.after.mbtiType != null)
            _section('Tính cách', [
              _textRow(
                'Loại tính cách',
                c.mbtiChanged
                    ? '${c.before.mbtiType ?? '–'} → ${c.after.mbtiType ?? '–'}'
                    : '${c.after.mbtiType ?? '–'} (không đổi)',
              ),
              ...c.changedMbtiDimensions.map(
                (d) => _textRow(
                  d,
                  '${c.before.mbtiChoices[d] ?? '–'} → ${c.after.mbtiChoices[d] ?? '–'}',
                ),
              ),
            ]),
          if (c.majors.isNotEmpty)
            _section('Ngành gợi ý', c.majors.map(_majorRow).toList()),
        ],
      ),
    );
  }

  // ---------- Thành phần giao diện ----------

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.border),
  );

  Widget _header(TestComparison c) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(Responsive.s(context, 16)),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            c.after.title,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: Responsive.font(context, 14),
            ),
          ),
          SizedBox(height: Responsive.s(context, 12)),
          Row(
            children: [
              Expanded(child: _headerCol('Bài cũ', c.before)),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.primaryDark,
              ),
              Expanded(child: _headerCol('Bài mới', c.after)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerCol(String label, TestResult t) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: Responsive.font(context, 11),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          t.createdAtLabel.isEmpty ? '–' : t.createdAtLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: Responsive.font(context, 13),
          ),
        ),
        if (t.fitLevel != null)
          Text(
            t.fitLevel!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: Responsive.font(context, 11),
            ),
          ),
      ],
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Padding(
      padding: EdgeInsets.only(top: Responsive.s(context, 16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(Responsive.s(context, 16)),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: Responsive.font(context, 14),
              ),
            ),
            SizedBox(height: Responsive.s(context, 8)),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, List<Widget> trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textBody,
                fontSize: Responsive.font(context, 13),
              ),
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }

  Widget _textRow(String label, String value) => _row(label, [
    Text(
      value,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: Responsive.font(context, 13),
      ),
    ),
  ]);

  Widget _metricRow(MetricDelta m) => _row(m.label, [
    Text(
      '${_n(m.before)} → ${_n(m.after)}',
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: Responsive.font(context, 13),
      ),
    ),
    const SizedBox(width: 8),
    _deltaChip(m.delta),
  ]);

  Widget _majorRow(MajorChange m) {
    if (m.isNew) return _row(m.name, [_pill('Mới', AppColors.success)]);
    if (m.isDropped) {
      return _row(m.name, [_pill('Không còn', AppColors.textSecondary)]);
    }
    return _row(m.name, [
      Text(
        '${_n(m.before)} → ${_n(m.after)}',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: Responsive.font(context, 13),
        ),
      ),
      const SizedBox(width: 8),
      _deltaChip(m.delta),
    ]);
  }

  Widget _deltaChip(double? d) {
    if (d == null) return _pill('–', AppColors.textHint);
    if (d.abs() < 0.05) return _pill('=', AppColors.textSecondary);
    return d > 0
        ? _pill('+${_n(d)}', AppColors.success)
        : _pill('−${_n(d.abs())}', AppColors.error);
  }

  Widget _pill(String text, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 52),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: Responsive.font(context, 12),
        ),
      ),
    );
  }

  String _n(double? v) =>
      v == null ? '–' : v.toStringAsFixed(v % 1 == 0 ? 0 : 1);
}
