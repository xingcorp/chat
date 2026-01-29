import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chat_app/generated/l10n/app_localizations.dart';
import 'package:flutter_chat_app/presentation/widgets/design_system/forms/app_slider.dart';
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
    testWidgets('Property 5: Slider Value Updates', (tester) async {
      // Feature: design-system-advanced-components, Property 5: Slider Value Updates
      // Validates: Requirements 1.7, 1.8
      //
      // Property: For all slider configurations, dragging the slider should
      // continuously update the value within the min/max range and trigger onChanged callbacks

      final random = Random(45); // Fixed seed for reproducibility

      for (int i = 0; i < 100; i++) {
        // Generate random slider configuration
        final double min = random.nextDouble() * 50; // 0-50
        final double max = min + 50 + random.nextDouble() * 100; // min+50 to min+150
        final double initialValue = min + random.nextDouble() * (max - min);
        
        final sliderType = random.nextBool() ? SliderType.continuous : SliderType.discrete;
        final int? divisions = sliderType == SliderType.discrete 
            ? (5 + random.nextInt(15)) // 5-20 divisions
            : null;

        int callbackCount = 0;
        double? lastReceivedValue;

        await tester.pumpWidget(
          makeTestableWidget(
            StatefulBuilder(
              builder: (context, setState) {
                return AppSlider(
                  value: initialValue,
                  onChanged: (newValue) {
                    callbackCount++;
                    lastReceivedValue = newValue;
                  },
                  min: min,
                  max: max,
                  divisions: divisions,
                  type: sliderType,
                );
              },
            ),
          ),
        );

        // Verify slider widget exists
        final sliderFinder = find.byType(Slider);
        expect(sliderFinder, findsOneWidget,
            reason: 'Iteration $i: Slider should exist');

        // Verify slider has correct initial value
        final slider = tester.widget<Slider>(sliderFinder);
        expect(slider.value, initialValue,
            reason: 'Iteration $i: Slider value should match initial value');
        expect(slider.min, min,
            reason: 'Iteration $i: Slider min should match input min');
        expect(slider.max, max,
            reason: 'Iteration $i: Slider max should match input max');

        // Verify divisions for discrete slider
        if (sliderType == SliderType.discrete) {
          expect(slider.divisions, divisions,
              reason: 'Iteration $i: Discrete slider should have divisions');
        } else {
          expect(slider.divisions, null,
              reason: 'Iteration $i: Continuous slider should not have divisions');
        }

        // Simulate drag gesture
        final sliderCenter = tester.getCenter(sliderFinder);
        final sliderSize = tester.getSize(sliderFinder);
        
        // Drag to a random position (25%-75% of slider width)
        final dragPercent = 0.25 + random.nextDouble() * 0.5;
        final dragOffset = Offset(
          sliderSize.width * dragPercent - sliderSize.width / 2,
          0,
        );

        await tester.drag(sliderFinder, dragOffset);
        await tester.pumpAndSettle();

        // Verify callback was called
        expect(callbackCount, greaterThan(0),
            reason: 'Iteration $i: onChanged callback should be called during drag');

        // Verify received value is within range
        if (lastReceivedValue != null) {
          expect(lastReceivedValue! >= min && lastReceivedValue! <= max, isTrue,
              reason: 'Iteration $i: Value should be within min/max range');
        }

        // Clean up for next iteration
        await tester.pumpWidget(Container());
      }
    });
  });

  group('Unit Tests - Single Value Mode', () {
    testWidgets('renders continuous slider correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
            type: SliderType.continuous,
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 50);
      expect(slider.min, 0);
      expect(slider.max, 100);
      expect(slider.divisions, null);
    });

    testWidgets('renders discrete slider correctly', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 5,
            onChanged: (_) {},
            min: 0,
            max: 10,
            divisions: 10,
            type: SliderType.discrete,
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 5);
      expect(slider.min, 0);
      expect(slider.max, 10);
      expect(slider.divisions, 10);
    });

    testWidgets('updates value on drag', (tester) async {
      double value = 50;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSlider(
                value: value,
                onChanged: (newValue) => setState(() => value = newValue),
                min: 0,
                max: 100,
              );
            },
          ),
        ),
      );

      // Drag slider to the right
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pumpAndSettle();

      // Value should have increased
      expect(value, greaterThan(50));
    });
  });

  group('Unit Tests - Min/Max Constraints', () {
    testWidgets('respects minimum value', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 10,
            onChanged: (_) {},
            min: 10,
            max: 100,
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 10);
      expect(slider.min, 10);
    });

    testWidgets('respects maximum value', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 100,
            onChanged: (_) {},
            min: 0,
            max: 100,
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, 100);
      expect(slider.max, 100);
    });

    testWidgets('throws assertion error when value < min', (tester) async {
      expect(
        () => AppSlider(
          value: 5,
          onChanged: (_) {},
          min: 10,
          max: 100,
        ),
        throwsAssertionError,
      );
    });

    testWidgets('throws assertion error when value > max', (tester) async {
      expect(
        () => AppSlider(
          value: 150,
          onChanged: (_) {},
          min: 0,
          max: 100,
        ),
        throwsAssertionError,
      );
    });
  });

  group('Unit Tests - Divisions', () {
    testWidgets('snaps to divisions in discrete mode', (tester) async {
      double value = 5;

      await tester.pumpWidget(
        makeTestableWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return AppSlider(
                value: value,
                onChanged: (newValue) => setState(() => value = newValue),
                min: 0,
                max: 10,
                divisions: 10,
                type: SliderType.discrete,
              );
            },
          ),
        ),
      );

      // Drag slider
      await tester.drag(find.byType(Slider), const Offset(50, 0));
      await tester.pumpAndSettle();

      // Value should be a whole number (snapped to division)
      expect(value % 1, 0);
    });

    testWidgets('continuous mode has no divisions', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
            type: SliderType.continuous,
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, null);
    });
  });

  group('Unit Tests - Label Display', () {
    testWidgets('renders label when provided', (tester) async {
      const labelText = 'Volume';

      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
            label: labelText,
          ),
        ),
      );

      expect(find.text(labelText), findsOneWidget);
    });

    testWidgets('does not render label when not provided', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
          ),
        ),
      );

      // Should only find the slider, no label text
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('renders min/max labels when enabled', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
            showMinMaxLabels: true,
            minLabel: 'Min',
            maxLabel: 'Max',
          ),
        ),
      );

      expect(find.text('Min'), findsOneWidget);
      expect(find.text('Max'), findsOneWidget);
    });

    testWidgets('does not render min/max labels when disabled', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
            showMinMaxLabels: false,
            minLabel: 'Min',
            maxLabel: 'Max',
          ),
        ),
      );

      expect(find.text('Min'), findsNothing);
      expect(find.text('Max'), findsNothing);
    });
  });

  group('Unit Tests - Disabled State', () {
    testWidgets('renders disabled state when onChanged is null', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppSlider(
            value: 50,
            onChanged: null,
            min: 0,
            max: 100,
            label: 'Disabled slider',
          ),
        ),
      );

      // Verify slider is disabled
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, null);
    });

    testWidgets('applies disabled styling to label', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppSlider(
            value: 50,
            onChanged: null,
            min: 0,
            max: 100,
            label: 'Disabled',
          ),
        ),
      );

      // Verify label has reduced opacity
      final text = tester.widget<Text>(find.text('Disabled'));
      expect(text.style?.color?.alpha, lessThan(255));
    });

    testWidgets('cannot be dragged when disabled', (tester) async {
      const initialValue = 50.0;

      await tester.pumpWidget(
        makeTestableWidget(
          const AppSlider(
            value: initialValue,
            onChanged: null,
            min: 0,
            max: 100,
          ),
        ),
      );

      // Try to drag slider
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pumpAndSettle();

      // Value should remain unchanged
      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.value, initialValue);
    });
  });

  group('Unit Tests - Dark Mode', () {
    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
            label: 'Dark mode slider',
          ),
          themeMode: ThemeMode.dark,
        ),
      );

      // Verify slider renders
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Dark mode slider'), findsOneWidget);

      // Verify theme is dark
      final BuildContext context = tester.element(find.byType(AppSlider));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('disabled state renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          const AppSlider(
            value: 50,
            onChanged: null,
            min: 0,
            max: 100,
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

  group('Unit Tests - Custom Colors', () {
    testWidgets('applies custom active color', (tester) async {
      const customColor = Colors.green;

      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
            activeColor: customColor,
          ),
        ),
      );

      final sliderTheme = tester.widget<SliderTheme>(find.byType(SliderTheme));
      expect(sliderTheme.data.activeTrackColor, customColor);
    });

    testWidgets('applies custom inactive color', (tester) async {
      const customColor = Colors.grey;

      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
            inactiveColor: customColor,
          ),
        ),
      );

      final sliderTheme = tester.widget<SliderTheme>(find.byType(SliderTheme));
      expect(sliderTheme.data.inactiveTrackColor, customColor);
    });

    testWidgets('applies custom thumb color', (tester) async {
      const customColor = Colors.blue;

      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
            thumbColor: customColor,
          ),
        ),
      );

      final sliderTheme = tester.widget<SliderTheme>(find.byType(SliderTheme));
      expect(sliderTheme.data.thumbColor, customColor);
    });

    testWidgets('uses theme colors by default', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
          ),
        ),
      );

      final BuildContext context = tester.element(find.byType(AppSlider));
      final theme = Theme.of(context);
      final sliderTheme = tester.widget<SliderTheme>(find.byType(SliderTheme));

      expect(sliderTheme.data.activeTrackColor, theme.colorScheme.primary);
      expect(sliderTheme.data.thumbColor, theme.colorScheme.primary);
    });
  });

  group('Unit Tests - Accessibility', () {
    testWidgets('has proper semantic labels', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
            label: 'Accessible slider',
          ),
        ),
      );

      // Verify slider renders with label
      expect(find.text('Accessible slider'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('slider is accessible', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50,
            onChanged: (_) {},
            min: 0,
            max: 100,
          ),
        ),
      );

      // Verify slider can be found and interacted with
      expect(find.byType(Slider), findsOneWidget);
      await tester.drag(find.byType(Slider), const Offset(50, 0));
      await tester.pumpAndSettle();
    });
  });

  group('Unit Tests - Value Label', () {
    testWidgets('shows value label for discrete slider', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 5,
            onChanged: (_) {},
            min: 0,
            max: 10,
            divisions: 10,
            type: SliderType.discrete,
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.label, '5');
    });

    testWidgets('shows decimal value label for continuous slider', (tester) async {
      await tester.pumpWidget(
        makeTestableWidget(
          AppSlider(
            value: 50.5,
            onChanged: (_) {},
            min: 0,
            max: 100,
            type: SliderType.continuous,
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.label, '50.5');
    });
  });
}
