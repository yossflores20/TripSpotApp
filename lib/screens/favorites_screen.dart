import 'package:flutter/material.dart';
import '../models/place.dart';
import '../widgets/place_card.dart';

class FavoritesScreen extends StatelessWidget {
  final List<Place> favorites;
  final void Function(Place place) onOpen;
  final void Function(Place place) onToggleFavorite;

  const FavoritesScreen({
    super.key,
    required this.favorites,
    required this.onOpen,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('Tus lugares favoritos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: favorites.isEmpty
              ? const Center(
                  child: Text(
                    'Tus lugares favoritos\naparecerán aquí',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: favorites.length,
                  itemBuilder: (_, i) {
                    final place = favorites[i];
                    return PlaceCard(
                      place: place,
                      isFavorite: true,
                      onTap: () => onOpen(place),
                      onToggleFavorite: () => onToggleFavorite(place),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
