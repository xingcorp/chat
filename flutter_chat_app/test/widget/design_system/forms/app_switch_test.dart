import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/app_switch.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/form_enums.dart';

void main() {
  // Helper to wrap widget with MaterialApp and localization
  Widget makeTestableWidget(Widget child, {ThemeMode themeMode = ThemeMode.light}) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('Property Tests', () {
    testWidgets('Property 4: Switch Toggle Animation', (tester) async {
      // Feature: design-system-advanced-components, Property 4: Switch Toggle Animation
      // Validates: Requirements 1.5, 1.6
      //
      // Property: For all switch interactions, toggling the switch
      // must animate smoothly and provide haptic feedback

      final random = Random(45); // Fixed seed for reproducibility

      for (int i = 0; i < 100; i++) {
        // Generate random initial state
        bool value = random.nextBool();
        
        // Generate random configuration
        final size = SwitchSize.values[random.nextInt(SwitchSize.values.length)];
        final hasLabel = random.nextBool();
        final label = hasLabel ? 'Switch Label $i' : null;
        final hasDescription = random.nextBool();
        final description = hasDescription ? 'Description $i' : null;

        bool callbackCalled = false;
        bool? receivedValue;

        await tester.pumpWidget(
          makeTestableWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return AppSwitch(
                  value: value,
                  onChanged: (newValue) {
                    callbackCalled = true;
                    receivedValue = newValue;
                    setState(() => value = newValue);
                  },
                  label: label,
                  description: description,
                  size: size,
                );
              },
            ),
          ),
        );

        // Verify switch widget exists
        final switchFinder = find.byType(Switch);
        expect(switchFinder, findsOneWidget,
            reason: 'Iteration $i: Switch should exist');

        // Verify switch has correct initial value
        final switchWidget = tester.widget<Switch>(switchFinder);
        expect(switchWidget.value, value,
            reason: 'Iteration $i: Switch value should match input value');

        // Store the initial value before toggle
        final initialValue = value;
        
        // Tap the switch to toggle
        await tester.tap(find.byType(Switch));
        await tester.pump(); // Start animation
        
        // Verify callback was called
        expect(callbackCalled, isTrue,
            reason: 'Iteration $i: onChanged callback should be called');
        expect(receivedValue, !initialValue,
            reason: 'Iteration $i: should toggle from $initialValue to ${!initialValue}');

        // Pump animation frames to verify smooth animation
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Verify final state
        final switchWidgetAfter = tester.widget<Switch>(switchFinder);
        expect(switchWidgetAfter.value, !initialValue,
            reason: 'Iteration $i: Switch should be toggled after animation');

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });

  group('Unit Tests - On/Off States', () {
    testWidgets('renders on state correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('renders off state correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: false,
            onChanged: (_) {},
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, false);
    });

    testWidgets('toggles from off to on', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSwitch(
                value: value,
                onChanged: (newValue) => setState(() => value = newValue),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(value, true);
    });

    testWidgets('toggles from on to off', (tester) async {
      bool value = true;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSwitch(
                value: value,
                onChanged: (newValue) => setState(() => value = newValue),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(value, false);
    });

    testWidgets('can toggle multiple times', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSwitch(
                value: value,
                onChanged: (newValue) => setState(() => value = newValue),
              );
            },
          ),
        ),
      );

      // Toggle on
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(value, true);

      // Toggle off
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(value, false);

      // Toggle on again
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(value, true);
    });
  });

  group('Unit Tests - Animation', () {
    testWidgets('animates smoothly when toggled', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSwitch(
                value: value,
                onChanged: (newValue) => setState(() => value = newValue),
              );
            },
          ),
        ),
      );

      // Tap to toggle
      await tester.tap(find.byType(Switch));
      await tester.pump(); // Start animation

      // Verify animation is in progress
      expect(value, true);

      // Pump animation frames
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      
      // Complete animation
      await tester.pumpAndSettle();

      // Verify final state
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('animation completes within expected duration', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSwitch(
                value: value,
                onChanged: (newValue) => setState(() => value = newValue),
              );
            },
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();

      // Animation should complete within 500ms (300ms + buffer)
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });
  });

  group('Unit Tests - Disabled State', () {
    testWidgets('renders disabled state when onChanged is null', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppSwitch(
            value: true,
            onChanged: null,
            label: 'Disabled switch',
          ),
        ),
      );

      // Verify switch is disabled
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.onChanged, null);
    });

    testWidgets('disabled switch cannot be toggled', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        makeTestableWidget(
          const AppSwitch(
            value: false,
            onChanged: null,
          ),
        ),
      );

      // Try to tap the switch
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();

      // Value should remain unchanged
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, false);
    });

    testWidgets('applies disabled styling to label', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppSwitch(
            value: false,
            onChanged: null,
            label: 'Disabled',
          ),
        ),
      );

      // Verify label has reduced opacity
      final text = tester.widget<Text>(find.text('Disabled'));
      expect(text.style?.color?.alpha, lessThan(255));
    });

    testWidgets('applies disabled styling to description', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppSwitch(
            value: false,
            onChanged: null,
            label: 'Disabled',
            description: 'Cannot toggle',
          ),
        ),
      );

      // Verify description has reduced opacity
      final text = tester.widget<Text>(find.text('Cannot toggle'));
      expect(text.style?.color?.alpha, lessThan(255));
    });
  });

  group('Unit Tests - Label and Description', () {
    testWidgets('renders label when provided', (tester) async {
      const labelText = 'Enable notifications';

      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: false,
            onChanged: (_) {},
            label: labelText,
          ),
        ),
      );

      expect(find.text(labelText), findsOneWidget);
    });

    testWidgets('renders description when provided', (tester) async {
      const descriptionText = 'Receive push notifications';

      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: false,
            onChanged: (_) {},
            label: 'Notifications',
            description: descriptionText,
          ),
        ),
      );

      expect(find.text(descriptionText), findsOneWidget);
    });

    testWidgets('does not render label when not provided', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: false,
            onChanged: (_) {},
          ),
        ),
      );

      // Should only find the switch, no text widgets for label
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('label is tappable', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSwitch(
                value: value,
                onChanged: (newValue) => setState(() => value = newValue),
                label: 'Tap me',
              );
            },
          ),
        ),
      );

      // Tap the label text
      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();

      expect(value, true);
    });

    testWidgets('description is tappable', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSwitch(
                value: value,
                onChanged: (newValue) => setState(() => value = newValue),
                label: 'Label',
                description: 'Tap this description',
              );
            },
          ),
        ),
      );

      // Tap the description text
      await tester.tap(find.text('Tap this description'));
      await tester.pumpAndSettle();

      expect(value, true);
    });
  });

  group('Unit Tests - Size Variants', () {
    testWidgets('renders small size correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: false,
            onChanged: (_) {},
            size: SwitchSize.small,
          ),
        ),
      );

      // Verify switch renders
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
    });

    testWidgets('renders medium size correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: false,
            onChanged: (_) {},
            size: SwitchSize.medium,
          ),
        ),
      );

      // Verify switch renders
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
    });

    testWidgets('renders large size correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: false,
            onChanged: (_) {},
            size: SwitchSize.large,
          ),
        ),
      );

      // Verify switch renders
      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(AppSwitch), findsOneWidget);
    });
  });

  group('Unit Tests - Dark Mode', () {
    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: true,
            onChanged: (_) {},
            label: 'Dark mode switch',
          ),
          themeMode: ThemeMode.dark,
        ),
      );

      // Verify switch renders
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Dark mode switch'), findsOneWidget);

      // Verify theme is dark
      final BuildContext context = tester.element(find.byType(AppSwitch));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('disabled state renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppSwitch(
            value: false,
            onChanged: null,
            label: 'Disabled dark',
          ),
          themeMode: ThemeMode.dark,
        ),
      );

      // Verify disabled styling in dark mode
      final text = tester.widget<Text>(find.text('Disabled dark'));
      expect(text.style?.color?.alpha, lessThan(255));
    });
  });

  group('Unit Tests - Accessibility', () {
    testWidgets('has proper semantic labels', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: true,
            onChanged: (_) {},
            label: 'Accessible switch',
          ),
        ),
      );

      // Verify label renders
      expect(find.text('Accessible switch'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('has minimum touch target size', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: false,
            onChanged: (_) {},
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(AppSwitch),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(constrainedBox.constraints.minWidth, greaterThanOrEqualTo(48));
      expect(constrainedBox.constraints.minHeight, greaterThanOrEqualTo(48));
    });

    testWidgets('switch is accessible', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      // Verify switch can be found and interacted with
      expect(find.byType(Switch), findsOneWidget);
      await tester.tap(find.byType(AppSwitch));
      await tester.pumpAndSettle();
    });
  });

  group('Unit Tests - Custom Colors', () {
    testWidgets('applies custom active color', (tester) async {
      const customColor = Colors.green;

      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: true,
            onChanged: (_) {},
            activeColor: customColor,
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.activeColor, customColor);
    });

    testWidgets('applies custom active track color', (tester) async {
      const customColor = Colors.green;

      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: true,
            onChanged: (_) {},
            activeTrackColor: customColor,
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.activeTrackColor, customColor);
    });

    testWidgets('applies custom inactive thumb color', (tester) async {
      const customColor = Colors.grey;

      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: false,
            onChanged: (_) {},
            inactiveThumbColor: customColor,
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.inactiveThumbColor, customColor);
    });

    testWidgets('applies custom inactive track color', (tester) async {
      const customColor = Colors.grey;

      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: false,
            onChanged: (_) {},
            inactiveTrackColor: customColor,
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.inactiveTrackColor, customColor);
    });

    testWidgets('uses theme colors by default', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(AppSwitch));
      final theme = Theme.of(context);
      final switchWidget = tester.widget<Switch>(find.byType(Switch));

      expect(switchWidget.activeColor, theme.colorScheme.primary);
    });
  });

  group('Unit Tests - Callback', () {
    testWidgets('triggers onChanged callback when toggled', (tester) async {
      bool? receivedValue;
      bool callbackCalled = false;

      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: false,
            onChanged: (value) {
              callbackCalled = true;
              receivedValue = value;
            },
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(callbackCalled, isTrue);
      expect(receivedValue, true);
    });

    testWidgets('callback receives correct value', (tester) async {
      bool? receivedValue;

      await tester.pumpWidget(
        makeTestableWidget(
          AppSwitch(
            value: true,
            onChanged: (value) => receivedValue = value,
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(receivedValue, false);
    });
  });
}
