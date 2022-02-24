import 'package:flutter/foundation.dart';

class ListDiffNotifier<I> extends ChangeNotifier {
  final VoidCallback? _onDisposed;
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

  void forEach(ValueChanged<I> action) => _items.forEach(action);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _onDisposed?.call();
    _addedListeners.clear();
    _removedListeners.clear();
    super.dispose();
  }
}
