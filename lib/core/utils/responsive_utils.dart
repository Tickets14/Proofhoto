import 'package:flutter/material.dart';

/// Lightweight phone-focused responsive helpers.
class ResponsiveSpec {
  const ResponsiveSpec._(this.width);

  final double width;

  static ResponsiveSpec of(BuildContext context) {
    return ResponsiveSpec._(MediaQuery.sizeOf(context).width);
  }

  bool get isCompact => width < 360;
  bool get isRegular => width >= 360 && width < 412;
  bool get isLargePhone => width >= 412;

  double get horizontalPadding {
    if (isCompact) return 12;
    if (isRegular) return 16;
    return 20;
  }

  double value({
    required double compact,
    required double regular,
    double? largePhone,
  }) {
    if (isCompact) return compact;
    if (isLargePhone && largePhone != null) return largePhone;
    return regular;
  }
}

/// Centers content and keeps a readable max width on wider phones/foldables.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.maxWidth = 640,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
