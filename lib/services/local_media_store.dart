import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../utils/cast_logger.dart';

const _log = CastLogger('LocalMediaStore');
const _storageKey = 'local_media_items';

class LocalMediaStore extends ChangeNotifier {
  List<MediaItem> _items = [];
  bool _isLoaded = false;

  List<MediaItem> get items => List.unmodifiable(_items);
  bool get isLoaded => _isLoaded;
  bool get isEmpty => _items.isEmpty;

  List<MediaItem> get videos =>
      _items.where((m) => m.type == MediaType.video).toList();

  List<MediaItem> get photos =>
      _items.where((m) => m.type == MediaType.photo).toList();

  List<MediaItem> get music =>
      _items.where((m) => m.type == MediaType.music).toList();

  List<MediaItem> get favorites =>
      _items.where((m) => m.isFavorite).toList();

  List<MediaItem> recentlyAdded({int days = 3}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _items.where((m) => m.dateAdded.isAfter(cutoff)).toList()
      ..sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        _items = decoded.map((e) => MediaItem.fromMap(e)).toList();
        _log.info('Loaded ${_items.length} local media items');
      } else {
        _log.info('No saved local media found');
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      _log.error('Failed to load local media', e);
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> add(MediaItem item) async {
    if (_items.any((m) => m.id == item.id)) {
      _log.debug('Item already exists: ${item.id}');
      return;
    }
    _items.add(item);
    _log.info('Added: ${item.title} (${item.type.name})');
    await _save();
    notifyListeners();
  }

  Future<void> addAll(List<MediaItem> items) async {
    for (final item in items) {
      if (!_items.any((m) => m.id == item.id)) {
        _items.add(item);
      }
    }
    _log.info('Added ${items.length} items');
    await _save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((m) => m.id == id);
    _log.info('Removed: $id');
    await _save();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _items.indexWhere((m) => m.id == id);
    if (index != -1) {
      final item = _items[index];
      _items[index] = item.copyWith(isFavorite: !item.isFavorite);
      _log.info('Toggled favorite: ${item.title}');
      await _save();
      notifyListeners();
    }
  }

  Future<void> clear() async {
    _items.clear();
    _log.info('Cleared all local media');
    await _save();
    notifyListeners();
  }

  bool contains(String id) {
    return _items.any((m) => m.id == id);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_items.map((e) => e.toMap()).toList());
      await prefs.setString(_storageKey, json);
    } catch (e) {
      _log.error('Failed to save local media', e);
    }
  }
}
