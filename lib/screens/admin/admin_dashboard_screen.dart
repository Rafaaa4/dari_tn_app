import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/repositories/auth_repository.dart';
import 'package:dari_app/repositories/property_repository.dart';
import 'package:dari_app/repositories/booking_repository.dart';
import 'package:dari_app/models/user_model.dart';
import 'package:dari_app/models/property_model.dart';
import 'package:dari_app/models/booking_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<UserModel> _users = [];
  List<PropertyModel> _properties = [];
  List<BookingModel> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _users = await AuthRepository().getAllUsers();
    _properties = await PropertyRepository().getAllProperties();
    _bookings = await BookingRepository().getAllBookings();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalRevenue = _bookings
        .where((b) => b.paymentStatus == 'paid')
        .fold(0.0, (s, b) => s + b.totalPrice);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppTheme.warning,
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('ADMIN',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            const Text('Panneau d\'administration'),
          ],
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textGrey,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'Utilisateurs'),
            Tab(text: 'Annonces'),
            Tab(text: 'Réservations'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats
                Container(
                  color: AppTheme.cardColor(context),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _AdminStat('Utilisateurs', '${_users.length}',
                          Icons.people_rounded, AppTheme.primary),
                      _AdminStat('Annonces', '${_properties.length}',
                          Icons.home_rounded, AppTheme.secondary),
                      _AdminStat('Réservations', '${_bookings.length}',
                          Icons.calendar_today_rounded, AppTheme.warning),
                      _AdminStat('Revenus', '${totalRevenue.toInt()} TND',
                          Icons.payments_rounded, const Color(0xFF8B5CF6)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      // Users list
                      ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _users.length,
                        itemBuilder: (_, i) => _UserTile(
                          user: _users[i],
                          onToggle: () async {
                            final newStatus = _users[i].status == 'active'
                                ? 'blocked'
                                : 'active';
                            await AuthRepository()
                                .toggleUserStatus(_users[i].id!, newStatus);
                            _load();
                          },
                        ),
                      ),

                      // Properties list
                      ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _properties.length,
                        itemBuilder: (_, i) => _PropertyTile(
                          property: _properties[i],
                          onApprove: () async {
                            await PropertyRepository().setPropertyStatus(
                                _properties[i].id!, 'published');
                            _load();
                          },
                          onReject: () async {
                            await PropertyRepository().setPropertyStatus(
                                _properties[i].id!, 'refused');
                            _load();
                          },
                        ),
                      ),

                      // Bookings list
                      ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _bookings.length,
                        itemBuilder: (_, i) =>
                            _BookingTile(booking: _bookings[i]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _AdminStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _AdminStat(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark)),
          Text(label,
              style: const TextStyle(fontSize: 9, color: AppTheme.textGrey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final VoidCallback onToggle;

  const _UserTile({required this.user, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isBlocked = user.status == 'blocked';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isBlocked
                ? AppTheme.error.withValues(alpha: 0.3)
                : AppTheme.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _roleColor(user.role).withValues(alpha: 0.12),
            child: Text(user.fullName[0],
                style: TextStyle(
                    color: _roleColor(user.role), fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(user.email,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textGrey)),
                Row(
                  children: [
                    _Badge(
                        user.role == 'owner'
                            ? 'Propriétaire'
                            : user.role == 'admin'
                                ? 'Admin'
                                : 'Locataire',
                        _roleColor(user.role)),
                    const SizedBox(width: 6),
                    if (isBlocked) _Badge('Bloqué', AppTheme.error),
                  ],
                ),
              ],
            ),
          ),
          if (user.role != 'admin')
            IconButton(
              onPressed: onToggle,
              icon: Icon(
                isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                color: isBlocked ? AppTheme.secondary : AppTheme.error,
              ),
              tooltip: isBlocked ? 'Débloquer' : 'Bloquer',
            ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'owner':
        return AppTheme.secondary;
      case 'admin':
        return AppTheme.warning;
      default:
        return AppTheme.primary;
    }
  }
}

class _PropertyTile extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PropertyTile(
      {required this.property,
      required this.onApprove,
      required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property.title,
                        style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                        '${property.city} · ${property.type} · ${property.ownerName ?? ''}',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textGrey)),
                    Text('${property.price.toInt()} TND${property.priceLabel}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            fontSize: 13)),
                  ],
                ),
              ),
              _Badge(
                property.status == 'published'
                    ? 'Publiée'
                    : property.status == 'pending'
                        ? 'En attente'
                        : property.status == 'refused'
                            ? 'Refusée'
                            : property.status,
                property.status == 'published'
                    ? AppTheme.secondary
                    : property.status == 'pending'
                        ? AppTheme.warning
                        : AppTheme.error,
              ),
            ],
          ),
          if (property.status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label:
                        const Text('Refuser', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(
                          color: AppTheme.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded, size: 14),
                    label:
                        const Text('Approuver', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
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

class _BookingTile extends StatelessWidget {
  final BookingModel booking;
  const _BookingTile({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.propertyTitle ?? 'Propriété',
                    style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('Locataire: ${booking.tenantName ?? '?'}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textGrey)),
                Text(
                    '${booking.startDate.substring(0, 10)} → ${booking.endDate.substring(0, 10)}',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textGrey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${booking.totalPrice.toInt()} TND',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                      fontSize: 15)),
              const SizedBox(height: 4),
              _Badge(
                booking.paymentStatus == 'paid' ? 'Payé' : 'Non payé',
                booking.paymentStatus == 'paid'
                    ? AppTheme.secondary
                    : AppTheme.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge(this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      );
}
