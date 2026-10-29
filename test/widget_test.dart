// 3상태(로딩·오류·빈) + 화면 흐름(push · tab · modal) + 적응형(600dp) 위젯 테스트.
// 네트워크를 쓰지 않도록 ListScreen에 가짜 loader를 넣는다 → json-server 없이 `flutter test`가 돈다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mid_project_template/api.dart';
import 'package:mid_project_template/models.dart';
import 'package:mid_project_template/screens/a_list_screen.dart';

const _items = [
  Item(id: 1, title: '항목 1', subtitle: '설명 1', image: '', tags: ['태그']),
  Item(id: 2, title: '항목 2', subtitle: '설명 2', image: ''),
];

Future<List<Note>> _noNotes(int _) async => const [];

Widget _app(ItemsLoader load) => MaterialApp(
  home: ListScreen(load: load, loadNotes: _noNotes),
);

void _setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('3상태: 로딩 → 오류 → 다시 시도 → 성공', (tester) async {
    _setSize(tester, const Size(400, 800));

    // 로딩 → 오류
    final first = Completer<List<Item>>();
    var calls = 0;
    await tester.pumpWidget(
      _app(() => ++calls == 1 ? first.future : Future.value(_items)),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('목록을 불러오는 중…'), findsOneWidget);

    first.completeError(Exception('테스트 오류'));
    await tester.pumpAndSettle();
    expect(find.text('목록을 불러오지 못했습니다.'), findsOneWidget);

    // 다시 시도 → 성공
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('항목 1'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('3상태: 빈 상태', (tester) async {
    await tester.pumpWidget(_app(() async => const []));
    await tester.pumpAndSettle();
    expect(find.text('아직 등록된 항목이 없습니다.'), findsOneWidget);
  });

  testWidgets('흐름: A 목록 → push B 상세 → tab 메모 → modal C 결과', (tester) async {
    _setSize(tester, const Size(400, 800));
    await tester.pumpWidget(_app(() async => _items));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsOneWidget); // 폰: 목록
    expect(find.byType(GridView), findsNothing);

    await tester.tap(find.text('항목 1'));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget); // push

    await tester.tap(find.text('결과 보기'));
    await tester.pumpAndSettle();
    expect(find.textContaining('실제 기능은 없습니다'), findsOneWidget); // modal
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('메모'));
    await tester.pumpAndSettle();
    expect(find.text('아직 메모가 없습니다.'), findsOneWidget); // tab + 빈 상태
  });

  testWidgets('적응형: 600dp 이상이면 격자', (tester) async {
    _setSize(tester, const Size(1024, 768));
    await tester.pumpWidget(_app(() async => _items));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
  });
}
