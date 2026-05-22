import 'package:flutter/material.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/models/property_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;

  const PropertyCard({super.key, required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: property.images.isNotEmpty
                    ? _buildImage(context, property.images.first)
                    : _placeholder(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge
                  Row(
                    children: [
                      _TypeBadge(property.type),
                      const Spacer(),
                      if (property.avgRating != null)
                        _RatingBadge(property.avgRating!),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(property.title,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.bodyLarge?.color),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppTheme.textGrey),
                      const SizedBox(width: 2),
                      Text(property.city,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textGrey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoChip(Icons.bed_outlined, '${property.rooms} ch.'),
                      const SizedBox(width: 8),
                      _InfoChip(
                          Icons.bathtub_outlined, '${property.bathrooms} sdb'),
                      if (property.surface != null) ...[
                        const SizedBox(width: 8),
                        _InfoChip(Icons.square_foot_outlined,
                            '${property.surface!.toInt()}m²'),
                      ],
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${property.price.toInt()} TND',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary),
                          ),
                          Text(property.priceLabel,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textGrey)),
                        ],
                      ),
                    ],
                  ),
                ],
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
          errorBuilder: (_, __, ___) => _placeholder(context));
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
      errorBuilder: (_, __, ___) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: AppTheme.mutedSurface(context),
      child: const Center(
        child: Icon(Icons.home_rounded, size: 56, color: AppTheme.divider),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge(this.type);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(type,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary)),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  final double rating;
  const _RatingBadge(this.rating);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 14, color: AppTheme.warning),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1),
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppTheme.textGrey),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
      ],
    );
  }
}
