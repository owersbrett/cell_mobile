part of 'cell_bloc.dart';

@immutable
class CellState {
  CellState({@required this.organelleInfo});

  final OrganelleInfo organelleInfo;
}



enum Organelle {
  nucleolus,
  nucleic_acids,
  rna,
  base_pairs,
  dna,
  nucleoplasm,
  nuclear_envelope,
  nuclear_pore,
  nucleus,
  nuclear_membrane,
  cytoplasm,
  smooth_endoplasmic_reticulum,
  ribosomes,
  rough_endoplasmic_reticulum,
  golgi_apparatus,
  mitochondrion,
  vacuoles,
  microtubules,
  centrioles,
  lysosome,
  peroxisome,
  secretory_vesicles,
  membrane_proteins,
  cell_membrane,
  microfilament,
  microvilli
}

class EnumHelper {
  static Organelle nextOrganelle(Organelle organelle) {
    Organelle _nextOrganelle;
    switch (organelle) {
      case Organelle.nucleolus:
      _nextOrganelle =Organelle.nucleic_acids;
        break;
      case Organelle.nucleic_acids:
      _nextOrganelle =Organelle.rna;
        break;
      case Organelle.rna:
      _nextOrganelle =Organelle.base_pairs;
        break;
      case Organelle.base_pairs:
      _nextOrganelle =Organelle.dna;
        break;
      case Organelle.dna:
      _nextOrganelle =Organelle.nucleoplasm;
        break;
      case Organelle.nucleoplasm:
      _nextOrganelle =Organelle.nuclear_membrane;
        break;
      case Organelle.nuclear_membrane:
      _nextOrganelle =Organelle.smooth_endoplasmic_reticulum;
        break;
      case Organelle.smooth_endoplasmic_reticulum:
      _nextOrganelle =Organelle.ribosomes;
        break;
      case Organelle.ribosomes:
      _nextOrganelle =Organelle.rough_endoplasmic_reticulum;
        break;
      case Organelle.rough_endoplasmic_reticulum:
      _nextOrganelle =Organelle.golgi_apparatus;
        break;
      case Organelle.microtubules:
      _nextOrganelle =Organelle.centrioles;
        break;
      case Organelle.centrioles:
      _nextOrganelle =Organelle.mitochondrion;
        break;
      case Organelle.mitochondrion:
      _nextOrganelle =Organelle.vacuoles;
        break;
      case Organelle.vacuoles:
      _nextOrganelle =Organelle.peroxisome;
        break;
      case Organelle.peroxisome:
      _nextOrganelle =Organelle.cytoplasm;
        break;
      case Organelle.cytoplasm:
      _nextOrganelle =Organelle.cell_membrane;
        break;
      case Organelle.secretory_vesicles:
      _nextOrganelle =Organelle.membrane_proteins;
        break;
      case Organelle.membrane_proteins:
      _nextOrganelle =Organelle.cell_membrane;
        break;
      case Organelle.cell_membrane:
      _nextOrganelle =Organelle.microfilament;
        break;
      case Organelle.microfilament:
      _nextOrganelle =Organelle.microvilli;
        break;
      case Organelle.microvilli:
      _nextOrganelle =Organelle.nucleoplasm;
        break;
      default:
        _nextOrganelle = null;
    }
    return _nextOrganelle;
  }

  static Organelle previousOrganelle(Organelle organelle) {
     Organelle _previousOrganelle;
    switch (organelle) {
      case Organelle.nucleic_acids:
      _previousOrganelle =Organelle.nucleolus;
        break;
      case Organelle.rna:
      _previousOrganelle =Organelle.nucleic_acids;
        break;
      case Organelle.base_pairs:
      _previousOrganelle =Organelle.rna;
        break;
      case Organelle.dna:
      _previousOrganelle =Organelle.base_pairs;
        break;
      case Organelle.nucleoplasm:
      _previousOrganelle =Organelle.dna;
        break;
      case Organelle.nuclear_membrane:
      _previousOrganelle =Organelle.nucleoplasm;
        break;
      case Organelle.smooth_endoplasmic_reticulum:
      _previousOrganelle =Organelle.ribosomes;
        break;
      case Organelle.ribosomes:
      _previousOrganelle =Organelle.smooth_endoplasmic_reticulum;
        break;
      case Organelle.rough_endoplasmic_reticulum:
      _previousOrganelle =Organelle.ribosomes;
        break;
      case Organelle.golgi_apparatus:
      _previousOrganelle =Organelle.rough_endoplasmic_reticulum;
        break;
      case Organelle.microtubules:
      _previousOrganelle =Organelle.golgi_apparatus;
        break;
      case Organelle.centrioles:
      _previousOrganelle =Organelle.microtubules;
        break;
      case Organelle.mitochondrion:
      _previousOrganelle =Organelle.centrioles;
        break;
      case Organelle.vacuoles:
      _previousOrganelle =Organelle.mitochondrion;
        break;
      case Organelle.peroxisome:
      _previousOrganelle =Organelle.vacuoles;
        break;
      case Organelle.cytoplasm:
      _previousOrganelle =Organelle.peroxisome;
        break;
      case Organelle.cell_membrane:
      _previousOrganelle =Organelle.cytoplasm;
        break;
      case Organelle.membrane_proteins:
      _previousOrganelle =Organelle.cell_membrane;
        break;
      case Organelle.cell_membrane:
      _previousOrganelle =Organelle.microfilament;
        break;
      case Organelle.microfilament:
      _previousOrganelle =Organelle.microvilli;
        break;
      case Organelle.microvilli:
      _previousOrganelle =Organelle.nucleoplasm;
        break;
      default:
        _previousOrganelle = null;
    }
    return _previousOrganelle;
  }
}
