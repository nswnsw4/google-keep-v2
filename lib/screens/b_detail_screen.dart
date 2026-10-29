// 화면 B: 상세 — TODO: 기획 문서의 화면 이름으로 바꾼다 (예: "○○ 상세")
//
// ┌──────── 디자인 가이드 대응표: B 상세 ───────────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                  │ 비즈니스 명칭(한글)  │ 원칙(P번호)    │
// │ B-1  │ AppBar + BackButton             │ TODO: 상세 제목줄    │ P03 통제·자유  │
// │ B-2  │ TabBar + TabBarView             │ TODO: 정보|메모 탭   │ P06 재인(예)   │
// │ B-3  │ NetImage + Text(titleLarge)     │ TODO: 대표 사진·이름 │ P02 실세계(예) │
// │ B-4  │ Wrap(Chip …)                    │ TODO: 태그 칩        │ P08 미니멀(예) │
// │ B-5  │ OutlinedButton → SnackBar       │ TODO: 저장 버튼(가짜)│ STATE 표시만   │
// │ B-6  │ FilledButton → 모달 시트        │ TODO: 결과 보기 버튼 │ P07 효율성(예) │
// │ B-7  │ FutureBuilder(GET /notes)       │ TODO: 메모 목록      │ P01 · P09      │
// └────────────────────────────────────────────────────────────────────────────┘
// 전환: A → B 쌓기(push) · B 안에서 옆으로(tab) · B → C 덮기(modal)
import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';
import 'c_result_sheet.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.item,
    this.loadNotes = fetchNotes,
  });

  final Item item;
  final NotesLoader loadNotes;

  @override
  Widget build(BuildContext context) {
    // 옆으로(tab) 예시: DefaultTabController가 탭 선택을 화면 안에서만 처리한다 (허용)
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(item.title), // B-1 (뒤로 버튼 자동)
          bottom: const TabBar(
            // B-2
            tabs: [
              Tab(text: '정보'), // TODO: 탭 이름 = 비즈니스 명칭
              Tab(text: '메모'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _InfoTab(item: item),
            _NotesTab(itemId: item.id, load: loadNotes),
          ],
        ),
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(aspectRatio: 16 / 9, child: NetImage(item.image)),
        ), // B-3
        const SizedBox(height: 16),
        Text(item.title, style: text.titleLarge), // B-3
        const SizedBox(height: 4),
        Text(item.subtitle, style: text.bodyMedium),
        const SizedBox(height: 12),
        if (item.tags.isNotEmpty)
          Wrap(
            // B-4
            spacing: 6,
            runSpacing: 6,
            children: [for (final t in item.tags) Chip(label: Text(t))],
          ),
        const SizedBox(height: 24),
        // STATE: 저장(즐겨찾기) 여부 → B-5 버튼 모양, A-2 카드 표시 — v2 이후 상태관리로 구현 (지금은 표시만)
        //   실제로 저장하지 않는다(영구 저장은 감점). 누르면 SnackBar로 "보이기만" 한다.
        OutlinedButton.icon(
          // B-5
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('예시 화면입니다 — 실제로 저장하지 않습니다.')),
          ),
          icon: const Icon(Icons.bookmark_border),
          label: const Text('저장 (예시)'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          // B-6 P07 — 덮기(modal) 예시
          onPressed: () => ResultSheet.show(context, item),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('결과 보기'),
        ),
      ],
    );
  }
}

/// '메모' 탭 — 두 번째 GET 예시 (GET /notes?itemId=…)
class _NotesTab extends StatefulWidget {
  const _NotesTab({required this.itemId, required this.load});

  final int itemId;
  final NotesLoader load;

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  late Future<List<Note>> _future = widget.load(widget.itemId);

  void _retry() {
    setState(() {
      _future = widget.load(widget.itemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Note>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const LoadingView(label: '메모를 불러오는 중…'); // B-7 P01
        }
        if (snap.hasError) {
          return ErrorView(
            title: '메모를 불러오지 못했습니다.',
            message: '${snap.error}',
            onRetry: _retry,
          ); // B-7 P09
        }
        final notes = snap.data ?? const <Note>[];
        if (notes.isEmpty) {
          return const EmptyView(message: '아직 메모가 없습니다.'); // B-7 P01
        }
        return ListView.separated(
          // B-7
          padding: const EdgeInsets.all(8),
          itemCount: notes.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) => ListTile(
            leading: const Icon(Icons.notes_outlined),
            title: Text(notes[i].text),
            subtitle: Text(notes[i].date),
          ),
        );
      },
    );
  }
}
