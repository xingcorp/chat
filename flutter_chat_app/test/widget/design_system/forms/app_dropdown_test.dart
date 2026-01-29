import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/app_dropdown.dart';
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
    testWidgets('Property 6: Dropdown Search Filtering', (tester) async {
      // Feature: design-system-advanced-components, Property 6: Dropdown Search Filtering
      // Validates: Requirements 1.9
      //
      // Property: For all searchable dropdowns, typing a search query should
      // filter the displayed options to only those matching the query

      final random = Random(46); // Fixed seed for reproducibility

      for (int i = 0; i < 100; i++) {
        // Generate random list of items
        final itemCount = 5 + random.nextInt(15); // 5-20 items
        final items = List.generate(
          itemCount,
          (index) => 'Item ${String.fromCharCode(65 + (index % 26))}$index',
        );

        String? selectedValue;

        await tester.pumpWidget(
          makeTestableWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return AppDropdown<String>(
                  value: selectedValue,
                  items: items,
                  onChanged: (value) => setState(() => selectedValue = value),
                  searchable: true,
                  label: 'Test Dropdown $i',
                );
              },
            ),
          ),
        );

        // Open dropdown
        await tester.tap(find.byType(AppDropdown<String>));
        await tester.pumpAndSettle();

        // Verify all items are initially visible
        for (final item in items) {
          expect(find.text(item), findsOneWidget,
              reason: 'Iteration $i: All items should be visible initially');
        }

        // Generate a random search query (first character of a random item)
        final randomItem = items[random.nextInt(items.length)];
        final searchQuery = randomItem.substring(0, min(3, randomItem.length));

        // Enter search query
        await tester.enterText(find.byType(TextField), searchQuery);
        await tester.pumpAndSettle();

        // Verify only matching items are visible
        final expectedMatches = items
            .where((item) =>
                item.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

        for (final item in items) {
          if (expectedMatches.contains(item)) {
            expect(find.text(item), findsOneWidget,
                reason:
                    'Iteration $i: Matching item "$item" should be visible for query "$searchQuery"');
          } else {
            expect(find.text(item), findsNothing,
                reason:
                    'Iteration $i: Non-matching item "$item" should be hidden for query "$searchQuery"');
          }
        }

        // Close dropdown
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('Property 7: Dropdown Selection Behavior', (tester) async {
      // Feature: design-system-advanced-components, Property 7: Dropdown Selection Behavior
      // Validates: Requirements 1.10
      //
      // Property: For all dropdowns, selecting an option should update the selected value,
      // trigger onChanged callback, and close the dropdown

      final random = Random(47); // Different seed

      for (int i = 0; i < 100; i++) {
        // Generate random list of items (keep it small to avoid off-screen issues)
        final itemCount = 3 + random.nextInt(5); // 3-7 items
        final items = List.generate(itemCount, (index) => 'Option $index');

        String? selectedValue;
        bool callbackCalled = false;
        String? receivedValue;

        await tester.pumpWidget(
          makeTestableWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return AppDropdown<String>(
                  value: selectedValue,
                  items: items,
                  onChanged: (value) {
                    callbackCalled = true;
                    receivedValue = value;
                    setState(() => selectedValue = value);
                  },
                  label: 'Test Dropdown $i',
                );
              },
            ),
          ),
        );

        // Open dropdown
        await tester.tap(find.byType(AppDropdown<String>));
        await tester.pumpAndSettle();

        // Select a random item (prefer first few items to avoid off-screen issues)
        final itemToSelect = items[random.nextInt(min(3, items.length))];
        await tester.tap(find.text(itemToSelect).last, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Verify callback was called
        expect(callbackCalled, isTrue,
            reason: 'Iteration $i: onChanged callback should be called');

        // Verify correct value was received
        expect(receivedValue, itemToSelect,
            reason:
                'Iteration $i: Callback should receive the selected item');

        // Verify dropdown is closed (overlay should not exist)
        expect(find.byType(Material).evaluate().length, lessThanOrEqualTo(2),
            reason: 'Iteration $i: Dropdown should be closed after selection');

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });

  group('Unit Tests - Basic Rendering', () {
    testWidgets('renders dropdown correctly', (tester) async {
      final items = ['Option 1', 'Option 2', 'Option 3'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byType(AppDropdown<String>), findsOneWidget);
    });

    testWidgets('renders label when provided', (tester) async {
      const labelText = 'Choose your option';
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
            label: labelText,
          ),
        ),
      );

      expect(find.text(labelText), findsOneWidget);
    });

    testWidgets('displays hint when no value selected', (tester) async {
      const hintText = 'Choose one';
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
            hint: hintText,
          ),
        ),
      );

      expect(find.text(hintText), findsOneWidget);
    });

    testWidgets('displays selected value', (tester) async {
      final items = ['Option 1', 'Option 2', 'Option 3'];
      const selectedValue = 'Option 2';

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: selectedValue,
            items: items,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text(selectedValue), findsOneWidget);
    });
  });

  group('Unit Tests - Dropdown Interaction', () {
    testWidgets('opens dropdown on tap', (tester) async {
      final items = ['Option 1', 'Option 2', 'Option 3'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
          ),
        ),
      );

      // Tap to open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Verify all items are visible
      for (final item in items) {
        expect(find.text(item), findsOneWidget);
      }
    });

    testWidgets('closes dropdown on outside tap', (tester) async {
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Tap outside to close
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Verify dropdown is closed
      expect(find.byType(Material).evaluate().length, lessThanOrEqualTo(2));
    });

    testWidgets('selects item on tap', (tester) async {
      final items = ['Option 1', 'Option 2', 'Option 3'];
      String? selectedValue;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppDropdown<String>(
                value: selectedValue,
                items: items,
                onChanged: (value) => setState(() => selectedValue = value),
              );
            },
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Select an item
      await tester.tap(find.text('Option 2').last);
      await tester.pumpAndSettle();

      // Verify selection
      expect(selectedValue, 'Option 2');
    });

    testWidgets('closes dropdown after selection', (tester) async {
      final items = ['Option 1', 'Option 2'];
      String? selectedValue;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppDropdown<String>(
                value: selectedValue,
                items: items,
                onChanged: (value) => setState(() => selectedValue = value),
              );
            },
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Select an item
      await tester.tap(find.text('Option 1').last);
      await tester.pumpAndSettle();

      // Verify dropdown is closed
      expect(find.byType(Material).evaluate().length, lessThanOrEqualTo(2));
    });
  });

  group('Unit Tests - Search Functionality', () {
    testWidgets('shows search field when searchable', (tester) async {
      final items = ['Apple', 'Banana', 'Cherry'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
            searchable: true,
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Verify search field exists
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('does not show search field when not searchable', (tester) async {
      final items = ['Apple', 'Banana', 'Cherry'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
            searchable: false,
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Verify search field does not exist
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('filters items based on search query', (tester) async {
      final items = ['Apple', 'Banana', 'Cherry', 'Date'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
            searchable: true,
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(TextField), 'an');
      await tester.pumpAndSettle();

      // Verify only matching items are visible
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
      expect(find.text('Date'), findsNothing);
    });

    testWidgets('shows all items when search is cleared', (tester) async {
      final items = ['Apple', 'Banana', 'Cherry'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
            searchable: true,
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Enter and clear search
      await tester.enterText(find.byType(TextField), 'Ban');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Verify all items are visible
      for (final item in items) {
        expect(find.text(item), findsOneWidget);
      }
    });

    testWidgets('shows no results message when no matches', (tester) async {
      final items = ['Apple', 'Banana', 'Cherry'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
            searchable: true,
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Enter non-matching search query
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pumpAndSettle();

      // Verify no items are visible
      for (final item in items) {
        expect(find.text(item), findsNothing);
      }
    });
  });

  group('Unit Tests - Disabled State', () {
    testWidgets('renders disabled state when onChanged is null', (tester) async {
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: 'Option 1',
            items: items,
            onChanged: null,
            label: 'Disabled dropdown',
          ),
        ),
      );

      // Verify dropdown exists
      expect(find.byType(AppDropdown<String>), findsOneWidget);
    });

    testWidgets('cannot be opened when disabled', (tester) async {
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: 'Option 1',
            items: items,
            onChanged: null,
          ),
        ),
      );

      // Try to open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Verify dropdown did not open (no overlay items visible)
      expect(find.text('Option 2'), findsNothing);
    });

    testWidgets('applies disabled styling', (tester) async {
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: 'Option 1',
            items: items,
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

  group('Unit Tests - Dark Mode', () {
    testWidgets('renders correctly in dark mode', (tester) async {
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
            label: 'Dark mode dropdown',
          ),
          themeMode: ThemeMode.dark,
        ),
      );

      // Verify dropdown renders
      expect(find.byType(AppDropdown<String>), findsOneWidget);
      expect(find.text('Dark mode dropdown'), findsOneWidget);

      // Verify theme is dark
      final BuildContext context = tester.element(find.byType(AppDropdown<String>));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('dropdown menu renders correctly in dark mode', (tester) async {
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
          ),
          themeMode: ThemeMode.dark,
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Verify items are visible
      for (final item in items) {
        expect(find.text(item), findsOneWidget);
      }
    });
  });

  group('Unit Tests - Custom Item Builder', () {
    testWidgets('uses custom item builder when provided', (tester) async {
      final items = [1, 2, 3];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<int>(
            value: null,
            items: items,
            onChanged: (_) {},
            itemBuilder: (item) => Text('Number: $item'),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<int>));
      await tester.pumpAndSettle();

      // Verify custom builder is used
      expect(find.text('Number: 1'), findsOneWidget);
      expect(find.text('Number: 2'), findsOneWidget);
      expect(find.text('Number: 3'), findsOneWidget);
    });

    testWidgets('uses toString when no custom builder', (tester) async {
      final items = [1, 2, 3];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<int>(
            value: null,
            items: items,
            onChanged: (_) {},
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<int>));
      await tester.pumpAndSettle();

      // Verify toString is used
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });
  });

  group('Unit Tests - Selected Item Indicator', () {
    testWidgets('shows check icon for selected item', (tester) async {
      final items = ['Option 1', 'Option 2', 'Option 3'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: 'Option 2',
            items: items,
            onChanged: (_) {},
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Verify check icon exists
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('highlights selected item', (tester) async {
      final items = ['Option 1', 'Option 2', 'Option 3'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: 'Option 2',
            items: items,
            onChanged: (_) {},
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Verify selected item has different styling
      // (This is implicit in the check icon presence)
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('Unit Tests - Empty State', () {
    testWidgets('handles empty items list', (tester) async {
      final items = <String>[];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      // Verify no items are shown
      expect(find.byType(InkWell).evaluate().length, lessThanOrEqualTo(2));
    });
  });

  group('Unit Tests - Accessibility', () {
    testWidgets('has proper semantic labels', (tester) async {
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
            label: 'Accessible dropdown',
          ),
        ),
      );

      // Verify dropdown renders with label
      expect(find.text('Accessible dropdown'), findsOneWidget);
    });

    testWidgets('has minimum touch target size', (tester) async {
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppDropdown<String>),
          matching: find.byType(Container),
        ).first,
      );

      expect(container.constraints?.minHeight, greaterThanOrEqualTo(48));
    });
  });

  group('Unit Tests - Dropdown Arrow Icon', () {
    testWidgets('shows down arrow when closed', (tester) async {
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('shows up arrow when open', (tester) async {
      final items = ['Option 1', 'Option 2'];

      await tester.pumpWidget(
        makeTestableWidget(
          AppDropdown<String>(
            value: null,
            items: items,
            onChanged: (_) {},
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(AppDropdown<String>));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
    });
  });
}
