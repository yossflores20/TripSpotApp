import 'package:flutter/material.dart';
import '../models/place.dart';

class CategoryChip extends StatelessWidget {
  final PlaceCategory category;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3AA6B9) : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Text(category.emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
