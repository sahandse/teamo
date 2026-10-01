import 'package:flutter/foundation.dart';

import '../data/sprint_repository.dart';
import '../models/sprint_item.dart';

class SprintStore extends ChangeNotifier {
  final SprintRepository repository;
  SprintStore(this.repository);

  bool loading = false;
  List<SprintItem> items = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();
    items = await repository.all();
    loading = false;
    notifyListeners();
  }

  Future<void> add(SprintItem item) async {
    final saved = await repository.create(item);
    items = [saved, ...items];
    notifyListeners();
  }

  Future<void> update(SprintItem item) async {
    await repository.update(item);
    items = [for (final current in items) if (current.id == item.id) item else current];
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await repository.delete(id);
    items = items.where((e) => e.id != id).toList();
    notifyListeners();
  }
}
