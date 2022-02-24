extension BoolExtensions on bool {
  T? ifTrue<T>(T? Function() factory) {
    return this ? factory() : null;
  }
}

T? ifTrue<T>(bool check, T? Function() factory) {
  return check.ifTrue(factory);
}
