import 'package:cell_mobile/blocs/cell/cell_bloc.dart';
import 'package:cell_mobile/models/organelle.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/genetic_animation.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/plasm_animation.dart';
import 'package:flutter/material.dart';

import 'nucleolus.dart';

class CellAnimationDelegate {
  static Widget organelle(OrganelleInfo organelleInfo) {
    Widget image = Image.asset(organelleInfo.mainImagePath);
    Widget animatedImage;
    switch (organelleInfo.organelle) {
      case Organelle.nucleolus:
        return Nucleolus(organelleInfo: organelleInfo);
        break;
      case Organelle.nucleic_acids:
        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: GeneticAnimation(
            organelleInfo: organelleInfo,
            fast: false,
            right: false,
          ),
        );
      case Organelle.rna:
        return GeneticAnimation(
          organelleInfo: organelleInfo,
          fast: false,
          right: true,
        );
      case Organelle.base_pairs:
        return GeneticAnimation(
          organelleInfo: organelleInfo,
          fast: true,
          right: false,
        );
      case Organelle.dna:
        return GeneticAnimation(
          organelleInfo: organelleInfo,
          fast: true,
          right: true,
        );
      case Organelle.nucleoplasm:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: PlasmAnimation(image: image),
        );
      case Organelle.nuclear_membrane:
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: image,
        );
      default:
    }

    return image;
    return animatedImage;
  }
}
