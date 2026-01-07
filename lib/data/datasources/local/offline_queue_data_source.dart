import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants.dart';

/// Local data source for offline queue operations
abstract class OfflineQueueDataSource {
  Future<void> initialize();
  Future<String> enqueue(QueueItemData item); // Returns queueKey
  Future<List<QueueItemData>> getPendingItems();
  Future<void> remove(String queueKey);
  Future<int> get queueSize;
  Future<void> clear();
}

/// Implementation of OfflineQueueDataSource
class OfflineQueueDataSourceImpl implements OfflineQueueDataSource {
  Box<String>? _queueBox;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    
    await Hive.initFlutter();
    _queueBox = await Hive.openBox<String>(AppConstants.offlineQueueBox);
    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  @override
  Future<String> enqueue(QueueItemData item) async {
    await _ensureInitialized();
    final key = '${item.type.name}_${item.id}_${DateTime.now().millisecondsSinceEpoch}';
    await _queueBox!.put(key, jsonEncode(item.toMap()));
    return key; // Return queueKey for later removal
  }

  @override
  Future<List<QueueItemData>> getPendingItems() async {
    await _ensureInitialized();
    final items = <QueueItemData>[];
    
    for (final key in _queueBox!.keys) {
      final json = _queueBox!.get(key);
      if (json != null) {
        try {
          final map = jsonDecode(json) as Map<String, dynamic>;
          items.add(QueueItemData.fromMap(map, key as String));
        } catch (_) {
          // Skip corrupted items
        }
      }
    }
    
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  @override
  Future<void> remove(String queueKey) async {
    await _ensureInitialized();
    await _queueBox!.delete(queueKey);
  }

  @override
  Future<int> get queueSize async {
    await _ensureInitialized();
    return _queueBox!.length;
  }

  @override
  Future<void> clear() async {
    await _ensureInitialized();
    await _queueBox!.clear();
  }
}

/// Queue item types
enum QueueItemType {
  event,
  telemetry,
  intent,
  haulerUpdate,
}

/// Queue item data
class QueueItemData {
  final String id;
  final String queueKey;
  final QueueItemType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;

  const QueueItemData({
    required this.id,
    required this.queueKey,
    required this.type,
    required this.data,
    required this.createdAt,
  });

  factory QueueItemData.create({
    required String id,
    required QueueItemType type,
    required Map<String, dynamic> data,
  }) {
    return QueueItemData(
      id: id,
      queueKey: '',
      type: type,
      data: data,
      createdAt: DateTime.now(),
    );
  }

  factory QueueItemData.fromMap(Map<String, dynamic> map, String queueKey) {
    return QueueItemData(
      id: map['id'] as String,
      queueKey: queueKey,
      type: QueueItemType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => QueueItemType.event,
      ),
      data: map['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}


