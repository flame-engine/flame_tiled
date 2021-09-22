import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/widgets.dart' hide Animation, Image;
import 'package:tiled/tiled.dart' show ObjectGroup, TiledObject;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //Flame.images.load('coins.png');
  runApp(GameWidget(
    game: TiledGame(),
  ));
}

class TiledGame extends BaseGame {

  @override
  Future<void> onLoad() async {
    final TiledComponent tiledMap = TiledComponent('map.tmx', Size(16.0, 16.0));
    add(tiledMap);
    _addCoinsInMap(tiledMap);
  }

  void _addCoinsInMap(TiledComponent tiledMap) async {
    final ObjectGroup objGroup =
        await tiledMap.getObjectGroupFromLayer("AnimatedCoins");
    final sprite = await Sprite.load('coins.png');
    objGroup.objects.forEach((TiledObject obj) {
      final comp = SpriteAnimationComponent(
        animation: SpriteAnimation.fromFrameData(
          sprite.image,
          SpriteAnimationData.sequenced(
            amount: 8,
            textureSize: Vector2.all(20),
            stepTime: 0.15,
          ),
        ),
        position: Vector2(obj.x, obj.y),
        size: Vector2.all(20),
      );

      add(comp);
    });
  }
}
