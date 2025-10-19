import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../registrations/registration_service.dart';
import '../registrations/registration_model.dart';

// Vietnamese weekday names, Monday=1 ... Sunday=7
const Map<int, String> _dayNamesVi = {
  1: 'Thứ 2',
  2: 'Thứ 3',
  3: 'Thứ 4',
  4: 'Thứ 5',
  5: 'Thứ 6',
  6: 'Thứ 7',
  7: 'Chủ nhật',
};

class MemberScheduleScreen extends StatefulWidget {
  const MemberScheduleScreen({super.key});

  @override
  State<MemberScheduleScreen> createState() => _MemberScheduleScreenState();
}

class _MemberScheduleScreenState extends State<MemberScheduleScreen> {
  final _api = ApiClient();

  // Active registration (for display only)
  bool _loadingRegs = true;
  String? _regsError;
  List<RegistrationModel> _activeRegs = const [];

  // Weekly preferences: map day (1..7) -> shift ('morning'|'afternoon')
  bool _prefsLoading = true;
  final Map<int, String> _weekly = {}; // selected days only
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPrefs();
      await _loadRegsAndChanges();
    });
  }

  Future<void> _loadRegsAndChanges() async {
    setState(() {
      _loadingRegs = true;
      _regsError = null;
    });
    try {
      final svc = RegistrationService(ApiClient());
      final active = await svc.getSelfActive();
      _activeRegs = active;
      setState(() {});
    } catch (e) {
      setState(() => _regsError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingRegs = false);
    }
  }

  Future<void> _persistPrefsLocal() async {
    final sp = await SharedPreferences.getInstance();
    final entries = _weekly.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    await sp.setStringList(
      'member_schedule_weekly_days',
      entries.map((e) => e.key.toString()).toList(),
    );
    await sp.setStringList(
      'member_schedule_weekly_shifts',
      entries.map((e) => e.value).toList(),
    );
  }

  Future<void> _loadPrefs() async {
    setState(() => _prefsLoading = true);
    const defaults = <int, String>{1: 'morning', 3: 'morning', 5: 'morning'};
    try {
      final json = await _api.getJson('/api/members/me/schedule-preferences');
      final weekly = (json['weekly'] as List?)
          ?.map((e) => {
                'day': int.tryParse('${e['day']}') ?? 0,
                'shift': (e['shift']?.toString().toLowerCase() ?? 'morning'),
              })
          .where((e) => (e['day'] as int) >= 1 && (e['day'] as int) <= 7)
          .toList();
      setState(() {
        _weekly.clear();
        if (weekly != null && weekly.isNotEmpty) {
          for (final it in weekly) {
            _weekly[it['day'] as int] = it['shift'] as String;
          }
        } else {
          _weekly.addAll(defaults);
        }
        _prefsLoading = false;
      });
      // also cache locally
      await _persistPrefsLocal();
    } catch (_) {
      // Fallback to local cache
      final sp = await SharedPreferences.getInstance();
      final days = sp.getStringList('member_schedule_weekly_days');
      final shifts = sp.getStringList('member_schedule_weekly_shifts');
      setState(() {
        _weekly.clear();
        if (days != null && shifts != null && days.length == shifts.length) {
          for (var i = 0; i < days.length; i++) {
            final d = int.tryParse(days[i]) ?? 0;
            final s = shifts[i];
            if (d >= 1 && d <= 7 && (s == 'morning' || s == 'afternoon')) {
              _weekly[d] = s;
            }
          }
        }
        if (_weekly.isEmpty) _weekly.addAll(defaults);
        _prefsLoading = false;
      });
    }
  }

  Future<void> _savePrefs() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final weekly = _weekly.entries
          .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
      final body = {
        'weekly': weekly
            .map((e) => {
                  'day': e.key,
                  'shift': e.value,
                })
            .toList(),
      };
      await _api.putJson('/api/members/me/schedule-preferences', body: body);
    } catch (_) {
      // ignore
    } finally {
      await _persistPrefsLocal();
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu lịch tập')),
        );
      }
    }
  }

  String _shiftVi(String s) => s == 'afternoon' ? 'Chiều' : 'Sáng';

  Widget _prefsSection() {
    if (_prefsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Chọn ngày và ca tập theo tuần'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int d = 1; d <= 7; d++)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilterChip(
                    label: Text(_dayNamesVi[d]!),
                    selected: _weekly.containsKey(d),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _weekly[d] = _weekly[d] ?? 'morning';
                        } else {
                          _weekly.remove(d);
                        }
                        if (_weekly.isEmpty) {
                          _weekly[1] = 'morning';
                          _weekly[3] = 'morning';
                          _weekly[5] = 'morning';
                        }
                      });
                    },
                  ),
                  if (_weekly.containsKey(d))
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'morning', label: Text('Sáng')),
                          ButtonSegment(value: 'afternoon', label: Text('Chiều')),
                        ],
                        selected: {_weekly[d]!},
                        onSelectionChanged: (s) {
                          setState(() => _weekly[d] = s.first);
                        },
                      ),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Bạn đã chọn:\n' +
              ([
                for (final e in _weekly.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key)))
                  '${_dayNamesVi[e.key]}: ${_shiftVi(e.value)}'
              ].join(', ')),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: _saving ? null : _savePrefs,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save),
            label: const Text('Lưu lịch'),
          ),
        )
      ],
    );
  }

  // Nút đổi lịch đã chuyển sang màn hình gói tập, không xử lý tại đây.

  @override
  Widget build(BuildContext context) {
    final hasActive = _activeRegs.isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch tập của tôi')),
      // Nút "Đổi lịch" được chuyển sang màn hình gói tập, không hiển thị ở đây
      body: _loadingRegs
          ? const Center(child: CircularProgressIndicator())
          : _regsError != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _regsError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (hasActive) ...[
                      Text('Gói: ${_activeRegs.first.package.name}')
                    ] else ...[
                      const Text('Chưa có gói tập hiện tại')
                    ],
                    const SizedBox(height: 12),
                    _prefsSection(),
                  ],
                ),
    );
  }
}

