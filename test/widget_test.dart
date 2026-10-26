import 'package:flutter_test/flutter_test.dart';
import 'package:mysearch/main.dart';

void main() {
  testWidgets('App renders MySearch title on home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MySearchApp());
    await tester.pumpAndSettle();

    expect(find.text('MySearch'), findsWidgets);
  });
}
