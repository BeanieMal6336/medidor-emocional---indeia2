import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/router/app_router.dart';

void popOrGoDashboard(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.dashboard);
  }
}
