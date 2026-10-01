import 'package:flutter/foundation.dart';
import '../data/project_repository.dart';
import '../models/project_item.dart';

class ProjectStore extends ChangeNotifier {
  final ProjectRepository repository;
  ProjectStore(this.repository);

  bool loading = false;
  List<ProjectItem> items = [];

  Future<void> load() async {
    loading = true;
    notifyListeners();
    items = await repository.all();
    loading = false;
    notifyListeners();
  }

  Future<void> add(ProjectItem item) async {
    final saved = await repository.create(item);
    items = [saved, ...items];
    notifyListeners();
  }

  Future<void> update(ProjectItem item) async {
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
