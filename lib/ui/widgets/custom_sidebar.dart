import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shivaaymusic/utils/helper.dart';

/// Custom animated sidebar with configurable logo size and title
class CustomSideBarAnimated extends StatefulWidget {
  final ValueChanged<int>? onTap;
  final Color sideBarColor;
  final Duration sideBarAnimationDuration;
  final Duration floatingAnimationDuration;
  final Color animatedContainerColor;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final Color dividerColor;
  final Color hoverColor;
  final Color splashColor;
  final Color highlightColor;
  final Color unSelectedTextColor;
  final double widthSwitch;
  final double borderRadius;
  final double sideBarWidth;
  final double sideBarSmallWidth;
  final String mainLogoImage;
  final Size? mainLogoSize; // New property for logo size
  final String? mainLogoTitle; // New property for logo title
  final List<SideBarItem> sidebarItems;
  final bool settingsDivider;
  final Curve curve;
  final TextStyle textStyle;

  const CustomSideBarAnimated({
    super.key,
    this.onTap,
    this.sideBarColor = const Color(0xff1D1D1D),
    this.animatedContainerColor = const Color(0xff323232),
    this.unSelectedTextColor = const Color(0xffA0A5A9),
    this.selectedIconColor = Colors.white,
    this.unselectedIconColor = const Color(0xffA0A5A9),
    this.hoverColor = Colors.black38,
    this.splashColor = Colors.black87,
    this.highlightColor = Colors.black,
    this.borderRadius = 20,
    this.sideBarWidth = 260,
    this.sideBarSmallWidth = 84,
    this.settingsDivider = true,
    this.curve = Curves.easeOut,
    this.sideBarAnimationDuration = const Duration(milliseconds: 700),
    this.floatingAnimationDuration = const Duration(milliseconds: 500),
    this.dividerColor = const Color(0xff929292),
    this.textStyle = const TextStyle(fontFamily: "SFPro", fontSize: 16),
    required this.mainLogoImage,
    this.mainLogoSize, // Optional logo size
    this.mainLogoTitle, // Optional logo title
    required this.sidebarItems,
    required this.widthSwitch,
  });

  @override
  State<CustomSideBarAnimated> createState() => _CustomSideBarAnimatedState();
}

class _CustomSideBarAnimatedState extends State<CustomSideBarAnimated>
    with SingleTickerProviderStateMixin {
  late double _width;
  late double _height;
  late double sideBarItemHeight = 48;
  double _itemIndex = 0.0;
  bool _minimize = false;
  late AnimationController _animationController;

  @override
  void initState() {
    if (widget.sidebarItems.isEmpty) {
      throw "Side bar Items Can't be empty";
    }
    _animationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200))
      ..addListener(() {
        setState(() {});
      });
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void moveToNewIndex(int index) {
    setState(() {
      _itemIndex = index.toDouble();
    });
    widget.onTap?.call(index);
  }

  /// Handles the share button press
  void _onSharePressed(BuildContext context) {
    const String shareText = '🎧🔥 Tired of ads ruining your music vibe?\n\n'
        '🎶 Dive into pure music bliss with ShivaayMusic – your FREE high-quality music streaming app with ZERO ADS!\n\n'
        'Whether you\'re chilling, working, or vibing solo – ShivaayMusic has the perfect track for every mood.\n\n'
        '𝘿𝙤𝙬𝙣𝙡𝙤𝙖𝙙 ShivaayMusic 𝘼𝙥𝙥 𝙛𝙧𝙤𝙢 𝙝𝙚𝙧𝙚 👇👇 \n\n'
        'https://shivaaymusic.netlify.app/\n\n'
        '🎵 No Ads.\n\n'
        '🎵 High Quality.\n\n'
        '🎵 100% Free.\n\n'
        '✨ Let the music chill your soul – Share the vibe with your friends! 🔁💙';
    
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    _height = MediaQuery.sizeOf(context).height;
    _width = MediaQuery.sizeOf(context).width;

    
    // Use custom logo size or default to 48x48
    final logoWidth = widget.mainLogoSize?.width ?? 48;
    final logoHeight = widget.mainLogoSize?.height ?? 48;

    return AnimatedContainer(
      curve: widget.curve,
      height: _height,
      margin: const EdgeInsets.all(20),
      width: _width >= widget.widthSwitch && !_minimize
          ? widget.sideBarWidth
          : widget.sideBarSmallWidth,
      decoration: BoxDecoration(
        color: widget.sideBarColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      duration: widget.sideBarAnimationDuration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
                left: _width >= widget.widthSwitch && !_minimize ? 20 : 18,
                top: 15),
            child: Row(
              children: [
                Image.asset(
                  widget.mainLogoImage,
                  width: logoWidth,
                  height: logoHeight,
                ),
                if (widget.mainLogoTitle != null && 
                    _width >= widget.widthSwitch && !_minimize)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Text(
                      widget.mainLogoTitle!,
                      style: TextStyle(
                        fontFamily: 'DancingScript',
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                  top: 20,
                  left: _width >= widget.widthSwitch && !_minimize ? 20 : 18,
                  right: _width >= widget.widthSwitch && !_minimize ? 20 : 18,
                  bottom: 24),
              child: Column(
                children: [
                  SizedBox(
                    height: 786.0,
                    child: Stack(
                      children: [
                        ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            // Check if this is one of our additional buttons
                            if (index == widget.sidebarItems.length) {
                              // Telegram button
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () async {
                                    final url = 'https://t.me/Shivaay20005';
                                    await launchUrlSafe(url);
                                  },
                                  child: Container(
                                    height: sideBarItemHeight,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.telegram,
                                          color: widget.unselectedIconColor,
                                        ),
                                        if (_width >= widget.widthSwitch && !_minimize)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 12.0),
                                            child: Text(
                                              'Telegram Channel',
                                              style: widget.textStyle.copyWith(color: widget.unSelectedTextColor),
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else if (index == widget.sidebarItems.length + 1) {
                              // Share button
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _onSharePressed(context),
                                  child: Container(
                                    height: sideBarItemHeight,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.share,
                                          color: widget.unselectedIconColor,
                                        ),
                                        if (_width >= widget.widthSwitch && !_minimize)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 12.0),
                                            child: Text(
                                              'Share App',
                                              style: widget.textStyle.copyWith(color: widget.unSelectedTextColor),
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              // Regular sidebar items
                              return sideBarItem(
                                  textStyle: widget.textStyle,
                                  unselectedIconColor: widget.unselectedIconColor,
                                  unSelectedTextColor: widget.unSelectedTextColor,
                                  widthSwitch: widget.widthSwitch,
                                  minimize: _minimize,
                                  height: sideBarItemHeight,
                                  hoverColor: widget.hoverColor,
                                  splashColor: widget.splashColor,
                                  highlightColor: widget.highlightColor,
                                  width: _width,
                                  icon:
                                      widget.sidebarItems[index].iconUnselected ??
                                          widget.sidebarItems[index].iconSelected,
                                  text: widget.sidebarItems[index].text,
                                  onTap: () => moveToNewIndex(index));
                            }
                          },
                          separatorBuilder: (context, index) {
                            if (index == widget.sidebarItems.length - 1 &&
                                widget.settingsDivider) {
                              return Divider(
                                height: 12,
                                thickness: 0.2,
                                color: widget.dividerColor,
                              );
                            } else {
                              return const SizedBox(
                                height: 8,
                              );
                            }
                          },
                          itemCount: widget.sidebarItems.length + 2,
                        ),
                        AnimatedPositioned(
                          duration: widget.floatingAnimationDuration,
                          curve: widget.curve,
                          top: _itemIndex * (sideBarItemHeight + 8),
                          left: 0,
                          right: 0,
                          height: sideBarItemHeight,
                          child: Container(
                            height: sideBarItemHeight,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: widget.animatedContainerColor,
                                borderRadius: BorderRadius.circular(12)),
                            child: ListView(
                              shrinkWrap: false,
                              clipBehavior: Clip.antiAliasWithSaveLayer,
                              scrollDirection: Axis.horizontal,
                              children: [
                                Icon(
                                  widget.sidebarItems[_itemIndex.floor()]
                                      .iconSelected,
                                  color: widget.selectedIconColor,
                                ),
                                if (_width >= widget.widthSwitch && !_minimize)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0),
                                    child: Text(
                                      widget.sidebarItems[_itemIndex.floor()]
                                          .text,
                                      overflow: TextOverflow.ellipsis,
                                      style: widget.textStyle.copyWith(color: widget.selectedIconColor),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_width >= widget.widthSwitch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: IconButton(
                  hoverColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: () {
                    setState(() => _minimize = !_minimize);
                  },
                  icon: Icon(
                      _width >= widget.widthSwitch && _minimize
                          ? Icons.keyboard_double_arrow_right
                          : Icons.keyboard_double_arrow_left,
                      color: widget.unselectedIconColor)),
            )
        ],
      ),
    );
  }

  Widget sideBarItem({
    required TextStyle textStyle,
    required Color unselectedIconColor,
    required Color unSelectedTextColor,
    required double widthSwitch,
    required bool minimize,
    required double height,
    required Color hoverColor,
    required Color splashColor,
    required Color highlightColor,
    required double width,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: unselectedIconColor,
              ),
              if (width >= widthSwitch && !minimize)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    text,
                    style: textStyle.copyWith(color: unSelectedTextColor),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class SideBarItem {
  final IconData iconSelected;
  final IconData? iconUnselected;
  final String text;

  SideBarItem({
    required this.iconSelected,
    this.iconUnselected,
    required this.text,
  });
}