import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dari_app/core/constants/app_routes.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/core/constants/app_constants.dart';
import 'package:dari_app/models/property_model.dart';
import 'package:dari_app/providers/auth_provider.dart';
import 'package:dari_app/providers/property_provider.dart';
import 'package:dari_app/widgets/loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class AddPropertyScreen extends ConsumerStatefulWidget {
  final int? propertyId;
  const AddPropertyScreen({super.key, this.propertyId});

  @override
  ConsumerState<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends ConsumerState<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController(text: '2');
  final _bathCtrl = TextEditingController(text: '1');
  final _surfaceCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();

  String _type = 'Appartement';
  String _city = 'Tunis';
  String _priceType = AppConstants.pricePerMonth;
  List<String> _images = [];
  bool _loading = false;
  bool _initialLoading = false;
  PropertyModel? _editingProperty;

  bool get _isEditing => widget.propertyId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _loadProperty();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _priceCtrl.dispose();
    _roomsCtrl.dispose();
    _bathCtrl.dispose();
    _surfaceCtrl.dispose();
    _contactCtrl.dispose();
    _conditionsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProperty() async {
    setState(() => _initialLoading = true);
    final property = await ref
        .read(propertyRepositoryProvider)
        .getPropertyById(widget.propertyId!);
    final user = ref.read(currentUserProvider);

    if (!mounted) return;
    if (property == null || user?.id != property.ownerId) {
      setState(() => _initialLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous ne pouvez modifier que vos propres annonces.'),
          backgroundColor: AppTheme.error,
        ),
      );
      _popAfterFrame();
      return;
    }

    _editingProperty = property;
    _titleCtrl.text = property.title;
    _descCtrl.text = property.description;
    _addressCtrl.text = property.address ?? '';
    _priceCtrl.text = property.price.toStringAsFixed(
        property.price.truncateToDouble() == property.price ? 0 : 2);
    _roomsCtrl.text = property.rooms.toString();
    _bathCtrl.text = property.bathrooms.toString();
    _surfaceCtrl.text = property.surface?.toStringAsFixed(
            property.surface!.truncateToDouble() == property.surface ? 0 : 2) ??
        '';
    _contactCtrl.text = property.contact ?? '';
    _conditionsCtrl.text = property.conditions ?? '';
    _type = property.type;
    _city = property.city;
    _priceType = property.priceType;
    _images = List<String>.from(property.images);
    setState(() => _initialLoading = false);
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(limit: 6);
    if (picked.isNotEmpty) {
      setState(() => _images =
          [..._images, ...picked.map((p) => p.path)].take(6).toList());
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final user = ref.read(currentUserProvider)!;
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expirée. Connectez-vous puis réessayez.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    final repo = ref.read(propertyRepositoryProvider);
    String? errorMessage;

    final property = (_editingProperty ??
            PropertyModel(
              ownerId: authUser.id,
              status: 'published', // auto-approve for MVP
              createdAt: DateTime.now().toIso8601String(),
              title: '',
              description: '',
              type: _type,
              city: _city,
              price: 0,
            ))
        .copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      type: _type,
      city: _city,
      address:
          _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      price: double.parse(_priceCtrl.text),
      priceType: _priceType,
      rooms: int.tryParse(_roomsCtrl.text) ?? 1,
      bathrooms: int.tryParse(_bathCtrl.text) ?? 1,
      surface: double.tryParse(_surfaceCtrl.text),
      contact:
          _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      conditions: _conditionsCtrl.text.trim().isEmpty
          ? null
          : _conditionsCtrl.text.trim(),
      status: 'published',
    );

    int? id;
    bool saved = true;
    try {
      await repo.ensureOwnerProfile(user);
      if (_isEditing) {
        saved = await repo.updateProperty(property);
        id = property.id;
        if (saved && id != null) {
          saved = await repo.replacePropertyImages(id, _images);
        }
      } else {
        id = await repo.addProperty(property);
        if (id != null) {
          for (final img in _images) {
            await repo.addPropertyImage(id, img);
          }
        }
      }
    } catch (e) {
      saved = false;
      errorMessage = e.toString();
      debugPrint('Erreur enregistrement annonce: $e');
    }

    if (!mounted) return;
    setState(() => _loading = false);
    if (!saved || id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(errorMessage == null
                ? 'Impossible d\'enregistrer cette annonce.'
                : 'Impossible d\'enregistrer cette annonce: $errorMessage'),
            backgroundColor: AppTheme.error),
      );
      return;
    }
    ref.invalidate(propertyDetailProvider(id));
    ref.invalidate(ownerPropertiesProvider(user.id!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing
            ? 'Annonce modifiée avec succès !'
            : 'Annonce publiée avec succès !'),
        backgroundColor: AppTheme.secondary,
      ),
    );
    _popAfterFrame();
  }

  void _popAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier l\'annonce' : 'Publier une annonce'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _loading ? null : _popAfterFrame,
        ),
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photos
                    _SectionHeader('Photos (max 6)'),
                    _PhotoPicker(
                        images: _images,
                        onAdd: _pickImages,
                        onRemove: (i) => setState(() => _images.removeAt(i))),
                    const SizedBox(height: 24),

                    _SectionHeader('Informations de base'),
                    _field('Titre de l\'annonce *', _titleCtrl,
                        'Ex: Bel appartement moderne...',
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requis' : null),
                    const SizedBox(height: 16),
                    _field('Description *', _descCtrl, 'Décrivez votre bien...',
                        maxLines: 4,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Requis' : null),
                    const SizedBox(height: 16),

                    // Type & City
                    Row(
                      children: [
                        Expanded(
                            child: _Dropdown(
                                'Type *',
                                _type,
                                AppConstants.propertyTypes,
                                (v) => setState(() => _type = v!))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _Dropdown(
                                'Ville *',
                                _city,
                                AppConstants.tunisianCities,
                                (v) => setState(() => _city = v!))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _field('Adresse approximative', _addressCtrl,
                        'Ex: Rue de la Liberté, Centre-ville'),
                    const SizedBox(height: 24),

                    _SectionHeader('Prix'),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _field('Prix *', _priceCtrl, '0',
                              type: TextInputType.number, validator: (v) {
                            if (v == null || v.isEmpty) return 'Requis';
                            if (double.tryParse(v) == null) return 'Invalide';
                            return null;
                          }),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Dropdown(
                              'Par',
                              _priceType,
                              [
                                AppConstants.pricePerDay,
                                AppConstants.pricePerWeek,
                                AppConstants.pricePerMonth
                              ],
                              (v) => setState(() => _priceType = v!),
                              displayMap: {
                                AppConstants.pricePerDay: 'Jour',
                                AppConstants.pricePerWeek: 'Semaine',
                                AppConstants.pricePerMonth: 'Mois',
                              }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _SectionHeader('Caractéristiques'),
                    Row(
                      children: [
                        Expanded(
                            child: _field('Chambres *', _roomsCtrl, '2',
                                type: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _field('Salles de bain', _bathCtrl, '1',
                                type: TextInputType.number)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _field('Surface (m²)', _surfaceCtrl, '80',
                                type: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _SectionHeader('Contact & Conditions'),
                    _field('Numéro de contact', _contactCtrl, '+216 XX XXX XXX',
                        type: TextInputType.phone),
                    const SizedBox(height: 16),
                    _field('Conditions de location', _conditionsCtrl,
                        'Ex: Caution 2 mois, pas d\'animaux...',
                        maxLines: 3),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: LoadingButton(
                        onPressed: _submit,
                        isLoading: _loading,
                        label: _isEditing
                            ? 'Enregistrer les modifications'
                            : 'Publier l\'annonce',
                        icon: _isEditing
                            ? Icons.save_rounded
                            : Icons.publish_rounded,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      {int maxLines = 1,
      TextInputType type = TextInputType.text,
      String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: type,
          decoration: InputDecoration(hintText: hint),
          validator: validator ?? (v) => null,
        ),
      ],
    );
  }

  Widget _Dropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged,
      {Map<String, String>? displayMap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          decoration: const InputDecoration(),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(displayMap?[e] ?? e,
                        style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
                fontWeight: FontWeight.w700,
              )),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final List<String> images;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _PhotoPicker(
      {required this.images, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button
          if (images.length < 6)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primary,
                      width: 1.5,
                      style: BorderStyle.solid),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        color: AppTheme.primary, size: 28),
                    SizedBox(height: 4),
                    Text('Ajouter',
                        style:
                            TextStyle(color: AppTheme.primary, fontSize: 11)),
                  ],
                ),
              ),
            ),
          // Images
          ...images.asMap().entries.map((e) => Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 10),
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: e.value.startsWith('/')
                          ? Image.file(File(e.value), fit: BoxFit.cover)
                          : Image.network(e.value, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 14,
                    child: GestureDetector(
                      onTap: () => onRemove(e.key),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: AppTheme.error, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
