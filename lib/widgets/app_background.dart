import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const footerHeight = 130.0;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final lightStyles = Theme.of(context).extension<LightTextStyles>();

    return Material(
      color: Colors.white,
      child: DefaultTextStyle(
        style: lightStyles?.body ?? const TextStyle(color: Colors.black87),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: SvgPicture.asset(
                  'assets/footer.svg',
                  fit: BoxFit.fitWidth,
                  width: MediaQuery.of(context).size.width,
                ),
              ),
            ),

            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: footerHeight + bottomPadding),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
