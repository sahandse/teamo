import 'app_database.dart';

class ChangeRequest {
  final int? id; final String title; final String project; final String requester; final String impact; final String status; final String decision; final DateTime createdAt;
  const ChangeRequest({this.id, required this.title, this.project = '', this.requester = '', this.impact = '', this.status = 'pending', this.decision = '', required this.createdAt});
  Map<String,Object?> toMap()=>{'id':id,'title':title,'project':project,'requester':requester,'impact':impact,'status':status,'decision':decision,'created_at':createdAt.toIso8601String()};
  factory ChangeRequest.fromMap(Map<String,Object?> m)=>ChangeRequest(id:m['id'] as int?,title:m['title'] as String,project:(m['project'] as String?)??'',requester:(m['requester'] as String?)??'',impact:(m['impact'] as String?)??'',status:(m['status'] as String?)??'pending',decision:(m['decision'] as String?)??'',createdAt:DateTime.tryParse((m['created_at'] as String?)??'')??DateTime.now());
}

class DecisionLog {
  final int? id; final String title; final String project; final String owner; final String rationale; final String outcome; final DateTime createdAt;
  const DecisionLog({this.id,required this.title,this.project='',this.owner='',this.rationale='',this.outcome='',required this.createdAt});
  Map<String,Object?> toMap()=>{'id':id,'title':title,'project':project,'owner':owner,'rationale':rationale,'outcome':outcome,'created_at':createdAt.toIso8601String()};
  factory DecisionLog.fromMap(Map<String,Object?> m)=>DecisionLog(id:m['id'] as int?,title:m['title'] as String,project:(m['project'] as String?)??'',owner:(m['owner'] as String?)??'',rationale:(m['rationale'] as String?)??'',outcome:(m['outcome'] as String?)??'',createdAt:DateTime.tryParse((m['created_at'] as String?)??'')??DateTime.now());
}

class Stakeholder {
  final int? id; final String name; final String role; final String project; final String influence; final String interest; final String engagement;
  const Stakeholder({this.id,required this.name,this.role='',this.project='',this.influence='medium',this.interest='medium',this.engagement='manage'});
  Map<String,Object?> toMap()=>{'id':id,'name':name,'role':role,'project':project,'influence':influence,'interest':interest,'engagement':engagement};
  factory Stakeholder.fromMap(Map<String,Object?> m)=>Stakeholder(id:m['id'] as int?,name:m['name'] as String,role:(m['role'] as String?)??'',project:(m['project'] as String?)??'',influence:(m['influence'] as String?)??'medium',interest:(m['interest'] as String?)??'medium',engagement:(m['engagement'] as String?)??'manage');
}

class Milestone {
  final int? id; final String title; final String project; final DateTime dueDate; final String status; final String owner;
  const Milestone({this.id,required this.title,this.project='',required this.dueDate,this.status='planned',this.owner=''});
  Map<String,Object?> toMap()=>{'id':id,'title':title,'project':project,'due_date':dueDate.toIso8601String(),'status':status,'owner':owner};
  factory Milestone.fromMap(Map<String,Object?> m)=>Milestone(id:m['id'] as int?,title:m['title'] as String,project:(m['project'] as String?)??'',dueDate:DateTime.tryParse((m['due_date'] as String?)??'')??DateTime.now(),status:(m['status'] as String?)??'planned',owner:(m['owner'] as String?)??'');
}

class WeeklyReport {
  final int? id; final String title; final String summary; final String achievements; final String blockers; final String nextWeek; final DateTime createdAt;
  const WeeklyReport({this.id,required this.title,this.summary='',this.achievements='',this.blockers='',this.nextWeek='',required this.createdAt});
  Map<String,Object?> toMap()=>{'id':id,'title':title,'summary':summary,'achievements':achievements,'blockers':blockers,'next_week':nextWeek,'created_at':createdAt.toIso8601String()};
  factory WeeklyReport.fromMap(Map<String,Object?> m)=>WeeklyReport(id:m['id'] as int?,title:m['title'] as String,summary:(m['summary'] as String?)??'',achievements:(m['achievements'] as String?)??'',blockers:(m['blockers'] as String?)??'',nextWeek:(m['next_week'] as String?)??'',createdAt:DateTime.tryParse((m['created_at'] as String?)??'')??DateTime.now());
}

class PmoGovernanceRepository {
  Future<List<ChangeRequest>> changes() async => (await (await AppDatabase.instance.database).query('change_requests',orderBy:'created_at DESC')).map(ChangeRequest.fromMap).toList();
  Future<List<DecisionLog>> decisions() async => (await (await AppDatabase.instance.database).query('decision_logs',orderBy:'created_at DESC')).map(DecisionLog.fromMap).toList();
  Future<List<Stakeholder>> stakeholders() async => (await (await AppDatabase.instance.database).query('stakeholders',orderBy:'name')).map(Stakeholder.fromMap).toList();
  Future<List<Milestone>> milestones() async => (await (await AppDatabase.instance.database).query('milestones',orderBy:'due_date')).map(Milestone.fromMap).toList();
  Future<List<WeeklyReport>> reports() async => (await (await AppDatabase.instance.database).query('weekly_reports',orderBy:'created_at DESC')).map(WeeklyReport.fromMap).toList();

  Future<void> save(String table, Map<String,Object?> data, int? id) async { final db=await AppDatabase.instance.database; final row=Map<String,Object?>.from(data)..remove('id'); if(id==null){await db.insert(table,row);}else{await db.update(table,row,where:'id = ?',whereArgs:[id]);} }
  Future<void> delete(String table,int id) async => (await AppDatabase.instance.database).delete(table,where:'id = ?',whereArgs:[id]);
}
