import 'package:flutter/cupertino.dart';

extension LoseFocus on BuildContext {
  VoidCallback loseFocusWrapper(VoidCallback callback) {
    return () {
      loseFocus();
      return callback();
    };
  }

  void loseFocus() {
    FocusScopeNode focus = FocusScope.of(this);
    if (!focus.hasPrimaryFocus) {
      focus.unfocus();
    }
  }
}

void loseFocus(BuildContext context) {
  context.loseFocus();
}

VoidCallback loseFocusCallback(BuildContext context, VoidCallback callback) {
  return context.loseFocusWrapper(callback);
}
