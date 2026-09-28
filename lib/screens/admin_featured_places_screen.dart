import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  static const Color _primaryColor = Color.fromARGB(
    255,
    58,
    64,
    185,
  );

  List<Place> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final places =
        await AppServices.instance.featuredPlaces.getFeatured();

    if (!mounted) return;

    setState(() {
      _places = places;
      _loading = false;
    });
  }

  Future<void> _delete(Place place) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar lugar',
          ),
          content: Text(
            '¿Deseas eliminar "${place.name}" de los lugares destacados?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await AppServices.instance.featuredPlaces.remove(
      place.id,
    );

    await _load();
  }

  Widget _categoryPlaceholder(Place place) {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Text(
        place.category.emoji,
        style: const TextStyle(
          fontSize: 28,
        ),
      ),
    );
  }

  Future<void> _openForm() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lonCtrl = TextEditingController();

    final formKey = GlobalKey<FormState>();

    PlaceCategory category =
        PlaceCategory.turistico;

    XFile? selectedImage;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            Future<void> selectImage() async {
              try {
                final picker = ImagePicker();

                final image =
                    await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );

                if (image != null) {
                  setDialogState(() {
                    selectedImage = image;
                  });
                }
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'No se pudo seleccionar la imagen.',
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(
                    Icons.add_location_alt_outlined,
                    color: _primaryColor,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nuevo lugar destacado',
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        // IMAGEN
                        GestureDetector(
                          onTap: selectImage,
                          child: Container(
                            height: 170,
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .grey.shade100,
                              borderRadius:
                                  BorderRadius
                                      .circular(18),
                              border: Border.all(
                                color: Colors
                                    .grey.shade300,
                              ),
                            ),
                            child:
                                selectedImage ==
                                        null
                                    ? const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .center,
                                        children: [
                                          Icon(
                                            Icons
                                                .add_photo_alternate_outlined,
                                            size: 42,
                                            color:
                                                _primaryColor,
                                          ),
                                          SizedBox(
                                            height:
                                                10,
                                          ),
                                          Text(
                                            'Agregar imagen',
                                            style:
                                                TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),
                                          SizedBox(
                                            height: 4,
                                          ),
                                          Text(
                                            'Seleccionar desde la galería',
                                            style:
                                                TextStyle(
                                              fontSize:
                                                  12,
                                              color: Colors
                                                  .black54,
                                            ),
                                          ),
                                        ],
                                      )
                                    : ClipRRect(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                                    18),
                                        child:
                                            Image.file(
                                          File(
                                            selectedImage!
                                                .path,
                                          ),
                                          width: double
                                              .infinity,
                                          height: 170,
                                          fit: BoxFit
                                              .cover,
                                        ),
                                      ),
                          ),
                        ),

                        if (selectedImage !=
                            null)
                          Align(
                            alignment:
                                Alignment.center,
                            child:
                                TextButton.icon(
                              onPressed:
                                  selectImage,
                              icon: const Icon(
                                Icons
                                    .image_outlined,
                              ),
                              label: const Text(
                                'Cambiar imagen',
                              ),
                            ),
                          ),

                        const SizedBox(
                          height: 12,
                        ),

                        // NOMBRE
                        TextFormField(
                          controller:
                              nameCtrl,
                          textCapitalization:
                              TextCapitalization
                                  .words,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Nombre del lugar',
                            prefixIcon: Icon(
                              Icons
                                  .place_outlined,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value
                                    .trim()
                                    .isEmpty) {
                              return 'Ingresa el nombre del lugar';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // CATEGORÍA
                        DropdownButtonFormField<
                            PlaceCategory>(
                          value: category,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Categoría',
                            prefixIcon: Icon(
                              Icons
                                  .category_outlined,
                            ),
                            border:
                                OutlineInputBorder(),
                          ),
                          items:
                              PlaceCategory
                                  .values
                                  .map(
                            (c) {
                              return DropdownMenuItem<
                                  PlaceCategory>(
                                value: c,
                                child: Text(
                                  '${c.emoji} ${c.label}',
                                ),
                              );
                            },
                          ).toList(),
                          onChanged: (value) {
                            if (value ==
                                null) {
                              return;
                            }

                            setDialogState(
                              () {
                                category =
                                    value;
                              },
                            );
                          },
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // DESCRIPCIÓN
                        TextFormField(
                          controller:
                              descCtrl,
                          textCapitalization:
                              TextCapitalization
                                  .sentences,
                          maxLines: 3,
                          decoration:
                              const InputDecoration(
                            labelText:
                                'Descripción',
                            hintText:
                                'Describe brevemente el lugar',
                            prefixIcon: Icon(
                              Icons
                                  .description_outlined,
                            ),
                            border:
                                OutlineInputBorder(),
                            alignLabelWithHint:
                                true,
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // COORDENADAS
                        Row(
                          children: [
                            Expanded(
                              child:
                                  TextFormField(
                                controller:
                                    latCtrl,
                                keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                  decimal:
                                      true,
                                  signed: true,
                                ),
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Latitud',
                                  border:
                                      OutlineInputBorder(),
                                ),
                                validator:
                                    (value) {
                                  if (double
                                          .tryParse(
                                        value ??
                                            '',
                                      ) ==
                                      null) {
                                    return 'Número inválido';
                                  }

                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                                  TextFormField(
                                controller:
                                    lonCtrl,
                                keyboardType:
                                    const TextInputType
                                        .numberWithOptions(
                                  decimal:
                                      true,
                                  signed: true,
                                ),
                                decoration:
                                    const InputDecoration(
                                  labelText:
                                      'Longitud',
                                  border:
                                      OutlineInputBorder(),
                                ),
                                validator:
                                    (value) {
                                  if (double
                                          .tryParse(
                                        value ??
                                            '',
                                      ) ==
                                      null) {
                                    return 'Número inválido';
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        Align(
                          alignment: Alignment
                              .centerLeft,
                          child:
                              TextButton.icon(
                            onPressed:
                                () async {
                              try {
                                final pos =
                                    await AppServices
                                        .instance
                                        .location
                                        .getCurrentPosition();

                                latCtrl.text =
                                    pos.latitude
                                        .toString();

                                lonCtrl.text =
                                    pos.longitude
                                        .toString();

                                setDialogState(
                                    () {});
                              } catch (e) {
                                if (!context
                                    .mounted) {
                                  return;
                                }

                                ScaffoldMessenger
                                        .of(
                                            context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'No se pudo obtener la ubicación.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.my_location,
                              size: 18,
                            ),
                            label: const Text(
                              'Usar mi ubicación actual',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    if (!formKey
                        .currentState!
                        .validate()) {
                      return;
                    }

                    final place =
                        Place(
                      id: 'featured_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text
                          .trim(),
                      lat: double.parse(
                        latCtrl.text,
                      ),
                      lon: double.parse(
                        lonCtrl.text,
                      ),
                      category:
                          category,
                      description:
                          descCtrl.text
                              .trim(),
                      imagePath:
                          selectedImage
                              ?.path,
                      isFeatured:
                          true,
                    );

                    await AppServices
                        .instance
                        .featuredPlaces
                        .add(place);

                    if (ctx.mounted) {
                      Navigator.pop(
                        ctx,
                      );
                    }

                    await _load();
                  },
                  icon: const Icon(
                    Icons.save_outlined,
                  ),
                  label: const Text(
                    'Guardar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text(
          'Lugares destacados',
        ),
        backgroundColor:
            const Color(0xFFF6F7FB),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: _openForm,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Agregar',
        ),
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _places.isEmpty
              ? _buildEmptyState()
              : _buildPlaces(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration:
                  BoxDecoration(
                color: _primaryColor
                    .withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .location_off_outlined,
                size: 42,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin lugares destacados',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega lugares para que aparezcan como recomendaciones para los usuarios.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaces() {
    return ListView.separated(
      padding:
          const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        100,
      ),
      itemCount: _places.length,
      separatorBuilder: (_, __) =>
          const SizedBox(
        height: 12,
      ),
      itemBuilder: (
        context,
        index,
      ) {
        final place =
            _places[index];

        return Material(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          child: Container(
            padding:
                const EdgeInsets.all(
              12,
            ),
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                      18),
              border: Border.all(
                color: Colors
                    .grey.shade200,
              ),
            ),
            child: Row(
              children: [
                // IMAGEN
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                  child: SizedBox(
                    width: 85,
                    height: 85,
                    child: place
                                .imagePath !=
                            null
                        ? Image.file(
                            File(
                              place
                                  .imagePath!,
                            ),
                            fit: BoxFit
                                .cover,
                            errorBuilder:
                                (
                              _,
                              __,
                              ___,
                            ) {
                              return _categoryPlaceholder(
                                place,
                              );
                            },
                          )
                        : _categoryPlaceholder(
                            place,
                          ),
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        place.name,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        '${place.category.emoji} ${place.category.label}',
                        style:
                            const TextStyle(
                          fontSize: 13,
                          color: Colors
                              .black54,
                        ),
                      ),

                      if (place
                              .description
                              ?.isNotEmpty ==
                          true) ...[
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          place
                              .description!,
                          maxLines: 2,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 12,
                            color: Colors
                                .black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                IconButton(
                  tooltip:
                      'Eliminar',
                  onPressed: () {
                    _delete(place);
                  },
                  icon: const Icon(
                    Icons
                        .delete_outline_rounded,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}