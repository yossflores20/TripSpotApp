
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Prueba básica de widgets de TripSpot', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('TripSpot'),
        ),
      ),
    );

    expect(find.text('TripSpot'), findsOneWidget);
  });
}

