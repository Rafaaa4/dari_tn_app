import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dari_app/core/constants/app_routes.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/core/constants/app_constants.dart';
import 'package:dari_app/providers/auth_provider.dart';
import 'package:dari_app/repositories/booking_repository.dart';
import 'package:dari_app/widgets/loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class SponsorScreen extends ConsumerStatefulWidget {
  final int propertyId;
  const SponsorScreen({super.key, required this.propertyId});

  @override
  ConsumerState<SponsorScreen> createState() => _SponsorScreenState();
}

class _SponsorScreenState extends ConsumerState<SponsorScreen> {
  int _selectedPlan = 1;
  bool _loading = false;

  Future<void> _pay() async {
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider)!;
    final plan = AppConstants.sponsorPlans[_selectedPlan];
    final now = DateTime.now();
    final end = now.add(Duration(days: plan['duration'] as int));

    await SponsorRepository().createSponsor(SponsoredAdModel(
      propertyId: widget.propertyId,
      ownerId: user.id!,
      planName: plan['name'],
      price: plan['price'],
      startDate: now.toIso8601String(),
      endDate: end.toIso8601String(),
      createdAt: now.toIso8601String(),
    ));

    if (!mounted) return;
    setState(() => _loading = false);
    _showSuccess(plan['name'], plan['duration'], plan['price']);
  }

  void _showSuccess(String name, int days, double price) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                  color: AppTheme.secondary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text('Sponsoring activé !',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(
                'Offre $name activée pour $days jours.\n${price.toInt()} TND débité.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textGrey)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!context.mounted) return;
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.ownerDashboard);
                    }
                  });
                },
                child: const Text('Voir mes annonces'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Sponsoriser mon annonce')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  Text('Boostez votre visibilité',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                      'Apparaissez en tête des résultats et recevez plus de demandes',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Choisir une offre',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...AppConstants.sponsorPlans.asMap().entries.map((e) {
              final i = e.key;
              final plan = e.value;
              final isSelected = _selectedPlan == i;
              final color = Color(plan['color'] as int);
              return _PlanCard(
                name: plan['name'],
                days: plan['duration'],
                price: plan['price'],
                description: plan['description'],
                color: color,
                isSelected: isSelected,
                isRecommended: i == 1,
                onTap: () => setState(() => _selectedPlan = i),
              );
            }),
            const SizedBox(height: 28),

            // Benefits
            Text('Avantages du sponsoring',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...[
              'Apparaît en haut de la page d\'accueil',
              'Badge "Sponsorisé" visible',
              'Priorité dans les résultats de recherche',
              'Section "Annonces Premium" dédiée',
              'Statistiques de vues détaillées',
            ].map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            color: AppTheme.secondary, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(b, style: const TextStyle(fontSize: 14))),
                    ],
                  ),
                )),

            const SizedBox(height: 28),

            // Payment summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Offre sélectionnée'),
                      Text(AppConstants.sponsorPlans[_selectedPlan]['name'],
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Durée'),
                      Text(
                          '${AppConstants.sponsorPlans[_selectedPlan]['duration']} jours'),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total à payer',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700)),
                      Text(
                        '${(AppConstants.sponsorPlans[_selectedPlan]['price'] as double).toInt()} TND',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: LoadingButton(
                onPressed: _pay,
                isLoading: _loading,
                label: 'Payer et activer le sponsoring',
                icon: Icons.payment_rounded,
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Paiement simulé (mode démo)',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGrey)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final int days;
  final double price;
  final String description;
  final Color color;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _PlanCard({
    required this.name,
    required this.days,
    required this.price,
    required this.description,
    required this.color,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.06)
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : AppTheme.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                days == 3
                    ? Icons.bolt_rounded
                    : days == 7
                        ? Icons.star_rounded
                        : Icons.workspace_premium_rounded,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name,
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Recommandé',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(description,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textGrey)),
                  const SizedBox(height: 4),
                  Text('$days jours',
                      style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${price.toInt()} TND',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color)),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: color, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
