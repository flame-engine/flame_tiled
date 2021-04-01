import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:tiled/tiled.dart';

import 'dart:ui';

import './tiled.dart';

class TiledComponent extends IsometricTileMapComponent {
  final SpriteSheet tileset;
  final List<List<int>> matrix;

  Tiled _tiled;

  TiledComponent(String filename, Size destTileSize,{this.matrix, this.tileset}) : super(tileset, matrix) {
    _tiled = Tiled(filename, destTileSize);
  }

  TiledComponent.fromTiled(this._tiled,{this.matrix, this.tileset}) :  super(tileset, matrix) ;

  @override
  void update(double dt) {

  }

  @override
  void render(Canvas canvas) {
    _tiled.render(canvas);
  }

  @override
  bool loaded() => _tiled.loaded();

  get future => _tiled.future;

  Future<ObjectGroup> getObjectGroupFromLayer(String name) =>
      _tiled.getObjectGroupFromLayer(name);
}
