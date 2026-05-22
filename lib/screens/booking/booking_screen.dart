import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dari_app/core/constants/app_routes.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/providers/property_provider.dart';
import 'package:dari_app/repositories/booking_repository.dart';
import 'package:dari_app/models/booking_model.dart';
import 'package:dari_app/widgets/loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final int propertyId;
  const BookingScreen({super.key, required this.propertyId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _loading = false;
  bool _paid = false;

  int get _days {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }

  double _totalPrice(double pricePerMonth) {
    if (_days == 0) return 0;
    return (pricePerMonth / 30) * _days;
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? DateTime.now().add(const Duration(days: 1))
          : (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
      firstDate: isStart
          ? DateTime.now()
          : (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!))
          _endDate = null;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _book(double pricePerMonth, String ownerId) async {
    if (_loading) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner les dates'),
            backgroundColor: AppTheme.error),
      );
      return;
    }
    if (_days <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La date de départ doit être après l\'arrivée'),
            backgroundColor: AppTheme.error),
      );
      return;
    }
    setState(() => _loading = true);
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Session expirée. Connectez-vous puis réessayez.'),
            backgroundColor: AppTheme.error),
      );
      return;
    }

    final booking = BookingModel(
      propertyId: widget.propertyId,
      tenantId: authUser.id,
      ownerId: ownerId,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate!),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate!),
      totalPrice: _totalPrice(pricePerMonth),
      status: 'pending',
      paymentStatus: 'unpaid',
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      final repo = BookingRepository();
      final id = await repo.createBooking(booking);

      // Mock payment
      await Future.delayed(const Duration(milliseconds: 800));
      final paid = await repo.payBooking(id);

      if (!mounted) return;
      setState(() {
        _loading = false;
        _paid = paid;
      });
      if (!paid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Réservation créée, mais paiement non confirmé.'),
              backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('Erreur réservation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Impossible de réserver: $e'),
            backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyAsync = ref.watch(propertyDetailProvider(widget.propertyId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Réserver')),
      body: propertyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (property) {
          if (property == null) return const SizedBox();

          if (_paid) {
            return _SuccessView(onHome: () => context.go(AppRoutes.home));
          }

          final total = _totalPrice(property.price);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.home_rounded,
                            color: AppTheme.primary, size: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(property.title,
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(property.city,
                                style: const TextStyle(
                                    color: AppTheme.textGrey, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                                '${property.price.toInt()} TND${property.priceLabel}',
                                style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text('Sélectionner les dates',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                        child: _DatePicker(
                      label: 'Date d\'arrivée',
                      date: _startDate,
                      onTap: () => _pickDate(true),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _DatePicker(
                      label: 'Date de départ',
                      date: _endDate,
                      onTap: () => _pickDate(false),
                    )),
                  ],
                ),

                if (_days > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Text('$_days nuit${_days > 1 ? 's' : ''}',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                Text('Détail du paiement',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    children: [
                      _PriceLine(
                          'Prix par mois', '${property.price.toInt()} TND'),
                      const SizedBox(height: 8),
                      _PriceLine('Prix par nuit',
                          '${(property.price / 30).toStringAsFixed(1)} TND'),
                      const SizedBox(height: 8),
                      _PriceLine('Durée', _days > 0 ? '$_days nuits' : '—'),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          Text(
                            _days > 0 ? '${total.toStringAsFixed(1)} TND' : '—',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Payment methods (mock)
                Text('Méthode de paiement',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Paiement simulé (Démo)',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('Aucun vrai paiement effectué',
                                style: const TextStyle(
                                    color: AppTheme.textGrey, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: LoadingButton(
                    onPressed: _days > 0
                        ? () => _book(property.price, property.ownerId)
                        : null,
                    isLoading: _loading,
                    label: _days > 0
                        ? 'Payer ${total.toStringAsFixed(1)} TND et réserver'
                        : 'Sélectionnez les dates',
                    icon: Icons.lock_rounded,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePicker({required this.label, this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasDate
              ? AppTheme.primary.withValues(alpha: 0.06)
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: hasDate ? AppTheme.primary : AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textGrey)),
            const SizedBox(height: 6),
            Text(
              hasDate
                  ? DateFormat('dd MMM yyyy').format(date!)
                  : 'Sélectionner',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: hasDate ? AppTheme.primary : AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  final String label;
  final String value;
  const _PriceLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textGrey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onHome;
  const _SuccessView({required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                  color: AppTheme.secondary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 56),
            ),
            const SizedBox(height: 24),
            Text('Réservation confirmée !',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            const Text(
              'Votre réservation a été envoyée et le paiement simulé a été validé.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onHome,
                child: const Text('Retour à l\'accueil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
