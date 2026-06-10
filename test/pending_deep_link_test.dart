import 'package:flutter_test/flutter_test.dart';
import 'package:pgo/utils/post_auth_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('invalid match link remains pending until it is consumed once',
      () async {
    final uri = Uri.parse(
      'https://pgoapp.com/partidos/no-es-uuid',
    );

    await savePendingDeepLink(uri);

    expect(await takePendingDeepLink(), uri);
    expect(await takePendingDeepLink(), isNull);
  });
}
