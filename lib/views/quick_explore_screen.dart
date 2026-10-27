import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/responsive.dart';
import '../viewmodels/quick_explore_viewmodels.dart';

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
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191922),
        elevation: 0,
        title: Text(
          'Khám Phá Nhanh Ngành Nghề',
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
                      color: const Color(0xFF191922),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF6C63FF),
                        ),
                        SizedBox(width: Responsive.s(context, 10)),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText:
                                  'Nhập tên ngành nghề (VD: Lập trình Flutter)...',
                              hintStyle: TextStyle(color: Color(0xFF5E6072)),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _onSearch(vm),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFF6C63FF),
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
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
        ),
      );
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Text(
          vm.errorMessage!,
          style: const TextStyle(color: Colors.redAccent),
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
              color: Color(0xFF5E6072),
            ),
            SizedBox(height: Responsive.s(context, 12)),
            Text(
              'Nhập từ khóa ngành nghề để tra cứu ngay thông tin chi tiết.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF888B9B),
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
              color: const Color(0xFF191922),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              overview,
              style: TextStyle(
                color: const Color(0xFFD1D5DB),
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
                color: Colors.white,
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
                      backgroundColor: const Color(0xFF191922),
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
