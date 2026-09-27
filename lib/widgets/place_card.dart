import 'package:flutter/material.dart';
import '../models/place.dart';

class PlaceCard extends StatelessWidget {
  final Place place;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const PlaceCard({
    super.key,
    required this.place,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF3AA6B9).withOpacity(0.15),
          child: Text(place.category.emoji),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(place.name,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            if (place.isFeatured) ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, size: 16, color: Colors.amber),
            ],
          ],
        ),
        subtitle: Text(
          place.address?.isNotEmpty == true
              ? place.address!
              : place.category.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? Colors.amber : Colors.grey,
          ),
          onPressed: onToggleFavorite,
        ),
      ),
    );
  }
}
