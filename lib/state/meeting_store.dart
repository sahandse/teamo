import 'package:flutter/foundation.dart';

import '../data/meeting_repository.dart';
import '../models/meeting_item.dart';

class MeetingStore extends ChangeNotifier {
  final MeetingRepository repository;
  MeetingStore(this.repository);

  bool loading = false;
  List<MeetingItem> items = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();
    items = await repository.all();
    loading = false;
    notifyListeners();
  }

  Future<void> add(MeetingItem item) async {
    final saved = await repository.create(item);
    items = [...items, saved]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    notifyListeners();
  }

  Future<void> update(MeetingItem item) async {
    await repository.update(item);
    items = [for (final current in items) if (current.id == item.id) item else current]
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await repository.delete(id);
    items = items.where((e) => e.id != id).toList();
    notifyListeners();
  }
}
