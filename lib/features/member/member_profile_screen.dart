import 'package:flutter/material.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'package:gym_frontend/core/token_storage.dart';
import 'package:gym_frontend/features/member/member_model.dart';
import 'package:gym_frontend/features/member/member_service.dart';
import 'package:intl/intl.dart';

class MemberProfileScreen extends StatefulWidget {
  const MemberProfileScreen({super.key});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  final _service = MemberService(ApiClient(storage: TokenStorage()));
  bool _loading = true;
  String? _error;
  MemberModel? _member;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final member = await _service.getMyProfile();
      if (mounted) {
        setState(() {
          _member = member;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        centerTitle: true,
        actions: [
          if (_member != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Navigate to edit profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng đang phát triển')),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text('Lỗi: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetch,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : _member == null
          ? const Center(child: Text('Không tìm thấy thông tin'))
          : RefreshIndicator(
              onRefresh: _fetch,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Membership Number
                    if (_member!.membershipNumber != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Mã HV: ${_member!.membershipNumber}',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Info Cards
                    _buildInfoCard(
                      icon: Icons.person_outline,
                      title: 'Họ tên',
                      value: _member!.fullName,
                    ),
                    _buildInfoCard(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: _member!.email,
                    ),
                    _buildInfoCard(
                      icon: Icons.phone_outlined,
                      title: 'Số điện thoại',
                      value: _member!.phone,
                    ),
                    if (_member!.dateOfBirth != null)
                      _buildInfoCard(
                        icon: Icons.cake_outlined,
                        title: 'Ngày sinh',
                        value: DateFormat(
                          'dd/MM/yyyy',
                        ).format(_member!.dateOfBirth!),
                      ),
                    if (_member!.gender != null)
                      _buildInfoCard(
                        icon: Icons.wc_outlined,
                        title: 'Giới tính',
                        value: _member!.gender!,
                      ),
                    if (_member!.address != null &&
                        _member!.address!.isNotEmpty)
                      _buildInfoCard(
                        icon: Icons.location_on_outlined,
                        title: 'Địa chỉ',
                        value: _member!.address!,
                      ),
                    _buildInfoCard(
                      icon: Icons.verified_outlined,
                      title: 'Trạng thái',
                      value: _member!.status,
                      valueColor: _member!.status == 'Hoạt động'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    if (_member!.joinDate != null)
                      _buildInfoCard(
                        icon: Icons.date_range_outlined,
                        title: 'Ngày tham gia',
                        value: DateFormat(
                          'dd/MM/yyyy',
                        ).format(_member!.joinDate!),
                      ),
                    _buildInfoCard(
                      icon: Icons.fitness_center_outlined,
                      title: 'Tổng số buổi tập',
                      value: _member!.totalVisits.toString(),
                    ),
                    if (_member!.lastVisit != null)
                      _buildInfoCard(
                        icon: Icons.access_time_outlined,
                        title: 'Lần tập gần nhất',
                        value: DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(_member!.lastVisit!),
                      ),

                    // Emergency Contact
                    if (_member!.emergencyContact != null &&
                        _member!.emergencyContact!.name != null) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Liên hệ khẩn cấp',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        title: 'Họ tên',
                        value: _member!.emergencyContact!.name!,
                      ),
                      if (_member!.emergencyContact!.phone != null)
                        _buildInfoCard(
                          icon: Icons.phone_outlined,
                          title: 'Số điện thoại',
                          value: _member!.emergencyContact!.phone!,
                        ),
                      if (_member!.emergencyContact!.relationship != null)
                        _buildInfoCard(
                          icon: Icons.family_restroom_outlined,
                          title: 'Mối quan hệ',
                          value: _member!.emergencyContact!.relationship!,
                        ),
                    ],

                    const SizedBox(height: 24),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/member/change-password',
                          );
                        },
                        icon: const Icon(Icons.lock_outline),
                        label: const Text('Đổi mật khẩu'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
