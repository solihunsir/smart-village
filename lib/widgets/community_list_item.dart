import 'package:flutter/material.dart';
import '../models/community.dart';
import '../widgets/village_image.dart';
class CommunityListItem extends StatelessWidget {
final Community community;
final VoidCallback onTap;
const CommunityListItem({
Key? key,
required this.community,
required this.onTap,
}) : super(key: key);
@override
Widget build(BuildContext context) {
return GestureDetector(
onTap: onTap,
child: Container(
margin: const EdgeInsets.only(bottom: 12),
decoration: BoxDecoration(
gradient: LinearGradient(
begin: Alignment.topLeft,
end: Alignment.bottomRight,
colors: [Colors.white, Colors.grey[50]!],
),
borderRadius: BorderRadius.circular(16),
boxShadow: [
BoxShadow(
color: const Color.fromRGBO(0, 0, 0, 0.08),
blurRadius: 12,
offset: const Offset(0, 4),
spreadRadius: 0,
),
BoxShadow(
color: const Color.fromRGBO(0, 0, 0, 0.04),
blurRadius: 6,
offset: const Offset(0, 2),
spreadRadius: 0,
),
],
),
child: Padding(
padding: const EdgeInsets.all(16),
child: Row(
children: [
Container(
decoration: BoxDecoration(
shape: BoxShape.circle,
boxShadow: [
BoxShadow(
color: const Color.fromRGBO(0, 0, 0, 0.1),
blurRadius: 8,
offset: const Offset(0, 2),
),
],
),
child: VillageImage(
villageName: community.name,
width: 56,
height: 56,
),
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
community.name,
style: const TextStyle(
fontSize: 16,
fontWeight: FontWeight.w600,
color: Colors.black87,
),
),
const SizedBox(height: 4),
Text(
'Area Balai Desa',
style: TextStyle(
fontSize: 13,
color: Colors.grey[600],
fontWeight: FontWeight.w400,
),
),
const SizedBox(height: 2),
Text(
'${_formatDate()}',
style: TextStyle(
fontSize: 12,
color: Colors.blue[600],
fontWeight: FontWeight.w500,
),
),
],
),
),
Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: Colors.grey[100],
shape: BoxShape.circle,
),
child: Icon(
Icons.chevron_right,
color: Colors.grey[600],
size: 20,
),
),
],
),
),
),
);
}
String _formatDate() {
final now = DateTime.now();
return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
}
}

