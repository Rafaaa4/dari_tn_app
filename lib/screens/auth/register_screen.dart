import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dari_app/core/theme/app_theme.dart';
import 'package:dari_app/core/constants/app_constants.dart';
import 'package:dari_app/core/constants/app_routes.dart';
import 'package:dari_app/providers/auth_provider.dart';
import 'package:dari_app/widgets/loading_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _role = AppConstants.roleTenant;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await ref.read(authStateProvider.notifier).register(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _role,
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      setState(() => _error = error);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Créer un compte',
                    style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text('Rejoignez Dari.tn aujourd\'hui',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppTheme.textGrey)),
                const SizedBox(height: 32),

                // Role selector
                Text('Je suis un...',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _RoleCard(
                      icon: Icons.search_rounded,
                      title: 'Locataire',
                      subtitle: 'Je cherche à louer',
                      isSelected: _role == AppConstants.roleTenant,
                      onTap: () =>
                          setState(() => _role = AppConstants.roleTenant),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _RoleCard(
                      icon: Icons.apartment_rounded,
                      title: 'Propriétaire',
                      subtitle: 'Je mets en location',
                      isSelected: _role == AppConstants.roleOwner,
                      onTap: () =>
                          setState(() => _role = AppConstants.roleOwner),
                    )),
                  ],
                ),
                const SizedBox(height: 28),

                _Field('Nom complet', _nameCtrl, Icons.person_outlined,
                    'Mohamed Ben Ali', (v) => v!.isEmpty ? 'Nom requis' : null),
                const SizedBox(height: 16),
                _Field(
                    'Email', _emailCtrl, Icons.email_outlined, 'votre@email.tn',
                    (v) {
                  if (v!.isEmpty) return 'Email requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                }, type: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _Field('Téléphone (optionnel)', _phoneCtrl,
                    Icons.phone_outlined, '+216 XX XXX XXX', null,
                    type: TextInputType.phone),
                const SizedBox(height: 16),

                Text('Mot de passe',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Minimum 8 caractères',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'Mot de passe requis';
                    if (v.length < 8) return 'Minimum 8 caractères';
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: LoadingButton(
                    onPressed: _register,
                    isLoading: _loading,
                    label: 'Créer mon compte',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Déjà un compte ?',
                        style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textGrey)),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text('Se connecter',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _Field(
    String label,
    TextEditingController ctrl,
    IconData icon,
    String hint,
    String? Function(String?)? validator, {
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
          validator: validator,
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primary.withValues(alpha: 0.06)
              : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isSelected ? AppTheme.primary : AppTheme.borderColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 32,
                color: isSelected ? AppTheme.primary : AppTheme.textGrey),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppTheme.primary
                      : Theme.of(context).textTheme.titleMedium?.color,
                  fontSize: 14,
                )),
            Text(subtitle,
                style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
