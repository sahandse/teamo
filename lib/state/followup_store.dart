import 'package:flutter/foundation.dart';
import '../data/followup_repository.dart';
import '../models/followup_item.dart';

class FollowupStore extends ChangeNotifier {
  final FollowupRepository repository;
  FollowupStore(this.repository);

  bool loading = false;
  List<FollowupItem> items = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();
    items = await repository.all();
    loading = false;
    notifyListeners();
  }

  Future<void> add(FollowupItem item) async {
    final saved = await repository.create(item);
    items = [saved, ...items];
    notifyListeners();
  }

  Future<void> update(FollowupItem item) async {
    await repository.update(item);
    items = [for (final current in items) if (current.id == item.id) item else current];
    notifyListeners();
  }

  Future<void> markDone(FollowupItem item) => update(item.copyWith(status: FollowupStatus.done));

  Future<void> snooze(FollowupItem item, DateTime until) => update(item.copyWith(status: FollowupStatus.snoozed, snoozedUntil: until));

  Future<void> remove(int id) async {
    await repository.delete(id);
    items = items.where((e) => e.id != id).toList();
    notifyListeners();
  }
}
