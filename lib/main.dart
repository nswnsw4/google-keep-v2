
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const KeepApp());

const keepBlue = Color(0xFFE3F0FF);
const keepBlueText = Color(0xFF1267D9);
const keepGray = Color(0xFF5F6368);
const searchGray = Color(0xFFE9EEF6);

const noteTypes = [
  '텍스트',
  '이미지',
  '음성',
  '그림',
  '체크리스트',
];

const sortOptions = [
  '맞춤(기본값)',
  '만든 날짜',
  '수정된 날짜',
];

String get apiBase =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';

IconData typeIcon(String type) {
  switch (type) {
    case '이미지':
      return Icons.image_outlined;
    case '음성':
      return Icons.mic_none;
    case '그림':
      return Icons.brush_outlined;
    case '체크리스트':
      return Icons.check_box_outlined;
    default:
      return Icons.notes_outlined;
  }
}

Color noteColor(String color) {
  switch (color) {
    case 'yellow':
      return const Color(0xFFFFF2B2);
    case 'blue':
      return const Color(0xFFDDEBFF);
    default:
      return Colors.white;
  }
}

// ============================================================
// DATA MODEL
// ============================================================

class KeepNote {
  const KeepNote({
    required this.id,
    required this.title,
    required this.body,
    required this.types,
    required this.color,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final List<String> types;
  final String color;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory KeepNote.fromJson(Map<String, dynamic> json) {
    return KeepNote(
      id: '${json['id']}',
      title: '${json['title'] ?? ''}',
      body: '${json['body'] ?? ''}',
      types: (json['types'] as List<dynamic>? ?? ['텍스트'])
          .map((e) => e.toString())
          .toList(),
      color: '${json['color'] ?? 'white'}',
      createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updatedAt'] ?? ''}'),
    );
  }
}

Future<List<KeepNote>> fetchNotes() async {
  final results = await Future.wait([
    http.get(Uri.parse('$apiBase/items')).timeout(const Duration(seconds: 8)),
    Future.delayed(const Duration(seconds: 1)),
  ]);
  final response = results[0] as http.Response;

  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}');
  }

  final decoded = jsonDecode(
    utf8.decode(response.bodyBytes),
  ) as List<dynamic>;

  return decoded
      .map(
        (item) => KeepNote.fromJson(
          item as Map<String, dynamic>,
        ),
      )
      .toList();
}

// ============================================================
// APP
// ============================================================

class KeepApp extends StatelessWidget {
  const KeepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Keep v2',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4),
          surface: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<KeepNote>> notesFuture = fetchNotes();

  final searchController = TextEditingController();
  final selectedTypes = <String>{};

  String selectedSort = sortOptions.first;
  bool isGrid = true;
  final Map<String, int> _defaultOrder = {};


  void retry() {
    setState(() {
      notesFuture = fetchNotes();
    });
  }

  void openNote(KeepNote note) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => EditorScreen(note: note),
      ),
    );
  }

  void createNote(String type) {
    openNote(
      KeepNote(
        id: 'new',
        title: '',
        body: '',
        types: [type],
        color: 'white',
      ),
    );
  }

  List<KeepNote> filterNotes(List<KeepNote> notes) {
    final query = searchController.text.trim().toLowerCase();

    final result = notes.where((note) {
      final matchesText =
          query.isEmpty ||
          note.title.toLowerCase().contains(query) ||
          note.body.toLowerCase().contains(query);

      final matchesType =
          selectedTypes.isEmpty ||
          note.types.any(selectedTypes.contains);

      return matchesText && matchesType;
    }).toList();

    // Shuffle once per dataset; retain the same default order while searching.
    if (_defaultOrder.length != notes.length ||
        notes.any((note) => !_defaultOrder.containsKey(note.id))) {
      final ids = notes.map((note) => note.id).toList()..shuffle(Random(42));
      _defaultOrder
        ..clear()
        ..addEntries(ids.asMap().entries.map(
          (entry) => MapEntry(entry.value, entry.key),
        ));
    }

    if (selectedSort == '만든 날짜') {
      result.sort((a, b) =>
          (b.createdAt ?? DateTime(1970))
              .compareTo(a.createdAt ?? DateTime(1970)));
    } else if (selectedSort == '수정된 날짜') {
      result.sort((a, b) =>
          (b.updatedAt ?? DateTime(1970))
              .compareTo(a.updatedAt ?? DateTime(1970)));
    } else {
      result.sort((a, b) =>
          (_defaultOrder[a.id] ?? 0).compareTo(_defaultOrder[b.id] ?? 0));
    }

    return result;
  }

  void openFilterSheet() {
    var tab = 0;
    var draftSort = selectedSort;
    final draftTypes = Set<String>.from(selectedTypes);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF0F5FC),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, update) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _TabButton(
                            label: '정렬 기준',
                            selected: tab == 0,
                            onTap: () => update(() => tab = 0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TabButton(
                            label: '종류',
                            selected: tab == 1,
                            onTap: () => update(() => tab = 1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (tab == 0)
                      for (final option in sortOptions)
                        _FilterOption(
                          label: option,
                          selected: draftSort == option,
                          onTap: () {
                            update(() => draftSort = option);
                          },
                        ),
                    if (tab == 1)
                      for (final type in noteTypes)
                        _FilterOption(
                          label: type,
                          icon: typeIcon(type),
                          selected: draftTypes.contains(type),
                          onTap: () {
                            update(() {
                              if (!draftTypes.add(type)) {
                                draftTypes.remove(type);
                              }
                            });
                          },
                        ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            update(() {
                              if (tab == 0) {
                                draftSort = sortOptions.first;
                              } else {
                                draftTypes.clear();
                              }
                            });
                          },
                          child: const Text('초기화'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              selectedSort = draftSort;
                              selectedTypes
                                ..clear()
                                ..addAll(draftTypes);
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('적용'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildSearchBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: searchGray,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              tooltip: '메뉴',
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '메모 검색',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            tooltip: '목록 보기 변경',
            onPressed: () {
              setState(() => isGrid = !isGrid);
            },
            icon: Icon(
              isGrid
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view,
            ),
          ),
          IconButton(
            tooltip: '정렬 및 종류 필터',
            onPressed: openFilterSheet,
            icon: const Icon(Icons.swap_vert),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF4285F4),
              child: ClipOval(
                child: Image.asset(
                  'assets/profile.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.person,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChips() {
    if (selectedTypes.isEmpty &&
        selectedSort == sortOptions.first) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (selectedSort != sortOptions.first)
            InputChip(
              label: Text(selectedSort),
              backgroundColor: keepBlue,
              onDeleted: () {
                setState(() {
                  selectedSort = sortOptions.first;
                });
              },
            ),
          for (final type in selectedTypes)
            InputChip(
              label: Text(type),
              backgroundColor: keepBlue,
              onDeleted: () {
                setState(() {
                  selectedTypes.remove(type);
                });
              },
            ),
        ],
      ),
    );
  }

  Widget buildBottomBar() {
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          IconButton(
            tooltip: '체크리스트',
            onPressed: () => createNote('체크리스트'),
            icon: const Icon(Icons.check_box_outlined),
          ),
          IconButton(
            tooltip: '그림',
            onPressed: () => createNote('그림'),
            icon: const Icon(Icons.brush_outlined),
          ),
          IconButton(
            tooltip: '음성',
            onPressed: () => createNote('음성'),
            icon: const Icon(Icons.mic_none),
          ),
          IconButton(
            tooltip: '이미지',
            onPressed: () => createNote('이미지'),
            icon: const Icon(Icons.image_outlined),
          ),
          const Spacer(),
          FloatingActionButton(
            heroTag: 'new-note',
            backgroundColor: Colors.white,
            elevation: 2,
            onPressed: () => createNote('텍스트'),
            child: const Icon(
              Icons.add,
              size: 32,
              color: Color(0xFF4285F4),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const KeepDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: buildSearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: buildChips(),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<KeepNote>>(
                future: notesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState !=
                      ConnectionState.done) {
                    return const _LoadingNotesState();
                  }

                  if (snapshot.hasError) {
                    return _CenterMessage(
                      icon: Icons.wifi_off,
                      title: '메모를 불러오지 못했습니다',
                      subtitle: '서버 연결을 확인한 후 다시 시도해 주세요.\nlocalhost:3000/items',
                      button: '다시 시도',
                      onPressed: retry,
                    );
                  }

                  final notes = filterNotes(snapshot.data ?? []);

                  if (notes.isEmpty) {
                    final hasActiveFilters = selectedTypes.isNotEmpty ||
                        searchController.text.trim().isNotEmpty;
                    return _CenterMessage(
                      icon: hasActiveFilters
                          ? Icons.search_off_rounded
                          : Icons.note_add_outlined,
                      title: hasActiveFilters
                          ? '검색 결과가 없습니다'
                          : '아직 메모가 없습니다',
                      subtitle: hasActiveFilters
                          ? '검색어 또는 메모 종류를 변경해 보세요.'
                          : '아래 + 버튼을 눌러 첫 메모를 만들어 보세요.',
                      button: hasActiveFilters ? '검색 및 필터 초기화' : '새 메모',
                      onPressed: () {
                        if (!hasActiveFilters) {
                          createNote('텍스트');
                          return;
                        }
                        setState(() {
                          selectedTypes.clear();
                          selectedSort = sortOptions.first;
                          searchController.clear();
                        });
                      },
                    );
                  }

                  // FIX: Grid cards have bounded dimensions.
                  // No Expanded widgets are used inside NoteCard.
                  if (isGrid) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;

                        final columns = width < 520
                            ? 2
                            : width < 900
                                ? 3
                                : width < 1300
                                    ? 4
                                    : 5;

                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            mainAxisExtent: 230,
                          ),
                          itemCount: notes.length,
                          itemBuilder: (context, index) {
                            return NoteCard(
                              note: notes[index],
                              onTap: () => openNote(notes[index]),
                            );
                          },
                        );
                      },
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NoteCard(
                          note: notes[index],
                          onTap: () => openNote(notes[index]),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(height: 1),
            buildBottomBar(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// ============================================================
// FILTER COMPONENTS
// ============================================================

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected ? keepBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? keepBlueText : keepGray,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? keepBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 20),
                SizedBox(
                  width: 35,
                  child: selected
                      ? const Icon(
                          Icons.check,
                          color: keepBlueText,
                        )
                      : icon == null
                          ? null
                          : Icon(icon, color: keepGray),
                ),
                const SizedBox(width: 15),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17,
                    color: selected ? keepBlueText : keepGray,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NOTE CARD - GRID/LIST SAFE
// ============================================================

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
  });

  final KeepNote note;
  final VoidCallback onTap;

  void showTypes(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('메모 콘텐츠 유형'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: note.types.map((type) {
            return Chip(
              avatar: Icon(typeIcon(type), size: 16),
              label: Text(type),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: noteColor(note.color),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
          color: Color(0xFFDADCE0),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty
                          ? '제목 없음'
                          : note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  ...note.types.take(3).map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(left: 3),
                      child: Icon(
                        typeIcon(type),
                        size: 16,
                        color: keepGray,
                      ),
                    ),
                  ),
                  if (note.types.length > 3)
                    GestureDetector(
                      onTap: () => showTypes(context),
                      onLongPress: () => showTypes(context),
                      child: Text(
                        '+${note.types.length - 3}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                note.body,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY / ERROR STATE
// ============================================================

class _LoadingNotesState extends StatelessWidget {
  const _LoadingNotesState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: keepBlueText,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              '메모를 불러오는 중...',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 7),
            Text(
              '잠시만 기다려 주세요.',
              style: TextStyle(fontSize: 14, color: keepGray),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String button;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: searchGray,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: keepGray),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: keepGray,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: keepBlue,
                  foregroundColor: keepBlueText,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  button,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NAVIGATION DRAWER
// ============================================================

class KeepDrawer extends StatelessWidget {
  const KeepDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(
      IconData icon,
      String title, {
      bool selected = false,
    }) {
      return ListTile(
        leading: Icon(
          icon,
          color: selected ? keepBlueText : keepGray,
        ),
        title: Text(title),
        selected: selected,
        selectedTileColor: keepBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(
            right: Radius.circular(32),
          ),
        ),
        onTap: () => Navigator.pop(context),
      );
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 25, 12, 26),
              child: Text(
                'Google Keep',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            item(
              Icons.lightbulb_outline,
              '메모',
              selected: true,
            ),
            item(Icons.notifications_none, '알림'),
            const Divider(indent: 72),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 18, 0, 12),
              child: Text(
                '라벨',
                style: TextStyle(color: keepGray),
              ),
            ),
            item(Icons.add, '새 라벨 만들기'),
            const Divider(indent: 72),
            item(Icons.archive_outlined, '보관처리된 메모'),
            item(Icons.delete_outline, '휴지통'),
            const Divider(indent: 72),
            item(Icons.settings_outlined, '설정'),
            item(Icons.feedback_outlined, '앱에 관한 의견 보내기'),
            item(Icons.help_outline, '도움말'),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RICH TEXT FORMATTING MODEL
// ============================================================

// Each range remembers which characters are bold, italic,
// or underlined. This allows mixed formatting in one note.

class FormatRange {
  FormatRange({
    required this.start,
    required this.end,
    this.bold = false,
    this.italic = false,
    this.underline = false,
  });

  int start;
  int end;
  bool bold;
  bool italic;
  bool underline;
}

enum FormatAction {
  bold,
  italic,
  underline,
}

// ============================================================
// RICH TEXT CONTROLLER
// ============================================================

class RichNoteController extends TextEditingController {
  RichNoteController({super.text});

  final List<FormatRange> ranges = [];

  String searchTerm = '';
  int activeMatch = 0;

  String _previousText = '';

  void initialize() {
    _previousText = text;
  }

  void setSearch(String term, int active) {
    searchTerm = term.trim();
    activeMatch = active;
    notifyListeners();
  }

  // Update formatting positions after typing or deleting.
  void syncTextChanges() {
    final oldText = _previousText;
    final newText = text;

    if (oldText == newText) return;

    var prefix = 0;

    while (prefix < oldText.length &&
        prefix < newText.length &&
        oldText[prefix] == newText[prefix]) {
      prefix++;
    }

    var suffix = 0;

    while (suffix < oldText.length - prefix &&
        suffix < newText.length - prefix &&
        oldText[oldText.length - 1 - suffix] ==
            newText[newText.length - 1 - suffix]) {
      suffix++;
    }

    final removed = oldText.length - prefix - suffix;
    final inserted = newText.length - prefix - suffix;
    final delta = inserted - removed;

    final editEnd = prefix + removed;

    for (final range in ranges) {
      if (range.end <= prefix) {
        continue;
      }

      if (range.start >= editEnd) {
        range.start += delta;
        range.end += delta;
      } else {
        if (range.start > prefix) {
          range.start = prefix;
        }

        range.end = (range.end + delta)
            .clamp(range.start, newText.length);
      }
    }

    ranges.removeWhere((range) => range.start >= range.end);

    _previousText = newText;
  }

  bool hasFormat(int index, FormatAction action) {
    for (final range in ranges) {
      if (index >= range.start && index < range.end) {
        switch (action) {
          case FormatAction.bold:
            if (range.bold) return true;
            break;
          case FormatAction.italic:
            if (range.italic) return true;
            break;
          case FormatAction.underline:
            if (range.underline) return true;
            break;
        }
      }
    }

    return false;
  }

  // Format only the selected characters.
  void applyFormat(
    int start,
    int end,
    FormatAction action,
  ) {
    if (start < 0 || end > text.length || start >= end) {
      return;
    }

    // If the whole selection already has this format,
    // tapping again removes it.
    var allFormatted = true;

    for (var i = start; i < end; i++) {
      if (!hasFormat(i, action)) {
        allFormatted = false;
        break;
      }
    }

    final newValue = !allFormatted;

    // Rebuild formatting into non-overlapping runs.
    final newRanges = <FormatRange>[];

    for (var i = 0; i < text.length; i++) {
      var b = hasFormat(i, FormatAction.bold);
      var it = hasFormat(i, FormatAction.italic);
      var u = hasFormat(i, FormatAction.underline);

      if (i >= start && i < end) {
        switch (action) {
          case FormatAction.bold:
            b = newValue;
            break;
          case FormatAction.italic:
            it = newValue;
            break;
          case FormatAction.underline:
            u = newValue;
            break;
        }
      }

      if (!b && !it && !u) continue;

      if (newRanges.isNotEmpty) {
        final last = newRanges.last;

        if (last.end == i &&
            last.bold == b &&
            last.italic == it &&
            last.underline == u) {
          last.end = i + 1;
          continue;
        }
      }

      newRanges.add(
        FormatRange(
          start: i,
          end: i + 1,
          bold: b,
          italic: it,
          underline: u,
        ),
      );
    }

    ranges
      ..clear()
      ..addAll(newRanges);

    notifyListeners();
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final source = text;

    if (source.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final term = searchTerm.toLowerCase();
    final lower = source.toLowerCase();

    final highlighted = List<bool>.filled(source.length, false);
    final active = List<bool>.filled(source.length, false);

    if (term.isNotEmpty) {
      var position = 0;
      var matchIndex = 0;

      while (position < source.length) {
        final index = lower.indexOf(term, position);

        if (index < 0) break;

        for (var i = index; i < index + term.length; i++) {
          highlighted[i] = true;

          if (matchIndex == activeMatch) {
            active[i] = true;
          }
        }

        position = index + term.length;
        matchIndex++;
      }
    }

    final spans = <InlineSpan>[];

    // Each run has the same formatting and highlight state.
    var runStart = 0;

    TextStyle styleAt(int index) {
      final b = hasFormat(index, FormatAction.bold);
      final it = hasFormat(index, FormatAction.italic);
      final u = hasFormat(index, FormatAction.underline);

      return TextStyle(
        fontWeight: b ? FontWeight.bold : FontWeight.normal,
        fontStyle: it ? FontStyle.italic : FontStyle.normal,
        decoration:
            u ? TextDecoration.underline : TextDecoration.none,
        backgroundColor: active[index]
            ? const Color(0xFFB6D9FF)
            : highlighted[index]
                ? keepBlue
                : null,
      );
    }

    TextStyle currentStyle = styleAt(0);

    for (var i = 1; i <= source.length; i++) {
      final nextStyle =
          i < source.length ? styleAt(i) : null;

      final sameStyle = nextStyle != null &&
          nextStyle.fontWeight == currentStyle.fontWeight &&
          nextStyle.fontStyle == currentStyle.fontStyle &&
          nextStyle.decoration == currentStyle.decoration &&
          nextStyle.backgroundColor ==
              currentStyle.backgroundColor;

      if (sameStyle) continue;

      spans.add(
        TextSpan(
          text: source.substring(runStart, i),
          style: currentStyle,
        ),
      );

      runStart = i;

      if (nextStyle != null) {
        currentStyle = nextStyle;
      }
    }

    return TextSpan(
      style: style,
      children: spans,
    );
  }
}

// ============================================================
// NOTE EDITOR
// ============================================================

class EditorScreen extends StatefulWidget {
  const EditorScreen({
    super.key,
    required this.note,
  });

  final KeepNote note;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController titleController;
  late final RichNoteController bodyController;

  final queryController = TextEditingController();
  final bodyFocus = FocusNode();

  bool searching = false;
  bool formatting = false;
  bool pinned = false;

  double fontSize = 17;
  TextAlign alignment = TextAlign.left;

  int currentMatch = 0;

  // Remember the last actual text selection.
  TextSelection? savedSelection;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(
      text: widget.note.title,
    );

    bodyController = RichNoteController(
      text: widget.note.body,
    );

    bodyController.initialize();

    bodyController.addListener(trackSelection);
    queryController.addListener(updateSearch);
  }

  void trackSelection() {
    final selection = bodyController.selection;

    if (selection.isValid && !selection.isCollapsed) {
      savedSelection = selection;
    }
  }

  // ==========================================================
  // SELECTED-TEXT FORMATTING
  // ==========================================================

  void formatSelection(FormatAction action) {
    final selection = bodyController.selection;

    final usableSelection =
        selection.isValid && !selection.isCollapsed
            ? selection
            : savedSelection;

    if (usableSelection == null ||
        !usableSelection.isValid ||
        usableSelection.isCollapsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 서식을 적용할 텍스트를 선택하세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final start = usableSelection.start;
    final end = usableSelection.end;

    bodyController.applyFormat(
      start,
      end,
      action,
    );

    bodyController.selection = usableSelection;

    setState(() {});
  }

  // ==========================================================
  // SEARCH
  // ==========================================================

  List<int> get matches {
    final term = queryController.text.trim().toLowerCase();

    if (term.isEmpty) return [];

    final source = bodyController.text.toLowerCase();
    final found = <int>[];

    var from = 0;

    while (from < source.length) {
      final index = source.indexOf(term, from);

      if (index < 0) break;

      found.add(index);
      from = index + term.length;
    }

    return found;
  }

  void updateSearch() {
    if (!mounted) return;

    setState(() => currentMatch = 0);

    bodyController.setSearch(
      searching ? queryController.text : '',
      currentMatch,
    );
  }

  void toggleSearch() {
    setState(() {
      searching = !searching;
      currentMatch = 0;

      if (!searching) {
        queryController.clear();
      }
    });

    bodyController.setSearch(
      searching ? queryController.text : '',
      currentMatch,
    );
  }

  void moveMatch(int direction) {
    final found = matches;

    if (found.isEmpty) return;

    setState(() {
      currentMatch =
          (currentMatch + direction + found.length) %
              found.length;
    });

    bodyController.setSearch(
      queryController.text,
      currentMatch,
    );

    final start = found[currentMatch];
    final end = start + queryController.text.trim().length;

    bodyController.selection = TextSelection(
      baseOffset: start,
      extentOffset: end,
    );

    bodyFocus.requestFocus();
  }

  // ==========================================================
  // ICON HELPER
  // ==========================================================

  Widget editorIcon(
    IconData icon, {
    required String tooltip,
    VoidCallback? onPressed,
    Color color = keepGray,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed ?? () {},
      icon: Icon(
        icon,
        color: color,
        size: 25,
      ),
    );
  }

  // ==========================================================
  // TOP BAR
  // ==========================================================

  Widget buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFF9FAFC),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: '뒤로',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF25282A),
              ),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                editorIcon(
                  pinned
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                  tooltip: '고정',
                  onPressed: () {
                    setState(() => pinned = !pinned);
                  },
                ),
                editorIcon(
                  Icons.notification_add_outlined,
                  tooltip: '알림',
                ),
                editorIcon(
                  Icons.archive_outlined,
                  tooltip: '보관',
                ),
                editorIcon(
                  Icons.search,
                  tooltip: '메모 내부 검색',
                  color: searching ? keepBlueText : keepGray,
                  onPressed: toggleSearch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SEARCH CONTROLS
  // ==========================================================

  Widget buildSearchControls() {
    final found = matches;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFDADCE0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: queryController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '메모 내부 검색',
                      hintStyle: TextStyle(
                        color: Color(0xFF80868B),
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                if (queryController.text.isNotEmpty)
                  IconButton(
                    tooltip: '검색어 지우기',
                    onPressed: queryController.clear,
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: keepGray,
                    ),
                  ),
                TextButton(
                  onPressed: toggleSearch,
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Text(
                queryController.text.trim().isEmpty
                    ? '검색어를 입력하세요'
                    : found.isEmpty
                        ? '검색 결과 없음'
                        : '${currentMatch + 1} / ${found.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF303134),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: '이전 결과',
                onPressed: found.isEmpty
                    ? null
                    : () => moveMatch(-1),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                tooltip: '다음 결과',
                onPressed: found.isEmpty
                    ? null
                    : () => moveMatch(1),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // FORMATTING BAR
  // ==========================================================

void toggleBulletPoints() {
  final text = bodyController.text;

  if (text.isEmpty) {
    bodyController.value = const TextEditingValue(
      text: '• ',
      selection: TextSelection.collapsed(offset: 2),
    );
    bodyController.syncTextChanges();
    return;
  }

  final selection = bodyController.selection;

  if (!selection.isValid) return;

  // Find the beginning of the line containing the cursor
  // or the start of the selected text.
  final start = selection.start;
  final end = selection.end;

  final lineStart = text.lastIndexOf('\n', start - 1) + 1;

  // If a selection ends exactly at the start of the next line,
  // don't modify that next line.
  final effectiveEnd = end > start && end > 0 && text[end - 1] == '\n'
      ? end - 1
      : end;

  final nextNewline = text.indexOf('\n', effectiveEnd);
  final lineEnd = nextNewline == -1 ? text.length : nextNewline;

  final selectedBlock = text.substring(lineStart, lineEnd);
  final lines = selectedBlock.split('\n');

  // Remove bullets if every nonempty selected line already has one.
  final nonEmptyLines = lines.where((line) => line.isNotEmpty).toList();

  final removeBullets = nonEmptyLines.isNotEmpty &&
      nonEmptyLines.every((line) => line.startsWith('• '));

  final updatedLines = lines.map((line) {
    if (removeBullets) {
      return line.startsWith('• ') ? line.substring(2) : line;
    }

    return line.startsWith('• ') ? line : '• $line';
  }).toList();

  final updatedBlock = updatedLines.join('\n');

  final updatedText = text.replaceRange(
    lineStart,
    lineEnd,
    updatedBlock,
  );

  final newSelection = TextSelection(
    baseOffset: lineStart,
    extentOffset: lineStart + updatedBlock.length,
  );

  bodyController.value = TextEditingValue(
    text: updatedText,
    selection: newSelection,
  );

  // Keep formatting ranges synchronized with the new text.
  bodyController.syncTextChanges();

  setState(() {});
}

  Widget buildFormattingBar() {
    return Container(
      height: 55,
      color: const Color(0xFFF3F6FB),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          IconButton(
            tooltip: '선택한 텍스트 굵게',
            onPressed: () {
              formatSelection(FormatAction.bold);
            },
            icon: const Icon(Icons.format_bold),
          ),
          IconButton(
            tooltip: '선택한 텍스트 기울임',
            onPressed: () {
              formatSelection(FormatAction.italic);
            },
            icon: const Icon(Icons.format_italic),
          ),
          IconButton(
            tooltip: '선택한 텍스트 밑줄',
            onPressed: () {
              formatSelection(FormatAction.underline);
            },
            icon: const Icon(Icons.format_underline),
          ),
          const VerticalDivider(),
          IconButton(
            tooltip: '글자 크기',
            onPressed: () {
              setState(() {
                fontSize = fontSize == 17 ? 21 : 17;
              });
            },
            icon: const Icon(Icons.format_size),
          ),
          IconButton(
            tooltip: '정렬',
            onPressed: () {
              setState(() {
                alignment = alignment == TextAlign.left
                    ? TextAlign.center
                    : TextAlign.left;
              });
            },
            icon: const Icon(Icons.format_align_left),
          ),
          IconButton(
            tooltip: '선택한 줄에 글머리 기호 추가/제거',
            onPressed: toggleBulletPoints,
            icon: const Icon(Icons.format_list_bulleted),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // THREE-DOT MENU
  // ==========================================================

  void showMoreMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF7F9FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(38),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 0, 0, 18),
                    child: Text(
                      '메모 미리보기 · 변경 사항은 저장되지 않습니다',
                      style: TextStyle(
                        color: keepGray,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                for (final entry in [
                  (Icons.delete_outline, '삭제'),
                  (Icons.copy_outlined, '사본 만들기'),
                  (Icons.share_outlined, '보내기'),
                  (Icons.person_add_alt_outlined, '공동작업자'),
                  (Icons.label_outline, '라벨'),
                  (Icons.feedback_outlined, '앱에 관한 의견 보내기'),
                ])
                  ListTile(
                    leading: Icon(entry.$1, color: keepGray),
                    title: Text(entry.$2),
                    onTap: () => Navigator.pop(sheetContext),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // EDITOR BOTTOM BAR
  // ==========================================================

  Widget buildBottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          height: 70,
          child: Row(
            children: [
              editorIcon(
                Icons.add_box_outlined,
                tooltip: '추가',
              ),
              editorIcon(
                Icons.palette_outlined,
                tooltip: '색상',
              ),
              editorIcon(
                Icons.text_format,
                tooltip: '서식',
                color: formatting ? keepBlueText : keepGray,
                onPressed: () {
                  setState(() => formatting = !formatting);
                },
              ),
              const Spacer(),
              editorIcon(
                Icons.more_vert,
                tooltip: '더보기',
                onPressed: showMoreMenu,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // EDITOR BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            buildTopBar(),
            if (searching) buildSearchControls(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  22,
                  18,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      maxLines: null,
                      style: const TextStyle(
                        fontSize: 27,
                        color: Color(0xFF202124),
                      ),
                      decoration: const InputDecoration(
                        hintText: '제목',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: bodyController,
                      focusNode: bodyFocus,
                      minLines: 14,
                      maxLines: null,
                      textAlign: alignment,
                      onChanged: (_) {
                        bodyController.syncTextChanges();
                        setState(() {});
                      },
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 1.5,
                        color: const Color(0xFF303134),
                      ),
                      decoration: const InputDecoration(
                        hintText: '메모 작성…',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (formatting) buildFormattingBar(),
            buildBottomBar(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    bodyController.removeListener(trackSelection);
    queryController.removeListener(updateSearch);

    titleController.dispose();
    bodyController.dispose();
    queryController.dispose();
    bodyFocus.dispose();

    super.dispose();
  }
}
