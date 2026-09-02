import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Z-order for VIPotato trait layers — mirrors the site's `TRAIT_Z_INDEX` so the
/// composed avatar stacks identically here and on hotpotatogames.com.
const Map<String, int> kTraitZIndex = {
  'background': 1,
  'body': 2,
  'skin': 2,
  'eyes': 3,
  'third-eye': 3,
  'mouth': 4,
  'outfit': 5,
  'shirt': 5,
  'hat': 6,
  'accessory': 7,
  'aura': 8,
  'element': 9,
  'state': 10,
};

int traitZIndex(String category) =>
    kTraitZIndex[category.toLowerCase().trim()] ?? 5;

/// One trait option from the `traits` collection: a transparent PNG overlay
/// belonging to a category (hat, eyes, outfit…).
@immutable
class Trait {
  final String id;
  final String category; // the doc's `trait` field
  final String rarity;
  final String theme;
  final String imageUrl;

  const Trait({
    required this.id,
    required this.category,
    required this.rarity,
    required this.theme,
    required this.imageUrl,
  });

  factory Trait.fromDoc(String id, Map<String, dynamic> d) => Trait(
        id: id,
        category: (d['trait'] ?? 'uncategorized') as String,
        rarity: (d['rarity'] ?? 'common') as String,
        theme: (d['theme'] ?? '') as String,
        imageUrl: (d['imageUrl'] ?? '') as String,
      );

  /// Rebuild a trait from a saved `vipotatoes.traits[category]` entry (which
  /// already carries everything needed to render — no traits-collection join).
  factory Trait.fromSaved(String category, Map<String, dynamic> d) => Trait(
        id: (d['traitId'] ?? '') as String,
        category: category,
        rarity: (d['rarity'] ?? 'common') as String,
        theme: (d['theme'] ?? '') as String,
        imageUrl: (d['imageUrl'] ?? '') as String,
      );
}

/// A built avatar: one selected trait per category. Mirrors a `vipotatoes` doc.
class VIPotatoConfig {
  final String? id; // Firestore doc id when persisted
  String name;
  final Map<String, Trait> traits; // category -> chosen trait

  VIPotatoConfig({this.id, this.name = '', Map<String, Trait>? traits})
      : traits = traits ?? {};

  bool get isEmpty => traits.isEmpty;

  /// Layers bottom→top, ready to stack.
  List<Trait> get layers => traits.values.toList()
    ..sort(
        (a, b) => traitZIndex(a.category).compareTo(traitZIndex(b.category)));

  /// The `traits` map shape persisted in a `vipotatoes` doc.
  Map<String, dynamic> traitsField() => {
        for (final e in traits.entries)
          e.key: {
            'traitId': e.value.id,
            'theme': e.value.theme,
            'rarity': e.value.rarity,
            'imageUrl': e.value.imageUrl,
          },
      };

  factory VIPotatoConfig.fromDoc(String id, Map<String, dynamic> d) {
    final raw = (d['traits'] as Map?)?.cast<String, dynamic>() ?? const {};
    final traits = <String, Trait>{};
    raw.forEach((category, value) {
      if (value is Map) {
        traits[category] =
            Trait.fromSaved(category, value.cast<String, dynamic>());
      }
    });
    return VIPotatoConfig(
      id: id,
      name: (d['name'] ?? '') as String,
      traits: traits,
    );
  }
}

/// Reads the trait catalogue and the user's equipped avatar, and saves/equips a
/// new build — all against the SAME `hot-potato-games` Firestore collections the
/// website uses, so a potato built here is the same avatar everywhere.
class VIPotatoService {
  VIPotatoService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// The current user's equipped avatar, kept live so the home corner and the
  /// account sheet both reflect a freshly-built potato. Updated by
  /// [loadEquipped] and [saveAndEquip].
  static final ValueNotifier<VIPotatoConfig?> equipped =
      ValueNotifier<VIPotatoConfig?>(null);

  /// All traits, grouped by category and ordered by layer z-index. Empty on any
  /// failure (offline / rules) — the builder shows an empty state, never throws.
  static Future<Map<String, List<Trait>>> loadTraitsByCategory() async {
    try {
      final snap = await _db.collection('traits').get();
      final all = snap.docs
          .map((d) => Trait.fromDoc(d.id, d.data()))
          .where((t) => t.imageUrl.isNotEmpty)
          .toList();
      final grouped = <String, List<Trait>>{};
      for (final t in all) {
        grouped.putIfAbsent(t.category, () => []).add(t);
      }
      final ordered = grouped.entries.toList()
        ..sort((a, b) => traitZIndex(a.key).compareTo(traitZIndex(b.key)));
      return {for (final e in ordered) e.key: e.value};
    } catch (e) {
      debugPrint('VIPotatoService.loadTraitsByCategory: $e');
      return {};
    }
  }

  /// The current user's equipped avatar, or null if none / signed out.
  static Future<VIPotatoConfig?> loadEquipped() async {
    final uid = _uid;
    if (uid == null) {
      equipped.value = null;
      return null;
    }
    try {
      final snap = await _db
          .collection('vipotatoes')
          .where('userId', isEqualTo: uid)
          .where('isEquipped', isEqualTo: true)
          .limit(1)
          .get();
      final config = snap.docs.isEmpty
          ? null
          : VIPotatoConfig.fromDoc(snap.docs.first.id, snap.docs.first.data());
      equipped.value = config;
      return config;
    } catch (e) {
      debugPrint('VIPotatoService.loadEquipped: $e');
      return null;
    }
  }

  /// Persist [config] (create or update) and equip it, unequipping the user's
  /// other potatoes. Returns the saved config (with its id). Throws on failure
  /// so the builder can surface it.
  static Future<VIPotatoConfig> saveAndEquip(VIPotatoConfig config) async {
    final uid = _uid;
    if (uid == null) throw StateError('Sign in to save your potato.');
    final col = _db.collection('vipotatoes');

    final data = {
      'name': config.name.trim().isEmpty ? 'My Potato' : config.name.trim(),
      'traits': config.traitsField(),
      'userId': uid,
      'isEquipped': true,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    String docId;
    if (config.id != null) {
      await col.doc(config.id).set(data, SetOptions(merge: true));
      docId = config.id!;
    } else {
      // Next ordinal across the collection (matches the site's scheme).
      int nextOrdinal = 1;
      final top = await col.orderBy('ordinal', descending: true).limit(1).get();
      if (top.docs.isNotEmpty) {
        nextOrdinal =
            ((top.docs.first.data()['ordinal'] ?? 0) as num).toInt() + 1;
      }
      final ref = await col.add({
        ...data,
        'ordinal': nextOrdinal,
        'bio': '',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
      docId = ref.id;
    }

    // Equip exclusively: unequip the user's other potatoes.
    final mine = await col.where('userId', isEqualTo: uid).get();
    final batch = _db.batch();
    for (final d in mine.docs) {
      batch.update(d.reference, {'isEquipped': d.id == docId});
    }
    await batch.commit();

    final saved =
        VIPotatoConfig(id: docId, name: config.name, traits: config.traits);
    equipped.value = saved;
    return saved;
  }
}
