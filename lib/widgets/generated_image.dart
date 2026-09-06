import 'dart:ui' as ui;
import 'package:flutter/material.dart';
class GeneratedImageWidget extends StatelessWidget {
final double width;
final double height;
final String letter;
final Color color;
const GeneratedImageWidget({
Key? key,
required this.width,
required this.height,
required this.letter,
this.color = Colors.blueGrey,
}) : super(key: key);
@override
Widget build(BuildContext context) {
return CustomPaint(
size: Size(width, height),
painter: ImagePainter(letter: letter, color: color),
);
}
}
class ImagePainter extends CustomPainter {
final String letter;
final Color color;
ImagePainter({required this.letter, required this.color});
@override
void paint(Canvas canvas, Size size) {
final paint = Paint()
..color = color
..style = PaintingStyle.fill;
canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
final textStyle = ui.TextStyle(
color: Colors.white,
fontSize: size.width * 0.5,
fontWeight: FontWeight.bold,
);
final paragraphStyle = ui.ParagraphStyle(textAlign: TextAlign.center);
final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
..pushStyle(textStyle)
..addText(letter);
final paragraph = paragraphBuilder.build();
paragraph.layout(ui.ParagraphConstraints(width: size.width));
canvas.drawParagraph(
paragraph,
Offset(0, (size.height - paragraph.height) / 2),
);
}
@override
bool shouldRepaint(covariant CustomPainter oldDelegate) {
return true;
}
}

