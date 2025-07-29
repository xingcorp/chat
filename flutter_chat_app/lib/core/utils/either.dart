// Custom implementation of the Either type from functional programming
// This provides a way to return either a failure or success value



/// Generic class that represents a value of one of two possible types.
/// Instances of [Either] are either an instance of [Left] or [Right].
abstract class Either<L, R> {
  const Either();

  /// Returns true if this is a [Left], false otherwise.
  bool get isLeft;

  /// Returns true if this is a [Right], false otherwise.
  bool get isRight;

  /// Returns the [Left] value if this is a [Left], throws an exception otherwise.
  L get left;

  /// Returns the [Right] value if this is a [Right], throws an exception otherwise.
  R get right;

  /// Transforms values of [Left] with [leftMap] and [Right] with [rightMap].
  Either<TL, TR> map<TL, TR>(
    TL Function(L) leftMap,
    TR Function(R) rightMap,
  );

  /// Executes [leftFn] if this is a [Left], or [rightFn] if this is a [Right].
  T fold<T>(
    T Function(L) leftFn,
    T Function(R) rightFn,
  );
}

/// The left side of an [Either]. Typically represents a failure.
class Left<L, R> extends Either<L, R> {
  final L _value;

  const Left(this._value);

  @override
  bool get isLeft => true;

  @override
  bool get isRight => false;

  @override
  L get left => _value;

  @override
  R get right => throw Exception('Cannot get right value from a Left');

  @override
  Either<TL, TR> map<TL, TR>(
    TL Function(L) leftMap,
    TR Function(R) rightMap,
  ) {
    return Left<TL, TR>(leftMap(_value));
  }

  @override
  T fold<T>(
    T Function(L) leftFn,
    T Function(R) rightFn,
  ) {
    return leftFn(_value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Left &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'Left($_value)';
}

/// The right side of an [Either]. Typically represents a success.
class Right<L, R> extends Either<L, R> {
  final R _value;

  const Right(this._value);

  @override
  bool get isLeft => false;

  @override
  bool get isRight => true;

  @override
  L get left => throw Exception('Cannot get left value from a Right');

  @override
  R get right => _value;

  @override
  Either<TL, TR> map<TL, TR>(
    TL Function(L) leftMap,
    TR Function(R) rightMap,
  ) {
    return Right<TL, TR>(rightMap(_value));
  }

  @override
  T fold<T>(
    T Function(L) leftFn,
    T Function(R) rightFn,
  ) {
    return rightFn(_value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Right &&
          runtimeType == other.runtimeType &&
          _value == other._value;

  @override
  int get hashCode => _value.hashCode;

  @override
  String toString() => 'Right($_value)';
} 