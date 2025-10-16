import 'package:flutter/material.dart';


class HomeController {
  final BuildContext context;
  final Function(VoidCallback) setState;

  HomeController(this.context, this.setState);

  String selectedSection = 'Dashboard';
  bool isLoading = true;




}