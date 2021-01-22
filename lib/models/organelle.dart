import 'package:cell_mobile/blocs/cell/cell_bloc.dart';
import 'package:flutter/material.dart';

class OrganelleInfo {
  final int position;
  final Organelle organelle;
  final String name;
  final String mainImagePath;
  final String shortDescription;
  final String longDescription;
  final List<String> carouselImagesPaths;

  OrganelleInfo(this.position, {
    @required this.name,
     @required this.organelle,
    @required this.mainImagePath,
    @required this.shortDescription,
    @required this.longDescription,
    @required this.carouselImagesPaths
  });
}

