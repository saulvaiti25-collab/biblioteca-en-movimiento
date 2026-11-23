import 'package:flutter_test/flutter_test.dart';
import 'package:biblioteca_en_movimiento/main.dart';

void main() {
  testWidgets('muestra el acceso a Biblioteca en Movimiento', (tester) async {
    await tester.pumpWidget(const LibraryApp());
    expect(find.text('Biblioteca en Movimiento'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
