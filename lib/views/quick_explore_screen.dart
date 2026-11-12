import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../utils/responsive.dart';
import '../viewmodels/quick_explore_viewmodel.dart';

class QuickExploreScreen extends StatefulWidget {
  const QuickExploreScreen({super.key});

  @override
  State<QuickExploreScreen> createState() => _QuickExploreScreenState();
}

class _QuickExploreScreenState extends State<QuickExploreScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(QuickExploreViewModel vm) {
    vm.searchCareer(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Khám Phá Nhanh Ngành Nghề',
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
      ),
      body: SafeArea(
        child: Consumer<QuickExploreViewModel>(
          builder: (context, vm, child) {
            return Padding(
              padding: EdgeInsets.all(Responsive.s(context, 20)),
              child: Column(
                children: [
                  // Thanh tìm kiếm
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.s(context, 16),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: AppColors.primaryDark,
                        ),
                        SizedBox(width: Responsive.s(context, 10)),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText:
                                  'Nhập tên ngành nghề (VD: Lập trình Flutter)...',
                              hintStyle: TextStyle(color: AppColors.textHint),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _onSearch(vm),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primaryDark,
                          ),
                          onPressed: () => _onSearch(vm),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: Responsive.s(context, 20)),

                  // Nội dung hiển thị
                  Expanded(child: _buildResultContent(vm)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultContent(QuickExploreViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Text(
          vm.errorMessage!,
          style: const TextStyle(color: AppColors.error),
        ),
      );
    }

    if (vm.exploreData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.travel_explore_rounded,
              size: 64,
              color: AppColors.textHint,
            ),
            SizedBox(height: Responsive.s(context, 12)),
            Text(
              'Nhập từ khóa ngành nghề để tra cứu ngay thông tin chi tiết.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: Responsive.font(context, 13),
              ),
            ),
          ],
        ),
      );
    }

    final overview =
        vm.exploreData!['overview']?.toString() ?? 'Chưa có thông tin.';
    final skills = vm.exploreData!['skills'] as List? ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.s(context, 16)),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              overview,
              style: TextStyle(
                color: AppColors.textBody,
                height: 1.5,
                fontSize: Responsive.font(context, 13),
              ),
            ),
          ),
          SizedBox(height: Responsive.s(context, 16)),
          if (skills.isNotEmpty) ...[
            Text(
              'Kỹ Năng Cần Có',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: Responsive.font(context, 15),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Responsive.s(context, 10)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map(
                    (s) => Chip(
                      label: Text(s.toString()),
                      backgroundColor: AppColors.surface,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
