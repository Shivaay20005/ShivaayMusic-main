import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'components/search_item.dart';
import '/ui/screens/Settings/settings_screen_controller.dart';
import '../../widgets/modified_text_field.dart';
import '/ui/navigator.dart';
import 'search_screen_controller.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  Color _pickVoiceIndicatorColor(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.canvasColor;
    final fallbackText = theme.textTheme.titleMedium?.color ?? Colors.white;
    final candidates = <Color>[
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.onSurface,
      fallbackText,
      Colors.white,
      Colors.black,
    ];

    Color best = candidates.first;
    double bestRatio = _contrastRatio(best, background);
    for (final color in candidates.skip(1)) {
      final ratio = _contrastRatio(color, background);
      if (ratio > bestRatio) {
        best = color;
        bestRatio = ratio;
      }
    }
    return best;
  }

  double _contrastRatio(Color a, Color b) {
    final l1 = a.computeLuminance();
    final l2 = b.computeLuminance();
    final brightest = l1 > l2 ? l1 : l2;
    final darkest = l1 > l2 ? l2 : l1;
    return (brightest + 0.05) / (darkest + 0.05);
  }

  @override
  Widget build(BuildContext context) {
    final searchScreenController = Get.put(SearchScreenController());
    final settingsScreenController = Get.find<SettingsScreenController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final voiceIndicatorColor = _pickVoiceIndicatorColor(context);
    final topPadding = (GetPlatform.isAndroid || GetPlatform.isIOS)
        ? 12.0
        : (context.isLandscape ? 30.0 : 25.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: Obx(
        () => Row(
          children: [
            if (settingsScreenController.isBottomNavBarEnabled.isFalse)
              Container(
                width: 64,
                color: theme.navigationRailTheme.backgroundColor,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.only(top: topPadding),
                    child: IconButton(
                      tooltip: 'Back',
                      style: IconButton.styleFrom(
                        backgroundColor: scheme.onSurface.withValues(alpha: 0.07),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () {
                        Get.nestedKey(ScreenNavigationSetup.id)!
                            .currentState!
                            .pop();
                      },
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPadding,
                    left: settingsScreenController.isBottomNavBarEnabled.isTrue
                        ? 18
                        : 14,
                    right: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SearchHeroHeader(theme: theme, scheme: scheme),
                      const SizedBox(height: 22),
                      _SearchField(
                        controller: searchScreenController,
                        voiceIndicatorColor: voiceIndicatorColor,
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: searchScreenController.isListening.value
                            ? Padding(
                                key: const ValueKey('listening-banner'),
                                padding: const EdgeInsets.only(top: 12),
                                child: ListeningStatusBanner(
                                  color: voiceIndicatorColor,
                                ),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('not-listening-banner'),
                              ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: Obx(() {
                          final query = searchScreenController
                              .textInputController.text
                              .trim();
                          final isEmpty = query.isEmpty;
                          final list = isEmpty
                              ? searchScreenController.historyQuerylist.toList()
                              : searchScreenController.suggestionList.toList();

                          if (searchScreenController.urlPasted.isTrue) {
                            return ListView(
                              padding: const EdgeInsets.only(bottom: 360),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _UrlImportCard(
                                  onTap: () {
                                    searchScreenController.filterLinks(
                                      Uri.parse(searchScreenController
                                          .textInputController.text),
                                    );
                                    searchScreenController.reset();
                                  },
                                ),
                              ],
                            );
                          }

                          if (isEmpty && list.isEmpty) {
                            return ListView(
                              padding: const EdgeInsets.only(bottom: 360),
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _SearchEmptyState(
                                  onChipTap: searchScreenController.suggestionInput,
                                ),
                              ],
                            );
                          }

                          if (!isEmpty && list.isEmpty) {
                            return _NoSuggestionState(theme: theme);
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 360),
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 7),
                            itemBuilder: (context, index) => TweenAnimationBuilder<double>(
                              key: ValueKey('${isEmpty ? 'history' : 'suggestion'}-$index-${list[index]}'),
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 180 + (index > 7 ? 180 : index * 25)),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 10 * (1 - value)),
                                  child: child,
                                ),
                              ),
                              child: SearchItem(
                                queryString: list[index].toString(),
                                isHistoryString: isEmpty,
                              ),
                            ),
                          );
                        }),
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
}

class _SearchHeroHeader extends StatelessWidget {
  const _SearchHeroHeader({required this.theme, required this.scheme});

  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.secondary, scheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: scheme.secondary.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Icon(Icons.graphic_eq_rounded, color: scheme.onSecondary),
            ),
            const SizedBox(width: 12),
            Text(
              'search'.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        Text(
          'Find your next vibe.',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 31,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Search songs, artists, albums and playlists',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.62),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.voiceIndicatorColor,
  });

  final SearchScreenController controller;
  final Color voiceIndicatorColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.18 : 0.06,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: ModifiedTextField(
          textCapitalization: TextCapitalization.sentences,
          controller: controller.textInputController,
          textInputAction: TextInputAction.search,
          onChanged: controller.onChanged,
          onSubmitted: controller.submitSearchQuery,
          autofocus: GetPlatform.isDesktop,
          cursorColor: scheme.secondary,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.transparent,
            hintText: 'searchDes'.tr,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.48),
              fontWeight: FontWeight.w600,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 19),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: scheme.secondary,
              size: 25,
            ),
            suffixIcon: Obx(
              () => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (GetPlatform.isAndroid)
                    ListeningMicButton(
                      isListening: controller.isListening.value,
                      onPressed: controller.toggleVoiceSearch,
                      activeColor: voiceIndicatorColor,
                      tooltip: 'Voice search',
                    ),
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: controller.reset,
                    icon: const Icon(Icons.close_rounded),
                    splashRadius: 20,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.onChipTap});

  final Future<void> Function(String) onChipTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const moodChips = ['Chill', 'Focus', 'Workout', 'Party', 'Romantic', 'Devotional'];
    const categoryChips = [
      'Hindi',
      'Punjabi',
      'Bhojpuri',
      'Tamil',
      'Telugu',
      'Malayalam',
      'Bollywood',
      'Indie',
      'Classical',
      'New releases',
      'Trending songs',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 104,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.secondary.withValues(alpha: 0.22),
                  scheme.primary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: scheme.secondary.withValues(alpha: 0.18),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 18,
                  top: 16,
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 44,
                    color: scheme.secondary.withValues(alpha: 0.55),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Start with a mood',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pick a vibe and let the music lead.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.64),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Explore moods',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: moodChips
                .map(
                  (chip) => ActionChip(
                    label: Text(chip),
                    onPressed: () => onChipTap(chip),
                    avatar: Icon(
                      Icons.play_arrow_rounded,
                      size: 17,
                      color: scheme.secondary,
                    ),
                    backgroundColor: scheme.onSurface.withValues(alpha: 0.07),
                    side: BorderSide(
                      color: scheme.onSurface.withValues(alpha: 0.08),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 26),
          Text(
            'Browse by language & style',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: categoryChips
                .map(
                  (chip) => ActionChip(
                    label: Text(chip),
                    onPressed: () => onChipTap(chip),
                    avatar: Icon(
                      Icons.music_note_rounded,
                      size: 17,
                      color: scheme.primary,
                    ),
                    backgroundColor: scheme.primary.withValues(alpha: 0.10),
                    side: BorderSide(
                      color: scheme.primary.withValues(alpha: 0.18),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _NoSuggestionState extends StatelessWidget {
  const _NoSuggestionState({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 46,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              'Keep typing to discover music',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrlImportCard extends StatelessWidget {
  const _UrlImportCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.secondary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.secondary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: scheme.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.link_rounded, color: scheme.onSecondary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Music link detected',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Open this link and start listening.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onTap,
            tooltip: 'Open link',
            style: IconButton.styleFrom(
              backgroundColor: scheme.secondary,
              foregroundColor: scheme.onSecondary,
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

class ListeningMicButton extends StatefulWidget {
  const ListeningMicButton({
    super.key,
    required this.isListening,
    required this.onPressed,
    required this.activeColor,
    this.tooltip,
  });

  final bool isListening;
  final VoidCallback onPressed;
  final Color activeColor;
  final String? tooltip;

  @override
  State<ListeningMicButton> createState() => _ListeningMicButtonState();
}

class _ListeningMicButtonState extends State<ListeningMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant ListeningMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isListening != widget.isListening) {
      _syncAnimationState();
    }
  }

  void _syncAnimationState() {
    if (widget.isListening) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = _pulseController.value;
        final scale = widget.isListening ? (1 + (pulse * 0.14)) : 1.0;
        final glow = widget.isListening ? (0.08 + (pulse * 0.18)) : 0.0;

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isListening
                  ? widget.activeColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              boxShadow: widget.isListening
                  ? [
                      BoxShadow(
                        color: widget.activeColor.withValues(alpha: glow),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              onPressed: widget.onPressed,
              tooltip: widget.tooltip,
              splashRadius: 16,
              iconSize: 21,
              icon: Icon(
                widget.isListening ? Icons.mic : Icons.mic_none,
                color: widget.isListening ? widget.activeColor : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class ListeningStatusBanner extends StatefulWidget {
  const ListeningStatusBanner({super.key, required this.color});

  final Color color;

  @override
  State<ListeningStatusBanner> createState() => _ListeningStatusBannerState();
}

class _ListeningStatusBannerState extends State<ListeningStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.canvasColor;
    final bannerBg = Color.alphaBlend(widget.color.withValues(alpha: 0.24), bg);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: widget.color.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          _AnimatedVoiceBars(controller: _controller, color: widget.color),
          const SizedBox(width: 10),
          Text(
            'Listening for your next song...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: widget.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedVoiceBars extends StatelessWidget {
  const _AnimatedVoiceBars({required this.controller, required this.color});

  final AnimationController controller;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value;
        final h1 = 6.0 + (t * 10);
        final h2 = 6.0 + ((1 - t) * 12);
        final h3 = 6.0 + (t * 8);
        return Row(
          children: [
            _bar(h1),
            const SizedBox(width: 2),
            _bar(h2),
            const SizedBox(width: 2),
            _bar(h3),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
