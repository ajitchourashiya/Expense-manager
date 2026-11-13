import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import 'user_detail_screen.dart';

class AdminUsers extends StatelessWidget { const AdminUsers({super.key});
 @override Widget build(BuildContext context)=>SafeArea(child:StreamBuilder<List<AppUser>>(stream:FirestoreService().allUsers(),builder:(context,snap){final users=snap.data??[];return SingleChildScrollView(padding:const EdgeInsets.fromLTRB(20,24,20,120),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('All users',style:TextStyle(fontSize:26,fontWeight:FontWeight.w800)),const SizedBox(height:5),const Text('Open a user to see registration info and expenses.',style:TextStyle(color:AppColors.slate)),const SizedBox(height:22),if(users.isEmpty)const SizedBox(height:300,child:Center(child:Text('No users found.'))) else ...users.map((u)=>_card(context,u))]));}));
 Widget _card(BuildContext context,AppUser u)=>InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>UserDetailScreen(user:u))),borderRadius:BorderRadius.circular(20),child:Container(margin:const EdgeInsets.only(bottom:11),padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:AppColors.border)),child:Row(children:[CircleAvatar(radius:24,backgroundColor:AppColors.primary.withValues(alpha:.1),child:Text((u.name.isNotEmpty?u.name[0]:'U').toUpperCase(),style:const TextStyle(color:AppColors.primary,fontWeight:FontWeight.w800))),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(u.name.isEmpty?'Unnamed user':u.name,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(u.email,style:const TextStyle(color:AppColors.slate,fontSize:12.5)),const SizedBox(height:3),Text('Registered ${u.createdAt==null?'—':DateFormat('dd MMM yyyy').format(u.createdAt!)}',style:const TextStyle(color:AppColors.slate,fontSize:11.5))])),const Icon(Icons.chevron_right_rounded,color:AppColors.slate)])));
}
