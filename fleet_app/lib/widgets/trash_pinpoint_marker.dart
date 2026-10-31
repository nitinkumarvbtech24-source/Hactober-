import 'package:flutter/material.dart';

class TrashPinpointWidget extends StatelessWidget {
  final VoidCallback? onTap;
  final int count;
  final bool isVeryDirty;
  final double size;

  const TrashPinpointWidget({
    super.key,
    this.onTap,
    this.count = 1,
    this.isVeryDirty = false,
    this.size = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor = isVeryDirty ? const Color(0xFFDC2626) : const Color(0xFFEA580C);
    final Color darkShade = isVeryDirty ? const Color(0xFF991B1B) : const Color(0xFFC2410C);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size + 8,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // Pointer tail
            Positioned(
              bottom: 0,
              child: CustomPaint(
                size: const Size(10, 8),
                painter: _PinTailPainter(color: darkShade),
              ),
            ),
            // Pinhead circle
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [mainColor, darkShade],
                ),
                border: Border.all(color: Colors.white, width: 2.2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.delete_rounded,
                  color: Colors.white,
                  size: size * 0.52,
                ),
              ),
            ),
            // Count badge for clustered detections
            if (count > 1)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
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

class _PinTailPainter extends CustomPainter {
  final Color color;
  _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) => oldDelegate.color != color;
}
