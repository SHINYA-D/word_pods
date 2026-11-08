// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'legal_consent_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LegalConsentState {

 LegalConsentPhase get phase;/// ログイン中のユーザーが現行の版に同意済みだと確認できているか。
/// 確認できるまでは false で、クラッシュ情報・利用状況を集めない
 bool get consented;/// その文書の行を表示するか
 bool get termsRequired; bool get privacyRequired;/// その文書のチェックボックスがチェックされているか
 bool get termsChecked; bool get privacyChecked;/// 判定に使った現行の規約の情報（送信する版数と閲覧画面の URL）
 LegalConfig? get config; LegalConsentMessage? get message;
/// Create a copy of LegalConsentState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalConsentStateCopyWith<LegalConsentState> get copyWith => _$LegalConsentStateCopyWithImpl<LegalConsentState>(this as LegalConsentState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LegalConsentState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalConsentState&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.consented, _this.consented) || other.consented == _this.consented)&&(identical(other.termsRequired, _this.termsRequired) || other.termsRequired == _this.termsRequired)&&(identical(other.privacyRequired, _this.privacyRequired) || other.privacyRequired == _this.privacyRequired)&&(identical(other.termsChecked, _this.termsChecked) || other.termsChecked == _this.termsChecked)&&(identical(other.privacyChecked, _this.privacyChecked) || other.privacyChecked == _this.privacyChecked)&&(identical(other.config, _this.config) || other.config == _this.config)&&(identical(other.message, _this.message) || other.message == _this.message));
}


@override
int get hashCode {
  final _this = this as LegalConsentState;
  return Object.hash(runtimeType,_this.phase,_this.consented,_this.termsRequired,_this.privacyRequired,_this.termsChecked,_this.privacyChecked,_this.config,_this.message);
}

@override
String toString() {
  final _this = this as LegalConsentState;
  return 'LegalConsentState(phase: ${_this.phase}, consented: ${_this.consented}, termsRequired: ${_this.termsRequired}, privacyRequired: ${_this.privacyRequired}, termsChecked: ${_this.termsChecked}, privacyChecked: ${_this.privacyChecked}, config: ${_this.config}, message: ${_this.message})';
}


}

/// @nodoc
abstract mixin class $LegalConsentStateCopyWith<$Res>  {
  factory $LegalConsentStateCopyWith(LegalConsentState value, $Res Function(LegalConsentState) _then) = _$LegalConsentStateCopyWithImpl;
@useResult
$Res call({
 LegalConsentPhase phase, bool consented, bool termsRequired, bool privacyRequired, bool termsChecked, bool privacyChecked, LegalConfig? config, LegalConsentMessage? message
});


$LegalConfigCopyWith<$Res>? get config;

}
/// @nodoc
class _$LegalConsentStateCopyWithImpl<$Res>
    implements $LegalConsentStateCopyWith<$Res> {
  _$LegalConsentStateCopyWithImpl(this._self, this._then);

  final LegalConsentState _self;
  final $Res Function(LegalConsentState) _then;

/// Create a copy of LegalConsentState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? consented = null,Object? termsRequired = null,Object? privacyRequired = null,Object? termsChecked = null,Object? privacyChecked = null,Object? config = freezed,Object? message = freezed,}) {
  return _then(LegalConsentState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LegalConsentPhase,consented: null == consented ? _self.consented : consented // ignore: cast_nullable_to_non_nullable
as bool,termsRequired: null == termsRequired ? _self.termsRequired : termsRequired // ignore: cast_nullable_to_non_nullable
as bool,privacyRequired: null == privacyRequired ? _self.privacyRequired : privacyRequired // ignore: cast_nullable_to_non_nullable
as bool,termsChecked: null == termsChecked ? _self.termsChecked : termsChecked // ignore: cast_nullable_to_non_nullable
as bool,privacyChecked: null == privacyChecked ? _self.privacyChecked : privacyChecked // ignore: cast_nullable_to_non_nullable
as bool,config: freezed == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as LegalConfig?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as LegalConsentMessage?,
  ));
}
/// Create a copy of LegalConsentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LegalConfigCopyWith<$Res>? get config {
    if (_self.config == null) {
    return null;
  }

  return $LegalConfigCopyWith<$Res>(_self.config!, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [LegalConsentState].
extension LegalConsentStatePatterns on LegalConsentState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LegalConsentState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LegalConsentState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LegalConsentState value)  $default,){
final _that = this;
switch (_that) {
case _LegalConsentState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LegalConsentState value)?  $default,){
final _that = this;
switch (_that) {
case _LegalConsentState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( LegalConsentPhase phase,  bool consented,  bool termsRequired,  bool privacyRequired,  bool termsChecked,  bool privacyChecked,  LegalConfig? config,  LegalConsentMessage? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LegalConsentState() when $default != null:
return $default(_that.phase,_that.consented,_that.termsRequired,_that.privacyRequired,_that.termsChecked,_that.privacyChecked,_that.config,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( LegalConsentPhase phase,  bool consented,  bool termsRequired,  bool privacyRequired,  bool termsChecked,  bool privacyChecked,  LegalConfig? config,  LegalConsentMessage? message)  $default,) {final _that = this;
switch (_that) {
case _LegalConsentState():
return $default(_that.phase,_that.consented,_that.termsRequired,_that.privacyRequired,_that.termsChecked,_that.privacyChecked,_that.config,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( LegalConsentPhase phase,  bool consented,  bool termsRequired,  bool privacyRequired,  bool termsChecked,  bool privacyChecked,  LegalConfig? config,  LegalConsentMessage? message)?  $default,) {final _that = this;
switch (_that) {
case _LegalConsentState() when $default != null:
return $default(_that.phase,_that.consented,_that.termsRequired,_that.privacyRequired,_that.termsChecked,_that.privacyChecked,_that.config,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _LegalConsentState extends LegalConsentState {
  const _LegalConsentState({this.phase = LegalConsentPhase.idle, this.consented = false, this.termsRequired = false, this.privacyRequired = false, this.termsChecked = false, this.privacyChecked = false, this.config, this.message}): super._();
  

@override@JsonKey() final  LegalConsentPhase phase;
/// ログイン中のユーザーが現行の版に同意済みだと確認できているか。
/// 確認できるまでは false で、クラッシュ情報・利用状況を集めない
@override@JsonKey() final  bool consented;
/// その文書の行を表示するか
@override@JsonKey() final  bool termsRequired;
@override@JsonKey() final  bool privacyRequired;
/// その文書のチェックボックスがチェックされているか
@override@JsonKey() final  bool termsChecked;
@override@JsonKey() final  bool privacyChecked;
/// 判定に使った現行の規約の情報（送信する版数と閲覧画面の URL）
@override final  LegalConfig? config;
@override final  LegalConsentMessage? message;

/// Create a copy of LegalConsentState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegalConsentStateCopyWith<_LegalConsentState> get copyWith => __$LegalConsentStateCopyWithImpl<_LegalConsentState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LegalConsentState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.consented, consented) || other.consented == consented)&&(identical(other.termsRequired, termsRequired) || other.termsRequired == termsRequired)&&(identical(other.privacyRequired, privacyRequired) || other.privacyRequired == privacyRequired)&&(identical(other.termsChecked, termsChecked) || other.termsChecked == termsChecked)&&(identical(other.privacyChecked, privacyChecked) || other.privacyChecked == privacyChecked)&&(identical(other.config, config) || other.config == config)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,consented,termsRequired,privacyRequired,termsChecked,privacyChecked,config,message);
}

@override
String toString() {
    return 'LegalConsentState(phase: $phase, consented: $consented, termsRequired: $termsRequired, privacyRequired: $privacyRequired, termsChecked: $termsChecked, privacyChecked: $privacyChecked, config: $config, message: $message)';
}


}

/// @nodoc
abstract mixin class _$LegalConsentStateCopyWith<$Res> implements $LegalConsentStateCopyWith<$Res> {
  factory _$LegalConsentStateCopyWith(_LegalConsentState value, $Res Function(_LegalConsentState) _then) = __$LegalConsentStateCopyWithImpl;
@override @useResult
$Res call({
 LegalConsentPhase phase, bool consented, bool termsRequired, bool privacyRequired, bool termsChecked, bool privacyChecked, LegalConfig? config, LegalConsentMessage? message
});


@override $LegalConfigCopyWith<$Res>? get config;

}
/// @nodoc
class __$LegalConsentStateCopyWithImpl<$Res>
    implements _$LegalConsentStateCopyWith<$Res> {
  __$LegalConsentStateCopyWithImpl(this._self, this._then);

  final _LegalConsentState _self;
  final $Res Function(_LegalConsentState) _then;

/// Create a copy of LegalConsentState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? consented = null,Object? termsRequired = null,Object? privacyRequired = null,Object? termsChecked = null,Object? privacyChecked = null,Object? config = freezed,Object? message = freezed,}) {
  return _then(_LegalConsentState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as LegalConsentPhase,consented: null == consented ? _self.consented : consented // ignore: cast_nullable_to_non_nullable
as bool,termsRequired: null == termsRequired ? _self.termsRequired : termsRequired // ignore: cast_nullable_to_non_nullable
as bool,privacyRequired: null == privacyRequired ? _self.privacyRequired : privacyRequired // ignore: cast_nullable_to_non_nullable
as bool,termsChecked: null == termsChecked ? _self.termsChecked : termsChecked // ignore: cast_nullable_to_non_nullable
as bool,privacyChecked: null == privacyChecked ? _self.privacyChecked : privacyChecked // ignore: cast_nullable_to_non_nullable
as bool,config: freezed == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as LegalConfig?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as LegalConsentMessage?,
  ));
}

/// Create a copy of LegalConsentState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LegalConfigCopyWith<$Res>? get config {
    if (_self.config == null) {
    return null;
  }

  return $LegalConfigCopyWith<$Res>(_self.config!, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}

// dart format on
