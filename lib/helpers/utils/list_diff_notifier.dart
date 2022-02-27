import 'package:flutter/foundation.dart';
import 'package:webrtc_test/blocs/models/connection.dart';

class ListDiffNotifier<I> extends ChangeNotifier {
  final ValueChanged<List<I>>? _onDisposed;
  final List<I> _items = [];

  final List<ValueChanged<I>> _addedListeners = [];
  final List<ValueChanged<I>> _removedListeners = [];

  ListDiffNotifier([this._onDisposed]);

  bool _disposed = false;

  bool get isEmpty => _items.isEmpty;

  int get length => _items.length;

  List<I> get items => List.unmodifiable(_items);

  void addDiffListener({
    ValueChanged<I>? onAdded,
    ValueChanged<I>? onRemoved,
  }) {
    if (onAdded != null) {
      _items.forEach(onAdded);
      _addedListeners.add(onAdded);
    }
    if (onRemoved != null) {
      _removedListeners.add(onRemoved);
    }
  }

  void removeDiffListener({
    ValueChanged<I>? onAdded,
    ValueChanged<I>? onRemoved,
  }) {
    if (onAdded != null) {
      _addedListeners.remove(onAdded);
    }
    if (onRemoved != null) {
      _removedListeners.remove(onRemoved);
    }
  }

  @override
  void addListener(VoidCallback listener) {
    if (_disposed) return;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_disposed) return;
    super.removeListener(listener);
  }

  @override
  void notifyListeners({I? addedItem, I? removedItem}) {
    if (_disposed) return;
    super.notifyListeners();
    if (addedItem != null) {
      for (var element in _addedListeners) {
        element.call(addedItem);
      }
    }
    if (removedItem != null) {
      for (var element in _removedListeners) {
        element.call(removedItem);
      }
    }
  }

  void addItem(I item) {
    if (_disposed) return;
    _items.add(item);
    notifyListeners(addedItem: item);
  }

  void removeItem(I item) {
    if (_disposed) return;
    final index = _items.indexOf(item);
    if (index >= 0) {
      item = _items[index];
      _items.remove(item);
      notifyListeners(removedItem: item);
    }
  }

  void clear([bool notify = true]) {
    if (notify) {
      for (var item in _items) {
        notifyListeners(removedItem: item);
      }
    }
    _items.clear();
  }

  void forEach(ValueChanged<I> action) => _items.forEach(action);

  I? replaceFirstWhere(I item, bool Function(I item) predicate, [bool notifyRemove = true]) {
    final index = _items.indexWhere(predicate);
    if (index >= 0) {
      final old = _items[index];
      if (notifyRemove) {
        notifyListeners(removedItem: old);
      }
      _items[index] = item;
      notifyListeners(addedItem: item);
      return old;
    }
    return null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _onDisposed?.call(_items);
    _addedListeners.clear();
    _removedListeners.clear();
    super.dispose();
  }

}
