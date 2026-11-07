// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'withdrawn_elsewhere_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WithdrawnElsewhereState {

 WithdrawnElsewherePhase get phase;/// データの削除ダイアログで削除する uid（ログイン中に退会済みと分かった uid）
 List<String> get userIds;/// 強制ログアウトの記録の uid。Firebase 上でログイン中でも、アプリではログアウトしたものとして扱う
 String? get forcedUserId;/// 強制ログアウトの記録を読み終えたか（読み終えるまでスプラッシュ画面から移動しない）
 bool get forcedLoaded;
/// Create a copy of WithdrawnElsewhereState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WithdrawnElsewhereStateCopyWith<WithdrawnElsewhereState> get copyWith => _$WithdrawnElsewhereStateCopyWithImpl<WithdrawnElsewhereState>(this as WithdrawnElsewhereState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WithdrawnElsewhereState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WithdrawnElsewhereState&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&const DeepCollectionEquality().equals(other.userIds, _this.userIds)&&(identical(other.forcedUserId, _this.forcedUserId) || other.forcedUserId == _this.forcedUserId)&&(identical(other.forcedLoaded, _this.forcedLoaded) || other.forcedLoaded == _this.forcedLoaded));
}


@override
int get hashCode {
  final _this = this as WithdrawnElsewhereState;
  return Object.hash(runtimeType,_this.phase,const DeepCollectionEquality().hash(_this.userIds),_this.forcedUserId,_this.forcedLoaded);
}

@override
String toString() {
  final _this = this as WithdrawnElsewhereState;
  return 'WithdrawnElsewhereState(phase: ${_this.phase}, userIds: ${_this.userIds}, forcedUserId: ${_this.forcedUserId}, forcedLoaded: ${_this.forcedLoaded})';
}


}

/// @nodoc
abstract mixin class $WithdrawnElsewhereStateCopyWith<$Res>  {
  factory $WithdrawnElsewhereStateCopyWith(WithdrawnElsewhereState value, $Res Function(WithdrawnElsewhereState) _then) = _$WithdrawnElsewhereStateCopyWithImpl;
@useResult
$Res call({
 WithdrawnElsewherePhase phase, List<String> userIds, String? forcedUserId, bool forcedLoaded
});




}
/// @nodoc
class _$WithdrawnElsewhereStateCopyWithImpl<$Res>
    implements $WithdrawnElsewhereStateCopyWith<$Res> {
  _$WithdrawnElsewhereStateCopyWithImpl(this._self, this._then);

  final WithdrawnElsewhereState _self;
  final $Res Function(WithdrawnElsewhereState) _then;

/// Create a copy of WithdrawnElsewhereState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? userIds = null,Object? forcedUserId = freezed,Object? forcedLoaded = null,}) {
  return _then(WithdrawnElsewhereState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as WithdrawnElsewherePhase,userIds: null == userIds ? _self.userIds : userIds // ignore: cast_nullable_to_non_nullable
as List<String>,forcedUserId: freezed == forcedUserId ? _self.forcedUserId : forcedUserId // ignore: cast_nullable_to_non_nullable
as String?,forcedLoaded: null == forcedLoaded ? _self.forcedLoaded : forcedLoaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WithdrawnElsewhereState].
extension WithdrawnElsewhereStatePatterns on WithdrawnElsewhereState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WithdrawnElsewhereState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WithdrawnElsewhereState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WithdrawnElsewhereState value)  $default,){
final _that = this;
switch (_that) {
case _WithdrawnElsewhereState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WithdrawnElsewhereState value)?  $default,){
final _that = this;
switch (_that) {
case _WithdrawnElsewhereState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WithdrawnElsewherePhase phase,  List<String> userIds,  String? forcedUserId,  bool forcedLoaded)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WithdrawnElsewhereState() when $default != null:
return $default(_that.phase,_that.userIds,_that.forcedUserId,_that.forcedLoaded);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WithdrawnElsewherePhase phase,  List<String> userIds,  String? forcedUserId,  bool forcedLoaded)  $default,) {final _that = this;
switch (_that) {
case _WithdrawnElsewhereState():
return $default(_that.phase,_that.userIds,_that.forcedUserId,_that.forcedLoaded);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WithdrawnElsewherePhase phase,  List<String> userIds,  String? forcedUserId,  bool forcedLoaded)?  $default,) {final _that = this;
switch (_that) {
case _WithdrawnElsewhereState() when $default != null:
return $default(_that.phase,_that.userIds,_that.forcedUserId,_that.forcedLoaded);case _:
  return null;

}
}

}

/// @nodoc


class _WithdrawnElsewhereState implements WithdrawnElsewhereState {
  const _WithdrawnElsewhereState({this.phase = WithdrawnElsewherePhase.idle,  List<String> userIds = const <String>[], this.forcedUserId, this.forcedLoaded = false}): _userIds = userIds;
  

@override@JsonKey() final  WithdrawnElsewherePhase phase;
/// データの削除ダイアログで削除する uid（ログイン中に退会済みと分かった uid）
 final  List<String> _userIds;
/// データの削除ダイアログで削除する uid（ログイン中に退会済みと分かった uid）
@override@JsonKey() List<String> get userIds {
  if (_userIds is EqualUnmodifiableListView) return _userIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_userIds);
}

/// 強制ログアウトの記録の uid。Firebase 上でログイン中でも、アプリではログアウトしたものとして扱う
@override final  String? forcedUserId;
/// 強制ログアウトの記録を読み終えたか（読み終えるまでスプラッシュ画面から移動しない）
@override@JsonKey() final  bool forcedLoaded;

/// Create a copy of WithdrawnElsewhereState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WithdrawnElsewhereStateCopyWith<_WithdrawnElsewhereState> get copyWith => __$WithdrawnElsewhereStateCopyWithImpl<_WithdrawnElsewhereState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WithdrawnElsewhereState&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.userIds, _userIds)&&(identical(other.forcedUserId, forcedUserId) || other.forcedUserId == forcedUserId)&&(identical(other.forcedLoaded, forcedLoaded) || other.forcedLoaded == forcedLoaded));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(_userIds),forcedUserId,forcedLoaded);
}

@override
String toString() {
    return 'WithdrawnElsewhereState(phase: $phase, userIds: $userIds, forcedUserId: $forcedUserId, forcedLoaded: $forcedLoaded)';
}


}

/// @nodoc
abstract mixin class _$WithdrawnElsewhereStateCopyWith<$Res> implements $WithdrawnElsewhereStateCopyWith<$Res> {
  factory _$WithdrawnElsewhereStateCopyWith(_WithdrawnElsewhereState value, $Res Function(_WithdrawnElsewhereState) _then) = __$WithdrawnElsewhereStateCopyWithImpl;
@override @useResult
$Res call({
 WithdrawnElsewherePhase phase, List<String> userIds, String? forcedUserId, bool forcedLoaded
});




}
/// @nodoc
class __$WithdrawnElsewhereStateCopyWithImpl<$Res>
    implements _$WithdrawnElsewhereStateCopyWith<$Res> {
  __$WithdrawnElsewhereStateCopyWithImpl(this._self, this._then);

  final _WithdrawnElsewhereState _self;
  final $Res Function(_WithdrawnElsewhereState) _then;

/// Create a copy of WithdrawnElsewhereState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? userIds = null,Object? forcedUserId = freezed,Object? forcedLoaded = null,}) {
  return _then(_WithdrawnElsewhereState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as WithdrawnElsewherePhase,userIds: null == userIds ? _self._userIds : userIds // ignore: cast_nullable_to_non_nullable
as List<String>,forcedUserId: freezed == forcedUserId ? _self.forcedUserId : forcedUserId // ignore: cast_nullable_to_non_nullable
as String?,forcedLoaded: null == forcedLoaded ? _self.forcedLoaded : forcedLoaded // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
