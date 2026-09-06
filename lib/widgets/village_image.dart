import 'package:flutter/material.dart';
import 'generated_image.dart';  

class VillageImage extends StatelessWidget {
  final double width;
  final double height;
  final String villageName;

  const VillageImage({
    super.key,
    this.width = 50,
    this.height = 50,
    required this.villageName,
  });
 
  Color _getColorFromName(String name) {
    if (name.isEmpty) return Colors.blueGrey;
     
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
     
    int red = 55 + (((hash & 0xFF0000) >> 16) % 200);
    int green = 55 + (((hash & 0x00FF00) >> 8) % 200);
    int blue = 55 + ((hash & 0x0000FF) % 200);
    
    return Color.fromRGBO(red, green, blue, 1);
  }

  @override
  Widget build(BuildContext context) { 
    String firstLetter = villageName.isNotEmpty ? villageName[0].toUpperCase() : 'D';

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: GeneratedImageWidget(
          width: width,
          height: height,
          letter: firstLetter,
          color: _getColorFromName(villageName),
        ),
      ),
    );
  }
}