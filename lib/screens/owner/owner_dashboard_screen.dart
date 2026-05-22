import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dari_app/core/constants/app_routes.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/providers/auth_provider.dart';
import 'package:dari_app/providers/property_provider.dart';
import 'package:dari_app/repositories/booking_repository.dart';
import 'package:dari_app/models/property_model.dart';
import 'package:dari_app/models/booking_model.dart';
import 'package:dari_app/widgets/loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<BookingModel> _bookings = [];
  bool _bookingsLoading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final bookings = await BookingRepository().getOwnerBookings(user.id!);
    if (mounted)
      setState(() {
        _bookings = bookings;
        _bookingsLoading = false;
      });
  }

  Future<void> _updateBooking(int id, String status) async {
    await BookingRepository().updateBookingStatus(id, status);
    _loadBookings();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(status == 'accepted'
          ? 'Réservation acceptée ✓'
          : 'Réservation refusée'),
      backgroundColor:
          status == 'accepted' ? AppTheme.secondary : AppTheme.error,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final propertiesAsync = user?.id == null
        ? const AsyncValue<List<PropertyModel>>.data([])
        : ref.watch(ownerPropertiesProvider(user!.id!));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mon tableau de bord'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textGrey,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Mes annonces'),
            Tab(text: 'Demandes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // TAB 1: Properties
          propertiesAsync.when(
            loading: () => const PropertyListShimmer(),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (properties) {
              if (properties.isEmpty) {
                return EmptyWidget(
                  icon: Icons.home_outlined,
                  message: 'Aucune annonce',
                  submessage: 'Publiez votre première propriété',
                  action: ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.addProperty),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Ajouter une annonce'),
                  ),
                );
              }

              // Stats summary
              final totalViews = properties.fold(0, (s, p) => s + p.views);
              final published = properties.where((p) => p.isPublished).length;
              final sponsored = properties.where((p) => p.isSponsored).length;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats cards
                  Row(
                    children: [
                      _StatCard('Annonces', '$published', Icons.home_rounded,
                          AppTheme.primary),
                      const SizedBox(width: 10),
                      _StatCard('Vues totales', '$totalViews',
                          Icons.remove_red_eye_rounded, AppTheme.secondary),
                      const SizedBox(width: 10),
                      _StatCard('Sponsorisées', '$sponsored',
                          Icons.star_rounded, AppTheme.warning),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mes annonces',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      TextButton.icon(
                        onPressed: () => context.push(AppRoutes.addProperty),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Ajouter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...properties.map((p) => _OwnerPropertyTile(
                        property: p,
                        onTap: () => context.push(AppRoutes.property(p.id!)),
                        onEdit: () =>
                            context.push(AppRoutes.editProperty(p.id!)),
                        onSponsor: () => context.push(AppRoutes.sponsor(p.id!)),
                      )),
                ],
              );
            },
          ),

          // TAB 2: Booking requests
          _bookingsLoading
              ? const Center(child: CircularProgressIndicator())
              : _bookings.isEmpty
                  ? const EmptyWidget(
                      icon: Icons.calendar_today_outlined,
                      message: 'Aucune demande',
                      submessage:
                          'Les demandes de réservation apparaîtront ici',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _bookings.length,
                      itemBuilder: (_, i) => _BookingRequestTile(
                        booking: _bookings[i],
                        onAccept: () =>
                            _updateBooking(_bookings[i].id!, 'accepted'),
                        onRefuse: () =>
                            _updateBooking(_bookings[i].id!, 'refused'),
                      ),
                    ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppTheme.textGrey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _OwnerPropertyTile extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onSponsor;

  const _OwnerPropertyTile({
    required this.property,
    required this.onTap,
    required this.onEdit,
    required this.onSponsor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Image thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: property.images.isNotEmpty
                      ? property.images.first.startsWith('/')
                          ? Image.file(
                              File(property.images.first),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _imgPlaceholder(context),
                            )
                          : Image.network(
                              property.images.first,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) =>
                                  progress == null
                                      ? child
                                      : _imgPlaceholder(context),
                              errorBuilder: (_, __, ___) =>
                                  _imgPlaceholder(context),
                            )
                      : _imgPlaceholder(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(property.title,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        _StatusBadge(property.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${property.city} · ${property.type}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textGrey)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                            '${property.price.toInt()} TND${property.priceLabel}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary)),
                        const Spacer(),
                        const Icon(Icons.remove_red_eye_outlined,
                            size: 13, color: AppTheme.textGrey),
                        const SizedBox(width: 3),
                        Text('${property.views}',
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textGrey)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniAction(
                          icon: Icons.edit_rounded,
                          label: 'Modifier',
                          color: AppTheme.primary,
                          onTap: onEdit,
                        ),
                        if (!property.isSponsored)
                          _MiniAction(
                            icon: Icons.rocket_launch_rounded,
                            label: 'Sponsoriser',
                            color: AppTheme.warning,
                            onTap: onSponsor,
                          )
                        else
                          _MiniAction(
                            icon: Icons.star_rounded,
                            label: 'Premium actif',
                            color: AppTheme.warning,
                            filled: true,
                            onTap: () {},
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgPlaceholder(BuildContext context) => Container(
        color: AppTheme.mutedSurface(context),
        child:
            const Icon(Icons.home_rounded, color: AppTheme.divider, size: 30),
      );
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border:
              filled ? null : Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: filled ? Colors.white : color),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: filled ? Colors.white : color)),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'published':
        color = AppTheme.secondary;
        label = 'Publiée';
        break;
      case 'pending':
        color = AppTheme.warning;
        label = 'En attente';
        break;
      case 'refused':
        color = AppTheme.error;
        label = 'Refusée';
        break;
      default:
        color = AppTheme.textGrey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _BookingRequestTile extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onAccept;
  final VoidCallback onRefuse;

  const _BookingRequestTile({
    required this.booking,
    required this.onAccept,
    required this.onRefuse,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = booking.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                child: Text((booking.tenantName ?? 'T')[0],
                    style: const TextStyle(
                        color: AppTheme.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.tenantName ?? 'Locataire',
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(booking.propertyTitle ?? '',
                        style: const TextStyle(
                            color: AppTheme.textGrey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _BookingStatusBadge(booking.status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.mutedSurface(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Période',
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.textGrey)),
                      Text(
                          '${booking.startDate.substring(0, 10)} → ${booking.endDate.substring(0, 10)}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total',
                        style:
                            TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                    Text('${booking.totalPrice.toInt()} TND',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary)),
                  ],
                ),
              ],
            ),
          ),
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRefuse,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(
                          color: AppTheme.error.withValues(alpha: 0.5)),
                    ),
                    child: const Text('Refuser'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary),
                    child: const Text('Accepter'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingStatusBadge extends StatelessWidget {
  final String status;
  const _BookingStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'accepted':
        color = AppTheme.secondary;
        label = 'Acceptée';
        break;
      case 'refused':
        color = AppTheme.error;
        label = 'Refusée';
        break;
      case 'cancelled':
        color = AppTheme.textGrey;
        label = 'Annulée';
        break;
      default:
        color = AppTheme.warning;
        label = 'En attente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
