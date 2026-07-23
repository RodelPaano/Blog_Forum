import 'package:flutter_test/flutter_test.dart';

import 'package:blog_forum_app/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Blog Forum'), findsNothing);
  });
}
