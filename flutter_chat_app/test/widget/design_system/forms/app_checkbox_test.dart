import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/app_checkbox.dart';
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
    testWidgets('Property 1: Checkbox State Rendering', (tester) async {
      // Feature: design-system-advanced-components, Property 1: Checkbox State Rendering
      // Validates: Requirements 1.1
      //
      // Property: For all checkbox configurations, the rendered checkbox
      // must correctly display the specified state (checked, unchecked, indeterminate)

      final random = Random(42); // Fixed seed for reproducibility

      for (int i = 0; i < 100; i++) {
        // Generate random checkbox configuration
        final bool? value;
        final bool tristate;

        // 33% chance for each state: true, false, null
        final stateChoice = random.nextInt(3);
        if (stateChoice == 0) {
          value = true;
          tristate = false;
        } else if (stateChoice == 1) {
          value = false;
          tristate = false;
        } else {
          value = null;
          tristate = true; // Required for null value
        }

        final size = CheckboxSize.values[random.nextInt(CheckboxSize.values.length)];
        final hasLabel = random.nextBool();
        final label = hasLabel ? 'Test Label $i' : null;

        bool? changedValue;

        await tester.pumpWidget(
          makeTestableWidget(
            AppCheckbox(
              value: value,
              tristate: tristate,
              onChanged: (newValue) => changedValue = newValue,
              label: label,
              size: size,
            ),
          ),
        );

        // Verify checkbox widget exists
        final checkboxFinder = find.byType(Checkbox);
        expect(checkboxFinder, findsOneWidget,
            reason: 'Iteration $i: Checkbox should exist');

        // Verify checkbox has correct value
        final checkbox = tester.widget<Checkbox>(checkboxFinder);
        expect(checkbox.value, value,
            reason: 'Iteration $i: Checkbox value should match input value');
        expect(checkbox.tristate, tristate,
            reason: 'Iteration $i: Checkbox tristate should match input tristate');

        // Verify label rendering
        if (label != null) {
          expect(find.text(label), findsOneWidget,
              reason: 'Iteration $i: Label should be rendered when provided');
        }

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('Property 2: Checkbox Interaction Feedback', (tester) async {
      // Feature: design-system-advanced-components, Property 2: Checkbox Interaction Feedback
      // Validates: Requirements 1.2
      //
      // Property: For all checkbox interactions, the onChanged callback
      // must be triggered when the checkbox is tapped

      final random = Random(43); // Different seed

      for (int i = 0; i < 100; i++) {
        // Generate random initial state (skip null for this test)
        final bool initialValue = random.nextBool();
        final bool tristate = false; // Keep it simple for interaction test

        bool callbackCalled = false;
        bool? receivedValue;

        await tester.pumpWidget(
          makeTestableWidget(
            AppCheckbox(
              value: initialValue,
              tristate: tristate,
              onChanged: (newValue) {
                callbackCalled = true;
                receivedValue = newValue;
              },
            ),
          ),
        );

        // Tap the checkbox widget
        await tester.tap(find.byType(Checkbox));
        await tester.pump();

        // Verify callback was called
        expect(callbackCalled, isTrue,
            reason: 'Iteration $i: onChanged callback should be called');
        
        // Verify correct value was received
        expect(receivedValue, !initialValue,
            reason: 'Iteration $i: should toggle from $initialValue to ${!initialValue}');

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });

  group('Unit Tests - State Variants', () {
    testWidgets('renders checked state correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, true);
      expect(checkbox.tristate, false);
    });

    testWidgets('renders unchecked state correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: false,
            onChanged: (_) {},
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, false);
      expect(checkbox.tristate, false);
    });

    testWidgets('renders indeterminate state correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: null,
            tristate: true,
            onChanged: (_) {},
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, null);
      expect(checkbox.tristate, true);
    });
  });

  group('Unit Tests - Disabled State', () {
    testWidgets('renders disabled state when onChanged is null', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppCheckbox(
            value: true,
            onChanged: null,
            label: 'Disabled checkbox',
          ),
        ),
      );

      // Verify checkbox is disabled
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.onChanged, null);

      // Verify tap does nothing
      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();

      // Value should remain unchanged
      final checkboxAfter = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkboxAfter.value, true);
    });

    testWidgets('applies disabled styling', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppCheckbox(
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
  });

  group('Unit Tests - Label Rendering', () {
    testWidgets('renders label when provided', (tester) async {
      const labelText = 'Accept terms and conditions';

      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: false,
            onChanged: (_) {},
            label: labelText,
          ),
        ),
      );

      expect(find.text(labelText), findsOneWidget);
    });

    testWidgets('does not render label when not provided', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: false,
            onChanged: (_) {},
          ),
        ),
      );

      // Should only find the checkbox, no text widgets
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('label is tappable', (tester) async {
      bool? value = false;

      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: value,
            onChanged: (newValue) => value = newValue,
            label: 'Tap me',
          ),
        ),
      );

      // Tap the label text
      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();

      expect(value, true);
    });
  });

  group('Unit Tests - Size Variants', () {
    testWidgets('renders small size correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: false,
            onChanged: (_) {},
            size: CheckboxSize.small,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(Checkbox),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.width, lessThan(20));
    });

    testWidgets('renders medium size correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: false,
            onChanged: (_) {},
            size: CheckboxSize.medium,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(Checkbox),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.width, greaterThanOrEqualTo(18));
      expect(sizedBox.width, lessThan(24));
    });

    testWidgets('renders large size correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: false,
            onChanged: (_) {},
            size: CheckboxSize.large,
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(Checkbox),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.width, greaterThanOrEqualTo(24));
    });
  });

  group('Unit Tests - Dark Mode', () {
    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: true,
            onChanged: (_) {},
            label: 'Dark mode checkbox',
          ),
          themeMode: ThemeMode.dark,
        ),
      );

      // Verify checkbox renders
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Dark mode checkbox'), findsOneWidget);

      // Verify theme is dark
      final BuildContext context = tester.element(find.byType(AppCheckbox));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('disabled state renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppCheckbox(
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

  group('Unit Tests - Interaction', () {
    testWidgets('toggles from false to true', (tester) async {
      bool? value = false;

      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: value,
            onChanged: (newValue) => value = newValue,
          ),
        ),
      );

      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();

      expect(value, true);
    });

    testWidgets('toggles from true to false', (tester) async {
      bool? value = true;

      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: value,
            onChanged: (newValue) => value = newValue,
          ),
        ),
      );

      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();

      expect(value, false);
    });

    testWidgets('tristate cycles through false → true → null → false', (tester) async {
      bool? value = false;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppCheckbox(
                value: value,
                tristate: true,
                onChanged: (newValue) => setState(() => value = newValue),
              );
            },
          ),
        ),
      );

      // false → true
      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();
      expect(value, true);

      // true → null
      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();
      expect(value, null);

      // null → false
      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();
      expect(value, false);
    });
  });

  group('Unit Tests - Accessibility', () {
    testWidgets('has proper semantic labels', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: true,
            onChanged: (_) {},
            label: 'Accessible checkbox',
          ),
        ),
      );

      // Verify checkbox renders with label
      expect(find.text('Accessible checkbox'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('checkbox is accessible', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      // Verify checkbox can be found and interacted with
      expect(find.byType(Checkbox), findsOneWidget);
      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();
    });

    testWidgets('has minimum touch target size', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: false,
            onChanged: (_) {},
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(AppCheckbox),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(constrainedBox.constraints.minWidth, greaterThanOrEqualTo(48));
      expect(constrainedBox.constraints.minHeight, greaterThanOrEqualTo(48));
    });
  });

  group('Unit Tests - Custom Colors', () {
    testWidgets('applies custom active color', (tester) async {
      const customColor = Colors.green;

      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: true,
            onChanged: (_) {},
            activeColor: customColor,
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.activeColor, customColor);
    });

    testWidgets('applies custom check color', (tester) async {
      const customColor = Colors.yellow;

      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: true,
            onChanged: (_) {},
            checkColor: customColor,
          ),
        ),
      );

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.checkColor, customColor);
    });

    testWidgets('uses theme colors by default', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppCheckbox(
            value: true,
            onChanged: (_) {},
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(AppCheckbox));
      final theme = Theme.of(context);
      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));

      expect(checkbox.activeColor, theme.colorScheme.primary);
      expect(checkbox.checkColor, theme.colorScheme.onPrimary);
    });
  });
}
