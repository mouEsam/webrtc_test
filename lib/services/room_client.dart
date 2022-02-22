import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class ListDiffNotifier<I> extends ChangeNotifier {
  List<I> _items = [];

  final List<ValueChanged<I>> _addedListeners = [];
  final List<ValueChanged<I>> _removedListeners = [];

  void addDiffListener({
    ValueChanged<I>? onAdded,
    ValueChanged<I>? onRemoved,
  }) {
    if (onAdded != null) {
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
  void notifyListeners({I? addedItem, I? removedItem}) {
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
    _items.add(item);
    notifyListeners(addedItem: item);
  }

  void removeItem(I item) {
    _items.remove(item);
    notifyListeners(removedItem: item);
  }
}

class Attendee extends Equatable {
  final String name;
  final ValueNotifier<List<RTCIceCandidate>> candidates;
}

class Room extends Equatable {
  final String name;
  final RTCSessionDescription offer;
  final ValueNotifier<List<Attendee>> attendees;
}

class RoomClient {
  static const _COLLECTION_NAME = 'AvailableRooms';
  static const _ANSWERS_COLLECTION_NAME = 'Answers';
  static const _ICE_CANDIDATES = 'IceCandidates';
  static const _ATTENDEES_COLLECTION = 'Attendees';

  final FirebaseFirestore _firestoreInstance;

  const RoomClient(this._firestoreInstance);
}
