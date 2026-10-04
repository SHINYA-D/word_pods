// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_deletion_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AccountDeletionState {
  AccountDeletionPhase get phase;

  /// 再開待ちで、直前の再試行が失敗したか
  bool get retryFailed;

  /// 再開ダイアログからの処理か（処理中の表示を再開ダイアログの中に出すため）
  bool get isRetry;

  /// Create a copy of AccountDeletionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AccountDeletionStateCopyWith<AccountDeletionState> get copyWith =>
      _$AccountDeletionStateCopyWithImpl<AccountDeletionState>(
          this as AccountDeletionState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AccountDeletionState &&
            (identical(other.phase, phase) || other.phase == phase) &&
            (identical(other.retryFailed, retryFailed) ||
                other.retryFailed == retryFailed) &&
            (identical(other.isRetry, isRetry) || other.isRetry == isRetry));
  }

  @override
  int get hashCode => Object.hash(runtimeType, phase, retryFailed, isRetry);

  @override
  String toString() {
    return 'AccountDeletionState(phase: $phase, retryFailed: $retryFailed, isRetry: $isRetry)';
  }
}

/// @nodoc
abstract mixin class $AccountDeletionStateCopyWith<$Res> {
  factory $AccountDeletionStateCopyWith(AccountDeletionState value,
          $Res Function(AccountDeletionState) _then) =
      _$AccountDeletionStateCopyWithImpl;
  @useResult
  $Res call({AccountDeletionPhase phase, bool retryFailed, bool isRetry});
}

/// @nodoc
class _$AccountDeletionStateCopyWithImpl<$Res>
    implements $AccountDeletionStateCopyWith<$Res> {
  _$AccountDeletionStateCopyWithImpl(this._self, this._then);

  final AccountDeletionState _self;
  final $Res Function(AccountDeletionState) _then;

  /// Create a copy of AccountDeletionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? phase = null,
    Object? retryFailed = null,
    Object? isRetry = null,
  }) {
    return _then(_self.copyWith(
      phase: null == phase
          ? _self.phase
          : phase // ignore: cast_nullable_to_non_nullable
              as AccountDeletionPhase,
      retryFailed: null == retryFailed
          ? _self.retryFailed
          : retryFailed // ignore: cast_nullable_to_non_nullable
              as bool,
      isRetry: null == isRetry
          ? _self.isRetry
          : isRetry // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [AccountDeletionState].
extension AccountDeletionStatePatterns on AccountDeletionState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AccountDeletionState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AccountDeletionState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AccountDeletionState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AccountDeletionState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AccountDeletionState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AccountDeletionState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            AccountDeletionPhase phase, bool retryFailed, bool isRetry)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AccountDeletionState() when $default != null:
        return $default(_that.phase, _that.retryFailed, _that.isRetry);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(AccountDeletionPhase phase, bool retryFailed, bool isRetry)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AccountDeletionState():
        return $default(_that.phase, _that.retryFailed, _that.isRetry);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            AccountDeletionPhase phase, bool retryFailed, bool isRetry)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AccountDeletionState() when $default != null:
        return $default(_that.phase, _that.retryFailed, _that.isRetry);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AccountDeletionState implements AccountDeletionState {
  const _AccountDeletionState(
      {required this.phase, this.retryFailed = false, this.isRetry = false});

  @override
  final AccountDeletionPhase phase;

  /// 再開待ちで、直前の再試行が失敗したか
  @override
  @JsonKey()
  final bool retryFailed;

  /// 再開ダイアログからの処理か（処理中の表示を再開ダイアログの中に出すため）
  @override
  @JsonKey()
  final bool isRetry;

  /// Create a copy of AccountDeletionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AccountDeletionStateCopyWith<_AccountDeletionState> get copyWith =>
      __$AccountDeletionStateCopyWithImpl<_AccountDeletionState>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AccountDeletionState &&
            (identical(other.phase, phase) || other.phase == phase) &&
            (identical(other.retryFailed, retryFailed) ||
                other.retryFailed == retryFailed) &&
            (identical(other.isRetry, isRetry) || other.isRetry == isRetry));
  }

  @override
  int get hashCode => Object.hash(runtimeType, phase, retryFailed, isRetry);

  @override
  String toString() {
    return 'AccountDeletionState(phase: $phase, retryFailed: $retryFailed, isRetry: $isRetry)';
  }
}

/// @nodoc
abstract mixin class _$AccountDeletionStateCopyWith<$Res>
    implements $AccountDeletionStateCopyWith<$Res> {
  factory _$AccountDeletionStateCopyWith(_AccountDeletionState value,
          $Res Function(_AccountDeletionState) _then) =
      __$AccountDeletionStateCopyWithImpl;
  @override
  @useResult
  $Res call({AccountDeletionPhase phase, bool retryFailed, bool isRetry});
}

/// @nodoc
class __$AccountDeletionStateCopyWithImpl<$Res>
    implements _$AccountDeletionStateCopyWith<$Res> {
  __$AccountDeletionStateCopyWithImpl(this._self, this._then);

  final _AccountDeletionState _self;
  final $Res Function(_AccountDeletionState) _then;

  /// Create a copy of AccountDeletionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? phase = null,
    Object? retryFailed = null,
    Object? isRetry = null,
  }) {
    return _then(_AccountDeletionState(
      phase: null == phase
          ? _self.phase
          : phase // ignore: cast_nullable_to_non_nullable
              as AccountDeletionPhase,
      retryFailed: null == retryFailed
          ? _self.retryFailed
          : retryFailed // ignore: cast_nullable_to_non_nullable
              as bool,
      isRetry: null == isRetry
          ? _self.isRetry
          : isRetry // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
