import 'package:flutter/material.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/models/property_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class SponsoredPropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;

  const SponsoredPropertyCard(
      {super.key, required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.sponsored.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.sponsored.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(15)),
                  child: SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: property.images.isNotEmpty
                        ? _buildImage(context, property.images.first)
                        : Container(
                            color: AppTheme.mutedSurface(context),
                            child: const Center(
                              child: Icon(Icons.home_rounded,
                                  size: 48, color: AppTheme.divider),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(property.title,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: AppTheme.textGrey),
                          Text(property.city,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textGrey)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${property.price.toInt()} TND${property.priceLabel}',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.sponsored,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 3),
                    Text('Sponsorisé',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, String path) {
    if (path.startsWith('/')) {
      return Image.file(File(path),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              Container(color: AppTheme.mutedSurface(context)));
    }
    return Image.network(
      path,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : Container(
              color: AppTheme.mutedSurface(context),
              child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
      errorBuilder: (_, __, ___) =>
          Container(color: AppTheme.mutedSurface(context)),
    );
  }
}
