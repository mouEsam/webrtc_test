import 'package:flutter/foundation.dart';
import 'package:webrtc_test/helpers/utils/tuple.dart';

class MapDiffNotifier<K, V> extends ChangeNotifier {
  final ValueChanged<Map<K, V>>? _onDisposed;
  final Map<K, V> _items = {};

  final List<ValueChanged<MapEntry<K, V>>> _addedListeners = [];
  final List<ValueChanged<MapEntry<K, V>>> _removedListeners = [];
  final List<ValueChanged<MapEntry<K, Tuple2<V, V>>>> _changedListeners = [];

  MapDiffNotifier([this._onDisposed]);

  bool _disposed = false;

  bool get isEmpty => _items.isEmpty;

  int get length => _items.length;

  Map<K, V> get items => Map.unmodifiable(_items);

  Iterable<V> get values => _items.values;

  V? operator [](K key) {
    return _items[key];
  }

  void operator []=(K key, V value) {
    if (_disposed) return;
    final oldValue = _items[key];
    _items[key] = value;
    notifyListeners(
      addedItem: oldValue == null ? MapEntry(key, value) : null,
      changedItem:
          oldValue != null ? MapEntry(key, Tuple2(oldValue, value)) : null,
    );
  }

  void addDiffListener({
    ValueChanged<MapEntry<K, V>>? onAdded,
    ValueChanged<MapEntry<K, V>>? onRemoved,
    ValueChanged<MapEntry<K, Tuple2<V, V>>>? onChanged,
  }) {
    if (onAdded != null) {
      _items.entries.forEach(onAdded);
      _addedListeners.add(onAdded);
    }
    if (onRemoved != null) {
      _removedListeners.add(onRemoved);
    }
    if (onChanged != null) {
      _changedListeners.add(onChanged);
    }
  }

  void removeDiffListener({
    ValueChanged<MapEntry<K, V>>? onAdded,
    ValueChanged<MapEntry<K, V>>? onRemoved,
    ValueChanged<MapEntry<K, Tuple2<V, V>>>? onChanged,
  }) {
    if (onAdded != null) {
      _addedListeners.remove(onAdded);
    }
    if (onRemoved != null) {
      _removedListeners.remove(onRemoved);
    }
    if (onChanged != null) {
      _changedListeners.remove(onChanged);
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
  void notifyListeners({
    MapEntry<K, V>? addedItem,
    MapEntry<K, V>? removedItem,
    MapEntry<K, Tuple2<V, V>>? changedItem,
  }) {
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
    if (changedItem != null) {
      for (var element in _changedListeners) {
        element.call(changedItem);
      }
    }
  }

  void addItem(K key, V item) {
    if (_disposed) return;
    final existing = _items[key];
    _items[key] = item;
    notifyListeners(
      addedItem: MapEntry(key, item),
      changedItem:
          existing != null ? MapEntry(key, Tuple2(existing, item)) : null,
    );
  }

  V? removeItem(K key) {
    if (_disposed) return null;
    final value = _items.remove(key);
    if (value != null) {
      notifyListeners(removedItem: MapEntry(key, value));
    }
    return value;
  }

  void forEach(ValueChanged<MapEntry<K, V>> action) =>
      _items.entries.forEach(action);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _onDisposed?.call(_items);
    _addedListeners.clear();
    _removedListeners.clear();
    _changedListeners.clear();
    super.dispose();
  }
}
