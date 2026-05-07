import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:thepastrypath/data/repositories/bakery_repository.dart';
import 'package:thepastrypath/providers/auth_provider.dart';
import 'package:thepastrypath/providers/recommendation_provider.dart';
import 'package:thepastrypath/screens/auth/auth_screen.dart';
import 'package:thepastrypath/widgets/favorite_button.dart';

void main() {
  testWidgets('login form validates email and password', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppAuthProvider(),
        child: const MaterialApp(home: AuthScreen()),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('auth-submit-button')));
    await tester.pump();

    expect(find.text('Enter a valid email.'), findsOneWidget);
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
  });

  testWidgets('animated favorite button toggles icon state', (tester) async {
    var favorite = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => FavoriteButton(
            isFavorite: favorite,
            onTap: () => setState(() => favorite = !favorite),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    await tester.tap(find.byType(FavoriteButton));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  test('recommendation engine ranks favorites and strong scores higher', () {
    final ranked = RecommendationProvider.rankBakeries(
      bakeries: seedBakeries,
      favoriteIds: {'sweet-crumbs'},
      categoryVisits: {'Pastries': 4, 'Coffee': 1},
    );

    expect(ranked.first.category, 'Pastries');
    expect(ranked.take(3).map((bakery) => bakery.id), contains('sweet-crumbs'));
  });
}
