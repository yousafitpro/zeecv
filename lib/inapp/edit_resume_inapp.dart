
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
class EditResumeInapp extends StatefulWidget {
  const EditResumeInapp({ Key? key }) : super(key: key);

  @override
  _EditResumeInappState createState() => _EditResumeInappState();
}

class _EditResumeInappState extends State<EditResumeInapp> {
  @override
  Widget build(BuildContext context) {
    final GoRouterState routeState = GoRouterState.of(context);
    final String? url = routeState.pathParameters['url'];
    print(url);
    return Container(
      
    );
  }
}