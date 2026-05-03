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
    final voiceIndicatorColor = _pickVoiceIndicatorColor(context);
    // On Android/iOS, the parent scaffold already shows the custom AppHeaderBar.
    // Avoid double top padding which creates a large gap.
    final topPadding =
        (GetPlatform.isAndroid || GetPlatform.isIOS) ? 10.0 : (context.isLandscape ? 30.0 : 25.0);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Obx(
        () => Row(
          children: [
            settingsScreenController.isBottomNavBarEnabled.isFalse
                ? Container(
                    width: 60,
                    color:
                        Theme.of(context).navigationRailTheme.backgroundColor,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: topPadding),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back_ios_new,
                              color: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .color,
                            ),
                            onPressed: () {
                              Get.nestedKey(ScreenNavigationSetup.id)!
                                  .currentState!
                                  .pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(
                    width: 15,
                  ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: topPadding, left: 5),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "search".tr,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ModifiedTextField(
                      textCapitalization: TextCapitalization.sentences,
                      controller: searchScreenController.textInputController,
                      textInputAction: TextInputAction.search,
                      onChanged: searchScreenController.onChanged,
                      onSubmitted: searchScreenController.submitSearchQuery,
                      autofocus: settingsScreenController
                          .isBottomNavBarEnabled.isFalse,
                      cursorColor:
                          Theme.of(context).textTheme.bodySmall!.color,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(left: 5),
                        focusColor: Theme.of(context).colorScheme.primary,
                        hintText: "searchDes".tr,
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (GetPlatform.isAndroid)
                              ListeningMicButton(
                                isListening:
                                    searchScreenController.isListening.value,
                                onPressed:
                                    searchScreenController.toggleVoiceSearch,
                              activeColor: voiceIndicatorColor,
                                tooltip: 'Voice search',
                              ),
                            IconButton(
                              onPressed: searchScreenController.reset,
                              icon: const Icon(Icons.close),
                              splashRadius: 16,
                              iconSize: 19,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (GetPlatform.isAndroid)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: searchScreenController.isListening.value
                            ? Padding(
                                key: const ValueKey('listening-banner'),
                                padding: const EdgeInsets.only(top: 8.0),
                                child: ListeningStatusBanner(
                                  color: voiceIndicatorColor,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    Expanded(
                      child: Obx(() {
                        final isEmpty = searchScreenController
                                .suggestionList.isEmpty ||
                            searchScreenController.textInputController.text ==
                                "";
                        final list = isEmpty
                            ? searchScreenController.historyQuerylist.toList()
                            : searchScreenController.suggestionList.toList();
                        return ListView(
                            padding: const EdgeInsets.only(top: 5, bottom: 400),
                            physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics()),
                            children: searchScreenController.urlPasted.isTrue
                                ? [
                                    InkWell(
                                      onTap: () {
                                        searchScreenController.filterLinks(
                                            Uri.parse(searchScreenController
                                                .textInputController.text));
                                        searchScreenController.reset();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        child: SizedBox(
                                          width: double.maxFinite,
                                          height: 60,
                                          child: Center(
                                              child: Text(
                                            "urlSearchDes".tr,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          )),
                                        ),
                                      ),
                                    )
                                  ]
                                : list
                                    .map((item) => SearchItem(
                                        queryString: item,
                                        isHistoryString: isEmpty))
                                    .toList());
                      }),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
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
    final bg = Theme.of(context).canvasColor;
    final bannerBg = Color.alphaBlend(widget.color.withValues(alpha: 0.24), bg);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.color.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          _AnimatedVoiceBars(controller: _controller, color: widget.color),
          const SizedBox(width: 8),
          Text(
            'Listening...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: widget.color,
                  fontWeight: FontWeight.w600,
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
