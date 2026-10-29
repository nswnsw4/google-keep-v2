// 화면 C: 결과(임의) — 덮기(modal) 예시 · TODO: 기획 문서의 화면 이름으로 바꾼다
//
// ┌──────── 디자인 가이드 대응표: C 결과(임의) ─────────────────────────────────┐
// │ 번호 │ Flutter 위젯명                   │ 비즈니스 명칭(한글)  │ 원칙(P번호)   │
// │ C-1  │ showModalBottomSheet + 손잡이    │ TODO: 결과 시트      │ P03 통제·자유 │
// │ C-2  │ Text(bodyMedium)                 │ TODO: 기준 안내 문구 │ P01 가시성    │
// │ C-3  │ ListTile × 3                     │ TODO: 결과 목록      │ P06 재인(예)  │
// │ C-4  │ Text(bodySmall, 회색)            │ 예시 결과 고지       │ P10 도움말    │
// └────────────────────────────────────────────────────────────────────────────┘
//
// ⚠ 실제 계산·추천·검색 로직 없음 (안내 5장: "실제 비즈니스 로직"은 감점).
//   어떤 항목에서 열어도 아래 _presetResults(미리 정한 값)를 그대로 보여 준다.
//   진짜 기능은 기획 문서의 "AI 활용 기회"로만 설명한다.
import 'package:flutter/material.dart';

import '../models.dart';

/// 미리 정한(하드코딩) 결과 — 계산하지 않는다. TODO: 내 앱에 맞는 예시 문구로 바꾼다.
const _presetResults = [
  (title: '예시 결과 1', reason: 'TODO: 이 결과를 보여 주는 이유'),
  (title: '예시 결과 2', reason: 'TODO: 이 결과를 보여 주는 이유'),
  (title: '예시 결과 3', reason: 'TODO: 이 결과를 보여 주는 이유'),
];

class ResultSheet extends StatelessWidget {
  const ResultSheet({super.key, required this.baseItem});

  final Item baseItem;

  /// 덮기(modal): 지금 화면 위에 잠깐 띄우고 닫는다.
  static Future<void> show(BuildContext context, Item item) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true, // C-1
      isScrollControlled: true,
      builder: (_) => ResultSheet(baseItem: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('결과', style: text.titleLarge),
            const SizedBox(height: 4),
            Text("'${baseItem.title}' 기준 결과", style: text.bodyMedium), // C-2
            const SizedBox(height: 8),
            for (final (i, r) in _presetResults.indexed) // C-3
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(r.title),
                subtitle: Text(r.reason),
              ),
            const SizedBox(height: 8),
            Text(
              '※ 예시 결과입니다. 실제 기능은 없습니다.',
              style: text.bodySmall?.copyWith(color: Colors.grey),
            ), // C-4 P10
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('닫기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
