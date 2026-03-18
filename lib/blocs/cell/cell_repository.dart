import 'package:cell_mobile/models/organelle.dart';
import 'package:flutter/material.dart';

class CellRepository {
  CellRepository({required this.currentIndex});
  int currentIndex;

  static List<OrganelleInfo> get organelles => organelles;


  OrganelleInfo get organelleInFocus => organelles[currentIndex];

}