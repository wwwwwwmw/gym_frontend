import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_frontend/core/api_client.dart';
import 'member_schedule_model.dart';
import 'member_schedule_service.dart';

class MemberScheduleScreen extends StatefulWidget {
  const MemberScheduleScreen({super.key});

  @override
  State<MemberScheduleScreen> createState() => _MemberScheduleScreenState();
}

class _MemberScheduleScreenState extends State<MemberScheduleScreen> {
  late final MemberScheduleService _service;
  bool _loading = true;
  String? _error;
  List<MemberScheduleItem> _items = [];

  final _dateFmt = DateFormat('EEEE, dd/MM/yyyy', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _service = MemberScheduleService(ApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForNextDays(14); // lấy lịch 14 ngày tới
    });
  }

  Future<void> _loadForNextDays(int days) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day);
    final to = from.add(Duration(days: days));

    try {
      final list = await _service.getSchedule(from: from, to: to);
      setState(() {
        _items = list;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch tập của tôi'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            )
          : _items.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: () => _loadForNextDays(14),
              child: _buildList(colorScheme),
            ),
    );
  }

  Widget _buildEmpty() => ListView(
    padding: const EdgeInsets.all(16),
    children: const [
      Text('Hiện tại bạn chưa có lịch tập nào trong thời gian sắp tới.'),
    ],
  );

  Widget _buildList(ColorScheme colorScheme) {
    // group theo ngày
    final Map<String, List<MemberScheduleItem>> grouped = {};
    for (final item in _items) {
      final key = DateTime(
        item.date.year,
        item.date.month,
        item.date.day,
      ).toIso8601String();
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final date = DateTime.parse(key);
        final items = grouped[key]!
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dateFmt.format(date),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...items.map((e) => _buildScheduleTile(e, colorScheme)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildScheduleTile(MemberScheduleItem item, ColorScheme colorScheme) {
    final trainer = item.trainerName != null && item.trainerName!.isNotEmpty
        ? 'HLV: ${item.trainerName}'
        : null;
    final pkg = item.packageName != null && item.packageName!.isNotEmpty
        ? item.packageName
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFEAEA),
          child: Icon(Icons.fitness_center, color: colorScheme.error),
        ),
        title: Text('${item.startTime} – ${item.endTime}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pkg != null) Text(pkg),
            if (trainer != null) Text(trainer),
            if (item.note != null && item.note!.isNotEmpty)
              Text(
                item.note!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
