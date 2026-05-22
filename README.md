# 🏠 Dari.tn — Application Flutter de Location Immobilière

Une application mobile complète pour la location de maisons, appartements et studios en Tunisie.

---

## 📱 Fonctionnalités

### Pour les Locataires
- 🔍 Recherche par ville, type, prix
- ⭐ Annonces sponsorisées en premier
- ❤️ Favoris
- 📅 Réservation avec calcul automatique du prix
- 💳 Paiement simulé (prêt pour intégration réelle)
- 📋 Historique des réservations
- ⭐ Avis et notes

### Pour les Propriétaires
- 🏠 Publication d'annonces avec photos
- 📊 Tableau de bord avec statistiques (vues, demandes)
- 🚀 Sponsoring d'annonces (3 offres disponibles)
- ✅ Gestion des demandes de réservation (accepter/refuser)

### Pour les Administrateurs
- 👥 Gestion des utilisateurs (bloquer/débloquer)
- 🏡 Validation des annonces
- 💰 Vue globale des réservations et revenus

---

## 🗃️ Base de données

SQLite locale avec 9 tables :
- `users` — Comptes utilisateurs
- `properties` — Annonces immobilières
- `property_images` — Photos des propriétés
- `favorites` — Favoris utilisateurs
- `bookings` — Réservations
- `sponsored_ads` — Offres de sponsoring
- `payments` — Historique paiements
- `reviews` — Avis et notes
- `messages` — Messagerie (structure prête)

---

## 🚀 Installation

### Prérequis
- Flutter SDK >= 3.0.0
- Android Studio ou VS Code
- Dart >= 3.0.0

### Étapes

```bash
# 1. Extraire le projet
unzip dari_app.zip
cd dari_app

# 2. Installer les dépendances
flutter pub get

# 3. Lancer l'application
flutter run
```

---

## 🔑 Comptes de démo

| Rôle | Email | Mot de passe |
|------|-------|-------------|
| Locataire | tenant@dari.tn | Tenant@123 |
| Propriétaire | owner@dari.tn | Owner@123 |
| Admin | admin@dari.tn | Admin@123 |

---

## 📁 Structure du projet

```
lib/
├── main.dart                    # Point d'entrée
├── app.dart                     # Configuration app
├── core/
│   ├── constants/
│   │   ├── app_constants.dart   # Constantes globales
│   │   └── app_router.dart      # Navigation GoRouter
│   └── theme/
│       └── app_theme.dart       # Thème Material 3
├── database/
│   └── app_database.dart        # SQLite + seed data
├── models/                      # Modèles de données
│   ├── user_model.dart
│   ├── property_model.dart
│   ├── booking_model.dart
│   └── review_model.dart
├── repositories/                # Accès base de données
│   ├── auth_repository.dart
│   ├── property_repository.dart
│   └── booking_repository.dart  # + SponsorRepository
├── providers/                   # État Riverpod
│   ├── auth_provider.dart
│   └── property_provider.dart
├── screens/
│   ├── auth/                    # Splash, Onboarding, Login, Register
│   ├── home/                    # Home, Favoris, MainShell
│   ├── property/                # Détail, Ajout propriété
│   ├── owner/                   # Dashboard, Sponsoring
│   ├── booking/                 # Réservation, Mes réservations
│   ├── profile/                 # Profil
│   └── admin/                   # Panneau admin
└── widgets/                     # Composants réutilisables
    ├── property_card.dart
    ├── sponsored_property_card.dart
    └── loading_widget.dart
```

---

## 🎨 Design System

### Couleurs
| Rôle | Couleur |
|------|---------|
| Primary | `#2563EB` (Bleu) |
| Secondary | `#10B981` (Vert) |
| Background | `#F8FAFC` |
| Warning | `#F59E0B` (Or) |
| Error | `#EF4444` (Rouge) |

### Typographie
- Police : **Plus Jakarta Sans** (Google Fonts)
- Design : Material Design 3 avec `useMaterial3: true`

---

## 📦 Packages utilisés

| Package | Usage |
|---------|-------|
| `flutter_riverpod` | State management |
| `go_router` | Navigation |
| `sqflite` | Base de données SQLite |
| `image_picker` | Sélection photos |
| `google_fonts` | Typographie |
| `shimmer` | Loading skeletons |
| `flutter_secure_storage` | Session sécurisée |
| `crypto` | Hash mot de passe (SHA-256) |
| `intl` | Formatage dates |
| `dio` | HTTP (prêt pour backend) |

---

## 🗺️ Sprints MVP complétés

- ✅ Sprint 1 — Setup & structure
- ✅ Sprint 2 — Base SQLite (9 tables)
- ✅ Sprint 3 — Authentification locale
- ✅ Sprint 4 — Publications immobilières
- ✅ Sprint 5 — Recherche & filtres
- ✅ Sprint 6 — Réservations & paiement mock
- ✅ Sprint 7 — Système sponsoring (3 offres)
- ✅ Sprint 8 — Admin dashboard

---

## 🔮 Évolutions futures

- [ ] Backend REST API (Node.js / Spring Boot)
- [ ] PostgreSQL / Supabase
- [ ] Paiement réel : Stripe, Konnect, Flouci
- [ ] Google Maps intégration
- [ ] Chat temps réel
- [ ] Notifications push (FCM)
- [ ] Contrats PDF automatiques
- [ ] Dark mode
- [ ] Multi-langue (AR/FR/EN)
- [ ] Dashboard web admin

---

## 🏗️ Architecture future

```
Flutter App (Dart)
       ↓
REST API Backend (Node.js / Spring Boot)
       ↓
PostgreSQL + Redis
       ↓
Payment Gateway (Stripe / Konnect)
       ↓
Push Notifications (FCM)
```

---

## 📄 Licence

MIT License — Libre d'utilisation pour vos projets.

---

*Développé avec ❤️ pour la communauté Flutter tunisienne*
