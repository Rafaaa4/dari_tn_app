import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dari_app/core/constants/app_routes.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/providers/auth_provider.dart';
import 'package:dari_app/providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editMode = false;
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl = TextEditingController(text: user?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final user = ref.read(currentUserProvider)!;
    await ref.read(authStateProvider.notifier).updateProfile(
          user.copyWith(
              fullName: _nameCtrl.text.trim(), phone: _phoneCtrl.text.trim()),
        );
    if (mounted)
      setState(() {
        _saving = false;
        _editMode = false;
      });
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Se déconnecter ?'),
        content:
            const Text('Voulez-vous vraiment vous déconnecter de Dari.tn ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Déconnecter',
                style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _loggingOut = true);
    await ref.read(authStateProvider.notifier).logout();
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          if (!_editMode)
            TextButton.icon(
              onPressed: () => setState(() => _editMode = true),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Modifier'),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 16),
              label: const Text('Enregistrer'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar card
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.fullName,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                _RoleBadge(user.role),
                const SizedBox(height: 4),
                Text(user.email,
                    style: const TextStyle(
                        color: AppTheme.textGrey, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Edit form
          if (_editMode) ...[
            _SectionTitle('Informations personnelles'),
            const SizedBox(height: 12),
            _Field('Nom complet', _nameCtrl, Icons.person_outlined),
            const SizedBox(height: 14),
            _Field('Téléphone', _phoneCtrl, Icons.phone_outlined,
                type: TextInputType.phone),
            const SizedBox(height: 24),
          ] else ...[
            _InfoCard([
              _InfoRow(Icons.person_outlined, 'Nom', user.fullName),
              _InfoRow(Icons.email_outlined, 'Email', user.email),
              _InfoRow(Icons.phone_outlined, 'Téléphone',
                  user.phone ?? 'Non renseigné'),
              _InfoRow(Icons.badge_outlined, 'Rôle', _roleLabel(user.role)),
              _InfoRow(Icons.circle_outlined, 'Statut',
                  user.status == 'active' ? 'Actif' : user.status),
            ]),
            const SizedBox(height: 24),
          ],

          // Quick actions
          _SectionTitle('Actions rapides'),
          const SizedBox(height: 12),
          if (user.isOwner) ...[
            _ActionTile(
                Icons.dashboard_outlined,
                'Tableau de bord propriétaire',
                () => context.push(AppRoutes.ownerDashboard)),
            _ActionTile(Icons.add_home_outlined, 'Publier une annonce',
                () => context.push(AppRoutes.addProperty)),
          ],
          if (user.isTenant)
            _ActionTile(Icons.calendar_today_outlined, 'Mes réservations',
                () => context.go(AppRoutes.myBookings)),
          if (user.isAdmin)
            _ActionTile(
                Icons.admin_panel_settings_outlined,
                'Panneau d\'administration',
                () => context.push(AppRoutes.admin),
                color: AppTheme.warning),
          _ActionTile(Icons.favorite_outline_rounded, 'Mes favoris',
              () => context.go(AppRoutes.favorites)),
          // Theme toggle
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: ListTile(
              leading:
                  const Icon(Icons.dark_mode_outlined, color: AppTheme.primary),
              title: Text('Mode Sombre',
                  style: GoogleFonts.plusJakartaSans(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.w600)),
              trailing: Switch(
                value: ref.watch(themeProvider) == ThemeMode.dark,
                onChanged: (val) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
                activeColor: AppTheme.primary,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 8),

          // Logout
          Container(
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderColor(context)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppTheme.error),
              title: Text('Se déconnecter',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.error, fontWeight: FontWeight.w600)),
              onTap: _logout,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _Field(String label, TextEditingController ctrl, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(prefixIcon: Icon(icon)),
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Propriétaire';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Locataire';
    }
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge(this.role);

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (role) {
      case 'owner':
        color = AppTheme.secondary;
        label = 'Propriétaire';
        break;
      case 'admin':
        color = AppTheme.warning;
        label = 'Administrateur';
        break;
      default:
        color = AppTheme.primary;
        label = 'Locataire';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Text(title,
      style: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w700));
}

class _InfoCard extends StatelessWidget {
  final List<Widget> rows;
  const _InfoCard(this.rows);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(children: rows),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.textGrey),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 13)),
            const Spacer(),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile(this.icon, this.title, this.onTap, {this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: ListTile(
          leading: Icon(icon, color: color ?? AppTheme.primary),
          title: Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          trailing:
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textGrey),
          onTap: onTap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}
