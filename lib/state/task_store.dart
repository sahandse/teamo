import 'package:flutter/foundation.dart';

import '../data/task_repository.dart';
import '../models/task_item.dart';

class TaskStore extends ChangeNotifier {
  final TaskRepository repository;
  TaskStore(this.repository);

  bool loading = false;
  List<TaskItem> items = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();
    await repository.seedIfEmpty();
    items = await repository.all();
    loading = false;
    notifyListeners();
  }

  List<TaskItem> byStatus(TaskStatus status) =>
      items.where((task) => task.status == status).toList();

  Future<void> add(TaskItem task) async {
    final saved = await repository.create(task);
    items = [saved, ...items];
    notifyListeners();
  }

  Future<void> move(TaskItem task, TaskStatus status) async {
    final updated = task.copyWith(status: status);
    await repository.update(updated);
    items = [for (final item in items) if (item.id == task.id) updated else item];
    notifyListeners();
  }

  Future<void> remove(TaskItem task) async {
    if (task.id == null) return;
    await repository.delete(task.id!);
    items = items.where((item) => item.id != task.id).toList();
    notifyListeners();
  }
}
