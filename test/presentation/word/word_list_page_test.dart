import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:word_pods/domain/entities/word.dart';
import 'package:word_pods/presentation/word/word_list_page.dart';
import 'package:word_pods/presentation/word/word_list_view_model.dart';

import '../../helpers/test_helpers.dart';

const _folderId = 'folder-1';
const _folderName = '英単語';

Widget buildWordListPage({List<Override> extra = const []}) {
  return buildWithMockRepositories(
    child: const WordListPage(folderId: _folderId, folderName: _folderName),
    extra: extra,
  );
}

void main() {
  group('WordListPage', () {
    testWidgets('ローディング中は CircularProgressIndicator が表示される', (tester) async {
      await tester.pumpWidget(
        buildWordListPage(extra: [
          wordListViewModelProvider(_folderId)
              .overrideWith(LoadingWordListViewModel.new),
        ]),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('単語 0 件のとき「単語がありません」が表示される', (tester) async {
      await tester.pumpWidget(
        buildWordListPage(extra: [
          wordListViewModelProvider(_folderId)
              .overrideWith(EmptyWordListViewModel.new),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('単語がありません'), findsOneWidget);
    });

    testWidgets('単語が存在するとき表面・裏面が表示される', (tester) async {
      await tester.pumpWidget(
        buildWordListPage(extra: [
          wordListViewModelProvider(_folderId)
              .overrideWith(DataWordListViewModel.new),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('apple'), findsOneWidget);
      expect(find.text('りんご'), findsOneWidget);
      expect(find.text('banana'), findsOneWidget);
    });

    testWidgets('検索キーワードに一致しない単語は非表示になる', (tester) async {
      await tester.pumpWidget(
        buildWordListPage(extra: [
          wordListViewModelProvider(_folderId)
              .overrideWith(DataWordListViewModel.new),
        ]),
      );

      // 'apple' を検索
      // enterText は検索フィールド (EditableText) にも 'apple' を書き込むため
      // find.text('apple') が検索フィールドとワードタイルの両方にマッチすることに注意
      await tester.enterText(find.byType(TextField).first, 'apple');
      await tester.pump();

      // 'apple' に一致しない単語が非表示になっていることを確認
      expect(find.text('banana'), findsNothing);
      expect(find.text('cherry'), findsNothing);
    });

    testWidgets('検索クリアボタンをタップすると全単語が再表示される', (tester) async {
      await tester.pumpWidget(
        buildWordListPage(extra: [
          wordListViewModelProvider(_folderId)
              .overrideWith(DataWordListViewModel.new),
        ]),
      );

      await tester.enterText(find.byType(TextField).first, 'apple');
      await tester.pump();
      // clear ボタンが表示される
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(find.text('banana'), findsOneWidget);
    });

    testWidgets('単語追加用の FAB が表示される', (tester) async {
      await tester.pumpWidget(
        buildWordListPage(extra: [
          wordListViewModelProvider(_folderId)
              .overrideWith(DataWordListViewModel.new),
        ]),
      );
      await tester.pumpAndSettle();

      // FAB タップ時は WordCreateRoute へ画面遷移する（ダイアログ表示は廃止）。
      // ルーター依存のため遷移自体はここでは検証せず、FAB の存在のみ確認する。
      expect(find.descendant(
        of: find.byType(FloatingActionButton),
        matching: find.byIcon(Icons.add),
      ), findsOneWidget);
    });

    testWidgets('画面を開いた場合、テスト開始の FAB が単語追加の FAB の上に表示され、AppBar には表示されない', (tester) async {
      await tester.pumpWidget(
        buildWordListPage(extra: [
          wordListViewModelProvider(_folderId)
              .overrideWith(DataWordListViewModel.new),
        ]),
      );
      await tester.pumpAndSettle();

      final startFab = find.ancestor(
        of: find.byIcon(Icons.play_arrow),
        matching: find.byType(FloatingActionButton),
      );
      final addFab = find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(FloatingActionButton),
      );
      expect(startFab, findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(
        find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.play_arrow)),
        findsNothing,
      );
      expect(tester.getCenter(startFab).dy, lessThan(tester.getCenter(addFab).dy));
    });

    testWidgets('テスト開始の FAB をタップした場合、そのフォルダのテスト設定画面に遷移する', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (c, s) =>
                const WordListPage(folderId: _folderId, folderName: _folderName),
          ),
          GoRoute(
            path: '/test-settings/:folderId',
            builder: (c, s) =>
                Text('test-settings:${s.pathParameters['folderId']}:${s.extra}'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        buildWithMockRepositories(
          child: Router.withConfig(config: router),
          extra: [
            wordListViewModelProvider(_folderId)
                .overrideWith(DataWordListViewModel.new),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pumpAndSettle();

      expect(find.text('test-settings:$_folderId:$_folderName'), findsOneWidget);
    });
  });
}

class LoadingWordListViewModel extends WordListViewModel {
  @override
  Future<List<Word>> build(String folderId) =>
      // 決して完了しない Future → provider が AsyncLoading のままになる
      Completer<List<Word>>().future;
}

class EmptyWordListViewModel extends WordListViewModel {
  @override
  Future<List<Word>> build(String folderId) async => [];
}

class DataWordListViewModel extends WordListViewModel {
  @override
  Future<List<Word>> build(String folderId) async => testWords;
}
