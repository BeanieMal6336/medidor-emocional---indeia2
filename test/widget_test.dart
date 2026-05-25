// This is a basic Flutter widget test to verify that the app builds and boots.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindflow/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app within ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MindFlowApp()));
  });
}

