// 화면 A: 목록 (GET /items) — TODO: 기획 문서의 화면 이름으로 바꾼다 (예: "오늘의 ○○")
//
// ┌──────── 디자인 가이드 대응표: A 목록 ───────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                    │ 비즈니스 명칭(한글) │ 원칙(P번호)   │
// │ A-1  │ AppBar                            │ TODO: ○○ 제목줄     │ P04 일관성(예)│
// │ A-2  │ ListView + Card (ItemCard)        │ TODO: ○○ 카드 목록  │ P08 미니멀(예)│
// │ A-3  │ GridView (넓은 화면 ≥600dp)        │ TODO: ○○ 카드 격자  │ 적응형        │
// │ A-4  │ LoadingView                       │ 불러오는 중 표시    │ P01 가시성    │
// │ A-5  │ ErrorView + FilledButton          │ 오류 안내·다시 시도 │ P09 오류 복구 │
// │ A-6  │ EmptyView                         │ 빈 목록 안내        │ P01 가시성    │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환: A → B 는 쌓기(Navigator.push).  적응형: LayoutBuilder 600dp 분기 1곳(A-2 ↔ A-3).
// P번호 = 닐슨 원칙 번호 (docs/디자인가이드.md 2장). 그 원칙을 보여 주는 위젯 줄 끝에 `// A-4 P01` 처럼 단다.
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'b_detail_screen.dart';

/// 이 너비 이상이면 넓은 화면 배치 (Material 3 window size class: medium ≥ 600dp)
const wideBreakpoint = 600.0;

class ListScreen extends StatefulWidget {
  const ListScreen({
    super.key,
    this.load = fetchItems,
    this.loadNotes = fetchNotes,
  });

  /// 데이터를 가져오는 함수 — 앱은 기본값(GET), 테스트는 가짜 함수를 넣는다.
  final ItemsLoader load;
  final NotesLoader loadNotes;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late Future<List<Item>> _future = widget.load();

  // STATE: 검색어·필터(예: 태그 선택) → A-2 목록 — v2 이후 상태관리로 구현 (지금은 표시만)

  // 다시 시도 = Future만 새로 만드는 setState (화면 안 표시 변화 — 허용)
  // (주의) `setState(() => _future = …)`처럼 화살표로 쓰면 Future를 돌려줘 디버그 오류가 난다 → 중괄호로 쓴다.
  void _retry() {
    setState(() {
      _future = widget.load();
    });
  }

  void _open(Item item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DetailScreen(item: item, loadNotes: widget.loadNotes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mid Project Template')), // A-1 TODO: 화면 A 제목으로 바꾼다
      body: FutureBuilder<List<Item>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const LoadingView(label: '목록을 불러오는 중…'); // A-4 P01
          }
          if (snap.hasError) {
            return ErrorView(
              title: '목록을 불러오지 못했습니다.',
              message: '${snap.error}',
              onRetry: _retry,
            ); // A-5 P09
          }
          final items = snap.data ?? const <Item>[];
          if (items.isEmpty) {
            return const EmptyView(message: '아직 등록된 항목이 없습니다.'); // A-6 P01
          }
          return LayoutBuilder(
            // 적응형: 기기 종류가 아니라 "이 영역의 너비"로 나눈다
            builder: (context, constraints) {
              if (constraints.maxWidth >= wideBreakpoint) {
                return GridView.builder(
                  // A-3 넓은 화면: 카드 격자
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 260,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => ItemCard(
                    items[i],
                    vertical: true,
                    onTap: () => _open(items[i]),
                  ),
                );
              }
              return ListView.builder(
                // A-2 폰: 카드 목록
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                itemBuilder: (context, i) =>
                    ItemCard(items[i], onTap: () => _open(items[i])),
              );
            },
          );
        },
      ),
    );
  }
}

/// 항목 카드 한 장 — TODO: 비즈니스 명칭으로 이름을 바꾼다 (예: ProductCard)
class ItemCard extends StatelessWidget {
  const ItemCard(this.item, {super.key, this.onTap, this.vertical = false});

  final Item item;
  final VoidCallback? onTap;

  /// true: 넓은 화면 격자용(사진 위, 글 아래) · false: 폰 목록용(사진 왼쪽)
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(item.title, style: text.titleMedium, maxLines: 1),
        const SizedBox(height: 2),
        Text(item.subtitle, style: text.bodySmall, maxLines: 2),
      ],
    );
    return Card(
      margin: vertical
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: NetImage(item.image)),
                  Padding(padding: const EdgeInsets.all(12), child: info),
                ],
              )
            : Row(
                children: [
                  NetImage(item.image, width: 96, height: 80),
                  const SizedBox(width: 12),
                  Expanded(child: info),
                  const Icon(Icons.chevron_right),
                  const SizedBox(width: 8),
                ],
              ),
      ),
    );
  }
}
