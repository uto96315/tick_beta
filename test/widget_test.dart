import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tick/domain/records.dart';
import 'package:tick/domain/segments.dart';
import 'package:tick/ui/visuals.dart';

void main() {
  testWidgets('finished chunks show a check on the tile board', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SegmentBoard(
            views: [
              SegmentView(done: true, current: false, fraction: 1),
              SegmentView(done: false, current: true, fraction: 0.4),
            ],
            visual: TimerVisual.tiles,
            showCharacter: false,
            progress: 0.5,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
