import 'package:flutter/material.dart';
import 'constants.dart';
import 'values.dart';

class Piece {
  BlockShape type;
  List<int> position;

  Piece({required this.type, required this.position});

  // Calculate grid indices based on starting point and shape coordinates
  List<int> getGridIndices() {
    final coordinates = BlockShapeValues.coordinates[type] ?? [];
    List<int> gridIndices = [];
    
    for (int i = 0; i < coordinates.length; i += 2) {
      int xOffset = coordinates[i];
      int yOffset = coordinates[i + 1];
      int gridRow = position[1] + yOffset;
      int gridCol = position[0] + xOffset;
      gridIndices.add(gridRow);
      gridIndices.add(gridCol);
    }
    
    return gridIndices;
  }

  // Get the neon color for this piece
  Color get neonColor {
    return BlockShapeValues.neonColors[type] ?? Colors.grey;
  }

  // Get the shape coordinates relative to origin
  List<int> getShapeCoordinates() {
    return BlockShapeValues.coordinates[type] ?? [];
  }

  // Check if a specific grid position is occupied by this piece
  bool occupiesPosition(int row, int col) {
    final indices = getGridIndices();
    for (int i = 0; i < indices.length; i += 2) {
      if (indices[i] == row && indices[i + 1] == col) {
        return true;
      }
    }
    return false;
  }
}