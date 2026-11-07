// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_deletion_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountDeletionState {

 AccountDeletionPhase get phase;/// 再開待ちで、直前の再試行が失敗したか
 bool get retryFailed;/// 再開ダイアログからの処理か（処理中の表示を再開ダイアログの中に出すため）
 bool get isRetry;/// 本人確認のし直しを待っていて、直前の本人確認でパスワードが違った（別のアカウントを選んだ）か
 bool get reauthRejected;/// 直前の本人確認が、試行回数の上限を超えて失敗したか
 bool get tooManyAttempts;
/// Create a copy of AccountDeletionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountDeletionStateCopyWith<AccountDeletionState> get copyWith => _$AccountDeletionStateCopyWithImpl<AccountDeletionState>(this as AccountDeletionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AccountDeletionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDeletionState&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.retryFailed, _this.retryFailed) || other.retryFailed == _this.retryFailed)&&(identical(other.isRetry, _this.isRetry) || other.isRetry == _this.isRetry)&&(identical(other.reauthRejected, _this.reauthRejected) || other.reauthRejected == _this.reauthRejected)&&(identical(other.tooManyAttempts, _this.tooManyAttempts) || other.tooManyAttempts == _this.tooManyAttempts));
}


@override
int get hashCode {
  final _this = this as AccountDeletionState;
  return Object.hash(runtimeType,_this.phase,_this.retryFailed,_this.isRetry,_this.reauthRejected,_this.tooManyAttempts);
}

@override
String toString() {
  final _this = this as AccountDeletionState;
  return 'AccountDeletionState(phase: ${_this.phase}, retryFailed: ${_this.retryFailed}, isRetry: ${_this.isRetry}, reauthRejected: ${_this.reauthRejected}, tooManyAttempts: ${_this.tooManyAttempts})';
}


}

/// @nodoc
abstract mixin class $AccountDeletionStateCopyWith<$Res>  {
  factory $AccountDeletionStateCopyWith(AccountDeletionState value, $Res Function(AccountDeletionState) _then) = _$AccountDeletionStateCopyWithImpl;
@useResult
$Res call({
 AccountDeletionPhase phase, bool retryFailed, bool isRetry, bool reauthRejected, bool tooManyAttempts
});




}
/// @nodoc
class _$AccountDeletionStateCopyWithImpl<$Res>
    implements $AccountDeletionStateCopyWith<$Res> {
  _$AccountDeletionStateCopyWithImpl(this._self, this._then);

  final AccountDeletionState _self;
  final $Res Function(AccountDeletionState) _then;

/// Create a copy of AccountDeletionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? retryFailed = null,Object? isRetry = null,Object? reauthRejected = null,Object? tooManyAttempts = null,}) {
  return _then(AccountDeletionState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as AccountDeletionPhase,retryFailed: null == retryFailed ? _self.retryFailed : retryFailed // ignore: cast_nullable_to_non_nullable
as bool,isRetry: null == isRetry ? _self.isRetry : isRetry // ignore: cast_nullable_to_non_nullable
as bool,reauthRejected: null == reauthRejected ? _self.reauthRejected : reauthRejected // ignore: cast_nullable_to_non_nullable
as bool,tooManyAttempts: null == tooManyAttempts ? _self.tooManyAttempts : tooManyAttempts // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountDeletionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountDeletionState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountDeletionState value)  $default,){
final _that = this;
switch (_that) {
case _AccountDeletionState():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountDeletionState value)?  $default,){
final _that = this;
switch (_that) {
case _AccountDeletionState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AccountDeletionPhase phase,  bool retryFailed,  bool isRetry,  bool reauthRejected,  bool tooManyAttempts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountDeletionState() when $default != null:
return $default(_that.phase,_that.retryFailed,_that.isRetry,_that.reauthRejected,_that.tooManyAttempts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AccountDeletionPhase phase,  bool retryFailed,  bool isRetry,  bool reauthRejected,  bool tooManyAttempts)  $default,) {final _that = this;
switch (_that) {
case _AccountDeletionState():
return $default(_that.phase,_that.retryFailed,_that.isRetry,_that.reauthRejected,_that.tooManyAttempts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AccountDeletionPhase phase,  bool retryFailed,  bool isRetry,  bool reauthRejected,  bool tooManyAttempts)?  $default,) {final _that = this;
switch (_that) {
case _AccountDeletionState() when $default != null:
return $default(_that.phase,_that.retryFailed,_that.isRetry,_that.reauthRejected,_that.tooManyAttempts);case _:
  return null;

}
}

}

/// @nodoc


class _AccountDeletionState implements AccountDeletionState {
  const _AccountDeletionState({required this.phase, this.retryFailed = false, this.isRetry = false, this.reauthRejected = false, this.tooManyAttempts = false});
  

@override final  AccountDeletionPhase phase;
/// 再開待ちで、直前の再試行が失敗したか
@override@JsonKey() final  bool retryFailed;
/// 再開ダイアログからの処理か（処理中の表示を再開ダイアログの中に出すため）
@override@JsonKey() final  bool isRetry;
/// 本人確認のし直しを待っていて、直前の本人確認でパスワードが違った（別のアカウントを選んだ）か
@override@JsonKey() final  bool reauthRejected;
/// 直前の本人確認が、試行回数の上限を超えて失敗したか
@override@JsonKey() final  bool tooManyAttempts;

/// Create a copy of AccountDeletionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountDeletionStateCopyWith<_AccountDeletionState> get copyWith => __$AccountDeletionStateCopyWithImpl<_AccountDeletionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountDeletionState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.retryFailed, retryFailed) || other.retryFailed == retryFailed)&&(identical(other.isRetry, isRetry) || other.isRetry == isRetry)&&(identical(other.reauthRejected, reauthRejected) || other.reauthRejected == reauthRejected)&&(identical(other.tooManyAttempts, tooManyAttempts) || other.tooManyAttempts == tooManyAttempts));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,retryFailed,isRetry,reauthRejected,tooManyAttempts);
}

@override
String toString() {
    return 'AccountDeletionState(phase: $phase, retryFailed: $retryFailed, isRetry: $isRetry, reauthRejected: $reauthRejected, tooManyAttempts: $tooManyAttempts)';
}


}

/// @nodoc
abstract mixin class _$AccountDeletionStateCopyWith<$Res> implements $AccountDeletionStateCopyWith<$Res> {
  factory _$AccountDeletionStateCopyWith(_AccountDeletionState value, $Res Function(_AccountDeletionState) _then) = __$AccountDeletionStateCopyWithImpl;
@override @useResult
$Res call({
 AccountDeletionPhase phase, bool retryFailed, bool isRetry, bool reauthRejected, bool tooManyAttempts
});




}
/// @nodoc
class __$AccountDeletionStateCopyWithImpl<$Res>
    implements _$AccountDeletionStateCopyWith<$Res> {
  __$AccountDeletionStateCopyWithImpl(this._self, this._then);

  final _AccountDeletionState _self;
  final $Res Function(_AccountDeletionState) _then;

/// Create a copy of AccountDeletionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? retryFailed = null,Object? isRetry = null,Object? reauthRejected = null,Object? tooManyAttempts = null,}) {
  return _then(_AccountDeletionState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as AccountDeletionPhase,retryFailed: null == retryFailed ? _self.retryFailed : retryFailed // ignore: cast_nullable_to_non_nullable
as bool,isRetry: null == isRetry ? _self.isRetry : isRetry // ignore: cast_nullable_to_non_nullable
as bool,reauthRejected: null == reauthRejected ? _self.reauthRejected : reauthRejected // ignore: cast_nullable_to_non_nullable
as bool,tooManyAttempts: null == tooManyAttempts ? _self.tooManyAttempts : tooManyAttempts // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
