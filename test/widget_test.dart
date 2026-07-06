import 'package:flutter_test/flutter_test.dart';
import 'package:real_time_location_tracker/main.dart';

void main() {
  testWidgets('App bar title is correct', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Real-Time Location Tracker'), findsOneWidget);
  });
}
