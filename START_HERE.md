# Google Keep v2 — Quick start

1. Open this folder in VS Code.
2. Terminal A: `flutter pub get` then `flutter run -d chrome`
3. Terminal B: `npx.cmd json-server mock_server/db.json --port 3000`
4. In Chrome, open Flutter app. `http://localhost:3000/items` should show mock notes.
5. On home, use filter icon, select types, open note. In editor, use top search and bottom Aa.

This is a UI-only prototype: editing text is local and is not saved. The formatting toolbar visually changes the entire note, not selected text. Search uses the TextField selection to mark and navigate matches; it does not paint all occurrences. The +N type popover opens on long press. No POST/PUT/DELETE.

Demo states: `flutter run -d chrome --dart-define=DEMO_STATE=slow` (loading), `...=error`, `...=empty`.

Before submission: update professor's docs and README to reflect this redesign, record a 1-minute demo, verify code on your Windows Flutter installation, and publish your own GitHub repository.
