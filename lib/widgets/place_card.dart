import 'dart:io';

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

  static const Color _primaryColor = Color.fromARGB(
    255,
    58,
    64,
    185,
  );

  @override
  Widget build(BuildContext context) {
    final hasImage =
        place.imagePath != null && place.imagePath!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 7),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // IMAGEN O EMOJI
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child: hasImage
                      ? Image.file(
                          File(place.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return _buildPlaceholder();
                          },
                        )
                      : _buildPlaceholder(),
                ),
              ),

              const SizedBox(width: 14),

              // INFORMACIÓN DEL LUGAR
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        if (place.isFeatured) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified_rounded,
                            size: 18,
                            color: Colors.amber,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    // CATEGORÍA
                    Row(
                      children: [
                        Text(
                          place.category.emoji,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            place.category.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // DIRECCIÓN
                    if (place.address?.isNotEmpty == true) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: Colors.black45,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              place.address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // DESCRIPCIÓN PARA DESTACADOS
                    if (place.isFeatured &&
                        place.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 5),
                      Text(
                        place.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 4),

              // FAVORITO
              IconButton(
                tooltip: isFavorite
                    ? 'Quitar de favoritos'
                    : 'Agregar a favoritos',
                icon: Icon(
                  isFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: isFavorite
                      ? Colors.amber
                      : Colors.grey,
                ),
                onPressed: onToggleFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _primaryColor.withOpacity(0.10),
      alignment: Alignment.center,
      child: Text(
        place.category.emoji,
        style: const TextStyle(
          fontSize: 30,
        ),
      ),
    );
  }
}