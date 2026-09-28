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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final Set<PlaceCategory> _selectedCategories = {
    PlaceCategory.restaurante,
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

    if (mounted) {
      setState(() => _user = user);
    }
  }

  Future<void> _refreshFavorites() async {
    final favs = await AppServices.instance.favorites.getFavorites();

    if (mounted) {
      setState(() => _favorites = favs);
    }
  }

  Future<void> _refreshFeatured() async {
    final featured =
        await AppServices.instance.featuredPlaces.getFeatured();

    if (mounted) {
      setState(() => _featured = featured);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pos =
          await AppServices.instance.location.getCurrentPosition();

      if (mounted) {
        setState(() => _position = pos);
      }

      List<Place> places = [];

      const radios = [
        1500,
        5000,
        15000,
        30000,
      ];

      for (final radius in radios) {
        places = await AppServices.instance.places.searchNearby(
          lat: pos.latitude,
          lon: pos.longitude,
          categories: _selectedCategories.toList(),
          radiusMeters: radius,
        );

        if (places.isNotEmpty) {
          break;
        }
      }

      if (mounted) {
        setState(() {
          _places = places;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Set<String> get _favoriteIds =>
      _favorites.map((f) => f.id).toSet();

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

    final combinedPlaces = [
      ..._featured,
      ..._places,
    ];

    final screens = [
      _buildExploreTab(),

      MapScreen(
        position: _position,
        places: combinedPlaces,
      ),

      FavoritesScreen(
        favorites: _favorites,
        onOpen: (p) => _openDetail(p),
        onToggleFavorite: (p) => _toggleFavorite(p),
      ),

      const ProfileScreen(),

    ];

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: 'Explora',
      ),
      const NavigationDestination(
        icon: Icon(Icons.map_outlined),
        selectedIcon: Icon(Icons.map),
        label: 'Mapa',
      ),
      const NavigationDestination(
        icon: Icon(Icons.star_border_rounded),
        selectedIcon: Icon(Icons.star_rounded),
        label: 'Favoritos',
      ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    final index =
        _tabIndex >= screens.length ? 0 : _tabIndex;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: screens[index],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);

          if (isAdmin && i == 4) {
            _refreshFeatured();
          }
        },
        destinations: destinations,
      ),
    );
  }

  Widget _buildExploreTab() {
    return Column(
      children: [
        // Encabezado
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'TripSpot',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 58, 67, 185),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    tooltip: 'Actualizar',
                    onPressed: () {
                      _load();
                      _refreshFeatured();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                _user?.name.isNotEmpty == true
                    ? 'Hola, ${_user!.name} 👋'
                    : 'Hola 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '¿Qué quieres descubrir hoy?',
                style: TextStyle(
                  fontSize: 15,
                  color: const Color.fromARGB(255, 133, 133, 133),
                ),
              ),
            ],
          ),
        ),

        // Buscador
        Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            16,
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar lugares...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
                  const EdgeInsets.symmetric(
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 50, 56, 160),
                ),
              ),
            ),
          ),
        ),

        // Título categorías
        const Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            10,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Explorar categorías',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Categorías
        SizedBox(
          height: 85,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            children:
                PlaceCategory.values.map((c) {
              final selected =
                  _selectedCategories.contains(c);

              return Padding(
                padding:
                    const EdgeInsets.only(right: 10),
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

        // Contenido
        Expanded(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            children: [
              // Lugares destacados
              if (_featured.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Color.fromARGB(255, 45, 52, 147),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Lugares destacados',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                ..._featured.map(
                  (place) => PlaceCard(
                    place: place,
                    isFavorite:
                        _favoriteIds.contains(
                      place.id,
                    ),
                    onTap: () =>
                        _openDetail(place),
                    onToggleFavorite: () =>
                        _toggleFavorite(place),
                  ),
                ),

                const Divider(height: 28),
              ],

              // Lugares cercanos
              const Padding(
                padding: EdgeInsets.only(
                  top: 4,
                  bottom: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Color.fromARGB(255, 50, 58, 163),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Lugares cerca de ti',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              if (_loading)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 40,
                  ),
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 24,
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.location_off_outlined,
                        size: 38,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else if (_places.isEmpty)
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 24,
                  ),
                  child: Center(
                    child: Text(
                      'No se encontraron lugares '
                      'cercanos con esas categorías.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ..._places.map(
                  (place) => PlaceCard(
                    place: place,
                    isFavorite:
                        _favoriteIds.contains(
                      place.id,
                    ),
                    onTap: () =>
                        _openDetail(place),
                    onToggleFavorite: () =>
                        _toggleFavorite(place),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}