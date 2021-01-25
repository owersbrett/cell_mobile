import 'package:cell_mobile/blocs/cell/cell_bloc.dart';
import 'package:cell_mobile/models/organelle.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/genetic_animation.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/plasm_animation.dart';
import 'package:cell_mobile/views/screens/cell_page/animations/ribosome_animation.dart';
import 'package:flutter/material.dart';

import 'mitochondria.dart';
import 'nucleolus.dart';

class CellAnimationDelegate {
  static Widget organelle(OrganelleInfo organelleInfo) {
    Widget image = Image.asset(organelleInfo.mainImagePath);
    switch (organelleInfo.organelle) {
      case Organelle.nucleolus:
        return Nucleolus(organelleInfo: organelleInfo);
        break;
      case Organelle.nucleotide:
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
      case Organelle.smooth_endoplasmic_reticulum:
        return Padding(
          padding: const EdgeInsets.only(bottom: 11.0, right: 4),
          child: image,
        );
      case Organelle.ribosomes:
        return Padding(
          padding: const EdgeInsets.only(bottom: 11.0, right: 4),
          child: RibosomeAnimation(
              path: organelleInfo.mainImagePath, persistant: true),
        );
      case Organelle.rough_endoplasmic_reticulum:
        return Padding(
          padding: const EdgeInsets.only(bottom: 11.0, right: 4),
          child: RibosomeAnimation(
              path: organelleInfo.mainImagePath, persistant: false),
        );
      case Organelle.golgi_apparatus:
        return Padding(
          padding: const EdgeInsets.only(bottom: 11.0, right: 4),
          child: Transform.translate(
            offset: Offset(-15, 10),
            child: Transform.scale(
              scale: .75,
              child: RibosomeAnimation(
                path: organelleInfo.mainImagePath,
                persistant: false,
              ),
            ),
          ),
        );
      case Organelle.microtubules:
        return RibosomeAnimation(
          path: organelleInfo.mainImagePath,
          persistant: false,
        );
      case Organelle.centrioles:
        return RibosomeAnimation(
          path: organelleInfo.mainImagePath,
          persistant: false,
        );
      case Organelle.mitochondrion:
        return Mitochondria(
          organelleInfo: organelleInfo,
        );
      case Organelle.vacuoles:
        return Transform.scale(
          scale: 1.006,
                  child: RibosomeAnimation(
            path: organelleInfo.mainImagePath,
            persistant: true,
          ),
        );
      case Organelle.peroxisome:
        return Transform.scale(
          scale: 1.01,
                  child: RibosomeAnimation(
            path: organelleInfo.mainImagePath,
            persistant: true,
          ),
        );

      default:
    }

    return image;
  }
}
