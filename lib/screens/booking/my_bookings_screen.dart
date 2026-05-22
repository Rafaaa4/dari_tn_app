import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/providers/auth_provider.dart';
import 'package:dari_app/repositories/booking_repository.dart';
import 'package:dari_app/models/booking_model.dart';
import 'package:dari_app/widgets/loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  List<BookingModel> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final bookings = await BookingRepository().getTenantBookings(user.id!);
    if (mounted) setState(() { _bookings = bookings; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Mes réservations')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? const EmptyWidget(
                  icon: Icons.calendar_today_outlined,
                  message: 'Aucune réservation',
                  submessage: 'Vos réservations apparaîtront ici',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _bookings.length,
                  itemBuilder: (_, i) => _BookingCard(booking: _bookings[i]),
                ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    switch (booking.status) {
      case 'accepted':
        statusColor = AppTheme.secondary;
        statusLabel = 'Confirmée';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'refused':
        statusColor = AppTheme.error;
        statusLabel = 'Refusée';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'cancelled':
        statusColor = AppTheme.textGrey;
        statusLabel = 'Annulée';
        statusIcon = Icons.block_rounded;
        break;
      default:
        statusColor = AppTheme.warning;
        statusLabel = 'En attente';
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Text(statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(booking.createdAt.substring(0, 10),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.propertyTitle ?? 'Propriété',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textGrey),
                    Text(booking.propertyCity ?? '',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoBox(Icons.login_rounded, 'Arrivée', booking.startDate.substring(0, 10)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.textGrey),
                    const SizedBox(width: 8),
                    _InfoBox(Icons.logout_rounded, 'Départ', booking.endDate.substring(0, 10)),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 11, color: AppTheme.textGrey)),
                        Text('${booking.totalPrice.toStringAsFixed(0)} TND',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: booking.paymentStatus == 'paid'
                            ? AppTheme.secondary.withValues(alpha: 0.1)
                            : AppTheme.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            booking.paymentStatus == 'paid'
                                ? Icons.payment_rounded
                                : Icons.payment_outlined,
                            size: 12,
                            color: booking.paymentStatus == 'paid'
                                ? AppTheme.secondary
                                : AppTheme.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.paymentStatus == 'paid' ? 'Payé' : 'En attente',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: booking.paymentStatus == 'paid'
                                  ? AppTheme.secondary
                                  : AppTheme.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoBox(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
        Row(
          children: [
            Icon(icon, size: 12, color: AppTheme.primary),
            const SizedBox(width: 3),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}
