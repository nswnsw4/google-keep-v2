# Mid Project Template (TODO: 내 앱 이름 v2) — GAI3008 중간프로젝트 저장소 (1인 1팀)

## 앱 소개

> 앱스토어 상품 페이지처럼 채웁니다. 칸 이름과 순서는 발표 자료의 "앱 소개" 장과 같습니다 — 바꾸지 않습니다.

### 앱 이름
TODO: 앱 이름 v2

### 부제
TODO: 한 줄 (예: "○○를 3번 안에 끝내는 ○○ 앱")

### 카테고리
TODO: 스토어 카테고리 (예: 음식 및 음료 · 교육 · 생산성)

### 대상 사용자 / 사용 상황
- 대상 사용자: TODO (퍼소나 한 줄 — 사업 요약과 같게)
- 사용 상황: TODO (언제 · 어디서 · 어떤 기기로)

### 스크린샷
이미지는 `docs/screenshots/`에 넣고 아래 링크의 파일 이름만 맞춥니다. 3~5칸, 왼쪽부터 v1(현행) → v2.

| v1 현행 | v2 화면 A | v2 화면 B | v2 화면 C | v2 넓은 화면 |
|---|---|---|---|---|
| ![v1 현행](docs/screenshots/01_v1_current.png) | ![v2 A](docs/screenshots/02_v2_a.png) | ![v2 B](docs/screenshots/03_v2_b.png) | ![v2 C](docs/screenshots/04_v2_c.png) | ![v2 넓은 화면](docs/screenshots/05_v2_wide.png) |
| TODO: 캡션 | TODO: 캡션 | TODO: 캡션 | TODO: 캡션 | TODO: 캡션 |

### 설명
1. TODO: 이 앱이 무엇을 하는가
2. TODO: v2가 해결하는 문제 (리뷰·저니 근거)
3. TODO: v2의 핵심 가치

### 새로운 기능
v2에서 바뀐 것 3개 — 원칙 카드(`docs/원칙카드.md`)의 P번호와 연결합니다.

| P번호 | 바뀐 것 (화면 · 요소 번호) | 근거 (리뷰 · 원칙) |
|---|---|---|
| P__ | TODO | TODO |
| P__ | TODO | TODO |
| P__ | TODO | TODO |

### 평가 및 리뷰
| 항목 | 내용 |
|---|---|
| 현행 별점 | TODO: ★ _._ (App Store / Google Play) |
| 리뷰 수 | TODO: ____개 |
| 대표 리뷰 | TODO: "원문 인용" — ★_ · YYYY-MM-DD (**작성자 이름 지움**) |
| 출처 | TODO: 스토어 링크 · 확인한 날짜 |

---

## 작성자 · 제출 정보

| 칸 | 내용 |
|---|---|
| 현행 앱 | TODO: 실제 앱 이름 (스토어 링크) |
| v2 한 문장 | TODO: v2의 핵심 가치 한 줄 |
| 작성자 | TODO: 이름(또는 이니셜) · 1인 1팀 (각자 제출) |
| 데모 | TODO: 데모 영상 1분 링크(`docs/영상/demo_1min.mp4`) 또는 배포 URL — **제출물 ①에 필수** |
| AI 사용 | 규칙 `AGENTS.md` · 기록 `docs/prompt-log.md` · 셀프 논증 기록 `docs/셀프논증.md` · 기획 확정 태그 `v1-plan` |

> 이 저장소는 **UI만 구현**합니다(중간고사 안내문 5장). 보이기는 다 동작하는 것처럼, 실제 동작(저장·로그인·결제·실제 계산)은 없습니다.
> 템플릿 그대로는 "화면 A 목록 → 화면 B 상세 → 화면 C 결과(임의)" 빈칸 구조입니다. `TODO`를 검색해 내 앱으로 채웁니다: `grep -rn "TODO" lib docs README.md`

---

## 0. 처음 받았을 때: 폴더 이름 · 앱 이름 바꾸기

1. **폴더(저장소) 이름**: `mid-project-template` → `<영문 앱 이름>-v2` (예: `mealapp-v2`). GitHub 저장소 이름도 같게.
   - ⚠ **경로 전체를 영문·숫자·하이픈으로** 둡니다. 경로에 한글이 한 글자라도 있으면 `flutter analyze`(Flutter 3.44)가 analysis server 오류로 멈추는 것을 확인했습니다(`dart analyze`는 됨). 바탕화면·문서 폴더 이름이 한글이면 `C:\dev\` · `~/dev/` 같은 곳으로 옮깁니다.
2. **앱 이름(화면에 보이는 이름)** — 아래만 바꾸면 됩니다:
   - `lib/main.dart` — `MaterialApp(title: …)`, 각 화면 `AppBar` 제목
   - Android: `android/app/src/main/AndroidManifest.xml`의 `android:label`
   - iOS: `ios/Runner/Info.plist`의 `CFBundleDisplayName`
   - 웹: `web/index.html`의 `<title>`, `web/manifest.json`의 `name`·`short_name`
3. **패키지 이름 `mid_project_template`는 그대로 두는 것을 권장**합니다(바꾸면 `pubspec.yaml`의 `name`과 `test/`의 `import 'package:mid_project_template/…'`를 모두 고쳐야 함). 조직 ID는 `kr.ac.yonsei.gai3008`.

## 1. 실행 방법 — 터미널 2개

준비물: Flutter(Dart SDK ^3.10), Node.js 18 이상.

**터미널 1 — 목업 서버(json-server)**

```bash
cd mock_server
npm install && npm start          # http://localhost:3000  (npm run mock 도 같음)
curl http://localhost:3000/items  # 확인: JSON 배열이 나오면 성공
```

**터미널 2 — 앱**

```bash
flutter pub get && flutter run    # 저장소 루트(pubspec.yaml 있는 곳)에서
flutter run -d chrome             # 웹으로 볼 때
```

| 실행 대상 | 앱이 부르는 주소 | 따로 할 일 |
|---|---|---|
| Chrome · macOS · Windows · iOS 시뮬레이터 | `http://localhost:3000` | 없음 |
| **Android 에뮬레이터** | **`http://10.0.2.2:3000`** | 없음 — `lib/api.dart`가 Android면 자동으로 10.0.2.2를 씀 |
| 실기기(같은 Wi-Fi) | PC IP | `flutter run --dart-define=API_BASE=http://192.168.0.10:3000` |
| Vercel 배포(가산) | 배포 주소 | `--dart-define=API_BASE=https://<프로젝트>.vercel.app/api` — `mock_server/README.md` 5장 |

- 서버가 꺼져 있으면 앱은 **오류 화면 + "다시 시도"**를 보여 줍니다(서버를 켜고 다시 시도 누르면 목록이 뜸).
- 서버 설정·`db.json` 바꾸는 법·CORS: `mock_server/README.md`.

### 상태 화면 시연 — `DEMO_STATE` (발표·영상용)

```bash
flutter run --dart-define=DEMO_STATE=loading   # 3초 로딩 (slow 도 같음)
flutter run --dart-define=DEMO_STATE=error     # 오류 + 다시 시도
flutter run --dart-define=DEMO_STATE=empty     # 빈 상태
```

서버 없이도 세 상태를 바로 보여 줄 수 있습니다. `API_BASE`와 함께 써도 됩니다.

## 2. 구조

```
mid-project-template/
├── README.md                 # 실행 방법 [필수]
├── AGENTS.md                 # AI 가드레일 (UI만) — CLAUDE.md는 이 파일을 따른다는 한 줄
├── pubspec.yaml              # 추가 패키지는 http 하나
├── lib/
│   ├── main.dart             # 앱 뼈대 · 화면 흐름 주석
│   ├── api.dart              # GET만 · API_BASE · DEMO_STATE
│   ├── models.dart           # JSON → 객체 (Dart 3 패턴 fromJson)
│   ├── widgets.dart          # LoadingView · ErrorView · EmptyView (+ NetImage)
│   └── screens/
│       ├── a_list_screen.dart    # 화면 A 목록 — GET /items, 3상태, 600dp 적응형
│       ├── b_detail_screen.dart  # 화면 B 상세 — push로 들어옴, 탭(정보|메모), GET /notes
│       └── c_result_sheet.dart   # 화면 C 결과(임의) — 모달 시트, 미리 정한 결과
├── test/widget_test.dart     # 3상태 · push/tab/modal · 600dp 위젯 테스트
├── mock_server/
│   ├── db.json               # [필수] GET 데이터 (items · notes)
│   ├── package.json          # json-server 0.17.4 고정
│   ├── api/server.js · vercel.json   # (가산) 읽기 전용 배포
│   └── README.md
└── docs/
    ├── 디자인가이드.md       # 화면 목록 · 원칙 P01–P10 · 요소 분석 · 가이드 글 · 상태관리 포인트
    ├── 원칙카드.md           # 5칸 양식 (원칙 · 근거 · 적용 · 시연 · 판단)
    ├── prompt-log.md         # 4칸 (요청 · AI 결과 · 판단 · 이유)
    ├── 셀프논증.md           # 셀프 논증 기록: 내 주장 · 반론(AI) · 재반론 · 결론 · 근거 · 전/후
    ├── 자가평가.md           # 공개 배점 40/20/25/15 그대로
    ├── 영상/                 # demo_1min.mp4 · p01.mp4 …
    └── screenshots/          # README '앱 소개' 스크린샷 (01_v1_current.png …)
```

## 3. 화면 목록 ↔ 기획 문서 요소 번호

| 화면 | 이름 (TODO: 비즈니스 명칭) | 파일 | 전환 | 요소 번호 |
|---|---|---|---|---|
| A | TODO | `lib/screens/a_list_screen.dart` | 첫 화면 | A-1 ~ A-6 |
| B | TODO | `lib/screens/b_detail_screen.dart` | 쌓기(push) · 옆으로(tab) | B-1 ~ B-7 |
| C | TODO | `lib/screens/c_result_sheet.dart` | 덮기(modal) | C-1 ~ C-4 |

각 화면 파일 맨 위에 **디자인 가이드 대응표**(번호 · Flutter 위젯명 · 비즈니스 명칭 · 원칙) 주석이 있고, 코드 안에서 같은 번호(`// A-5 P09`)로 찾을 수 있습니다. `docs/디자인가이드.md`와 1:1로 맞춥니다. **가이드에 없는 화면은 만들지 않습니다**(감점).

**상태관리 포인트**는 구현하지 않고 주석으로만 표시합니다: `// STATE: <데이터> → <보여질 위젯>` — 모아 보기 `grep -rn "STATE:" lib`

## 4. 원칙 번호 추적 P01–P10 [권장]

P번호 = 닐슨 원칙 번호. 원칙 카드에 붙인 번호 하나를 다섯 곳에 그대로 씁니다.

| 어디 | 쓰는 법 |
|---|---|
| 디자인 가이드 | `docs/디자인가이드.md` 2장 표 · 요소 분석의 원칙 칸 |
| 코드 주석 | 그 원칙을 보여 주는 위젯 줄 끝: `); // A-5 P09` |
| 커밋 메시지 | `p09: 화면 A 오류 화면에 다시 시도` |
| 영상 | `docs/영상/p09.mp4` (원칙별 5–10초) |
| 발표 | 원칙 카드 P09 — 시연 칸 = p09.mp4 |

찾기: `grep -rn "P09" lib/` · `git log --oneline --grep="p09"`

## 5. 기준점 Git 태그 `v1-plan` [권장]

내가 화면 기획(흐름 · 요소 분석 · 가이드 글)을 확정한 직후 **한 번만** 붙입니다. 그 뒤 커밋이 UI 진행 기록이 되고, 셀프 논증 기록의 전 · 후 기준이 됩니다.

```bash
git tag -a v1-plan -m "화면 기획 확정"
git push origin v1-plan
git log v1-plan..HEAD --oneline        # 그 뒤 무엇이 바뀌었나
git diff v1-plan..HEAD --stat
```

기획이 바뀌면 셀프 논증 기록에 쟁점으로 남기고, 태그는 지우지 않습니다.

## 6. 영상 파일 이름

- `docs/영상/demo_1min.mp4` — 전체 흐름 1분 [필수 — 제출물 ①, README "데모" 칸에 링크 · 배포 URL로 대신 가능]: 첫 화면 → 전환 → 임의 결과 → GET 목록 → 넓은 화면
- `docs/영상/p01.mp4`, `p09.mp4` … — 원칙별 5–10초 클립 [권장], 원칙 카드 번호와 같게
- 녹화 전: 개인정보 · 알림이 화면에 보이지 않는지 확인. GitHub는 100MB가 넘는 파일을 받지 않으니 큰 영상은 LMS·드라이브 링크로 README "데모" 칸에 적습니다.

## 7. 감점 점검 (제출 전, 결과가 비어 있어야 함)

```bash
grep -rnE "http\.(post|put|patch|delete)|SharedPreferences|sqflite|hive|FirebaseAuth|ChangeNotifierProvider|Riverpod|BlocProvider" lib/ pubspec.yaml
```

걸린 줄은 지웁니다(안내문 8장). 검색은 이름만 찾으므로 화면을 직접 눌러 보며 실제로 저장·전송되는 곳이 없는지도 확인합니다. 자세한 점검: `docs/자가평가.md`.

## 8. 제출 전 clone 테스트 [필수 확인]

내 컴퓨터에서만 되는 저장소를 막습니다. 다른 사람 입장에서 README 명령만으로 됩니까?

1. 새 폴더에 받기: `git clone <저장소 URL> clone-test`
2. 터미널 1: `cd clone-test/mock_server && npm install && npm start`
3. 서버 확인: `curl http://localhost:3000/items` (내가 바꾼 `db.json` 키로)
4. 터미널 2: `cd clone-test && flutter pub get`
5. 실행: `flutter run -d chrome` (Android 에뮬레이터는 그냥 `flutter run`)
6. 화면 전환 · GET 목록 · 로딩/오류/빈 상태(`DEMO_STATE`) · 넓은 화면(창 크기 늘리기) 확인 → 안 되면 README를 고치고 1부터 다시

자주 빠지는 것: `db.json`이 커밋되지 않음 · `node_modules/`까지 올림 · README의 폴더 이름이 실제와 다름.

## 9. 제출물 2종 체크 (LMS, 10/29(목) 15:00 전 — 9주차 수업 시작 전, 각자 제출)

발표는 10/29(목) 9주차 수업(7–9교시)입니다. 10/22(목)은 수업이 없습니다.

- [ ] ① **데모 시연 + 코드** — 이 템플릿을 바탕으로 고친 **GitHub 저장소 URL** — **clone 테스트 통과**
  - [ ] Flutter 코드 + `mock_server/db.json`
  - [ ] README — 앱 소개 8칸 · 실행 방법 · **데모 영상 1분 링크 또는 배포 URL**("데모" 칸)
  - [ ] `docs/` — 디자인 가이드 · 원칙 카드 · prompt-log · **셀프 논증 기록**(`docs/셀프논증.md`) · 자가평가
- [ ] ② **발표자료** — `mid-project-presentation-template` 사용(PPTX 또는 PDF, 6분 발표 + 2분 질의)
  - [ ] 본문 7장 + 부록 B1 데모·스크린샷 · B2 원칙 카드 · B3 prompt-log · B4 자가평가 · **B5 기획 상세**(사업 요약 · 저니 · 피쉬본/5 Why · 화면별 요소 분석표 · 상태관리 포인트)

기획 1–5단계는 발표자료(본문 + 부록 B5)에 담습니다. 기획 양식 PPTX는 **선택(참고용)**이며 제출물이 아닙니다.

## 10. 확인된 상태 (템플릿 배포 시점)

```bash
flutter analyze   # No issues found!  (경로가 영문일 때 — 0장 참고)
flutter test      # 4개 통과: 3상태(로딩·오류→다시 시도 · 빈) · push/tab/modal 흐름 · 600dp 격자
```

`pubspec.yaml` 의존성: `flutter`, `cupertino_icons`, `http`뿐. 플랫폼 설정: Android 디버그 빌드 평문 HTTP 허용(`android/app/src/debug/AndroidManifest.xml`), macOS 나가는 네트워크 허용(`macos/Runner/*.entitlements`).
