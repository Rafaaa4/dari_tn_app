import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dari_app/core/constants/app_routes.dart';
import 'package:dari_app/providers/auth_provider.dart';
import 'package:dari_app/providers/property_provider.dart';
import 'package:dari_app/widgets/property_card.dart';
import 'package:dari_app/widgets/loading_widget.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();

    final favAsync = ref.watch(favoritesProvider(user.id!));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Mes favoris')),
      body: favAsync.when(
        loading: () => const PropertyListShimmer(),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (properties) => properties.isEmpty
            ? EmptyWidget(
                icon: Icons.favorite_outline_rounded,
                message: 'Aucun favori',
                submessage:
                    'Ajoutez des propriétés à vos favoris pour les retrouver ici',
                action: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Explorer les annonces'),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: properties.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PropertyCard(
                    property: properties[i],
                    onTap: () =>
                        context.push(AppRoutes.property(properties[i].id!)),
                  ),
                ),
              ),
      ),
    );
  }
}
