import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/widgets.dart' hide Animation, Image;
import 'package:tiled/tiled.dart' show ObjectGroup, TmxObject;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Flame.images.load('coins.png');
  runApp(GameWidget(
    game: TiledGame(),
  ));
}

class TiledGame extends BaseGame {
  late Image coins;

  @override
  Future<void> onLoad() async {
    final TiledComponent tiledMap = TiledComponent('map.tmx', Size(16.0, 16.0));
    add(tiledMap);
    _addCoinsInMap(tiledMap);
  }

  void _addCoinsInMap(TiledComponent tiledMap) async {
    final ObjectGroup objGroup =
        await tiledMap.getObjectGroupFromLayer("AnimatedCoins");
    coins = await images.load('coins.png');

    objGroup.tmxObjects.forEach((TmxObject obj) {
      final comp = SpriteAnimationComponent(
        position: Vector2(20.0, 20.0),
        animation: SpriteAnimation.fromFrameData(
          coins,
          SpriteAnimationData.sequenced(
            amount: 8,
            textureSize: Vector2.all(20),
            stepTime: 0.15,
          ),
        ),
      );
      comp.x = obj.x.toDouble();
      comp.y = obj.y.toDouble();
      add(comp);
    });
  }
}
