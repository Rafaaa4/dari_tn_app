import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dari_app/core/constants/app_routes.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/core/constants/app_constants.dart';
import 'package:dari_app/providers/auth_provider.dart';
import 'package:dari_app/providers/property_provider.dart';
import 'package:dari_app/widgets/property_card.dart';
import 'package:dari_app/widgets/sponsored_property_card.dart';
import 'package:dari_app/widgets/loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedCity;
  String? _selectedType;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearch(String q) {
    final current = ref.read(propertyFilterProvider);
    ref.read(propertyFilterProvider.notifier).state =
        current.copyWith(searchQuery: q);
  }

  void _applyCity(String? city) {
    setState(() => _selectedCity = city);
    final current = ref.read(propertyFilterProvider);
    ref.read(propertyFilterProvider.notifier).state =
        current.copyWith(city: city);
  }

  void _applyType(String? type) {
    setState(() => _selectedType = type);
    final current = ref.read(propertyFilterProvider);
    ref.read(propertyFilterProvider.notifier).state =
        current.copyWith(type: type);
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedType = null;
    });
    _searchCtrl.clear();
    ref.read(propertyFilterProvider.notifier).state = const PropertyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final propertiesAsync = ref.watch(propertiesProvider);
    final filter = ref.watch(propertyFilterProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bonjour, ${user?.fullName.split(' ').first ?? 'Bienvenue'} 👋',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Trouvez votre logement idéal',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.textGrey, fontSize: 14)),
                            ],
                          ),
                        ),
                        if (user?.isOwner == true)
                          IconButton.filled(
                            onPressed: () =>
                                context.push(AppRoutes.ownerDashboard),
                            icon: const Icon(Icons.dashboard_outlined),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (user?.isAdmin == true)
                          IconButton.filled(
                            onPressed: () => context.push(AppRoutes.admin),
                            icon:
                                const Icon(Icons.admin_panel_settings_outlined),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.warning,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search bar
                    TextField(
                      controller: _searchCtrl,
                      onChanged: _applySearch,
                      decoration: InputDecoration(
                        hintText: 'Chercher par ville, titre...',
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppTheme.textGrey),
                        suffixIcon: filter.hasFilters
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: AppTheme.textGrey),
                                onPressed: _clearFilters,
                              )
                            : null,
                        filled: true,
                        fillColor: AppTheme.cardColor(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppTheme.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // City filter
                          _FilterChip(
                            icon: Icons.location_city_outlined,
                            label: _selectedCity ?? 'Ville',
                            isActive: _selectedCity != null,
                            onTap: () => _showCityPicker(),
                          ),
                          const SizedBox(width: 8),
                          // Type filter
                          _FilterChip(
                            icon: Icons.home_work_outlined,
                            label: _selectedType ?? 'Type',
                            isActive: _selectedType != null,
                            onTap: () => _showTypePicker(),
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            icon: Icons.tune_rounded,
                            label: 'Prix',
                            isActive: false,
                            onTap: () => _showPriceFilter(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Content
            propertiesAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: PropertyListShimmer()),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Erreur: $e')),
              ),
              data: (properties) {
                if (properties.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyState(onClear: _clearFilters),
                  );
                }

                final sponsored =
                    properties.where((p) => p.isSponsored).toList();
                final normal = properties.where((p) => !p.isSponsored).toList();

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Sponsored section
                    if (sponsored.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.sponsored,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Annonces Premium',
                                      style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 220,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: sponsored.length,
                          itemBuilder: (_, i) => SponsoredPropertyCard(
                            property: sponsored[i],
                            onTap: () => context
                                .push(AppRoutes.property(sponsored[i].id!)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Normal listings
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${normal.length} annonces disponibles',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark)),
                        ],
                      ),
                    ),
                    ...normal.map((p) => Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: PropertyCard(
                            property: p,
                            onTap: () =>
                                context.push(AppRoutes.property(p.id!)),
                          ),
                        )),
                    const SizedBox(height: 20),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: user?.isOwner == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.addProperty),
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: Text('Publier',
                  style:
                      GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Choisir une ville',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Toutes les villes'),
            onTap: () {
              _applyCity(null);
              Navigator.pop(context);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: AppConstants.tunisianCities.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final city = AppConstants.tunisianCities[i];
                return ListTile(
                  title: Text(city),
                  trailing: _selectedCity == city
                      ? const Icon(Icons.check_rounded, color: AppTheme.primary)
                      : null,
                  onTap: () {
                    _applyCity(city);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTypePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Type de logement',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Tous les types'),
            onTap: () {
              _applyType(null);
              Navigator.pop(context);
            },
          ),
          const Divider(height: 1),
          ...AppConstants.propertyTypes.map((t) => Column(
                children: [
                  ListTile(
                    title: Text(t),
                    trailing: _selectedType == t
                        ? const Icon(Icons.check_rounded,
                            color: AppTheme.primary)
                        : null,
                    onTap: () {
                      _applyType(t);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(height: 1),
                ],
              )),
        ],
      ),
    );
  }

  void _showPriceFilter() {
    double min = 0, max = 5000;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text('Filtre par prix (TND/mois)',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 24),
              RangeSlider(
                values: RangeValues(min, max),
                min: 0,
                max: 10000,
                activeColor: AppTheme.primary,
                onChanged: (v) => setState(() {
                  min = v.start;
                  max = v.end;
                }),
              ),
              Text('${min.toInt()} TND - ${max.toInt()} TND'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final current = ref.read(propertyFilterProvider);
                    ref.read(propertyFilterProvider.notifier).state =
                        current.copyWith(minPrice: min, maxPrice: max);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Appliquer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: isActive ? AppTheme.primary : AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isActive ? Colors.white : AppTheme.textGrey),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : AppTheme.textDark,
                )),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;
  const _EmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              size: 64, color: AppTheme.textGrey),
          const SizedBox(height: 16),
          Text('Aucun résultat trouvé',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('Essayez de modifier vos filtres de recherche',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey)),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onClear,
            child: const Text('Effacer les filtres'),
          ),
        ],
      ),
    );
  }
}
