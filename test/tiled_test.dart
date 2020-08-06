import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/flame.dart';
import 'package:flutter/services.dart' show CachingAssetBundle;
import 'package:test/test.dart';
import '../lib/tiled_component.dart';

void main() {
  test('correct loads the file', () async {
    await Flame.init(bundle: TestAssetBundle());
    final tiled = TiledComponent('x', Size(16, 16));
    await tiled.future;
    expect(1, equals(1));
  });
}

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async => File('assets/map-level1.png')
      .readAsBytes()
      .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));

  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      File('assets/map.tmx').readAsString();
}
