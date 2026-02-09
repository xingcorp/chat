import 'dart:convert';

extension IsarIdX on String {
  int toIsarId() {
    var hash = 0x811c9dc5;
    const fnvPrime = 0x01000193;

    for (final byte in utf8.encode(this)) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0x7fffffff;
    }

    return hash;
  }
}
