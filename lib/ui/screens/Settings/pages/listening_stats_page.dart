import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
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
  int _selectedDays = 30;
  int _listeningSeconds = 0;
  int _activeDays = 0;
  List<int> _dailyTotals = const [];
  List<MapEntry<String, int>> _topSongs = const [];
  Map<String, Map<String, String>> _songMetadata = const {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats({int? days}) async {
    final range = days ?? _selectedDays;
    if (mounted) setState(() => _loading = true);
    if (!Get.isRegistered<ListeningStatsService>()) return;

    final service = Get.find<ListeningStatsService>();
    final now = DateTime.now();
    final start = now.subtract(Duration(days: range - 1));
    final recentDays = service.getRecentStats(range);
    final topSongs = service.getTopSongs(start, now, limit: 5);
    final metadata = <String, Map<String, String>>{
      for (final song in topSongs)
        song.key: service.getSongMetadata(song.key, start, now),
    };

    if (!mounted) return;
    setState(() {
      _selectedDays = range;
      _listeningSeconds = service.getTotalTimeInRange(start, now);
      _activeDays = recentDays.length;
      _dailyTotals = service.getDailyTotals(range);
      _topSongs = topSongs;
      _songMetadata = metadata;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Listening Stats',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh statistics',
            onPressed: _loading ? null : () => _loadStats(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 44),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: _loading
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          height: MediaQuery.sizeOf(context).height * 0.62,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: scheme.secondary,
                            ),
                          ),
                        )
                      : Column(
                          key: ValueKey(_selectedDays),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _heroCard(context),
                            const SizedBox(height: 18),
                            _periodSelector(context),
                            const SizedBox(height: 18),
                            _overviewCards(context),
                            const SizedBox(height: 18),
                            _chartCard(context),
                            const SizedBox(height: 28),
                            _sectionTitle(
                              context,
                              icon: Icons.auto_awesome_rounded,
                              title: 'Your top tracks',
                              subtitle: 'The songs that defined your days',
                            ),
                            const SizedBox(height: 12),
                            if (_topSongs.isEmpty)
                              _emptyState(context)
                            else
                              ..._topSongs.asMap().entries.map(
                                    (entry) => _trackCard(
                                      context,
                                      rank: entry.key + 1,
                                      song: entry.value,
                                    ),
                                  ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.alphaBlend(
              scheme.secondary.withValues(alpha: 0.82),
              scheme.primary,
            ),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -32,
            top: -40,
            child: _glowCircle(150, Colors.white.withValues(alpha: 0.10)),
          ),
          Positioned(
            right: 44,
            bottom: -42,
            child: _glowCircle(96, Colors.white.withValues(alpha: 0.08)),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'YOUR MUSIC JOURNEY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _formatDuration(_listeningSeconds),
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.4,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'listened in the last $_selectedDays days',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.graphic_eq_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodSelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          _periodButton(context, label: 'Last 7 days', days: 7),
          _periodButton(context, label: 'Last 30 days', days: 30),
        ],
      ),
    );
  }

  Widget _periodButton(
    BuildContext context, {
    required String label,
    required int days,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selectedDays == days;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: selected ? scheme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.secondary.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: selected || _loading ? null : () => _loadStats(days: days),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? scheme.onSecondary : null,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _overviewCards(BuildContext context) {
    final average = _activeDays == 0 ? 0 : _listeningSeconds ~/ _activeDays;
    return Row(
      children: [
        Expanded(
          child: _metricCard(
            context,
            icon: Icons.calendar_month_rounded,
            value: '$_activeDays',
            label: 'Active days',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricCard(
            context,
            icon: Icons.bolt_rounded,
            value: _formatDuration(average),
            label: 'Daily average',
          ),
        ),
      ],
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: scheme.secondary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxSeconds = _dailyTotals.fold<int>(
      0,
      (current, value) => math.max(current, value).toInt(),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(19, 19, 19, 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Listening activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: scheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  maxSeconds == 0 ? 'No activity yet' : 'Peak ${_formatDuration(maxSeconds)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.secondary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 126,
            width: double.infinity,
            child: CustomPaint(
              painter: _ListeningChartPainter(
                values: _dailyTotals,
                lineColor: scheme.secondary,
                gridColor: scheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDays == 7 ? '7 days ago' : '30 days ago',
                style: theme.textTheme.labelSmall,
              ),
              Text('Today', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.secondary, size: 25),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color
                      ?.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _trackCard(
    BuildContext context, {
    required int rank,
    required MapEntry<String, int> song,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final metadata = _songMetadata[song.key] ?? const {};
    final title = metadata['title'] ?? song.key;
    final artist = metadata['artist'] ?? 'Unknown artist';
    final artworkUrl = metadata['artworkUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.055),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              rank.toString().padLeft(2, '0'),
              style: theme.textTheme.labelLarge?.copyWith(
                color: rank == 1 ? scheme.secondary : null,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _trackArtwork(context, artworkUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color
                        ?.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _formatDuration(song.value),
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.secondary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackArtwork(BuildContext context, String url) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      color: scheme.secondary.withValues(alpha: 0.13),
      alignment: Alignment.center,
      child: Icon(Icons.music_note_rounded, color: scheme.secondary),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 54,
        width: 54,
        child: url.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 58,
            width: 58,
            decoration: BoxDecoration(
              color: scheme.secondary.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.headphones_rounded,
              color: scheme.secondary,
              size: 29,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Your story starts with a song',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Play some music and your favorite tracks will appear here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 60) return '$totalSeconds sec';
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours == 0) return '${totalSeconds ~/ 60} min';
    return minutes == 0 ? '$hours hr' : '$hours hr $minutes min';
  }
}

class _ListeningChartPainter extends CustomPainter {
  const _ListeningChartPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  final List<int> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (int line = 0; line < 4; line++) {
      final y = size.height * line / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (values.isEmpty || values.every((value) => value == 0)) return;
    final maxValue = values
        .reduce((current, value) => math.max(current, value).toInt())
        .toDouble();
    final step = values.length == 1 ? size.width : size.width / (values.length - 1);
    final path = Path();
    final fillPath = Path();

    for (int index = 0; index < values.length; index++) {
      final x = step * index;
      final normalized = values[index] / maxValue;
      final y = size.height - (normalized * (size.height - 8)) - 4;
      if (index == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          lineColor.withValues(alpha: 0.30),
          lineColor.withValues(alpha: 0.015),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    final lastX = step * (values.length - 1);
    final lastY = size.height -
        ((values.last / maxValue) * (size.height - 8)) -
        4;
    canvas.drawCircle(
      Offset(lastX, lastY),
      4.5,
      Paint()..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _ListeningChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
