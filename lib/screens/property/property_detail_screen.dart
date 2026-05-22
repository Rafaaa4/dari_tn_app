import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dari_app/core/constants/app_routes.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/providers/auth_provider.dart';
import 'package:dari_app/providers/property_provider.dart';
import 'package:dari_app/models/review_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  final int propertyId;
  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  int _currentImage = 0;
  bool _isFav = false;
  List<ReviewModel> _reviews = [];

  @override
  void initState() {
    super.initState();
    _loadExtra();
  }

  Future<void> _loadExtra() async {
    final user = ref.read(currentUserProvider);
    final repo = ref.read(propertyRepositoryProvider);
    if (user != null) {
      _isFav = await repo.isFavorite(user.id!, widget.propertyId);
    }
    _reviews = await repo.getPropertyReviews(widget.propertyId);
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await ref
        .read(propertyRepositoryProvider)
        .toggleFavorite(user.id!, widget.propertyId);
    setState(() => _isFav = !_isFav);
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailProvider(widget.propertyId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: propertyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (property) {
          if (property == null)
            return const Center(child: Text('Propriété introuvable'));
          final isOwner = user?.id == property.ownerId;
          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Image gallery
                  SliverAppBar(
                    expandedHeight: 280,
                    pinned: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    leading: GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor(context),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                blurRadius: 8,
                                color: Colors.black.withValues(alpha: 0.1))
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 18),
                      ),
                    ),
                    actions: [
                      GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(context),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  blurRadius: 8,
                                  color: Colors.black.withValues(alpha: 0.1))
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            color: _isFav
                                ? AppTheme.error
                                : Theme.of(context).iconTheme.color,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      background: property.images.isEmpty
                          ? Container(
                              color: AppTheme.mutedSurface(context),
                              child: const Center(
                                child: Icon(Icons.home_rounded,
                                    size: 80, color: AppTheme.divider),
                              ),
                            )
                          : PageView.builder(
                              itemCount: property.images.length,
                              onPageChanged: (i) =>
                                  setState(() => _currentImage = i),
                              itemBuilder: (_, i) {
                                final img = property.images[i];
                                return img.startsWith('/')
                                    ? Image.file(File(img), fit: BoxFit.cover)
                                    : Image.network(
                                        img,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (_, child, progress) =>
                                            progress == null
                                                ? child
                                                : Container(
                                                    color:
                                                        AppTheme.mutedSurface(
                                                            context),
                                                    child: const Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth:
                                                                    2)),
                                                  ),
                                        errorBuilder: (_, __, ___) => Container(
                                          color: AppTheme.mutedSurface(context),
                                          child: const Icon(
                                              Icons.broken_image_rounded,
                                              size: 48,
                                              color: AppTheme.divider),
                                        ),
                                      );
                              },
                            ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image dots
                          if (property.images.length > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                property.images.length,
                                (i) => Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  width: _currentImage == i ? 18 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _currentImage == i
                                        ? AppTheme.primary
                                        : AppTheme.divider,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Sponsored badge
                          if (property.isSponsored)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.sponsored,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Annonce Premium',
                                      style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12)),
                                ],
                              ),
                            ),

                          // Title and price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(property.title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('${property.price.toInt()} TND',
                                      style: GoogleFonts.plusJakartaSans(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.primary)),
                                  Text(property.priceLabel,
                                      style: const TextStyle(
                                          color: AppTheme.textGrey,
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Location
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 16, color: AppTheme.textGrey),
                              const SizedBox(width: 4),
                              Text(
                                  '${property.city}${property.address != null ? ', ${property.address}' : ''}',
                                  style: const TextStyle(
                                      color: AppTheme.textGrey)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Stats row
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: AppTheme.borderColor(context)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _Stat(Icons.bed_outlined, '${property.rooms}',
                                    'Chambres'),
                                _divider(),
                                _Stat(Icons.bathtub_outlined,
                                    '${property.bathrooms}', 'Salles de bain'),
                                if (property.surface != null) ...[
                                  _divider(),
                                  _Stat(
                                      Icons.square_foot_outlined,
                                      '${property.surface!.toInt()}m²',
                                      'Surface'),
                                ],
                                _divider(),
                                _Stat(Icons.remove_red_eye_outlined,
                                    '${property.views}', 'Vues'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Owner
                          if (property.ownerName != null)
                            _Section(
                              'Propriétaire',
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor:
                                        AppTheme.primary.withValues(alpha: 0.1),
                                    child: Text(property.ownerName![0],
                                        style: const TextStyle(
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(property.ownerName!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium)),
                                  if (property.contact != null)
                                    OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.phone_outlined,
                                          size: 16),
                                      label: const Text('Contacter'),
                                    ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),

                          // Description
                          _Section(
                              'Description',
                              Text(property.description,
                                  style: const TextStyle(
                                      color: AppTheme.textGrey, height: 1.6))),
                          const SizedBox(height: 20),

                          // Conditions
                          if (property.conditions != null)
                            _Section(
                                'Conditions de location',
                                Text(property.conditions!,
                                    style: const TextStyle(
                                        color: AppTheme.textGrey,
                                        height: 1.6))),

                          // Avis
                          _Section(
                            'Avis (${_reviews.length})',
                            _reviews.isEmpty
                                ? const Text('Aucun avis pour le moment.',
                                    style: TextStyle(color: AppTheme.textGrey))
                                : Column(
                                    children: _reviews
                                        .map((r) => _ReviewTile(r))
                                        .toList(),
                                  ),
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    border: Border(
                        top: BorderSide(color: AppTheme.borderColor(context))),
                  ),
                  child: Row(
                    children: [
                      if (property.contact != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.chat_bubble_outline_rounded,
                                size: 18),
                            label: const Text('Contacter'),
                          ),
                        ),
                      const SizedBox(width: 12),
                      if (isOwner)
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () => context
                                .push(AppRoutes.editProperty(property.id!)),
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Modifier'),
                          ),
                        )
                      else if (user?.isTenant == true && property.isAvailable)
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.push(AppRoutes.booking(property.id!)),
                            icon: const Icon(Icons.calendar_today_rounded,
                                size: 18),
                            label: const Text('Réserver'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _divider() => Container(height: 36, width: 1, color: AppTheme.divider);

  Widget _Section(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        content,
        const SizedBox(height: 20),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ReviewTile(this.review);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.mutedSurface(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Text(review.tenantName?[0] ?? '?',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Text(review.tenantName ?? 'Anonyme',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < review.rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: AppTheme.warning,
                        )),
              ),
            ],
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 8),
            Text(review.comment!,
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
