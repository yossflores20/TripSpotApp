import 'package:flutter/material.dart';
import '../main.dart';
import '../models/place.dart';

class AdminFeaturedPlacesScreen extends StatefulWidget {
  const AdminFeaturedPlacesScreen({super.key});

  @override
  State<AdminFeaturedPlacesScreen> createState() =>
      _AdminFeaturedPlacesScreenState();
}

class _AdminFeaturedPlacesScreenState
    extends State<AdminFeaturedPlacesScreen> {
  List<Place> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final places = await AppServices.instance.featuredPlaces.getFeatured();
    setState(() {
      _places = places;
      _loading = false;
    });
  }

  Future<void> _delete(String id) async {
    await AppServices.instance.featuredPlaces.remove(id);
    _load();
  }

  Future<void> _openForm() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();
    PlaceCategory category = PlaceCategory.turistico;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Nuevo lugar destacado'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  DropdownButtonFormField<PlaceCategory>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: PlaceCategory.values
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text('${c.emoji} ${c.label}')))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => category = v ?? category),
                  ),
                  TextFormField(
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Descripción corta'),
                    maxLines: 2,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: latCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Latitud'),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                          validator: (v) => double.tryParse(v ?? '') == null
                              ? 'Número inválido'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: lonCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Longitud'),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true, signed: true),
                          validator: (v) => double.tryParse(v ?? '') == null
                              ? 'Número inválido'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        try {
                          final pos = await AppServices.instance.location
                              .getCurrentPosition();
                          latCtrl.text = pos.latitude.toString();
                          lonCtrl.text = pos.longitude.toString();
                        } catch (_) {}
                      },
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text('Usar mi ubicación actual'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final place = Place(
                  id: 'featured_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  lat: double.parse(latCtrl.text),
                  lon: double.parse(lonCtrl.text),
                  category: category,
                  description: descCtrl.text.trim(),
                  isFeatured: true,
                );
                await AppServices.instance.featuredPlaces.add(place);
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lugares destacados')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _places.isEmpty
              ? const Center(
                  child: Text(
                      'Aún no hay lugares destacados.\nToca + para agregar '
                      'uno.',
                      textAlign: TextAlign.center))
              : ListView.builder(
                  itemCount: _places.length,
                  itemBuilder: (_, i) {
                    final place = _places[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(place.category.emoji)),
                      title: Text(place.name),
                      subtitle: Text(
                          place.description ?? place.category.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () => _delete(place.id),
                      ),
                    );
                  },
                ),
    );
  }
}
