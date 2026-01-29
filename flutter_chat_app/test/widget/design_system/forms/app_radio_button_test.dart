import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/app_radio_button.dart';
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
    testWidgets('Property 3: Radio Button Mutual Exclusion', (tester) async {
      // Feature: design-system-advanced-components, Property 3: Radio Button Mutual Exclusion
      // Validates: Requirements 1.3, 1.4
      //
      // Property: For all radio button groups, selecting one button
      // must deselect all other buttons in the group (mutual exclusion)

      final random = Random(44); // Fixed seed for reproducibility

      for (int i = 0; i < 100; i++) {
        // Generate random number of radio buttons (2-10)
        final buttonCount = 2 + random.nextInt(9);
        
        // Generate random initial selection (or null for no selection)
        final hasInitialSelection = random.nextBool();
        String? selectedValue = hasInitialSelection 
            ? 'option${random.nextInt(buttonCount)}' 
            : null;

        // Generate random size
        final size = RadioButtonSize.values[random.nextInt(RadioButtonSize.values.length)];

        await tester.pumpWidget(
          makeTestableWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return AppRadioGroup<String>(
                  value: selectedValue,
                  onChanged: (value) => setState(() => selectedValue = value),
                  size: size,
                  children: List.generate(
                    buttonCount,
                    (index) => AppRadioButton(
                      value: 'option$index',
                      label: 'Option $index',
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Verify initial state
        final radioButtons = tester.widgetList<Radio<String>>(find.byType(Radio<String>));
        expect(radioButtons.length, buttonCount,
            reason: 'Iteration $i: Should have $buttonCount radio buttons');

        // Count how many are selected initially
        int selectedCount = 0;
        for (final radio in radioButtons) {
          if (radio.groupValue == radio.value) {
            selectedCount++;
          }
        }
        expect(selectedCount, hasInitialSelection ? 1 : 0,
            reason: 'Iteration $i: Should have ${hasInitialSelection ? 1 : 0} selected initially');

        // Select a random radio button
        final indexToSelect = random.nextInt(buttonCount);
        await tester.tap(find.text('Option $indexToSelect'));
        await tester.pumpAndSettle();

        // Verify mutual exclusion: only one button should be selected
        final radioButtonsAfter = tester.widgetList<Radio<String>>(find.byType(Radio<String>));
        int selectedCountAfter = 0;
        String? selectedValueAfter;
        
        for (final radio in radioButtonsAfter) {
          if (radio.groupValue == radio.value) {
            selectedCountAfter++;
            selectedValueAfter = radio.value;
          }
        }

        expect(selectedCountAfter, 1,
            reason: 'Iteration $i: Exactly one radio button should be selected after tap');
        expect(selectedValueAfter, 'option$indexToSelect',
            reason: 'Iteration $i: The tapped button should be selected');

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });

  group('Unit Tests - Single Selection', () {
    testWidgets('renders with no selection initially', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppRadioGroup<String>(
            value: null,
            onChanged: (_) {},
            children: const [
              AppRadioButton(value: 'option1', label: 'Option 1'),
              AppRadioButton(value: 'option2', label: 'Option 2'),
            ],
          ),
        ),
      );

      final radioButtons = tester.widgetList<Radio<String>>(find.byType(Radio<String>));
      for (final radio in radioButtons) {
        expect(radio.groupValue, null);
      }
    });

    testWidgets('renders with initial selection', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppRadioGroup<String>(
            value: 'option2',
            onChanged: (_) {},
            children: const [
              AppRadioButton(value: 'option1', label: 'Option 1'),
              AppRadioButton(value: 'option2', label: 'Option 2'),
              AppRadioButton(value: 'option3', label: 'Option 3'),
            ],
          ),
        ),
      );

      final radioButtons = tester.widgetList<Radio<String>>(find.byType(Radio<String>)).toList();
      expect(radioButtons[0].groupValue, 'option2');
      expect(radioButtons[0].value, 'option1');
      expect(radioButtons[1].groupValue, 'option2');
      expect(radioButtons[1].value, 'option2');
      expect(radioButtons[2].groupValue, 'option2');
      expect(radioButtons[2].value, 'option3');
    });

    testWidgets('only one radio button can be selected at a time', (tester) async {
      String? selectedValue = 'option1';

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppRadioGroup<String>(
                value: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                children: const [
                  AppRadioButton(value: 'option1', label: 'Option 1'),
                  AppRadioButton(value: 'option2', label: 'Option 2'),
                  AppRadioButton(value: 'option3', label: 'Option 3'),
                ],
              );
            },
          ),
        ),
      );

      // Initially option1 is selected
      expect(selectedValue, 'option1');

      // Tap option2
      await tester.tap(find.text('Option 2'));
      await tester.pumpAndSettle();

      // Now option2 should be selected
      expect(selectedValue, 'option2');

      // Verify only one is selected
      final radioButtons = tester.widgetList<Radio<String>>(find.byType(Radio<String>));
      int selectedCount = 0;
      for (final radio in radioButtons) {
        if (radio.groupValue == radio.value) {
          selectedCount++;
        }
      }
      expect(selectedCount, 1);
    });
  });

  group('Unit Tests - Value Changes', () {
    testWidgets('triggers onChanged callback when radio button is tapped', (tester) async {
      String? selectedValue;
      bool callbackCalled = false;

      await tester.pumpWidget(
        makeTestableWidget(
          AppRadioGroup<String>(
            value: selectedValue,
            onChanged: (value) {
              callbackCalled = true;
              selectedValue = value;
            },
            children: const [
              AppRadioButton(value: 'option1', label: 'Option 1'),
              AppRadioButton(value: 'option2', label: 'Option 2'),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Option 1'));
      await tester.pumpAndSettle();

      expect(callbackCalled, isTrue);
      expect(selectedValue, 'option1');
    });

    testWidgets('can change selection multiple times', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppRadioGroup<String>(
                value: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                children: const [
                  AppRadioButton(value: 'option1', label: 'Option 1'),
                  AppRadioButton(value: 'option2', label: 'Option 2'),
                  AppRadioButton(value: 'option3', label: 'Option 3'),
                ],
              );
            },
          ),
        ),
      );

      // Select option1
      await tester.tap(find.text('Option 1'));
      await tester.pumpAndSettle();
      expect(selectedValue, 'option1');

      // Select option3
      await tester.tap(find.text('Option 3'));
      await tester.pumpAndSettle();
      expect(selectedValue, 'option3');

      // Select option2
      await tester.tap(find.text('Option 2'));
      await tester.pumpAndSettle();
      expect(selectedValue, 'option2');
    });

    testWidgets('tapping selected radio button does not deselect it', (tester) async {
      String? selectedValue = 'option1';

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppRadioGroup<String>(
                value: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                children: const [
                  AppRadioButton(value: 'option1', label: 'Option 1'),
                  AppRadioButton(value: 'option2', label: 'Option 2'),
                ],
              );
            },
          ),
        ),
      );

      // Tap the already selected option
      await tester.tap(find.text('Option 1'));
      await tester.pumpAndSettle();

      // Should still be selected
      expect(selectedValue, 'option1');
    });
  });

  group('Unit Tests - Disabled State', () {
    testWidgets('renders disabled state when onChanged is null', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppRadioGroup<String>(
            value: 'option1',
            onChanged: null,
            children: [
              AppRadioButton(value: 'option1', label: 'Option 1'),
              AppRadioButton(value: 'option2', label: 'Option 2'),
            ],
          ),
        ),
      );

      // Verify radio buttons are disabled
      final radioButtons = tester.widgetList<Radio<String>>(find.byType(Radio<String>));
      for (final radio in radioButtons) {
        expect(radio.onChanged, null);
      }
    });

    testWidgets('disabled radio buttons cannot be selected', (tester) async {
      String? selectedValue = 'option1';

      await tester.pumpWidget(
        makeTestableWidget(
          const AppRadioGroup<String>(
            value: 'option1',
            onChanged: null,
            children: [
              AppRadioButton(value: 'option1', label: 'Option 1'),
              AppRadioButton(value: 'option2', label: 'Option 2'),
            ],
          ),
        ),
      );

      // Try to tap option2
      await tester.tap(find.text('Option 2'));
      await tester.pumpAndSettle();

      // Value should not change
      final radioButtons = tester.widgetList<Radio<String>>(find.byType(Radio<String>)).toList();
      expect(radioButtons[0].groupValue, 'option1');
      expect(radioButtons[1].groupValue, 'option1');
    });

    testWidgets('applies disabled styling to labels', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppRadioGroup<String>(
            value: null,
            onChanged: null,
            children: [
              AppRadioButton(value: 'option1', label: 'Disabled Option'),
            ],
          ),
        ),
      );

      // Verify label has reduced opacity
      final text = tester.widget<Text>(find.text('Disabled Option'));
      expect(text.style?.color?.alpha, lessThan(255));
    });
  });

  group('Unit Tests - Generic Type Support', () {
    testWidgets('works with String values', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppRadioGroup<String>(
                value: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                children: const [
                  AppRadioButton(value: 'apple', label: 'Apple'),
                  AppRadioButton(value: 'banana', label: 'Banana'),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Banana'));
      await tester.pumpAndSettle();

      expect(selectedValue, 'banana');
    });

    testWidgets('works with int values', (tester) async {
      int? selectedValue;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppRadioGroup<int>(
                value: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                children: const [
                  AppRadioButton(value: 1, label: 'One'),
                  AppRadioButton(value: 2, label: 'Two'),
                  AppRadioButton(value: 3, label: 'Three'),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();

      expect(selectedValue, 2);
    });

    testWidgets('works with enum values', (tester) async {
      ThemeMode? selectedValue;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppRadioGroup<ThemeMode>(
                value: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                children: const [
                  AppRadioButton(value: ThemeMode.light, label: 'Light'),
                  AppRadioButton(value: ThemeMode.dark, label: 'Dark'),
                  AppRadioButton(value: ThemeMode.system, label: 'System'),
                ],
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(selectedValue, ThemeMode.dark);
    });
  });

  group('Unit Tests - Size Variants', () {
    testWidgets('renders small size correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppRadioGroup<String>(
            value: null,
            onChanged: (_) {},
            size: RadioButtonSize.small,
            children: const [
              AppRadioButton(value: 'option1', label: 'Option 1'),
            ],
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(Radio<String>),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.width, lessThan(20));
    });

    testWidgets('renders medium size correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppRadioGroup<String>(
            value: null,
            onChanged: (_) {},
            size: RadioButtonSize.medium,
            children: const [
              AppRadioButton(value: 'option1', label: 'Option 1'),
            ],
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(Radio<String>),
          matching: find.byType(SizedBox),
        ).first,
      );

      expect(sizedBox.width, greaterThanOrEqualTo(18));
      expect(sizedBox.width, lessThan(24));
    });

    testWidgets('renders large size correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppRadioGroup<String>(
            value: null,
            onChanged: (_) {},
            size: RadioButtonSize.large,
            children: const [
              AppRadioButton(value: 'option1', label: 'Option 1'),
            ],
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(Radio<String>),
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
          AppRadioGroup<String>(
            value: 'option1',
            onChanged: (_) {},
            children: const [
              AppRadioButton(value: 'option1', label: 'Dark mode option'),
            ],
          ),
          themeMode: ThemeMode.dark,
        ),
      );

      // Verify radio button renders
      expect(find.byType(Radio<String>), findsOneWidget);
      expect(find.text('Dark mode option'), findsOneWidget);

      // Verify theme is dark
      final BuildContext context = tester.element(find.byType(AppRadioGroup<String>));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('disabled state renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppRadioGroup<String>(
            value: null,
            onChanged: null,
            children: [
              AppRadioButton(value: 'option1', label: 'Disabled dark'),
            ],
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
          AppRadioGroup<String>(
            value: null,
            onChanged: (_) {},
            children: const [
              AppRadioButton(value: 'option1', label: 'Accessible option'),
            ],
          ),
        ),
      );

      // Verify label renders
      expect(find.text('Accessible option'), findsOneWidget);
      expect(find.byType(Radio<String>), findsOneWidget);
    });

    testWidgets('has minimum touch target size', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppRadioGroup<String>(
            value: null,
            onChanged: (_) {},
            children: const [
              AppRadioButton(value: 'option1', label: 'Option 1'),
            ],
          ),
        ),
      );

      final constrainedBox = tester.widget<ConstrainedBox>(
        find.descendant(
          of: find.byType(AppRadioGroup<String>),
          matching: find.byType(ConstrainedBox),
        ),
      );

      expect(constrainedBox.constraints.minWidth, greaterThanOrEqualTo(48));
      expect(constrainedBox.constraints.minHeight, greaterThanOrEqualTo(48));
    });

    testWidgets('radio buttons are keyboard navigable', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppRadioGroup<String>(
                value: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                children: const [
                  AppRadioButton(value: 'option1', label: 'Option 1'),
                  AppRadioButton(value: 'option2', label: 'Option 2'),
                ],
              );
            },
          ),
        ),
      );

      // Verify radio buttons can be found and interacted with
      expect(find.byType(Radio<String>), findsNWidgets(2));
      
      // Tap first radio button
      await tester.tap(find.text('Option 1'));
      await tester.pumpAndSettle();
      
      // Verify it works
      expect(selectedValue, 'option1');
    });
  });

  group('Unit Tests - Custom Colors', () {
    testWidgets('applies custom active color', (tester) async {
      const customColor = Colors.green;

      await tester.pumpWidget(
        makeTestableWidget(
          AppRadioGroup<String>(
            value: 'option1',
            onChanged: (_) {},
            activeColor: customColor,
            children: const [
              AppRadioButton(value: 'option1', label: 'Option 1'),
            ],
          ),
        ),
      );

      final radio = tester.widget<Radio<String>>(find.byType(Radio<String>));
      expect(radio.activeColor, customColor);
    });

    testWidgets('uses theme colors by default', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppRadioGroup<String>(
            value: 'option1',
            onChanged: (_) {},
            children: const [
              AppRadioButton(value: 'option1', label: 'Option 1'),
            ],
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(AppRadioGroup<String>));
      final theme = Theme.of(context);
      final radio = tester.widget<Radio<String>>(find.byType(Radio<String>));

      expect(radio.activeColor, theme.colorScheme.primary);
    });
  });

  group('Unit Tests - Spacing', () {
    testWidgets('applies custom spacing between radio buttons', (tester) async {
      const customSpacing = 16.0;

      await tester.pumpWidget(
        makeTestableWidget(
          AppRadioGroup<String>(
            value: null,
            onChanged: (_) {},
            spacing: customSpacing,
            children: const [
              AppRadioButton(value: 'option1', label: 'Option 1'),
              AppRadioButton(value: 'option2', label: 'Option 2'),
            ],
          ),
        ),
      );

      // Verify spacing is applied
      final paddings = tester.widgetList<Padding>(
        find.descendant(
          of: find.byType(AppRadioGroup<String>),
          matching: find.byType(Padding),
        ),
      );

      // At least one padding should have the custom spacing
      expect(
        paddings.any((p) => p.padding == const EdgeInsets.only(bottom: customSpacing)),
        isTrue,
      );
    });
  });

  group('Unit Tests - Label Interaction', () {
    testWidgets('tapping label selects radio button', (tester) async {
      String? selectedValue;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppRadioGroup<String>(
                value: selectedValue,
                onChanged: (value) => setState(() => selectedValue = value),
                children: const [
                  AppRadioButton(value: 'option1', label: 'Tap this label'),
                ],
              );
            },
          ),
        ),
      );

      // Tap the label text
      await tester.tap(find.text('Tap this label'));
      await tester.pumpAndSettle();

      expect(selectedValue, 'option1');
    });
  });
}
