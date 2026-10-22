import 'dart:async';

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
  static const int _radiusMeters = 1500;
  static const double _refreshDistanceMeters = 200;
  static const Duration _minimumSearchInterval = Duration(seconds: 90);
  static const Duration _rateLimitCooldown = Duration(minutes: 5);

  int _tabIndex = 0;
  int _requestId = 0;
  String _searchText = '';
  bool _showAllCategories = true;
  final Set<PlaceCategory> _selectedCategories = {};

  AppUser? _user;
  Position? _position;
  Position? _lastSearchPosition;
  DateTime? _lastSearchTime;
  DateTime? _retryAfter;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _filterDebounce;

  List<Place> _places = [];
  List<Place> _favorites = [];
  List<Place> _featured = [];
  bool _loading = true;
  String? _error;

  List<PlaceCategory> get _activeCategories => _showAllCategories
      ? PlaceCategory.values.toList()
      : _selectedCategories.toList();

  @override
  void initState() {
    super.initState();
    _loadUser();
    _refreshFavorites();
    _refreshFeatured();
    _load();
  }

  @override
  void dispose() {
    _requestId++;
    _locationSubscription?.cancel();
    _filterDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final user = await AppServices.instance.auth.currentUser();
      if (mounted) setState(() => _user = user);
    } catch (_) {
      // No bloquear la búsqueda por un fallo al cargar el perfil.
    }
  }

  Future<void> _refreshFavorites() async {
    try {
      final favs = await AppServices.instance.favorites.getFavorites();
      if (mounted) setState(() => _favorites = favs);
    } catch (_) {
      // La pantalla puede seguir funcionando sin actualizar favoritos.
    }
  }

  Future<void> _refreshFeatured() async {
    try {
      final featured = await AppServices.instance.featuredPlaces.getFeatured();
      if (mounted) setState(() => _featured = featured);
    } catch (_) {
      // La pantalla puede seguir funcionando sin actualizar destacados.
    }
  }

  void _startLocationTracking() {
    if (_locationSubscription != null) return;
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50,
    );
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) {
        if (!mounted) return;
        setState(() => _position = position);

        final previous = _lastSearchPosition;
        if (previous == null || _loading) return;
        final moved = Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          position.latitude,
          position.longitude,
        );
        final now = DateTime.now();
        final timeOk = _lastSearchTime == null ||
            now.difference(_lastSearchTime!) >= _minimumSearchInterval;
        final notLimited = _retryAfter == null || now.isAfter(_retryAfter!);
        if (moved >= _refreshDistanceMeters && timeOk && notLimited) {
          _load(position: position);
        }
      },
      onError: (Object error) {
        if (!mounted) return;
        // Mantener el último punto conocido; el usuario puede reintentar.
        if (_position == null) {
          setState(() => _error = 'No se pudo actualizar la ubicación: $error');
        }
      },
    );
  }

  Future<void> _load({Position? position, bool force = false}) async {
    if (!mounted) return;
    final now = DateTime.now();
    if (_retryAfter != null && now.isBefore(_retryAfter!)) {
      setState(() {
        _loading = false;
        _error = 'El servidor de lugares está ocupado (429). '
            'Espera unos minutos antes de volver a intentar.';
      });
      return;
    }
    // No generar consultas simultáneas por el movimiento o los filtros.
    if (_loading && _lastSearchTime != null && !force) return;

    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pos = position ??
          await AppServices.instance.location.getCurrentPosition();
      if (!mounted || requestId != _requestId) return;
      setState(() => _position = pos);
      _startLocationTracking();

      final categories = _activeCategories;
      if (categories.isEmpty) {
        setState(() {
          _places = [];
          _loading = false;
        });
        return;
      }

      // Guardar la fecha del intento, incluso si el servidor responde 429.
      _lastSearchTime = DateTime.now();
      _lastSearchPosition = pos;
      final results = await AppServices.instance.places.searchNearby(
        lat: pos.latitude,
        lon: pos.longitude,
        categories: categories,
        radiusMeters: _radiusMeters,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _places = results.where((place) {
          return Geolocator.distanceBetween(
                pos.latitude,
                pos.longitude,
                place.lat,
                place.lon,
              ) <= _radiusMeters;
        }).toList();
        _retryAfter = null;
      });
    } catch (error) {
      if (!mounted || requestId != _requestId) return;
      final message = error.toString().replaceFirst('Exception: ', '');
      if (message.contains('429')) {
        _retryAfter = DateTime.now().add(_rateLimitCooldown);
      }
      setState(() => _error = message);
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([_refreshFeatured(), _refreshFavorites()]);
    if (!mounted) return;
    await _load(force: true);
  }

  void _scheduleFilterSearch() {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _load(force: true);
    });
  }

  void _selectAll() {
    if (_showAllCategories) return;
    setState(() {
      _showAllCategories = true;
      _selectedCategories.clear();
    });
    _scheduleFilterSearch();
  }

  void _toggleCategory(PlaceCategory category) {
    if (!_showAllCategories && _selectedCategories.contains(category)) return;
    setState(() {
      _showAllCategories = false;
      _selectedCategories
        ..clear()
        ..add(category);
    });
    _scheduleFilterSearch();
  }

  bool _insideRadius(Place place) {
    final pos = _position;
    if (pos == null) return false;
    return Geolocator.distanceBetween(
          pos.latitude, pos.longitude, place.lat, place.lon,
        ) <= _radiusMeters;
  }

  bool _matchesSearch(Place place) {
    final text = _searchText.trim().toLowerCase();
    if (text.isEmpty) return true;
    return place.name.toLowerCase().contains(text) ||
        (place.address ?? '').toLowerCase().contains(text) ||
        (place.description ?? '').toLowerCase().contains(text) ||
        place.category.label.toLowerCase().contains(text);
  }

  bool _matchesCategory(Place place) =>
      _showAllCategories || _selectedCategories.contains(place.category);

  List<Place> get _visibleFeatured => _featured
      .where(_insideRadius)
      .where(_matchesCategory)
      .where(_matchesSearch)
      .toList();

  List<Place> get _visiblePlaces => _places
      .where(_insideRadius)
      .where(_matchesCategory)
      .where(_matchesSearch)
      .toList();

  Set<String> get _favoriteIds => _favorites.map((f) => f.id).toSet();

  Future<void> _toggleFavorite(Place place) async {
    try {
      if (_favoriteIds.contains(place.id)) {
        await AppServices.instance.favorites.remove(place.id);
      } else {
        await AppServices.instance.favorites.add(place);
      }
      await _refreshFavorites();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar favoritos: $error')),
      );
    }
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
    ).then((_) {
      if (mounted) _refreshFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final combined = <Place>[];
    final ids = <String>{};
    for (final place in [..._visibleFeatured, ..._visiblePlaces]) {
      if (ids.add(place.id)) combined.add(place);
    }

    final screens = <Widget>[
      _buildExploreTab(),
      MapScreen(position: _position, places: combined),
      FavoritesScreen(
        favorites: _favorites,
        onOpen: _openDetail,
        onToggleFavorite: _toggleFavorite,
      ),
      const ProfileScreen(),
    ];

    final destinations = <NavigationDestination>[
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

    final index = _tabIndex >= screens.length ? 0 : _tabIndex;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: screens[index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() => _tabIndex = i);
          if (i == 0 || i == 1) _refreshFeatured();
          if (i == 2) _refreshFavorites();
        },
        destinations: destinations,
      ),
    );
  }

  Widget _buildExploreTab() {
    final featured = _visibleFeatured;
    final nearby = _visiblePlaces;

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('TripSpot', style: TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 58, 67, 185),
                      )),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Actualizar lugares y ubicación',
                      onPressed: _loading ? null : _refreshAll,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _user?.name.isNotEmpty == true
                      ? 'Hola, ${_user!.name} 👋'
                      : 'Hola 👋',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text('¿Qué quieres descubrir hoy?',
                    style: TextStyle(fontSize: 15, color: Colors.grey)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: TextField(
              onChanged: (value) => setState(() => _searchText = value),
              decoration: InputDecoration(
                hintText: 'Buscar lugares...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 10),
            child: Text('Explorar categorías',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _selectAll,
                    child: SizedBox(
                      width: 85,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: _showAllCategories
                                ? const Color(0xFF323AA3)
                                : Colors.grey.shade200,
                            child: const Text('🌎', style: TextStyle(fontSize: 27)),
                          ),
                          const SizedBox(height: 6),
                          Text('Todos', style: TextStyle(
                            fontWeight: _showAllCategories
                                ? FontWeight.bold : FontWeight.normal,
                            color: _showAllCategories
                                ? const Color(0xFF323AA3) : Colors.black87,
                          )),
                        ],
                      ),
                    ),
                  ),
                ),
                ...PlaceCategory.values.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: CategoryChip(
                    category: category,
                    selected: !_showAllCategories &&
                        _selectedCategories.contains(category),
                    onTap: () => _toggleCategory(category),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
          // Los errores de red se indican discretamente; no bloquean destacados.
          if (!_loading && _error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    _retryAfter != null
                        ? 'La búsqueda de lugares está temporalmente limitada. Intenta más tarde.'
                        : 'No se pudieron actualizar los lugares cercanos.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  )),
                ],
              ),
            ),
          if (featured.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: Row(children: [
                Icon(Icons.star_rounded, color: Color(0xFF2D3493)),
                SizedBox(width: 8),
                Text('Lugares destacados', style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold,
                )),
              ]),
            ),
            ...featured.map((place) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildPlaceCard(place),
            )),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 28),
            ),
          ],
          if (!_loading) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(children: [
                Icon(Icons.location_on_rounded, color: Color(0xFF323AA3)),
                SizedBox(width: 8),
                Text('Lugares cerca de ti', style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold,
                )),
              ]),
            ),
            if (nearby.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Center(child: Text(
                  'No se encontraron lugares cercanos con estos filtros.',
                  textAlign: TextAlign.center,
                )),
              )
            else
              ...nearby.map((place) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildPlaceCard(place),
              )),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    return PlaceCard(
      place: place,
      isFavorite: _favoriteIds.contains(place.id),
      onTap: () => _openDetail(place),
      onToggleFavorite: () => _toggleFavorite(place),
    );
  }
}

