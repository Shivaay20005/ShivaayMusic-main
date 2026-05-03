import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shivaaymusic/ui/widgets/custom_sidebar.dart';

void main() {
  testWidgets('CustomSideBarAnimated displays logo and title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomSideBarAnimated(
            widthSwitch: 800,
            mainLogoImage: 'assets/icons/icon.png',
            mainLogoSize: const Size(60, 60),
            mainLogoTitle: 'ShivaayMusic',
            sidebarItems: [
              SideBarItem(
                iconSelected: Icons.home,
                text: 'Home',
              ),
            ],
          ),
        ),
      ),
    );

    // Verify that the logo is displayed
    expect(find.byType(Image), findsOneWidget);
    
    // Verify that the title is displayed
    expect(find.text('ShivaayMusic'), findsOneWidget);
  });
}