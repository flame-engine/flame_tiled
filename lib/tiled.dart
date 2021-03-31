import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';
import 'package:xml/xml.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:tiled/tiled.dart' hide Image;

/// Tiled represents all flips and rotation using three possible flips: horizontal, vertical and diagonal.
/// This class converts that representation to a simpler one, that uses one angle (with pi/2 steps) and two flips (H or V).
/// More reference: https://doc.mapeditor.org/en/stable/reference/tmx-map-format/#tile-flipping
class _SimpleFlips {
  /// The angle (in steps of pi/2 rads), clockwise, around the center of the tile.
  final int angle;

  /// Whether to flip across a central vertical axis (passing through the center).
  final bool flipH;

  /// Whether to flip across a central horizontal axis (passing through the center).
  final bool flipV;

  _SimpleFlips(this.angle, this.flipH, this.flipV);

  /// This is the conversion from the truth table that I drew.
  factory _SimpleFlips.fromFlips(Flips flips) {
    int angle;
    bool flipV, flipH;

    if (!flips.diagonally && !flips.vertically && !flips.horizontally) {
      angle = 0;
      flipV = false;
      flipH = false;
    } else if (!flips.diagonally && !flips.vertically && flips.horizontally) {
      angle = 0;
      flipV = false;
      flipH = true;
    } else if (!flips.diagonally && flips.vertically && !flips.horizontally) {
      angle = 0;
      flipV = true;
      flipH = false;
    } else if (!flips.diagonally && flips.vertically && flips.horizontally) {
      angle = 2;
      flipV = false;
      flipH = false;
    } else if (flips.diagonally && !flips.vertically && !flips.horizontally) {
      angle = 1;
      flipV = false;
      flipH = true;
    } else if (flips.diagonally && !flips.vertically && flips.horizontally) {
      angle = 1;
      flipV = false;
      flipH = false;
    } else if (flips.diagonally && flips.vertically && !flips.horizontally) {
      angle = 3;
      flipV = false;
      flipH = false;
    } else if (flips.diagonally && flips.vertically && flips.horizontally) {
      angle = 1;
      flipV = true;
      flipH = false;
    } else {
      // this should be exhaustive
      throw 'Invalid combination of booleans: $flips';
    }

    return _SimpleFlips(angle, flipH, flipV);
  }
}

/// This component renders a tile map based on a TMX file from Tiled.
class Tiled {
  String filename;
  TileMap map;
  Image image;
  Map<String, SpriteBatch> batches = <String, SpriteBatch>{};
  Future future;
  bool _loaded = false;
  Size destTileSize;

  static Paint paint = Paint()..color = Colors.white;

  /// Creates this Tiled with the filename (for the tmx file resource)
  /// and destTileSize is the tile size to be rendered (not the tile size in the texture, that one is configured inside Tiled).
  Tiled(this.filename, this.destTileSize) {
    future = _load();
  }

  Future _load() async {
    map = await _loadMap();

    if (map.tilesets[0].image != null)
      image = await Flame.images.load(map.tilesets[0].image.source);
    batches = await _loadImages(map);
    generate();
    _loaded = true;
  }

  XmlDocument _parseXml(String input) => XmlDocument.parse(input);

  Future<TileMap> _loadMap() async {
    String file = await Flame.bundle.loadString('assets/tiles/$filename');
    final parser = TileMapParser();

    final String tsxSourcePath = _parseXml(file)
        .rootElement
        .children
        .whereType<XmlElement>()
        .firstWhere((element) => element.name.local == 'tileset', orElse: () => null)
        ?.getAttribute('source');
    if(tsxSourcePath != null) {
      final TiledTsxProvider tsxProvider = TiledTsxProvider(tsxSourcePath);
      await tsxProvider.initialize();

      return parser.parse(file, tsx: tsxProvider);
    } else {
      return parser.parse(file);
    }
  }

  Future<Map<String, SpriteBatch>> _loadImages(TileMap map) async {
    final Map<String, SpriteBatch> result = {};
    await Future.forEach(map.tilesets, (tileset) async {
      await Future.forEach(tileset.images, (tmxImage) async {
        result[tmxImage.source] = await SpriteBatch.load(tmxImage.source);
      });
    });
    return result;
  }

  /// Generate the sprite batches from the existing tilemap.
  void generate() {
    for (var batch in batches.keys) {
      batches[batch].clear();
    }
    _drawTiles(map);
  }

  void _drawTiles(TileMap map) {
    map.layers.where((layer) => layer.visible).forEach((layer) {
      layer.tiles.forEach((tileRow) {
        tileRow.forEach((Tile tile) {
          if (tile.gid == 0) {
            return;
          }

          if (tile.image == null) {
            throw('Tile ${tile.x}:${tile.y} gid ${tile.gid} image is null');
          } else {
            final batch = batches[tile.image.source];

            final rect = tile.computeDrawRect();

            final src = Rect.fromLTWH(
              rect.left.toDouble(),
              rect.top.toDouble(),
              rect.width.toDouble(),
              rect.height.toDouble(),
            );

            final flips = _SimpleFlips.fromFlips(tile.flips);
            final Size tileSize = destTileSize ??
                Size(tile.width.toDouble(), tile.height.toDouble());

            batch.add(
              source: src,
              offset: Vector2(
                tile.x.toDouble() * tileSize.width +
                    (tile.flips.horizontally ? tileSize.width : 0),
                tile.y.toDouble() * tileSize.height +
                    (tile.flips.vertically ? tileSize.height : 0),
              ),
              rotation: flips.angle * math.pi / 2,
              scale: tileSize.width / tile.width,
            );
          }
        });
      });
    });
  }

  bool loaded() => _loaded;

  void render(Canvas c) {
    if (!loaded()) {
      return;
    }

    batches.forEach((_, batch) {
      batch.render(c);
    });
  }

  /// This returns an object group fetch by name from a given layer.
  /// Use this to add custom behaviour to special objects and groups.
  Future<ObjectGroup> getObjectGroupFromLayer(String name) {
    return future.then((onValue) {
      return map.objectGroups
          .firstWhere((objectGroup) => objectGroup.name == name);
    });
  }
}

class TiledTsxProvider implements TsxProvider {
  String data;
  final String key;

  Future<void> initialize() async {
    this.data = await Flame.bundle.loadString('assets/tiles/$key');
  }

  TiledTsxProvider(this.key);

  String getSource(String key) {
    return data;
  }
}
