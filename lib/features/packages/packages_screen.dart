import 'package:flutter/material.dart';
// Đã gỡ Provider quản trị. Hiển thị danh sách gói tập dạng chỉ đọc trực tiếp từ API.
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/features/packages/package_model.dart';
import 'package:gym_frontend/features/packages/package_detail_screen.dart';
import 'package:gym_frontend/core/env.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  String? _status;
  bool _loading = true;
  String? _error;
  List<PackageModel> _packages = [];
  final _api = ApiClient();

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({String? status}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getJson('/api/packages?page=1&limit=100');
      final raw = (res['items'] ?? res['data'] ?? res['results'] ?? []) as List;
      final list = raw
          .map((e) => PackageModel.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
      setState(() {
        _packages = list;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gói tập'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () => _fetch(status: _status),
          ),
        ],
      ),
      body: Column(
        children: [
          // ====== FILTER + TỔNG QUAN ======
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hàng trạng thái + tổng số
                  Row(
                    children: [
                      const Text(
                        'Trạng thái:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _status,
                        underline: const SizedBox(),
                        hint: const Text('Tất cả'),
                        items: const [
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Đang bán'),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Text('Tạm ẩn'),
                          ),
                          DropdownMenuItem(
                            value: 'discontinued',
                            child: Text('Ngừng kinh doanh'),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() => _status = v);
                          _fetch(status: v);
                        },
                      ),
                      const Spacer(),
                      if (!_loading)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Tổng: ${_filtered().length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Quản lý các gói tập đang bán, tạm ẩn hoặc ngừng kinh doanh.',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),

          // ====== DANH SÁCH GÓI TẬP ======
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  )
                : _filtered().isEmpty
                ? _emptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: _filtered().length,
                    itemBuilder: (ctx, i) {
                      final p = _filtered()[i];
                      return _packageCard(context, p, colorScheme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<PackageModel> _filtered() {
    if (_status == null) return _packages;
    return _packages.where((p) => p.status == _status).toList();
  }

  // ====== CARD GÓI TẬP ======

  Widget _packageCard(
    BuildContext context,
    PackageModel p,
    ColorScheme colorScheme,
  ) {
    final statusColor = _statusColor(p.status, colorScheme);
    final statusText = _statusVi(p.status);
    final resolvedImage = _resolveImageUrl(p.imageUrl);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).cardColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PackageDetailScreen(package: p),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hình/biểu tượng gói
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (resolvedImage == null)
                      ? Icon(Icons.fitness_center, size: 22, color: statusColor)
                      : Image.network(
                          resolvedImage,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Icon(
                            Icons.fitness_center,
                            size: 22,
                            color: statusColor,
                          ),
                        ),
                ),
                const SizedBox(width: 10),

                // Nội dung chính
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tên gói
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Giá + thời lượng
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${p.duration} ngày',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.payments,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${p.price} VND',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade900,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Chip trạng thái
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusText,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final r = raw.trim();
    if (r.startsWith('http://') || r.startsWith('https://')) return r;
    // Treat as relative path from API base
    final base = apiBaseUrl();
    if (r.startsWith('/')) return '$base$r';
    return '$base/$r';
  }

  // Menu chỉnh sửa/xoá đã bỏ trên mobile; chỉ xem chi tiết.

  // ====== EMPTY STATE ======

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 52,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chưa có gói tập nào',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hiện chưa có gói tập nào để hiển thị.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ====== STATUS HELPER ======

  String _statusVi(String s) {
    switch (s) {
      case 'active':
        return 'Đang bán';
      case 'inactive':
        return 'Tạm ẩn';
      case 'discontinued':
        return 'Ngừng kinh doanh';
      default:
        return s;
    }
  }

  Color _statusColor(String s, ColorScheme scheme) {
    switch (s) {
      case 'active':
        return Colors.green.shade600;
      case 'inactive':
        return Colors.orange.shade700;
      case 'discontinued':
        return Colors.red.shade600;
      default:
        return scheme.primary;
    }
  }
}
