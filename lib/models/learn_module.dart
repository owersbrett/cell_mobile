import 'package:flutter/material.dart';

import 'package:cell_mobile/models/bio_entity.dart';

/// The middle tier of the LEARN hierarchy: **Scale → Module → Entity**.
///
/// A scale (e.g. Atoms) is no longer a flat list of entities. It holds an
/// ordered set of [LearnModule]s, each a self-contained mini-course of
/// entities. Every scale is bracketed by convention:
///
///   Introductory ([ModuleKind.intro])  →  topic modules  →  Potato ([ModuleKind.potato])
///
/// The Introductory module is the low-friction "what is this scale" on-ramp
/// (today it holds the original seed entities). The Potato module is the
/// on-brand bookend — the scale seen through a potato (its atoms, its
/// molecules, its organs…), a teaching constraint, not a gimmick.
enum ModuleKind {
  /// First module of every scale — the on-ramp. Holds legacy seed entities
  /// (any [BioEntity] with a null `moduleId` falls here).
  intro,

  /// A focused breadth module between the bookends (e.g. "The Periodic Table",
  /// "Neurobiology", "The Standard Model").
  topic,

  /// Last module of every scale — the potato lens.
  potato,
}

@immutable
class LearnModule {
  /// Stable id, namespaced by scale: `'<scale>_<slug>'`
  /// (e.g. `'atoms_intro'`, `'atoms_periodic_table'`, `'atoms_potato'`).
  final String id;

  /// The scale this module belongs to.
  final BioScale scale;

  /// Display title (e.g. "The Periodic Table").
  final String title;

  /// One-line flavour under the title.
  final String subtitle;

  /// Module icon for the picker.
  final IconData icon;

  /// Where this module sits in the Introductory→topic→Potato spine.
  final ModuleKind kind;

  const LearnModule({
    required this.id,
    required this.scale,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.kind,
  });

  /// The canonical id of a scale's Introductory module. Any entity whose
  /// `moduleId` is null is treated as belonging here — that is how all the
  /// pre-module seed content migrates in with zero edits to the entity files.
  static String introId(BioScale scale) => '${scale.name}_intro';
}
