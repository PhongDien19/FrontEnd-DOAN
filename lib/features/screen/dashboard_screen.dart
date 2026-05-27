import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'models.dart';

final List<String> dimensions = [
  "Tư duy phân tích",
  "Sáng tạo",
  "Giao tiếp",
  "Tổ chức",
  "Kỹ thuật",
  "Lãnh đạo",
];

final List<TestEntry> testHistory = [
  TestEntry(
    id: 1,
    date: "Tháng 3/2024",
    career: "Kỹ sư phần mềm",
    match: 68,
    type: "Targeted",
    scores: {
      "Tư duy phân tích": 65,
      "Sáng tạo": 55,
      "Giao tiếp": 52,
      "Tổ chức": 68,
      "Kỹ thuật": 62,
      "Lãnh đạo": 50,
    },
  ),
  TestEntry(
    id: 2,
    date: "Tháng 7/2024",
    career: "Thiết kế UX/UI",
    match: 72,
    type: "Discovery",
    scores: {
      "Tư duy phân tích": 60,
      "Sáng tạo": 78,
      "Giao tiếp": 65,
      "Tổ chức": 70,
      "Kỹ thuật": 65,
      "Lãnh đạo": 58,
    },
  ),
  TestEntry(
    id: 3,
    date: "Tháng 11/2024",
    career: "Quản lý dự án",
    match: 65,
    type: "Targeted",
    scores: {
      "Tư duy phân tích": 68,
      "Sáng tạo": 52,
      "Giao tiếp": 72,
      "Tổ chức": 82,
      "Kỹ thuật": 55,
      "Lãnh đạo": 75,
    },
  ),
  TestEntry(
    id: 4,
    date: "Tháng 1/2025",
    career: "Kỹ sư phần mềm",
    match: 84,
    type: "Discovery",
    scores: {
      "Tư duy phân tích": 84,
      "Sáng tạo": 72,
      "Giao tiếp": 68,
      "Tổ chức": 80,
      "Kỹ thuật": 82,
      "Lãnh đạo": 74,
    },
  ),
];

// ── Main Dashboard Screen ────────────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  final AuthUser authUser;
  final String career;
  final VoidCallback onLogout;
  final VoidCallback onHome;

  const DashboardScreen({
    Key? key,
    required this.authUser,
    required this.career,
    required this.onLogout,
    required this.onHome,
  }) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _activeTab = "profile"; // profile, history, roadmap, market
  bool _editMode = false;

  // Profile Form States
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _phoneController = TextEditingController(text: "0901 234 567");
  final _locationController = TextEditingController(text: "TP. Hồ Chí Minh");
  late TextEditingController _bioController;

  // Comparison States
  final List<int> _selectedIds = [];
  bool _showComparison = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.authUser.name);
    _emailController = TextEditingController(text: widget.authUser.email);
    _bioController = TextEditingController(
      text: "Đang xây dựng lộ trình trở thành ${widget.career}.",
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // Đã chuẩn hóa logic mảng theo chuẩn Dart (.contains)
  void _toggleSelectHistory(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length >= 2) {
          _selectedIds.removeAt(0); // Cơ chế Slide window giữ tối đa 2 phần tử
        }
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber[500],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "CP",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Dashboard",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: _buildMobileTabBar(),
              ),
            ),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _buildMainContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Giao diện Từng Tab Nội Dung ─────────────────────────────────────────────
  Widget _buildMainContent() {
    switch (_activeTab) {
      case "profile":
        return _buildProfileTab();
      case "history":
        return _buildHistoryTab();
      case "roadmap":
        return const Center(
          child: Text("Giao diện Lộ trình (Đang phát triển)"),
        );
      case "market":
        return const Center(
          child: Text("Giao diện Thị trường (Đang phát triển)"),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildProfileTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Hồ sơ cá nhân",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Serif',
                  ),
                ),
                Text(
                  "Thông tin và thành tích của bạn",
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _editMode ? Colors.green[600] : Colors.white,
                foregroundColor: _editMode ? Colors.white : Colors.black87,
                side: BorderSide(color: Colors.grey[300]!),
                elevation: 0,
              ),
              onPressed: () => setState(() => _editMode = !_editMode),
              icon: Icon(
                _editMode ? LucideIcons.save : LucideIcons.pencil,
                size: 16,
              ),
              label: Text(_editMode ? "Lưu" : "Chỉnh sửa"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber[400]!, Colors.amber[600]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _nameController.text.isNotEmpty
                            ? _nameController.text[0].toUpperCase()
                            : "U",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _editMode
                              ? TextField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                  ),
                                )
                              : Text(
                                  _nameController.text,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          const SizedBox(height: 4),
                          _editMode
                              ? TextField(
                                  controller: _emailController,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                  ),
                                )
                              : Text(
                                  _emailController.text,
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ), // ĐÃ SỬA: py -> vertical
                                decoration: BoxDecoration(
                                  color: Colors.amber[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.career,
                                  style: TextStyle(
                                    color: Colors.amber[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ), // ĐÃ SỬA: py -> vertical
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "✓ Đã xác minh",
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildStatCard(
                      "Bài test đã làm",
                      "4",
                      LucideIcons.barChart2,
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "Điểm match hiện tại",
                      "84%",
                      LucideIcons.trendingUp,
                      Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      "Tuần học liên tiếp",
                      "8",
                      LucideIcons.clock,
                      Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildProfileFields(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    MaterialColor color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ), // ĐÃ SỬA: Border.solid không phải tham số trực tiếp trong BoxDecoration
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color[600], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileFields() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 3,
      children: [
        _buildInfoField("Số điện thoại", _phoneController.text),
        _buildInfoField("Khu vực sinh sống", _locationController.text),
        _buildInfoField("Trình độ học vấn", "Đại học"),
        _buildInfoField("Tình trạng", "Đi làm"),
        _buildInfoField("Ngành định hướng", widget.career),
        _buildInfoField("Lần đánh giá gần nhất", "Tháng 1/2025"),
      ],
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Lịch sử test",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Serif',
          ),
        ),
        Text(
          "So sánh kết quả và đối chiếu ngành nghề",
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                ...testHistory.map((item) {
                  final isSelected = _selectedIds.contains(
                    item.id,
                  ); // ĐÃ SỬA: Dùng hàm .contains chuẩn của Dart
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: InkWell(
                      onTap: () => _toggleSelectHistory(item.id),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.amber[50]!.withOpacity(0.5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.amber[500]!
                                : Colors.grey[200]!,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? LucideIcons.checkCircle2
                                  : LucideIcons.circle,
                              color: isSelected
                                  ? Colors.amber[600]
                                  : Colors.grey[300],
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: item.match >= 80
                                    ? Colors.green[50]
                                    : Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "${item.match}%",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: item.match >= 80
                                      ? Colors.green[700]
                                      : Colors.amber[700],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.career,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    "${item.date} · Chế độ ${item.type}",
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                if (_selectedIds.length == 2) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => setState(() => _showComparison = true),
                      icon: const Icon(LucideIcons.gitCompare, size: 16),
                      label: const Text("So sánh 2 kết quả đã chọn"),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_showComparison && _selectedIds.length == 2) ...[
          const SizedBox(height: 20),
          _buildComparisonPanel(),
        ],
      ],
    );
  }

  Widget _buildComparisonPanel() {
    final entry1 = testHistory.firstWhere((t) => t.id == _selectedIds[0]);
    final entry2 = testHistory.firstWhere((t) => t.id == _selectedIds[1]);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.amber[400]!, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.gitCompare, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      "So sánh nghề nghiệp",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 16),
                  onPressed: () => setState(() => _showComparison = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      fillColor: Colors.amber.withOpacity(0.25),
                      borderColor: Colors.amber,
                      entryRadius: 2,
                      dataEntries: dimensions
                          .map((d) => RadarEntry(value: entry1.scores[d] ?? 0))
                          .toList(),
                    ),
                    RadarDataSet(
                      fillColor: Colors.grey.withOpacity(0.2),
                      borderColor: Colors.grey,
                      entryRadius: 2,
                      dataEntries: dimensions
                          .map((d) => RadarEntry(value: entry2.scores[d] ?? 0))
                          .toList(),
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: const BorderSide(
                    color: Colors.grey,
                    width: 0.5,
                  ),
                  titlePositionPercentageOffset: 0.2,
                  getTitle: (index, angle) =>
                      RadarChartTitle(text: dimensions[index], angle: angle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Layout Components (Sidebar & Tabs) ──────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 260,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, // Chuyển color vào trong BoxDecoration
        border: Border(
          right: BorderSide(color: Colors.grey[200]!),
        ), // Chuyển border vào trong BoxDecoration
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber[500],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "CP",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Career Pathway",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarNavButton(
                  "profile",
                  "Hồ sơ cá nhân",
                  LucideIcons.user,
                ),
                _buildSidebarNavButton(
                  "history",
                  "Lịch sử test",
                  LucideIcons.history,
                ),
                _buildSidebarNavButton("roadmap", "Lộ trình", LucideIcons.map),
                _buildSidebarNavButton(
                  "market",
                  "Thị trường",
                  LucideIcons.trendingUp,
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.home, size: 18),
            title: const Text("Trang chủ", style: TextStyle(fontSize: 14)),
            onTap: widget.onHome,
          ),
          ListTile(
            leading: const Icon(
              LucideIcons.logOut,
              color: Colors.red,
              size: 18,
            ),
            title: const Text(
              "Đăng xuất",
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
            onTap: widget.onLogout,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarNavButton(String key, String label, IconData icon) {
    final isSelected = _activeTab == key;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Colors.amber[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(
          icon,
          color: isSelected ? Colors.amber[700] : Colors.grey[600],
          size: 18,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.amber[700] : Colors.black87,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: Colors.amber,
              )
            : null,
        onTap: () => setState(() => _activeTab = key),
      ),
    );
  }

  Widget _buildMobileTabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMobileTabIconButton("profile", LucideIcons.user),
        _buildMobileTabIconButton("history", LucideIcons.history),
        _buildMobileTabIconButton("roadmap", LucideIcons.map),
        _buildMobileTabIconButton("market", LucideIcons.trendingUp),
      ],
    );
  }

  Widget _buildMobileTabIconButton(String key, IconData icon) {
    final isSelected = _activeTab == key;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? Colors.amber[700] : Colors.grey[500],
      ),
      onPressed: () => setState(() => _activeTab = key),
    );
  }
}
