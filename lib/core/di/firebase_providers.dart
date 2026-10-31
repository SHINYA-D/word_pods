import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:word_pods/infrastructure/data_sources/firebase_auth_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/firestore_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/remote/account_deletion_remote_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/remote/account_remote_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/remote/firestore_sync_remote_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/remote/legal_remote_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/remote/sync_remote_data_source.dart';
import 'package:word_pods/infrastructure/data_sources/remote/withdrawn_account_remote_data_source.dart';

part 'firebase_providers.g.dart';

@Riverpod(keepAlive: true)
FirebaseAuth firebaseAuth(Ref ref) => FirebaseAuth.instance;

/// オフライン対応は SQLite と同期キューで自前で行うため、Firestore SDK のオフライン機能は使わない
@Riverpod(keepAlive: true)
FirebaseFirestore firestore(Ref ref) {
  final firestore = FirebaseFirestore.instance;
  firestore.settings = const Settings(persistenceEnabled: false);
  return firestore;
}

/// 関数は東京リージョンに置く（functions/src/index.ts の region と合わせる）
@Riverpod(keepAlive: true)
FirebaseFunctions firebaseFunctions(Ref ref) =>
    FirebaseFunctions.instanceFor(region: 'asia-northeast1');

@Riverpod(keepAlive: true)
GoogleSignIn googleSignIn(Ref ref) => GoogleSignIn();

@Riverpod(keepAlive: true)
FirebaseAuthDataSource firebaseAuthDataSource(Ref ref) =>
    FirebaseAuthDataSource(
      firebaseAuth: ref.watch(firebaseAuthProvider),
      googleSignIn: ref.watch(googleSignInProvider),
    );

@Riverpod(keepAlive: true)
FirestoreDataSource firestoreDataSource(Ref ref) =>
    FirestoreDataSource(firestore: ref.watch(firestoreProvider));

@Riverpod(keepAlive: true)
SyncRemoteDataSource syncRemoteDataSource(Ref ref) =>
    FirestoreSyncRemoteDataSource(firestore: ref.watch(firestoreProvider));

@Riverpod(keepAlive: true)
AccountDeletionRemoteDataSource accountDeletionRemoteDataSource(Ref ref) =>
    AccountDeletionRemoteDataSource(ref.watch(firebaseFunctionsProvider));

@Riverpod(keepAlive: true)
AccountRemoteDataSource accountRemoteDataSource(Ref ref) =>
    AccountRemoteDataSource(ref.watch(firestoreProvider));

@Riverpod(keepAlive: true)
WithdrawnAccountRemoteDataSource withdrawnAccountRemoteDataSource(Ref ref) =>
    WithdrawnAccountRemoteDataSource(ref.watch(firestoreProvider));

@Riverpod(keepAlive: true)
LegalRemoteDataSource legalRemoteDataSource(Ref ref) => LegalRemoteDataSource(
      ref.watch(firestoreProvider),
      ref.watch(firebaseFunctionsProvider),
    );
