import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart';
import '../models/place.dart';
import '../models/user.dart';
import '../widgets/category_chip.dart';
import '../widgets/place_card.dart';
import 'map_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';
import 'place_detail_screen.dart';
import 'admin_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final Set<PlaceCategory> _selectedCategories = {
    PlaceCategory.restaurante,
    PlaceCategory.cafeteria,
  };

  AppUser? _user;
  Position? _position;
  List<Place> _places = [];
  List<Place> _favorites = [];
  List<Place> _featured = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _refreshFavorites();
    _refreshFeatured();
    _load();
  }

  Future<void> _loadUser() async {
    final user = await AppServices.instance.auth.currentUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _refreshFavorites() async {
    final favs = await AppServices.instance.favorites.getFavorites();
    if (mounted) setState(() => _favorites = favs);
  }

  Future<void> _refreshFeatured() async {
    final featured = await AppServices.instance.featuredPlaces.getFeatured();
    if (mounted) setState(() => _featured = featured);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pos = await AppServices.instance.location.getCurrentPosition();
      if (mounted) setState(() => _position = pos);

      List<Place> places = [];
      const radios = [1500, 5000, 15000, 30000];
      for (final radius in radios) {
        places = await AppServices.instance.places.searchNearby(
          lat: pos.latitude,
          lon: pos.longitude,
          categories: _selectedCategories.toList(),
          radiusMeters: radius,
        );
        if (places.isNotEmpty) break;
      }
      setState(() {
        _places = places;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Set<String> get _favoriteIds => _favorites.map((f) => f.id).toSet();

  Future<void> _toggleFavorite(Place place) async {
    if (_favoriteIds.contains(place.id)) {
      await AppServices.instance.favorites.remove(place.id);
    } else {
      await AppServices.instance.favorites.add(place);
    }
    await _refreshFavorites();
  }

  void _openDetail(Place place) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaceDetailScreen(
          place: place,
          isFavorite: _favoriteIds.contains(place.id),
          onToggleFavorite: () => _toggleFavorite(place),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user?.isAdmin ?? false;
    final combinedPlaces = [..._featured, ..._places];

    final screens = [
      _buildExploreTab(),
      MapScreen(position: _position, places: combinedPlaces),
      FavoritesScreen(
        favorites: _favorites,
        onOpen: (p) => _openDetail(p),
        onToggleFavorite: (p) => _toggleFavorite(p),
      ),
      const ProfileScreen(),
      if (isAdmin) AdminHomeScreen(onChanged: _refreshFeatured),
    ];

    final destinations = [
      const NavigationDestination(icon: Icon(Icons.explore), label: 'Explora'),
      const NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
      const NavigationDestination(icon: Icon(Icons.star), label: 'Favoritos'),
      const NavigationDestination(icon: Icon(Icons.person), label: 'Perfil'),
      if (isAdmin)
        const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
    ];

    final index = _tabIndex >= screens.length ? 0 : _tabIndex;

    return Scaffold(
      body: SafeArea(child: screens[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          if (i == 4) _refreshFeatured(); // refresca al entrar a Admin
        },
        destinations: destinations,
      ),
    );
  }

  Widget _buildExploreTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Expanded(
                child: Text('Explora destinos',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _load();
                  _refreshFeatured();
                },
                tooltip: 'Actualizar',
              ),
            ],
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: PlaceCategory.values.map((c) {
              final selected = _selectedCategories.contains(c);
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: CategoryChip(
                  category: c,
                  selected: selected,
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedCategories.remove(c);
                      } else {
                        _selectedCategories.add(c);
                      }
                    });
                    _load();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              if (_featured.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('Destacados por el administrador',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                ..._featured.map((place) => PlaceCard(
                      place: place,
                      isFavorite: _favoriteIds.contains(place.id),
                      onTap: () => _openDetail(place),
                      onToggleFavorite: () => _toggleFavorite(place),
                    )),
                const Divider(height: 24),
              ],
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(_error!, textAlign: TextAlign.center),
                )
              else if (_places.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: Text('No se encontraron lugares cercanos con '
                          'esas categorías.')),
                )
              else
                ..._places.map((place) => PlaceCard(
                      place: place,
                      isFavorite: _favoriteIds.contains(place.id),
                      onTap: () => _openDetail(place),
                      onToggleFavorite: () => _toggleFavorite(place),
                    )),
            ],
          ),
        ),
      ],
    );
  }
}
