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
    items = await repository.all();
    loading = false;
    notifyListeners();
  }

  List<TaskItem> byStatus(TaskStatus status) => items.where((task) => task.status == status).toList();

  Future<void> add(TaskItem task) async {
    final saved = await repository.create(task);
    items = [saved, ...items];
    notifyListeners();
  }

  Future<void> update(TaskItem task) async {
    await repository.update(task);
    items = [for (final item in items) if (item.id == task.id) task else item];
    notifyListeners();
  }

  Future<void> move(TaskItem task, TaskStatus status) async {
    await update(task.copyWith(status: status));
  }

  Future<void> remove(TaskItem task) async {
    if (task.id == null) return;
    await repository.delete(task.id!);
    items = items.where((item) => item.id != task.id).toList();
    notifyListeners();
  }

  Future<void> removeById(int id) async {
    await repository.delete(id);
    items = items.where((item) => item.id != id).toList();
    notifyListeners();
  }
}
