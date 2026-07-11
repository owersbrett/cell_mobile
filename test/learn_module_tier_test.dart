import 'package:cell_mobile/data/bio_entity_registry.dart';
import 'package:cell_mobile/data/scales/scale_modules.dart';
import 'package:cell_mobile/models/bio_entity.dart';
import 'package:cell_mobile/models/learn_module.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final registry = BioEntityRegistry();

  test('module ids are unique and scale-namespaced', () {
    expect(debugValidateModules(), isTrue);
  });

  test('every scale has at least an Introductory module', () {
    for (final scale in BioScale.values) {
      final modules = registry.modulesForScale(scale);
      expect(modules, isNotEmpty, reason: '$scale has no modules');
      expect(modules.first.kind, ModuleKind.intro,
          reason: '$scale must lead with Introductory');
    }
  });

  test('legacy (moduleId-less) entities fall into their scale intro module',
      () {
    // The invariant, scale-agnostic (so this doesn't break every time a scale
    // gains modules): for EVERY scale, its Introductory module holds exactly
    // the entities with no explicit moduleId — that IS the null→intro migration.
    for (final scale in BioScale.values) {
      final intro = registry.getByModule(LearnModule.introId(scale));
      final seed =
          registry.getByScale(scale).where((e) => e.moduleId == null).toList();
      expect(intro.length, seed.length, reason: '$scale intro != seed count');
      expect(intro.every((e) => e.moduleId == null), isTrue,
          reason: '$scale intro has a non-seed entity');
    }
  });

  test('Infinity exposes the full math curriculum, spine-ordered', () {
    final modules = registry.modulesForScale(BioScale.infinities);
    expect(modules.length, 6);
    // intro → topics → potato
    expect(modules.first.kind, ModuleKind.intro);
    expect(modules.last.kind, ModuleKind.potato);
    final ids = modules.map((m) => m.id).toList();
    expect(
        ids,
        containsAll(<String>[
          'infinities_calc1',
          'infinities_calc2',
          'infinities_calc3',
          'infinities_linear_algebra',
          'infinities_potato',
        ]));
    // Every module has real content.
    for (final m in modules) {
      expect(registry.getByModule(m.id), isNotEmpty, reason: '${m.id} empty');
    }
  });

  test('Atoms periodic table is complete: 118 elements, Z-ordered, no gaps', () {
    final elements = registry.getByModule('atoms_periodic_table');
    expect(elements.length, 118, reason: 'expected all 118 elements');
    // getByModule sorts by position; position = Z − 1, so this must be 0..117.
    for (var i = 0; i < elements.length; i++) {
      expect(elements[i].position, i,
          reason: 'gap or duplicate at atomic number ${i + 1}');
    }
    // Bookends by convention.
    expect(elements.first.name, 'Hydrogen');
    expect(elements.last.name, 'Oganesson');
    // Ids are unique.
    final ids = elements.map((e) => e.id).toSet();
    expect(ids.length, 118);
  });

  test('Atoms exposes intro → Periodic Table → Potato, spine-ordered', () {
    final modules = registry.modulesForScale(BioScale.atoms);
    expect(modules.first.kind, ModuleKind.intro);
    expect(modules.last.kind, ModuleKind.potato);
    expect(modules.map((m) => m.id),
        containsAll(<String>['atoms_periodic_table', 'atoms_potato']));
    expect(registry.getByModule('atoms_potato'), hasLength(6));
  });

  test('Particles Standard Model has all 17 fundamental particles, ordered', () {
    final sm = registry.getByModule('particles_standard_model');
    expect(sm.length, 17, reason: '12 fermions + 5 bosons');
    for (var i = 0; i < sm.length; i++) {
      expect(sm[i].position, i, reason: 'gap/dup at position $i');
    }
    // Fermions lead (0–11), bosons close (12–16).
    expect(sm.first.name, contains('Up'));
    expect(sm.last.name, contains('Higgs'));
  });

  test('Particles exposes intro → 3 topics → Potato, spine-ordered', () {
    final modules = registry.modulesForScale(BioScale.particles);
    expect(modules.first.kind, ModuleKind.intro);
    expect(modules.last.kind, ModuleKind.potato);
    expect(
        modules.map((m) => m.id),
        containsAll(<String>[
          'particles_standard_model',
          'particles_forces',
          'particles_beyond',
          'particles_potato',
        ]));
  });

  test('Cell exposes intro → Types/Neuro/Life → Potato, spine-ordered', () {
    final modules = registry.modulesForScale(BioScale.cell);
    expect(modules.first.kind, ModuleKind.intro);
    expect(modules.last.kind, ModuleKind.potato);
    expect(
        modules.map((m) => m.id),
        containsAll(<String>[
          'cell_types',
          'cell_neurobiology',
          'cell_life',
          'cell_potato',
        ]));
    expect(registry.getByModule('cell_neurobiology'), hasLength(10));
  });

  test('every authored module entity carries the matching moduleId', () {
    for (final m in kExtraModules) {
      for (final e in registry.getByModule(m.id)) {
        expect(e.moduleId, m.id);
        expect(e.scale, m.scale);
      }
    }
  });
}
