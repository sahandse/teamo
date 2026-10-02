import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/date/persian_date.dart';
import '../../data/pmo_governance_repository.dart';

class PmoGovernancePage extends StatefulWidget {
  const PmoGovernancePage({super.key});
  @override
  State<PmoGovernancePage> createState() => _PmoGovernancePageState();
}

class _PmoGovernancePageState extends State<PmoGovernancePage> with SingleTickerProviderStateMixin {
  final repo = PmoGovernanceRepository();
  late final TabController tabs;
  List<ChangeRequest> changes=[]; List<DecisionLog> decisions=[]; List<Stakeholder> stakeholders=[]; List<Milestone> milestones=[]; List<WeeklyReport> reports=[]; bool loading=true;

  @override
  void initState(){super.initState();tabs=TabController(length:5,vsync:this);_load();}
  @override
  void dispose(){tabs.dispose();super.dispose();}

  Future<void> _load() async {
    final d=await Future.wait([repo.changes(),repo.decisions(),repo.stakeholders(),repo.milestones(),repo.reports()]);
    if(!mounted)return; setState((){changes=d[0] as List<ChangeRequest>;decisions=d[1] as List<DecisionLog>;stakeholders=d[2] as List<Stakeholder>;milestones=d[3] as List<Milestone>;reports=d[4] as List<WeeklyReport>;loading=false;});
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('PMO Governance'),bottom:TabBar(controller:tabs,isScrollable:true,tabs:const [Tab(text:'Change'),Tab(text:'Decision'),Tab(text:'Stakeholders'),Tab(text:'Milestones'),Tab(text:'Weekly Report')]),actions:[IconButton(onPressed:_copySummary,icon:const Icon(Icons.content_copy_rounded),tooltip:'کپی خلاصه')]),
    body:loading?const Center(child:CircularProgressIndicator()):TabBarView(controller:tabs,children:[_changes(),_decisions(),_stakeholders(),_milestones(),_reports()]),
  );

  Widget _changes()=>_section(
    title:'Change Request',subtitle:'درخواست تغییر، اثر، تصمیم و وضعیت',icon:Icons.change_circle_outlined,
    add:()=>_editChange(),
    children:changes.map((e)=>ListTile(onTap:()=>_editChange(e),leading:const CircleAvatar(child:Icon(Icons.change_circle_outlined)),title:Text(e.title,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${e.project.isEmpty?'بدون پروژه':e.project} • ${_changeStatus(e.status)}\n${e.impact}'),isThreeLine:true,trailing:const Icon(Icons.chevron_left_rounded))).toList(),
  );

  Widget _decisions()=>_section(
    title:'Decision Log',subtitle:'ثبت تصمیمات کلیدی، دلیل و نتیجه',icon:Icons.gavel_outlined,
    add:()=>_editDecision(),
    children:decisions.map((e)=>ListTile(onTap:()=>_editDecision(e),leading:const CircleAvatar(child:Icon(Icons.gavel_outlined)),title:Text(e.title,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${e.project.isEmpty?'بدون پروژه':e.project} • ${e.owner.isEmpty?'بدون مالک':e.owner}\n${e.outcome}'),isThreeLine:true,trailing:Text(PersianDate.short(e.createdAt),style:Theme.of(context).textTheme.bodySmall))).toList(),
  );

  Widget _stakeholders()=>_section(
    title:'Stakeholder Register',subtitle:'قدرت، علاقه و استراتژی تعامل',icon:Icons.groups_2_outlined,
    add:()=>_editStakeholder(),
    children:stakeholders.map((e)=>ListTile(onTap:()=>_editStakeholder(e),leading:const CircleAvatar(child:Icon(Icons.person_outline_rounded)),title:Text(e.name,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${e.role} • ${e.project.isEmpty?'همه پروژه‌ها':e.project}\nنفوذ: ${_level(e.influence)} • علاقه: ${_level(e.interest)} • ${_engagement(e.engagement)}'),isThreeLine:true)).toList(),
  );

  Widget _milestones()=>_section(
    title:'Portfolio Milestones',subtitle:'نقاط کلیدی بین همه پروژه‌ها',icon:Icons.flag_outlined,
    add:()=>_editMilestone(),
    children:milestones.map((e){final late=e.dueDate.isBefore(DateTime.now())&&e.status!='done';return ListTile(onTap:()=>_editMilestone(e),leading:CircleAvatar(child:Icon(late?Icons.warning_amber_rounded:Icons.flag_outlined)),title:Text(e.title,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text('${e.project.isEmpty?'بدون پروژه':e.project} • ${e.owner.isEmpty?'بدون مالک':e.owner}\n${PersianDate.full(e.dueDate)} • ${_milestoneStatus(e.status)}'),isThreeLine:true);}).toList(),
  );

  Widget _reports()=>ListView(padding:const EdgeInsets.fromLTRB(16,16,16,100),children:[
    FilledButton.icon(onPressed:_createWeeklyReport,icon:const Icon(Icons.auto_awesome_rounded),label:const Text('ساخت گزارش هفتگی جدید')),
    const SizedBox(height:14),
    if(reports.isEmpty)const _Empty(title:'گزارش هفتگی ندارید',subtitle:'یک گزارش مدیریتی از دستاوردها، موانع و برنامه هفته بعد بساز.'),
    ...reports.map((e)=>Card(margin:const EdgeInsets.only(bottom:10),child:ExpansionTile(title:Text(e.title,style:const TextStyle(fontWeight:FontWeight.w900)),subtitle:Text(PersianDate.full(e.createdAt)),childrenPadding:const EdgeInsets.fromLTRB(16,0,16,16),children:[_label('خلاصه',e.summary),_label('دستاوردها',e.achievements),_label('موانع',e.blockers),_label('هفته بعد',e.nextWeek),Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:()async{await repo.delete('weekly_reports',e.id!);await _load();},icon:const Icon(Icons.delete_outline),label:const Text('حذف')))]))),
  ]);

  Widget _section({required String title,required String subtitle,required IconData icon,required VoidCallback add,required List<Widget> children})=>ListView(padding:const EdgeInsets.fromLTRB(16,16,16,100),children:[
    Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer,borderRadius:BorderRadius.circular(24)),child:Row(children:[CircleAvatar(child:Icon(icon)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18)),Text(subtitle,style:Theme.of(context).textTheme.bodySmall)])),FilledButton.icon(onPressed:add,icon:const Icon(Icons.add_rounded),label:const Text('جدید'))])),
    const SizedBox(height:14),
    if(children.isEmpty)_Empty(title:'هنوز چیزی ثبت نشده',subtitle:'اولین مورد را با دکمه «جدید» ثبت کن.'),
    ...children.map((w)=>Card(margin:const EdgeInsets.only(bottom:10),child:w)),
  ]);

  Future<void> _editChange([ChangeRequest? e]) async {final title=TextEditingController(text:e?.title??'');final project=TextEditingController(text:e?.project??'');final requester=TextEditingController(text:e?.requester??'');final impact=TextEditingController(text:e?.impact??'');final decision=TextEditingController(text:e?.decision??'');var status=e?.status??'pending';final saved=await _form<ChangeRequest>(title:e==null?'Change Request جدید':'ویرایش Change Request',fields:[_f(title,'عنوان'),_f(project,'پروژه'),_f(requester,'درخواست‌دهنده'),_f(impact,'Impact / اثر',lines:3),_dropdown('وضعیت',status,{'pending':'در انتظار','approved':'تایید','rejected':'رد','implemented':'اجرا شده'},(v)=>status=v),_f(decision,'تصمیم / توضیح',lines:3)],build:()=>ChangeRequest(id:e?.id,title:title.text.trim(),project:project.text.trim(),requester:requester.text.trim(),impact:impact.text.trim(),status:status,decision:decision.text.trim(),createdAt:e?.createdAt??DateTime.now()));if(saved!=null){await repo.save('change_requests',saved.toMap(),saved.id);await _load();}}

  Future<void> _editDecision([DecisionLog? e]) async {final title=TextEditingController(text:e?.title??'');final project=TextEditingController(text:e?.project??'');final owner=TextEditingController(text:e?.owner??'');final rationale=TextEditingController(text:e?.rationale??'');final outcome=TextEditingController(text:e?.outcome??'');final saved=await _form<DecisionLog>(title:e==null?'تصمیم جدید':'ویرایش تصمیم',fields:[_f(title,'عنوان'),_f(project,'پروژه'),_f(owner,'مالک تصمیم'),_f(rationale,'Rationale / دلیل',lines:3),_f(outcome,'نتیجه / Outcome',lines:3)],build:()=>DecisionLog(id:e?.id,title:title.text.trim(),project:project.text.trim(),owner:owner.text.trim(),rationale:rationale.text.trim(),outcome:outcome.text.trim(),createdAt:e?.createdAt??DateTime.now()));if(saved!=null){await repo.save('decision_logs',saved.toMap(),saved.id);await _load();}}

  Future<void> _editStakeholder([Stakeholder? e]) async {final name=TextEditingController(text:e?.name??'');final role=TextEditingController(text:e?.role??'');final project=TextEditingController(text:e?.project??'');var influence=e?.influence??'medium';var interest=e?.interest??'medium';var engagement=e?.engagement??'manage';final saved=await _form<Stakeholder>(title:e==null?'Stakeholder جدید':'ویرایش Stakeholder',fields:[_f(name,'نام'),_f(role,'نقش'),_f(project,'پروژه'),_dropdown('Influence',influence,{'low':'کم','medium':'متوسط','high':'بالا'},(v)=>influence=v),_dropdown('Interest',interest,{'low':'کم','medium':'متوسط','high':'بالا'},(v)=>interest=v),_dropdown('Engagement',engagement,{'monitor':'پایش','inform':'اطلاع‌رسانی','manage':'مدیریت نزدیک','satisfy':'راضی نگه‌داشتن'},(v)=>engagement=v)],build:()=>Stakeholder(id:e?.id,name:name.text.trim(),role:role.text.trim(),project:project.text.trim(),influence:influence,interest:interest,engagement:engagement));if(saved!=null){await repo.save('stakeholders',saved.toMap(),saved.id);await _load();}}

  Future<void> _editMilestone([Milestone? e]) async {final title=TextEditingController(text:e?.title??'');final project=TextEditingController(text:e?.project??'');final owner=TextEditingController(text:e?.owner??'');var due=e?.dueDate??DateTime.now().add(const Duration(days:7));var status=e?.status??'planned';final saved=await showModalBottomSheet<Milestone>(context:context,isScrollControlled:true,showDragHandle:true,builder:(context)=>StatefulBuilder(builder:(context,setSheet)=>Padding(padding:EdgeInsets.fromLTRB(16,0,16,MediaQuery.of(context).viewInsets.bottom+24),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(e==null?'Milestone جدید':'ویرایش Milestone',style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:14),_f(title,'عنوان'),const SizedBox(height:10),_f(project,'پروژه'),const SizedBox(height:10),_f(owner,'مالک'),const SizedBox(height:10),DropdownButtonFormField<String>(initialValue:status,decoration:const InputDecoration(labelText:'وضعیت'),items:const [DropdownMenuItem(value:'planned',child:Text('برنامه‌ریزی')),DropdownMenuItem(value:'doing',child:Text('در حال انجام')),DropdownMenuItem(value:'done',child:Text('تکمیل')),DropdownMenuItem(value:'delayed',child:Text('تاخیر'))],onChanged:(v)=>setSheet(()=>status=v??'planned')),const SizedBox(height:10),OutlinedButton.icon(onPressed:()async{final d=await showDatePicker(context:context,initialDate:due,firstDate:DateTime(2024),lastDate:DateTime(2040));if(d!=null)setSheet(()=>due=d);},icon:const Icon(Icons.calendar_month_outlined),label:Text(PersianDate.short(due))),const SizedBox(height:16),FilledButton(onPressed:()=>Navigator.pop(context,Milestone(id:e?.id,title:title.text.trim(),project:project.text.trim(),dueDate:due,status:status,owner:owner.text.trim())),child:const Text('ذخیره'))])))));if(saved!=null){await repo.save('milestones',saved.toMap(),saved.id);await _load();}}

  Future<void> _createWeeklyReport() async {final pending=changes.where((e)=>e.status=='pending').length;final upcoming=milestones.where((e)=>e.status!='done').take(5).map((e)=>e.title).join('، ');final report=WeeklyReport(title:'گزارش هفتگی ${PersianDate.short(DateTime.now())}',summary:'${changes.length} درخواست تغییر، ${decisions.length} تصمیم، ${milestones.length} Milestone',achievements:'${milestones.where((e)=>e.status=='done').length} Milestone تکمیل شده',blockers:'$pending Change Request در انتظار تصمیم',nextWeek:upcoming.isEmpty?'موردی ثبت نشده':upcoming,createdAt:DateTime.now());await repo.save('weekly_reports',report.toMap(),null);await _load();}

  Future<T?> _form<T>({required String title,required List<Widget> fields,required T Function() build})=>showModalBottomSheet<T>(context:context,isScrollControlled:true,showDragHandle:true,builder:(context)=>Padding(padding:EdgeInsets.fromLTRB(16,0,16,MediaQuery.of(context).viewInsets.bottom+24),child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(title,style:Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight:FontWeight.w900)),const SizedBox(height:14),...fields.expand((w)=>[w,const SizedBox(height:10)]),FilledButton(onPressed:()=>Navigator.pop(context,build()),child:const Text('ذخیره'))]))));
  Widget _f(TextEditingController c,String label,{int lines=1})=>TextField(controller:c,maxLines:lines,decoration:InputDecoration(labelText:label));
  Widget _dropdown(String label,String value,Map<String,String> options,ValueChanged<String> changed)=>DropdownButtonFormField<String>(initialValue:value,decoration:InputDecoration(labelText:label),items:options.entries.map((e)=>DropdownMenuItem(value:e.key,child:Text(e.value))).toList(),onChanged:(v){if(v!=null)changed(v);});

  Future<void> _copySummary() async {final text='PMO Governance\nChange Requests: ${changes.length}\nDecisions: ${decisions.length}\nStakeholders: ${stakeholders.length}\nMilestones: ${milestones.length}\nWeekly Reports: ${reports.length}';await Clipboard.setData(ClipboardData(text:text));if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('خلاصه PMO کپی شد')));}
  Widget _label(String t,String v)=>Padding(padding:const EdgeInsets.only(top:8),child:Align(alignment:Alignment.centerRight,child:RichText(text:TextSpan(style:Theme.of(context).textTheme.bodyMedium,children:[TextSpan(text:'$t: ',style:const TextStyle(fontWeight:FontWeight.w900)),TextSpan(text:v.isEmpty?'—':v)]))));
  String _changeStatus(String s)=>{'pending':'در انتظار','approved':'تایید','rejected':'رد','implemented':'اجرا شده'}[s]??s;
  String _level(String s)=>{'low':'کم','medium':'متوسط','high':'بالا'}[s]??s;
  String _engagement(String s)=>{'monitor':'پایش','inform':'اطلاع‌رسانی','manage':'مدیریت نزدیک','satisfy':'راضی نگه‌داشتن'}[s]??s;
  String _milestoneStatus(String s)=>{'planned':'برنامه‌ریزی','doing':'در حال انجام','done':'تکمیل','delayed':'تاخیر'}[s]??s;
}

class _Empty extends StatelessWidget {final String title;final String subtitle;const _Empty({required this.title,required this.subtitle});@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surfaceContainerLow,borderRadius:BorderRadius.circular(24)),child:Column(children:[const Icon(Icons.account_tree_outlined,size:40),const SizedBox(height:10),Text(title,style:const TextStyle(fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(subtitle,textAlign:TextAlign.center)]));}
