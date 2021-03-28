import 'package:flame/components.dart';
import 'package:tiled/tiled.dart';

import 'dart:ui';

import './tiled.dart';

class TiledComponent extends Component {
  Tiled? _tiled;

  TiledComponent(String filename, Size destTileSize) {
    _tiled = Tiled(filename, destTileSize);
  }

  TiledComponent.fromTiled(this._tiled);

  @override
  void update(double dt) {}

  @override
  void render(Canvas canvas) {
    _tiled!.render(canvas);
  }

  bool loaded() => _tiled!.loaded();

  get future => _tiled!.future;

  Future<ObjectGroup> getObjectGroupFromLayer(String name) =>
      _tiled!.getObjectGroupFromLayer(name);
}
