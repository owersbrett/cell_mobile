import 'package:cell_mobile/blocs/cell/cell_bloc.dart';
import 'package:cell_mobile/models/organelle.dart';
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
      default:
    }

   return image;
   return animatedImage;
  }
}

