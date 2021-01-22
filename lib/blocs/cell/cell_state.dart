part of 'cell_bloc.dart';

@immutable
class CellState {
  CellState({@required this.organelleInfo});

  final OrganelleInfo organelleInfo;
}



enum Organelle {
  nucleolous,
  nucleoplasm,
  nuclear_envelope,
  nuclear_pore,
  nucleus,
  cytoplasm,
  smooth_endoplasmic_reticulum,
  ribosomes,
  rough_endoplasmic_reticulum,
  golgi_apparatus,
  mitochondrion,
  microtubules,
  centrosome,
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
      case Organelle.nucleolous:
      _nextOrganelle =Organelle.nucleoplasm;
        break;
      case Organelle.nucleoplasm:
      _nextOrganelle =Organelle.nuclear_envelope;
        break;
      case Organelle.nuclear_envelope:
      _nextOrganelle =Organelle.nuclear_pore;
        break;
      case Organelle.nuclear_pore:
      _nextOrganelle =Organelle.nucleus;
        break;
      case Organelle.nucleus:
      _nextOrganelle =Organelle.cytoplasm;
        break;
      case Organelle.cytoplasm:
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
      case Organelle.golgi_apparatus:
      _nextOrganelle =Organelle.mitochondrion;
        break;
      case Organelle.mitochondrion:
      _nextOrganelle =Organelle.microtubules;
        break;
      case Organelle.microtubules:
      _nextOrganelle =Organelle.ribosomes;
        break;
      case Organelle.ribosomes:
      _nextOrganelle =Organelle.centrosome;
        break;
      case Organelle.centrosome:
      _nextOrganelle =Organelle.lysosome;
        break;
      case Organelle.lysosome:
      _nextOrganelle =Organelle.peroxisome;
        break;
      case Organelle.peroxisome:
      _nextOrganelle =Organelle.secretory_vesicles;
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
      case Organelle.nucleolous:
      _previousOrganelle =Organelle.nucleoplasm;
        break;
      case Organelle.nucleoplasm:
      _previousOrganelle =Organelle.nuclear_envelope;
        break;
      case Organelle.nuclear_envelope:
      _previousOrganelle =Organelle.nuclear_pore;
        break;
      case Organelle.nuclear_pore:
      _previousOrganelle =Organelle.nucleus;
        break;
      case Organelle.nucleus:
      _previousOrganelle =Organelle.cytoplasm;
        break;
      case Organelle.cytoplasm:
      _previousOrganelle =Organelle.smooth_endoplasmic_reticulum;
        break;
      case Organelle.smooth_endoplasmic_reticulum:
      _previousOrganelle =Organelle.ribosomes;
        break;
      case Organelle.ribosomes:
      _previousOrganelle =Organelle.rough_endoplasmic_reticulum;
        break;
      case Organelle.rough_endoplasmic_reticulum:
      _previousOrganelle =Organelle.golgi_apparatus;
        break;
      case Organelle.golgi_apparatus:
      _previousOrganelle =Organelle.mitochondrion;
        break;
      case Organelle.mitochondrion:
      _previousOrganelle =Organelle.microtubules;
        break;
      case Organelle.microtubules:
      _previousOrganelle =Organelle.ribosomes;
        break;
      case Organelle.ribosomes:
      _previousOrganelle =Organelle.centrosome;
        break;
      case Organelle.centrosome:
      _previousOrganelle =Organelle.lysosome;
        break;
      case Organelle.lysosome:
      _previousOrganelle =Organelle.peroxisome;
        break;
      case Organelle.peroxisome:
      _previousOrganelle =Organelle.secretory_vesicles;
        break;
      case Organelle.secretory_vesicles:
      _previousOrganelle =Organelle.membrane_proteins;
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
