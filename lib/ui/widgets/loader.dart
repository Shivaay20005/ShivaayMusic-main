import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double strokeWidth;
  final double? value;
  final double dimension;

  /// Colour of the indicator. Defaults to the theme's title colour, which is
  /// unreadable on some surfaces (for example a white spinner on a white
  /// player). Callers should pass the colour of the surface it sits on.
  final Color? color;
  const LoadingIndicator(
      {super.key,
      this.strokeWidth = 4,
      this.dimension = 25,
      this.value,
      this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
        dimension: dimension,
        child: CircularProgressIndicator(
          value: value,
          strokeWidth: strokeWidth,
          color: color ?? Theme.of(context).textTheme.titleLarge?.color,
        ));
  }
}
