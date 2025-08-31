import 'dart:math';

class IdempotencyUtils {
  static String _uuidV4() {
    final rnd = Random.secure();
    int next16() => rnd.nextInt(1 << 16);
    String hex(int n, int pad) => n.toRadixString(16).padLeft(pad, '0');
    final p1 = hex(next16(), 4) + hex(next16(), 4);
    final p2 = hex(next16(), 4);
    final p3 = hex(0x4000 | (next16() & 0x0fff), 4); // version 4
    final p4 = hex(0x8000 | (next16() & 0x3fff), 4); // variant
    final p5 = hex(next16(), 4) + hex(next16(), 4) + hex(next16(), 4);
    return '$p1-$p2-$p3-$p4-$p5';
  }

  static String newIdempotencyKey({String prefix = 'idem'}) {
    return '$prefix:${_uuidV4()}';
  }
}
