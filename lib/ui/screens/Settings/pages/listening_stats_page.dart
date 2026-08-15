import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/listening_stats_service.dart';

class ListeningStatsPage extends StatefulWidget {
  const ListeningStatsPage({super.key});

  @override
  State<ListeningStatsPage> createState() => _ListeningStatsPageState();
}

class _ListeningStatsPageState extends State<ListeningStatsPage> {
  bool _loading = true;
  int _minutes = 0;
  int _activeDays = 0;
  List<MapEntry<String, int>> _topSongs = const [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!Get.isRegistered<ListeningStatsService>()) return;
    final service = Get.find<ListeningStatsService>();
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 29));
    final days = service.getRecentStats(30);
    if (!mounted) return;
    setState(() {
      _minutes = service.getTotalTimeInRange(start, now) ~/ 60;
      _activeDays = days.length;
      _topSongs = service.getTopSongs(start, now, limit: 5);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Stats'),
        actions: [
          IconButton(
            tooltip: 'Refresh statistics',
            onPressed: () {
              setState(() => _loading = true);
              _loadStats();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scheme.primary,
                          Color.alphaBlend(
                            scheme.secondary.withValues(alpha: 0.55),
                            scheme.primary,
                          ),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insights_rounded, color: scheme.onPrimary, size: 40),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            'Your listening, your rhythm.\nA 30-day snapshot of your music life.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: _statCard(context, Icons.timer_outlined, '$_minutes min', 'Listening time')),
                      const SizedBox(width: 12),
                      Expanded(child: _statCard(context, Icons.calendar_month_outlined, '$_activeDays', 'Active days')),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text('Your top tracks', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  if (_topSongs.isEmpty)
                    _emptyState(context)
                  else
                    ..._topSongs.asMap().entries.map(
                      (entry) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: CircleAvatar(
                          backgroundColor: scheme.primary.withValues(alpha: 0.12),
                          foregroundColor: scheme.primary,
                          child: Text('${entry.key + 1}', style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                        title: Text(entry.value.key, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${entry.value.value ~/ 60} min listened'),
                        trailing: Icon(Icons.equalizer_rounded, color: scheme.secondary),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _statCard(BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.secondary),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        'Play a few songs and your personal listening story will appear here.',
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
