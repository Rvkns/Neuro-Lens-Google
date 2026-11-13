import 'package:flutter_test/flutter_test.dart';
import 'package:neural_lens/main.dart';

void main() {
  testWidgets('Neural Lens Academic Shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NeuralLensApp());
    expect(find.textContaining('NEURAL LENS'), findsWidgets);
  });
}
