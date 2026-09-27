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
      child: SizedBox(
        width: 85,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? const Color.fromARGB(255, 49, 53, 155)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Text(
                category.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),

            const SizedBox(height: 6),

            Text(
              category.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                color: selected
                    ? const Color.fromARGB(255, 52, 60, 174)
                    : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}