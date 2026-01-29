import 'package:flutter/widgets.dart';

class VidyarambhLogo extends StatelessWidget {
  final double size;
  const VidyarambhLogo({this.size = 64, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'packages/management_org/assets/Vidyarambh.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
