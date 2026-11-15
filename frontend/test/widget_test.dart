import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('LabInventoryApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LabInventoryApp(isLoggedIn: false));
    expect(find.text('Lab Sistem Komputer'), findsOneWidget);
  });
}
