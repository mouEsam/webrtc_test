T? ifTrue<T>(bool check, T? Function() ifTrue) {
  return check ? ifTrue() : null;
}
