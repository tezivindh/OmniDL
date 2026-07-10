import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:omnidl/app/app.dart';

void main() {
  setUpAll(() {
    // Initialize MediaKit for test environments
    MediaKit.ensureInitialized();
  });

  testWidgets('App renders HomeView with OmniDL title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: OmniDLApp(),
      ),
    );

    // Verify that the title 'OmniDL' is shown.
    expect(find.text('OmniDL'), findsAtLeastNWidgets(1));
  });
}
