import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_profile.dart';

/// The signed-in hot-potato-games account, merged from Firebase Auth + the
/// `users/{uid}` Firestore profile doc. Mirrors the site's user schema:
/// uid, email, displayName, phoneNumber, photoURL, theme, notifications.
@immutable
class HpgUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final String theme; // 'light' | 'dark'
  final bool notifications;
  final bool isAnonymous;

  const HpgUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    this.theme = 'dark',
    this.notifications = true,
    this.isAnonymous = false,
  });

  HpgUser copyWith({
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    String? theme,
    bool? notifications,
  }) =>
      HpgUser(
        uid: uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        photoURL: photoURL ?? this.photoURL,
        theme: theme ?? this.theme,
        notifications: notifications ?? this.notifications,
        isAnonymous: isAnonymous,
      );
}

/// Account layer over Firebase Auth + Firestore. Email + anonymous sign-in,
/// plus editing the profile values. NEVER blocks launch and tolerates an
/// unconfigured / offline backend — sign-in methods surface their own errors,
/// everything else swallows so the game keeps running.
class AuthService {
  AuthService._();

  /// The current account, or null when signed out. The account icon + sheets
  /// listen to this. An anonymous session still produces an [HpgUser].
  static final ValueNotifier<HpgUser?> current = ValueNotifier<HpgUser?>(null);

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static bool _bound = false;

  /// Start tracking auth state. Called once from [initFirebaseSafe] after
  /// Firebase is up. Idempotent.
  static void bind() {
    if (_bound) return;
    _bound = true;
    try {
      _auth.authStateChanges().listen((user) async {
        if (user == null) {
          current.value = null;
          return;
        }
        // Show the auth-only view immediately, then enrich from Firestore.
        current.value = _fromAuth(user);
        await _syncDoc(user);
      });
    } catch (e) {
      debugPrint('AuthService.bind skipped: $e');
    }
  }

  static HpgUser _fromAuth(User u) => HpgUser(
        uid: u.uid,
        email: u.email,
        displayName: u.displayName,
        phoneNumber: u.phoneNumber,
        photoURL: u.photoURL,
        isAnonymous: u.isAnonymous,
      );

  /// Ensure `users/{uid}` exists and refresh login bookkeeping, then merge the
  /// stored profile (theme, notifications, displayName…) into [current].
  static Future<void> _syncDoc(User u) async {
    try {
      final ref = _db.collection('users').doc(u.uid);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          'uid': u.uid,
          'email': u.email,
          'displayName': u.displayName,
          'phoneNumber': u.phoneNumber,
          'photoURL': u.photoURL,
          'theme': 'dark',
          'notifications': true,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        // Only allowlisted fields may be touched on update (see firestore.rules
        // users/{uid} allowedFields). email/isActive are set once at create.
        await ref.set({
          'lastLogin': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      final data = (await ref.get()).data() ?? const {};
      final merged = HpgUser(
        uid: u.uid,
        email: u.email ?? data['email'] as String?,
        displayName: data['displayName'] as String? ?? u.displayName,
        phoneNumber: data['phoneNumber'] as String? ?? u.phoneNumber,
        photoURL: data['photoURL'] as String? ?? u.photoURL,
        theme: data['theme'] as String? ?? 'dark',
        notifications: data['notifications'] as bool? ?? true,
        isAnonymous: u.isAnonymous,
      );
      current.value = merged;
      // Keep the in-game avatar/name in sync with the signed-in account.
      AuthProfile.set(name: merged.displayName, avatarUrl: merged.photoURL);
    } catch (e) {
      debugPrint('AuthService._syncDoc skipped: $e');
    }
  }

  // ── Sign-in flows (these surface their errors to the caller) ──

  static Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
  }

  /// Create an account. If the visitor is currently anonymous, upgrade that
  /// session in place (keeping their uid + progress) by linking credentials.
  static Future<void> registerWithEmail(String email, String password) async {
    final cred =
        EmailAuthProvider.credential(email: email.trim(), password: password);
    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      await user.linkWithCredential(cred);
      await user.reload();
      await _syncDoc(_auth.currentUser!);
    } else {
      await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
    }
  }

  static Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('AuthService.signOut: $e');
    }
  }

  /// Patch the profile doc and reflect it locally. Auth-managed fields
  /// (displayName/photoURL) are pushed to the Auth record too.
  static Future<void> updateProfile({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    final u = _auth.currentUser;
    if (u == null) return;
    try {
      // Only allowlisted users/{uid} fields (see firestore.rules).
      final patch = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        if (displayName != null) 'displayName': displayName,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
        if (photoURL != null) 'photoURL': photoURL,
      };
      await _db
          .collection('users')
          .doc(u.uid)
          .set(patch, SetOptions(merge: true));
      if (displayName != null) await u.updateDisplayName(displayName);
      if (photoURL != null) await u.updatePhotoURL(photoURL);
      current.value = current.value?.copyWith(
        displayName: displayName,
        phoneNumber: phoneNumber,
        photoURL: photoURL,
      );
      final c = current.value;
      if (c != null) AuthProfile.set(name: c.displayName, avatarUrl: c.photoURL);
    } catch (e) {
      debugPrint('AuthService.updateProfile: $e');
      rethrow;
    }
  }
}
