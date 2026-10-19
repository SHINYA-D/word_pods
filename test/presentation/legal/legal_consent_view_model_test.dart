import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:word_stock/application/use_cases/auth/sign_out_use_case.dart';
import 'package:word_stock/application/use_cases/auth/withdrawn_elsewhere_use_case.dart';
import 'package:word_stock/core/di/auth_providers.dart';
import 'package:word_stock/core/di/repository_providers.dart';
import 'package:word_stock/core/di/sync_status_providers.dart';
import 'package:word_stock/core/error/failure.dart';
import 'package:word_stock/domain/entities/account_deletion_request.dart';
import 'package:word_stock/domain/entities/app_user.dart';
import 'package:word_stock/domain/entities/legal_consent.dart';
import 'package:word_stock/domain/repositories/account_deletion_repository.dart';
import 'package:word_stock/domain/repositories/legal_repository.dart';
import 'package:word_stock/presentation/legal/legal_consent_state.dart';
import 'package:word_stock/presentation/legal/legal_consent_view_model.dart';
import 'package:word_stock/presentation/settings/withdrawn_elsewhere_state.dart';
import 'package:word_stock/presentation/settings/withdrawn_elsewhere_view_model.dart';

import '../../helpers/fake_auth_use_case_repositories.dart';

/// 仕様書（docs/detailed_design/legal_consent/legal_consent.md）4章の
/// LegalConsentViewModel のテスト。期待値は仕様書から作っている。
const _userA = AppUser(id: 'A', email: 'a@example.com');
const _userB = AppUser(id: 'B', email: 'b@example.com');

const _config = LegalConfig(
  termsVersion: '2026-01-01',
  privacyVersion: '2026-01-01',
  termsUrl: 'https://example.com/terms',
  privacyUrl: 'https://example.com/privacy',
);

const _matching = LegalConsents(
  termsVersion: '2026-01-01',
  privacyVersion: '2026-01-01',
);

Failure get _network => const Failure.network();
Failure get _auth => const Failure.auth();
Failure get _notFound => const Failure.notFound();
Failure get _unknown => const Failure.unknown('x');

typedef _Phase = LegalConsentPhase;
typedef _Msg = LegalConsentMessage;

/// 仕様 ID を付けたテスト。テスト名は「○○の場合、△△になる [ID]」。
void spec(String id, String name, Future<void> Function() body) =>
    test('$name [$id]', body);

/// ログイン中のユーザーを切り替えられるようにするための Provider。
final _userState = StateProvider<AppUser?>((ref) => _userA);

class _FakeLegalRepository implements LegalRepository {
  Either<Failure, LegalConfig> config = const Right(_config);
  final configQueue = <Either<Failure, LegalConfig>>[];
  Completer<void>? configGate;

  Either<Failure, LegalConsents> consents = const Right(LegalConsents());
  final consentsByUser = <String, Either<Failure, LegalConsents>>{};

  Either<Failure, LegalAcceptResult> acceptResult =
      const Right(LegalAcceptResult.accepted);
  final acceptQueue = <Either<Failure, LegalAcceptResult>>[];
  Completer<void>? acceptGate;

  int fetchConfigCalls = 0;
  final fetchConsentsUsers = <String>[];
  final acceptCalls = <({String? terms, String? privacy})>[];

  @override
  Future<Either<Failure, LegalConfig>> fetchLegalConfig() async {
    fetchConfigCalls++;
    await configGate?.future;
    if (configQueue.isNotEmpty) return configQueue.removeAt(0);
    return config;
  }

  @override
  Future<Either<Failure, LegalConsents>> fetchConsents(String userId) async {
    fetchConsentsUsers.add(userId);
    return consentsByUser[userId] ?? consents;
  }

  @override
  Future<Either<Failure, LegalAcceptResult>> accept({
    String? termsVersion,
    String? privacyVersion,
  }) async {
    acceptCalls.add((terms: termsVersion, privacy: privacyVersion));
    await acceptGate?.future;
    if (acceptQueue.isNotEmpty) return acceptQueue.removeAt(0);
    return acceptResult;
  }
}

class _FakeSignOutUseCase extends SignOutUseCase {
  _FakeSignOutUseCase() : super(FakeAuthRepository(), FakeSyncServiceForLogin());

  Either<Failure, Unit> result = const Right(unit);
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<Either<Failure, Unit>> call() async {
    calls++;
    await gate?.future;
    return result;
  }
}

/// 退会処理の記録（findPending）だけを制御する Fake。ほかは使われない。
class _FakeAccountDeletionRepository implements AccountDeletionRepository {
  AccountDeletionRequest? record;

  @override
  Future<Either<Failure, Option<AccountDeletionRequest>>> findPending() async =>
      Right(optionOf(record));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

/// 他の端末での退会の phase と forcedUserId を外から変えられる ViewModel。
class _FakeWithdrawnViewModel extends WithdrawnElsewhereViewModel {
  @override
  WithdrawnElsewhereState build() => const WithdrawnElsewhereState();

  void setPhase(WithdrawnElsewherePhase phase) =>
      state = state.copyWith(phase: phase);

  void setForced(String? userId) =>
      state = state.copyWith(forcedUserId: userId);
}

AccountDeletionRequest _record(AccountDeletionStatus status) =>
    AccountDeletionRequest(
      userId: 'A',
      status: status,
      updatedAt: DateTime(2026, 10, 12),
    );

/// 応答待ちで止めた操作の完了（gate を開けた後に await する）。
class _Pending {
  _Pending(this.done);
  final Future<void> done;
}

class _Env {
  _Env({AppUser? user = _userA}) {
    container = ProviderContainer(
      overrides: [
        _userState.overrideWith((ref) => user),
        currentUserProvider.overrideWith((ref) => ref.watch(_userState)),
        legalRepositoryProvider.overrideWithValue(legal),
        signOutUseCaseProvider.overrideWithValue(signOut),
        withdrawnElsewhereUseCaseProvider.overrideWithValue(
          WithdrawnElsewhereUseCase(
            deletion,
            FakeAuthRepository(),
            FakeSyncServiceForLogin(),
          ),
        ),
        withdrawnElsewhereViewModelProvider
            .overrideWith(_FakeWithdrawnViewModel.new),
      ],
    );
    addTearDown(container.dispose);
    vm = container.read(legalConsentViewModelProvider.notifier);
    withdrawn = container.read(withdrawnElsewhereViewModelProvider.notifier)
        as _FakeWithdrawnViewModel;
  }

  final legal = _FakeLegalRepository();
  final signOut = _FakeSignOutUseCase();
  final deletion = _FakeAccountDeletionRepository();
  late final ProviderContainer container;
  late final LegalConsentViewModel vm;
  late final _FakeWithdrawnViewModel withdrawn;

  LegalConsentState get s => container.read(legalConsentViewModelProvider);

  Future<void> settle() => pumpEventQueue();

  void setSyncing(bool value) =>
      container.read(authSyncInProgressProvider.notifier).state = value;

  void setUser(AppUser? user) =>
      container.read(_userState.notifier).state = user;

  /// 同意ダイアログを表示している状態（phase が required）にする。
  Future<void> toRequired() async {
    await vm.check();
    expect(s.phase, _Phase.required, reason: '準備: required になっている');
  }

  void checkBoth() {
    vm.setTermsChecked(true);
    vm.setPrivacyChecked(true);
  }

  /// 両方チェックして accept を呼び、応答を待っている状態にする。
  Future<_Pending> acceptWaiting() async {
    checkBoth();
    legal.acceptGate = Completer<void>();
    final f = vm.accept();
    await settle();
    return _Pending(f);
  }

  void releaseAccept() => legal.acceptGate!.complete();

  /// signOut を呼び、応答を待っている状態にする。
  Future<_Pending> signOutWaiting() async {
    signOut.gate = Completer<void>();
    final f = vm.signOut();
    await settle();
    return _Pending(f);
  }

  void releaseSignOut() => signOut.gate!.complete();

  /// networkError にする（両方チェック → 送信が NetworkFailure）。
  Future<void> toNetworkError() async {
    await toRequired();
    checkBoth();
    legal.acceptResult = Left(_network);
    await vm.accept();
    expect(s.phase, _Phase.networkError, reason: '準備: networkError');
  }
}

void main() {
  group('check（判定）', () {
    spec('LGL-V01', '未同意の状態で check を呼んだ場合、phase が required で両方の行が表示対象になり、チェックと message は初期値のままになる',
        () async {
      final e = _Env();
      await e.vm.check();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsRequired, isTrue);
      expect(e.s.privacyRequired, isTrue);
      expect(e.s.termsChecked, isFalse);
      expect(e.s.privacyChecked, isFalse);
      expect(e.s.message, isNull);
    });

    spec('LGL-V02', '利用規約が最新でプライバシーポリシーが古い状態で check を呼んだ場合、プライバシーポリシーだけが表示対象になる',
        () async {
      final e = _Env();
      e.legal.consents = const Right(LegalConsents(
          termsVersion: '2026-01-01', privacyVersion: '2025-06-01'));
      await e.vm.check();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsRequired, isFalse);
      expect(e.s.privacyRequired, isTrue);
    });

    spec('LGL-V03', '利用規約が古くプライバシーポリシーが最新の状態で check を呼んだ場合、利用規約だけが表示対象になる',
        () async {
      final e = _Env();
      e.legal.consents = const Right(LegalConsents(
          termsVersion: '2025-06-01', privacyVersion: '2026-01-01'));
      await e.vm.check();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsRequired, isTrue);
      expect(e.s.privacyRequired, isFalse);
    });

    spec('LGL-V04', '両方とも現行の版数に同意済みの状態で check を呼んだ場合、phase が idle のままで表示対象にならない',
        () async {
      final e = _Env();
      e.legal.consents = const Right(_matching);
      await e.vm.check();
      expect(e.s.phase, _Phase.idle);
      expect(e.s.termsRequired, isFalse);
      expect(e.s.privacyRequired, isFalse);
    });

    spec('LGL-V05', '判定が NetworkFailure を返す状態で check を呼んだ場合、phase が idle のままで表示対象にならない',
        () async {
      final e = _Env();
      e.legal.config = Left(_network);
      await e.vm.check();
      expect(e.legal.fetchConfigCalls, 1);
      expect(e.s.phase, _Phase.idle);
      expect(e.s.termsRequired, isFalse);
      expect(e.s.privacyRequired, isFalse);
    });

    spec('LGL-V06', '1回目の判定が NetworkFailure で2回目が成功する状態で check を2回呼んだ場合、1回目の後は idle で2回目の後は required になる',
        () async {
      final e = _Env();
      e.legal.configQueue.add(Left(_network));
      await e.vm.check();
      expect(e.s.phase, _Phase.idle);
      await e.vm.check();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsRequired, isTrue);
      expect(e.s.privacyRequired, isTrue);
    });

    spec('LGL-V07', '判定が UnknownFailure を返す状態で check を呼んだ場合、phase が idle のままで表示対象にならない',
        () async {
      final e = _Env();
      e.legal.config = Left(_unknown);
      await e.vm.check();
      expect(e.legal.fetchConfigCalls, 1);
      expect(e.s.phase, _Phase.idle);
      expect(e.s.termsRequired, isFalse);
      expect(e.s.privacyRequired, isFalse);
    });

    spec('LGL-V09', 'ログインしていない状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない',
        () async {
      final e = _Env(user: null);
      await e.vm.check();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.fetchConfigCalls, 0);
      expect(e.legal.fetchConsentsUsers, isEmpty);
    });

    spec('LGL-V10', 'uid A の退会処理の記録が requested の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない',
        () async {
      final e = _Env();
      e.deletion.record = _record(AccountDeletionStatus.requested);
      await e.vm.check();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.fetchConfigCalls, 0);
      expect(e.legal.fetchConsentsUsers, isEmpty);
    });

    spec('LGL-V11', '他の端末での退会の phase が notifying の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない',
        () async {
      final e = _Env();
      e.withdrawn.setPhase(WithdrawnElsewherePhase.notifying);
      await e.vm.check();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.fetchConfigCalls, 0);
      expect(e.legal.fetchConsentsUsers, isEmpty);
    });

    spec('LGL-V12', 'phase が required の後に他の端末での退会の phase が notifying に変わった場合、phase が idle になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.withdrawn.setPhase(WithdrawnElsewherePhase.notifying);
      await e.settle();
      expect(e.s.phase, _Phase.idle);
    });

    spec('LGL-V13', 'uid A に強制ログアウトの記録がある状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない',
        () async {
      final e = _Env();
      e.withdrawn.setForced('A');
      await e.vm.check();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.fetchConfigCalls, 0);
      expect(e.legal.fetchConsentsUsers, isEmpty);
    });

    spec('LGL-V14', 'phase が required で利用規約をチェックした後にもう一度 check を呼んだ場合、required と termsChecked が保たれ fetchLegalConfig は合計1回になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.vm.setTermsChecked(true);
      await e.vm.check();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsChecked, isTrue);
      expect(e.legal.fetchConfigCalls, 1);
    });

    spec('LGL-V33', 'uid A の退会処理の記録が serverDone の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない',
        () async {
      final e = _Env();
      e.deletion.record = _record(AccountDeletionStatus.serverDone);
      await e.vm.check();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.fetchConfigCalls, 0);
      expect(e.legal.fetchConsentsUsers, isEmpty);
    });

    spec('LGL-V34', '判定の応答を待っている間にログイン中の uid が null に変わり同意が必要という結果が返った場合、phase が idle のままで表示対象にならない',
        () async {
      final e = _Env();
      e.legal.configGate = Completer<void>();
      final f = e.vm.check();
      await e.settle();
      e.setUser(null);
      await e.settle();
      e.legal.configGate!.complete();
      await f;
      expect(e.s.phase, _Phase.idle);
      expect(e.s.termsRequired, isFalse);
      expect(e.s.privacyRequired, isFalse);
    });

    spec('LGL-V35', '判定の応答を待っている間に他の端末での退会の phase が notifying に変わり同意が必要という結果が返った場合、phase が idle のままで表示対象にならない',
        () async {
      final e = _Env();
      e.legal.configGate = Completer<void>();
      final f = e.vm.check();
      await e.settle();
      e.withdrawn.setPhase(WithdrawnElsewherePhase.notifying);
      await e.settle();
      e.legal.configGate!.complete();
      await f;
      expect(e.s.phase, _Phase.idle);
      expect(e.s.termsRequired, isFalse);
      expect(e.s.privacyRequired, isFalse);
    });

    spec('LGL-V36', '判定の応答を待っている間に退会処理の記録が requested になり同意が必要という結果が返った場合、phase が idle のままで表示対象にならない',
        () async {
      final e = _Env();
      e.legal.configGate = Completer<void>();
      final f = e.vm.check();
      await e.settle();
      e.deletion.record = _record(AccountDeletionStatus.requested);
      e.legal.configGate!.complete();
      await f;
      expect(e.s.phase, _Phase.idle);
      expect(e.s.termsRequired, isFalse);
      expect(e.s.privacyRequired, isFalse);
    });

    spec('LGL-V37', '判定の応答を待っている間にもう一度 check を呼んだ場合、fetchLegalConfig は合計1回で phase が required になる',
        () async {
      final e = _Env();
      e.legal.configGate = Completer<void>();
      final f = e.vm.check();
      await e.settle();
      await e.vm.check();
      e.legal.configGate!.complete();
      await f;
      expect(e.legal.fetchConfigCalls, 1);
      expect(e.s.phase, _Phase.required);
    });

    spec('LGL-V44', 'phase が networkError の状態で check を呼んだ場合、phase が networkError のままで fetchLegalConfig の呼び出し回数が増えない',
        () async {
      final e = _Env();
      await e.toNetworkError();
      final before = e.legal.fetchConfigCalls;
      await e.vm.check();
      expect(e.s.phase, _Phase.networkError);
      expect(e.legal.fetchConfigCalls, before);
    });

    spec('LGL-V62', '他の端末での退会の phase が confirming の状態で check を呼んだ場合、phase が idle のままで fetchLegalConfig と fetchConsents は呼ばれない',
        () async {
      final e = _Env();
      e.withdrawn.setPhase(WithdrawnElsewherePhase.confirming);
      await e.vm.check();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.fetchConfigCalls, 0);
      expect(e.legal.fetchConsentsUsers, isEmpty);
    });

    spec('LGL-V72', 'phase が signingOut の状態で check を呼んだ場合、phase が signingOut のままで fetchLegalConfig の呼び出し回数が増えない',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.signOutWaiting()).done;
      final before = e.legal.fetchConfigCalls;
      await e.vm.check();
      expect(e.s.phase, _Phase.signingOut);
      expect(e.legal.fetchConfigCalls, before);
      e.releaseSignOut();
      await f;
    });

    spec('LGL-V82', '`app_config/legal` が無く未同意の状態で check を呼んだ場合、phase が required で両方の行が表示対象になり config は既定値になる',
        () async {
      final e = _Env();
      e.legal.config = Left(_notFound);
      await e.vm.check();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsRequired, isTrue);
      expect(e.s.privacyRequired, isTrue);
      expect(e.s.config?.termsVersion, '2026-10-12');
      expect(e.s.config?.privacyVersion, '2026-10-12');
      expect(e.s.config?.termsUrl, 'https://word-stock-web.web.app/terms');
      expect(e.s.config?.privacyUrl, 'https://word-stock-web.web.app/privacy');
    });

    spec('LGL-V83', '`app_config/legal` が無く既定値と同じ版数に同意済みの状態で check を呼んだ場合、phase が idle のままになる',
        () async {
      final e = _Env();
      e.legal.config = Left(_notFound);
      e.legal.consents = const Right(LegalConsents(
          termsVersion: '2026-10-12', privacyVersion: '2026-10-12'));
      await e.vm.check();
      expect(e.s.phase, _Phase.idle);
    });

    spec('LGL-V87', '初回の同期の間にログイン中の uid が A で check を呼んだ場合、phase が idle のままで fetchLegalConfig は呼ばれない',
        () async {
      final e = _Env();
      e.setSyncing(true);
      await e.vm.check();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.fetchConfigCalls, 0);
    });
  });

  group('ログイン中の uid の変化', () {
    spec('LGL-V15', 'start の後にログイン中の uid が null から A に変わった場合、fetchLegalConfig が1回呼ばれ phase が required になる',
        () async {
      final e = _Env(user: null);
      await e.vm.start();
      e.setUser(_userA);
      await e.settle();
      expect(e.legal.fetchConfigCalls, 1);
      expect(e.s.phase, _Phase.required);
    });

    spec('LGL-V16', 'phase が required で termsChecked が true の状態でログイン中の uid が null に変わった場合、State が初期値に戻る',
        () async {
      final e = _Env();
      await e.toRequired();
      e.vm.setTermsChecked(true);
      e.setUser(null);
      await e.settle();
      expect(e.s.phase, _Phase.idle);
      expect(e.s.termsRequired, isFalse);
      expect(e.s.privacyRequired, isFalse);
      expect(e.s.termsChecked, isFalse);
      expect(e.s.privacyChecked, isFalse);
      expect(e.s.config, isNull);
      expect(e.s.message, isNull);
    });

    spec('LGL-V46', 'phase が required で termsChecked が true の状態でログイン中の uid が A から B に変わった場合、B で判定し直し、チェックと message が初期値の required になる',
        () async {
      final e = _Env();
      await e.vm.start();
      e.vm.setTermsChecked(true);
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsChecked, isTrue);
      e.setUser(_userB);
      await e.settle();
      expect(e.legal.fetchConsentsUsers.where((u) => u == 'B').length, 1);
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsChecked, isFalse);
      expect(e.s.privacyChecked, isFalse);
      expect(e.s.message, isNull);
    });

    spec('LGL-V47', 'start の後にログイン中の uid が null から A に変わり A が現行の版数に同意済みの場合、phase が idle のままになる',
        () async {
      final e = _Env(user: null);
      e.legal.consentsByUser['A'] = const Right(_matching);
      await e.vm.start();
      e.setUser(_userA);
      await e.settle();
      expect(e.legal.fetchConsentsUsers, ['A']);
      expect(e.s.phase, _Phase.idle);
    });

    spec('LGL-V85', '初回の同期の間にログイン中の uid が null から A に変わった場合、phase が idle のままで fetchLegalConfig は呼ばれない',
        () async {
      final e = _Env(user: null);
      await e.vm.start();
      e.setSyncing(true);
      e.setUser(_userA);
      await e.settle();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.fetchConfigCalls, 0);
    });

    spec('LGL-V86', '初回の同期の間に uid が null から A に変わった後で同期が終わった場合、fetchLegalConfig が1回呼ばれ phase が required になる',
        () async {
      final e = _Env(user: null);
      await e.vm.start();
      e.setSyncing(true);
      e.setUser(_userA);
      await e.settle();
      e.setSyncing(false);
      await e.settle();
      expect(e.legal.fetchConfigCalls, 1);
      expect(e.s.phase, _Phase.required);
    });

    spec('LGL-V89', '初回の同期の間に uid が null から A に変わり同期の終わる前に null に戻ってから同期が終わった場合、phase が idle のままで fetchLegalConfig は呼ばれない',
        () async {
      final e = _Env(user: null);
      await e.vm.start();
      e.setSyncing(true);
      e.setUser(_userA);
      await e.settle();
      e.setUser(null);
      await e.settle();
      e.setSyncing(false);
      await e.settle();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.fetchConfigCalls, 0);
    });

    spec('LGL-V90', 'phase が required の状態で初回の同期の終了（true から false）を受けた場合、phase が required のままで fetchLegalConfig の呼び出し回数が増えない',
        () async {
      final e = _Env();
      await e.vm.start();
      expect(e.s.phase, _Phase.required);
      final before = e.legal.fetchConfigCalls;
      e.setSyncing(true);
      await e.settle();
      e.setSyncing(false);
      await e.settle();
      expect(e.s.phase, _Phase.required);
      expect(e.legal.fetchConfigCalls, before);
    });

    spec('LGL-V91', '初回の同期の間に uid が null から A に変わり同期が失敗して終わった場合、fetchLegalConfig が1回呼ばれ phase が required になる',
        () async {
      final e = _Env(user: null);
      await e.vm.start();
      e.setSyncing(true);
      e.setUser(_userA);
      await e.settle();
      // 同期の失敗も authSyncInProgressProvider が false に戻ることで表される
      e.setSyncing(false);
      await e.settle();
      expect(e.legal.fetchConfigCalls, 1);
      expect(e.s.phase, _Phase.required);
    });
  });

  group('setTermsChecked / setPrivacyChecked（チェックの切り替え）', () {
    spec('LGL-V17', 'phase が required の状態で setTermsChecked(true) を呼んだ場合、termsChecked だけが true になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.vm.setTermsChecked(true);
      expect(e.s.termsChecked, isTrue);
      expect(e.s.privacyChecked, isFalse);
    });

    spec('LGL-V18', 'phase が required の状態で setTermsChecked(true) と setPrivacyChecked(true) を呼んだ場合、両方が true になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      expect(e.s.termsChecked, isTrue);
      expect(e.s.privacyChecked, isTrue);
    });

    spec('LGL-V19', '両方チェックした状態で setTermsChecked(false) を呼んだ場合、termsChecked が false で privacyChecked は true のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.vm.setTermsChecked(false);
      expect(e.s.termsChecked, isFalse);
      expect(e.s.privacyChecked, isTrue);
    });

    spec('LGL-V20', 'プライバシーポリシーだけが表示対象の required の状態で setPrivacyChecked(true) を呼んだ場合、privacyChecked が true になる',
        () async {
      final e = _Env();
      e.legal.consents = const Right(LegalConsents(
          termsVersion: '2026-01-01', privacyVersion: '2025-06-01'));
      await e.toRequired();
      e.vm.setPrivacyChecked(true);
      expect(e.s.privacyChecked, isTrue);
    });

    spec('LGL-V48', 'phase が required の状態で setPrivacyChecked(true) を呼んだ場合、privacyChecked だけが true になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.vm.setPrivacyChecked(true);
      expect(e.s.privacyChecked, isTrue);
      expect(e.s.termsChecked, isFalse);
    });

    spec('LGL-V49', '両方チェックした状態で setPrivacyChecked(false) を呼んだ場合、privacyChecked が false で termsChecked は true のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.vm.setPrivacyChecked(false);
      expect(e.s.privacyChecked, isFalse);
      expect(e.s.termsChecked, isTrue);
    });

    spec('LGL-V59', 'message が outdated の required の状態で setTermsChecked(true) を呼んだ場合、termsChecked が true で message は outdated のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = const Right(LegalAcceptResult.outdated);
      await e.vm.accept();
      expect(e.s.message, _Msg.outdated);
      e.vm.setTermsChecked(true);
      expect(e.s.termsChecked, isTrue);
      expect(e.s.message, _Msg.outdated);
    });

    spec('LGL-V74', 'message が signOutFailed の required の状態で setPrivacyChecked(true) を呼んだ場合、message は signOutFailed のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.signOut.result = Left(_unknown);
      await e.vm.signOut();
      expect(e.s.message, _Msg.signOutFailed);
      e.vm.setPrivacyChecked(true);
      expect(e.s.message, _Msg.signOutFailed);
    });

    spec('LGL-V75', 'message が sendFailed の required の状態で setTermsChecked(false) を呼んだ場合、message は sendFailed のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = Left(_unknown);
      await e.vm.accept();
      expect(e.s.message, _Msg.sendFailed);
      e.vm.setTermsChecked(false);
      expect(e.s.message, _Msg.sendFailed);
    });
  });

  group('accept（送信）', () {
    spec('LGL-V21', '両方チェックして accept を呼び送信が accepted を返した場合、phase が idle で message が null になり、現行の版数2つで送信が1回呼ばれる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      await e.vm.accept();
      expect(e.s.phase, _Phase.idle);
      expect(e.s.message, isNull);
      expect(e.legal.acceptCalls.length, 1);
      expect(e.legal.acceptCalls.single.terms, '2026-01-01');
      expect(e.legal.acceptCalls.single.privacy, '2026-01-01');
    });

    spec('LGL-V22', '利用規約だけが表示対象で termsChecked が true の状態で accept を呼び accepted が返った場合、phase が idle で利用規約の版数とプライバシーポリシー null で送信される',
        () async {
      final e = _Env();
      e.legal.consents = const Right(LegalConsents(
          termsVersion: '2025-06-01', privacyVersion: '2026-01-01'));
      await e.toRequired();
      e.vm.setTermsChecked(true);
      await e.vm.accept();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.acceptCalls.length, 1);
      expect(e.legal.acceptCalls.single.terms, '2026-01-01');
      expect(e.legal.acceptCalls.single.privacy, isNull);
    });

    spec('LGL-V23', '両方チェックして accept を呼び送信の応答を待っている場合、phase が sending になる',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.acceptWaiting()).done;
      expect(e.s.phase, _Phase.sending);
      e.releaseAccept();
      await f;
    });

    spec('LGL-V24', '送信の応答を待っている間にもう一度 accept を呼んだ場合、送信は1回だけ呼ばれる',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.acceptWaiting()).done;
      await e.vm.accept();
      expect(e.legal.acceptCalls.length, 1);
      e.releaseAccept();
      await f;
    });

    spec('LGL-V25', '両方チェックして accept を呼び送信が UnknownFailure で失敗した場合、phase が required でチェックは true のまま message が sendFailed になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = Left(_unknown);
      await e.vm.accept();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsChecked, isTrue);
      expect(e.s.privacyChecked, isTrue);
      expect(e.s.message, _Msg.sendFailed);
    });

    spec('LGL-V26', '1回目の送信が UnknownFailure で2回目が accepted の状態で accept を2回呼んだ場合、2回目の後は phase が idle で message が null になり送信は合計2回になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptQueue.add(Left(_unknown));
      await e.vm.accept();
      await e.vm.accept();
      expect(e.s.phase, _Phase.idle);
      expect(e.s.message, isNull);
      expect(e.legal.acceptCalls.length, 2);
    });

    spec('LGL-V27', '現行の termsVersion が変わって accept を呼び送信が outdated を返した場合、判定し直した結果で表示し直し、チェックが外れて message が outdated になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.config =
          Right(_config.copyWith(termsVersion: '2026-02-01'));
      e.legal.acceptResult = const Right(LegalAcceptResult.outdated);
      await e.vm.accept();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsRequired, isTrue);
      expect(e.s.privacyRequired, isTrue);
      expect(e.s.termsChecked, isFalse);
      expect(e.s.privacyChecked, isFalse);
      expect(e.s.message, _Msg.outdated);
      expect(e.s.config?.termsVersion, '2026-02-01');
      expect(e.legal.fetchConfigCalls, 2);
    });

    spec('LGL-V28', '現行の termsVersion が変わって1回目の送信が outdated を返した後に再度チェックして accept を呼び accepted が返った場合、phase が idle で2回目は新しい版数で送信される',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.config =
          Right(_config.copyWith(termsVersion: '2026-02-01'));
      e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated));
      await e.vm.accept();
      e.checkBoth();
      await e.vm.accept();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.acceptCalls.length, 2);
      expect(e.legal.acceptCalls.last.terms, '2026-02-01');
      expect(e.legal.acceptCalls.last.privacy, '2026-01-01');
    });

    spec('LGL-V29', '両方チェックして accept を呼び送信が NetworkFailure で失敗した場合、phase が networkError になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = Left(_network);
      await e.vm.accept();
      expect(e.s.phase, _Phase.networkError);
    });

    spec('LGL-V30', '両方チェックして accept を呼び送信が AuthFailure で失敗した場合、phase が networkError になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = Left(_auth);
      await e.vm.accept();
      expect(e.s.phase, _Phase.networkError);
    });

    spec('LGL-V32', 'termsChecked だけが true の状態で accept を呼んだ場合、送信は0回で phase は required のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.vm.setTermsChecked(true);
      await e.vm.accept();
      expect(e.legal.acceptCalls, isEmpty);
      expect(e.s.phase, _Phase.required);
    });

    spec('LGL-V38', '送信の応答を待っている間に check を呼んだ場合、phase は sending のままで fetchLegalConfig は合計1回、送信は1回になる',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.acceptWaiting()).done;
      await e.vm.check();
      expect(e.s.phase, _Phase.sending);
      expect(e.legal.fetchConfigCalls, 1);
      expect(e.legal.acceptCalls.length, 1);
      e.releaseAccept();
      await f;
    });

    spec('LGL-V39', '送信の応答を待っている間に他の端末での退会の phase が notifying に変わった場合、phase が idle になる',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.acceptWaiting()).done;
      e.withdrawn.setPhase(WithdrawnElsewherePhase.notifying);
      await e.settle();
      expect(e.s.phase, _Phase.idle);
      e.releaseAccept();
      await f;
      expect(e.s.phase, _Phase.idle);
    });

    spec('LGL-V40', '送信の応答を待っている間にログイン中の uid が null に変わり送信が NetworkFailure で失敗した場合、phase が idle のままで SignOutUseCase は呼ばれない',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.acceptWaiting()).done;
      e.setUser(null);
      await e.settle();
      e.legal.acceptResult = Left(_network);
      e.releaseAccept();
      await f;
      expect(e.s.phase, _Phase.idle);
      expect(e.signOut.calls, 0);
    });

    spec('LGL-V41', '送信の応答を待っている間にログイン中の uid が null に変わり送信が accepted を返した場合、phase が idle のままで表示対象にならない',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.acceptWaiting()).done;
      e.setUser(null);
      await e.settle();
      e.releaseAccept();
      await f;
      expect(e.s.phase, _Phase.idle);
      expect(e.s.termsRequired, isFalse);
      expect(e.s.privacyRequired, isFalse);
    });

    spec('LGL-V50', 'プライバシーポリシーだけが表示対象で privacyChecked が true の状態で accept を呼び accepted が返った場合、phase が idle で利用規約 null とプライバシーポリシーの版数で送信される',
        () async {
      final e = _Env();
      e.legal.consents = const Right(LegalConsents(
          termsVersion: '2026-01-01', privacyVersion: '2025-06-01'));
      await e.toRequired();
      e.vm.setPrivacyChecked(true);
      await e.vm.accept();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.acceptCalls.length, 1);
      expect(e.legal.acceptCalls.single.terms, isNull);
      expect(e.legal.acceptCalls.single.privacy, '2026-01-01');
    });

    spec('LGL-V51', '現行の privacyVersion が変わって accept を呼び送信が outdated を返した場合、判定し直した結果で表示し直し、チェックが外れて message が outdated になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.config =
          Right(_config.copyWith(privacyVersion: '2026-02-01'));
      e.legal.acceptResult = const Right(LegalAcceptResult.outdated);
      await e.vm.accept();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsRequired, isTrue);
      expect(e.s.privacyRequired, isTrue);
      expect(e.s.termsChecked, isFalse);
      expect(e.s.privacyChecked, isFalse);
      expect(e.s.message, _Msg.outdated);
      expect(e.s.config?.privacyVersion, '2026-02-01');
    });

    spec('LGL-V52', '現行の privacyVersion が変わって1回目の送信が outdated を返した後に再度チェックして accept を呼び accepted が返った場合、phase が idle で2回目は新しい版数で送信される',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.config =
          Right(_config.copyWith(privacyVersion: '2026-02-01'));
      e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated));
      await e.vm.accept();
      e.checkBoth();
      await e.vm.accept();
      expect(e.s.phase, _Phase.idle);
      expect(e.legal.acceptCalls.last.terms, '2026-01-01');
      expect(e.legal.acceptCalls.last.privacy, '2026-02-01');
    });

    spec('LGL-V53', 'privacyChecked だけが true の状態で accept を呼んだ場合、送信は0回で phase は required のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.vm.setPrivacyChecked(true);
      await e.vm.accept();
      expect(e.legal.acceptCalls, isEmpty);
      expect(e.s.phase, _Phase.required);
    });

    spec('LGL-V54', '送信が outdated を返し続く判定し直しが NetworkFailure を返した場合、phase が idle になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = const Right(LegalAcceptResult.outdated);
      e.legal.configQueue.add(Left(_network));
      await e.vm.accept();
      expect(e.s.phase, _Phase.idle);
    });

    spec('LGL-V55', '送信が outdated を返し続く判定し直しで同意済みの版数が現行の版数と一致していた場合、phase が idle で message が null になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = const Right(LegalAcceptResult.outdated);
      e.legal.consentsByUser['A'] = const Right(_matching);
      await e.vm.accept();
      expect(e.s.phase, _Phase.idle);
      expect(e.s.message, isNull);
    });

    spec('LGL-V56', '利用規約だけが表示対象で現行の privacyVersion が変わり送信が outdated を返した場合、両方が表示対象になりチェックが外れる',
        () async {
      final e = _Env();
      e.legal.consents = const Right(LegalConsents(
          termsVersion: '2025-06-01', privacyVersion: '2026-01-01'));
      await e.toRequired();
      e.vm.setTermsChecked(true);
      e.legal.config =
          Right(_config.copyWith(privacyVersion: '2026-02-01'));
      e.legal.acceptResult = const Right(LegalAcceptResult.outdated);
      await e.vm.accept();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsRequired, isTrue);
      expect(e.s.privacyRequired, isTrue);
      expect(e.s.termsChecked, isFalse);
      expect(e.s.privacyChecked, isFalse);
    });

    spec('LGL-V57', '現行の termsVersion と termsUrl が変わり送信が outdated を返した場合、config.termsUrl が新しい URL になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.config = Right(_config.copyWith(
        termsVersion: '2026-02-01',
        termsUrl: 'https://example.com/terms-v2',
      ));
      e.legal.acceptResult = const Right(LegalAcceptResult.outdated);
      await e.vm.accept();
      expect(e.s.config?.termsUrl, 'https://example.com/terms-v2');
    });

    spec('LGL-V58', '1回目の送信が UnknownFailure で失敗した後にもう一度 accept を呼び応答を待っている場合、phase が sending で message が null になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = Left(_unknown);
      await e.vm.accept();
      expect(e.s.message, _Msg.sendFailed);
      e.legal.acceptGate = Completer<void>();
      final f = e.vm.accept();
      await e.settle();
      expect(e.s.phase, _Phase.sending);
      expect(e.s.message, isNull);
      e.releaseAccept();
      await f;
    });

    spec('LGL-V60', '送信が outdated を返し続く判定し直しが UnknownFailure を返した場合、phase が idle になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = const Right(LegalAcceptResult.outdated);
      e.legal.configQueue.add(Left(_unknown));
      await e.vm.accept();
      expect(e.s.phase, _Phase.idle);
    });

    spec('LGL-V70', 'phase が signingOut の状態で accept を呼んだ場合、送信は0回で phase は signingOut のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      final f = (await e.signOutWaiting()).done;
      await e.vm.accept();
      expect(e.legal.acceptCalls, isEmpty);
      expect(e.s.phase, _Phase.signingOut);
      e.releaseSignOut();
      await f;
    });

    spec('LGL-V76', 'message が signOutFailed で両方チェックして accept を呼び応答を待っている場合、message が null になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.signOut.result = Left(_unknown);
      await e.vm.signOut();
      expect(e.s.message, _Msg.signOutFailed);
      final f = (await e.acceptWaiting()).done;
      expect(e.s.message, isNull);
      e.releaseAccept();
      await f;
    });

    spec('LGL-V79', 'message が outdated で両方チェックして accept を呼び応答を待っている場合、message が null になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptQueue.add(const Right(LegalAcceptResult.outdated));
      await e.vm.accept();
      expect(e.s.message, _Msg.outdated);
      final f = (await e.acceptWaiting()).done;
      expect(e.s.message, isNull);
      e.releaseAccept();
      await f;
    });

    spec('LGL-V84', '送信が outdated を返し続く判定し直しで `app_config/legal` が無かった場合、phase が required でチェックが外れ message が outdated になり config は既定値になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = const Right(LegalAcceptResult.outdated);
      e.legal.configQueue.add(Left(_notFound));
      await e.vm.accept();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsChecked, isFalse);
      expect(e.s.privacyChecked, isFalse);
      expect(e.s.message, _Msg.outdated);
      expect(e.s.config?.termsVersion, '2026-10-12');
    });
  });

  group('signOut（同意ダイアログのログアウト）', () {
    spec('LGL-V63', 'phase が required の状態で signOut を呼びログアウトの応答を待っている場合、phase が signingOut になる',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.signOutWaiting()).done;
      expect(e.s.phase, _Phase.signingOut);
      e.releaseSignOut();
      await f;
    });

    spec('LGL-V64', 'phase が required の状態で signOut を呼びログアウトが成功した場合、SignOutUseCase が1回呼ばれ送信は0回になる',
        () async {
      final e = _Env();
      await e.toRequired();
      await e.vm.signOut();
      expect(e.signOut.calls, 1);
      expect(e.legal.acceptCalls, isEmpty);
    });

    spec('LGL-V65', 'termsChecked が true の required の状態で signOut を呼びログアウトが UnknownFailure で失敗した場合、phase が required で termsChecked は true のまま message が signOutFailed になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.vm.setTermsChecked(true);
      e.signOut.result = Left(_unknown);
      await e.vm.signOut();
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsChecked, isTrue);
      expect(e.s.message, _Msg.signOutFailed);
    });

    spec('LGL-V66', 'phase が sending の状態で signOut を呼んだ場合、SignOutUseCase は呼ばれず phase は sending のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.acceptWaiting()).done;
      await e.vm.signOut();
      expect(e.signOut.calls, 0);
      expect(e.s.phase, _Phase.sending);
      e.releaseAccept();
      await f;
    });

    spec('LGL-V68', 'ログアウトの応答を待っている間にもう一度 signOut を呼んだ場合、SignOutUseCase は1回だけ呼ばれる',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.signOutWaiting()).done;
      await e.vm.signOut();
      expect(e.signOut.calls, 1);
      e.releaseSignOut();
      await f;
    });

    spec('LGL-V69', 'message が sendFailed の required の状態で signOut を呼び応答を待っている場合、message が null になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = Left(_unknown);
      await e.vm.accept();
      expect(e.s.message, _Msg.sendFailed);
      final f = (await e.signOutWaiting()).done;
      expect(e.s.message, isNull);
      e.releaseSignOut();
      await f;
    });

    spec('LGL-V71', 'signingOut の間に他の端末での退会の phase が notifying に変わりその後ログアウトが UnknownFailure を返した場合、phase が idle で message は null のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.signOutWaiting()).done;
      e.withdrawn.setPhase(WithdrawnElsewherePhase.notifying);
      await e.settle();
      e.signOut.result = Left(_unknown);
      e.releaseSignOut();
      await f;
      expect(e.s.phase, _Phase.idle);
      expect(e.s.message, isNull);
    });

    spec('LGL-V73', 'signingOut の間にログイン中の uid が null に変わりその後ログアウトが UnknownFailure を返した場合、phase が idle で message は null のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      final f = (await e.signOutWaiting()).done;
      e.setUser(null);
      await e.settle();
      e.signOut.result = Left(_unknown);
      e.releaseSignOut();
      await f;
      expect(e.s.phase, _Phase.idle);
      expect(e.s.message, isNull);
    });

    spec('LGL-V77', 'message が signOutFailed の required の状態で signOut を呼び応答を待っている場合、message が null になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.signOut.result = Left(_unknown);
      await e.vm.signOut();
      expect(e.s.message, _Msg.signOutFailed);
      final f = (await e.signOutWaiting()).done;
      expect(e.s.message, isNull);
      e.releaseSignOut();
      await f;
    });

    spec('LGL-V78', 'message が outdated の required の状態で signOut を呼び応答を待っている場合、message が null になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.checkBoth();
      e.legal.acceptResult = const Right(LegalAcceptResult.outdated);
      await e.vm.accept();
      expect(e.s.message, _Msg.outdated);
      final f = (await e.signOutWaiting()).done;
      expect(e.s.message, isNull);
      e.releaseSignOut();
      await f;
    });

    spec('LGL-V80', 'phase が required の状態で signOut を呼びログアウトが NetworkFailure で失敗した場合、phase が required で message が signOutFailed になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.signOut.result = Left(_network);
      await e.vm.signOut();
      expect(e.s.phase, _Phase.required);
      expect(e.s.message, _Msg.signOutFailed);
    });

    spec('LGL-V81', 'phase が required の状態で signOut を呼びログアウトが AuthFailure で失敗した場合、phase が required で message が signOutFailed になる',
        () async {
      final e = _Env();
      await e.toRequired();
      e.signOut.result = Left(_auth);
      await e.vm.signOut();
      expect(e.s.phase, _Phase.required);
      expect(e.s.message, _Msg.signOutFailed);
    });
  });

  group('acknowledgeNetworkError（通信エラーダイアログの OK）', () {
    spec('LGL-V31', 'phase が networkError でログアウトが成功する状態で acknowledgeNetworkError を呼んだ場合、SignOutUseCase が1回呼ばれ phase が idle になる',
        () async {
      final e = _Env();
      await e.toNetworkError();
      await e.vm.acknowledgeNetworkError();
      expect(e.signOut.calls, 1);
      expect(e.s.phase, _Phase.idle);
    });

    spec('LGL-V42', 'ログアウトの応答を待っている間にもう一度 acknowledgeNetworkError を呼んだ場合、SignOutUseCase は1回だけ呼ばれる',
        () async {
      final e = _Env();
      await e.toNetworkError();
      e.signOut.gate = Completer<void>();
      final f = e.vm.acknowledgeNetworkError();
      await e.settle();
      await e.vm.acknowledgeNetworkError();
      expect(e.signOut.calls, 1);
      e.releaseSignOut();
      await f;
    });

    spec('LGL-V43', 'phase が required の状態で acknowledgeNetworkError を呼んだ場合、SignOutUseCase は呼ばれず phase は required のままになる',
        () async {
      final e = _Env();
      await e.toRequired();
      await e.vm.acknowledgeNetworkError();
      expect(e.signOut.calls, 0);
      expect(e.s.phase, _Phase.required);
    });

    spec('LGL-V45', 'phase が networkError でログアウトが UnknownFailure で失敗し判定し直しで未同意と分かる場合、SignOutUseCase が1回呼ばれ phase が required でチェックと message は初期値になる',
        () async {
      final e = _Env();
      await e.toNetworkError();
      e.signOut.result = Left(_unknown);
      await e.vm.acknowledgeNetworkError();
      expect(e.signOut.calls, 1);
      expect(e.s.phase, _Phase.required);
      expect(e.s.termsChecked, isFalse);
      expect(e.s.privacyChecked, isFalse);
      expect(e.s.message, isNull);
    });

    spec('LGL-V67', 'phase が networkError の状態で他の端末での退会の phase が notifying に変わった場合、phase が idle になり SignOutUseCase は呼ばれない',
        () async {
      final e = _Env();
      await e.toNetworkError();
      e.withdrawn.setPhase(WithdrawnElsewherePhase.notifying);
      await e.settle();
      expect(e.s.phase, _Phase.idle);
      expect(e.signOut.calls, 0);
    });
  });
}
