// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verify_email_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VerifyEmailState {

/// 「確認しました」の問い合わせ中
 bool get isChecking;/// 確認メールの再送中
 bool get isResending;/// 「ログイン画面へ」のログアウト中
 bool get isSigningOut;/// スナックバーに出すメッセージ。画面が表示したら [VerifyEmailViewModel.clearMessage] で消す
 VerifyEmailMessage? get message;
/// Create a copy of VerifyEmailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerifyEmailStateCopyWith<VerifyEmailState> get copyWith => _$VerifyEmailStateCopyWithImpl<VerifyEmailState>(this as VerifyEmailState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VerifyEmailState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerifyEmailState&&(identical(other.isChecking, _this.isChecking) || other.isChecking == _this.isChecking)&&(identical(other.isResending, _this.isResending) || other.isResending == _this.isResending)&&(identical(other.isSigningOut, _this.isSigningOut) || other.isSigningOut == _this.isSigningOut)&&(identical(other.message, _this.message) || other.message == _this.message));
}


@override
int get hashCode {
  final _this = this as VerifyEmailState;
  return Object.hash(runtimeType,_this.isChecking,_this.isResending,_this.isSigningOut,_this.message);
}

@override
String toString() {
  final _this = this as VerifyEmailState;
  return 'VerifyEmailState(isChecking: ${_this.isChecking}, isResending: ${_this.isResending}, isSigningOut: ${_this.isSigningOut}, message: ${_this.message})';
}


}

/// @nodoc
abstract mixin class $VerifyEmailStateCopyWith<$Res>  {
  factory $VerifyEmailStateCopyWith(VerifyEmailState value, $Res Function(VerifyEmailState) _then) = _$VerifyEmailStateCopyWithImpl;
@useResult
$Res call({
 bool isChecking, bool isResending, bool isSigningOut, VerifyEmailMessage? message
});




}
/// @nodoc
class _$VerifyEmailStateCopyWithImpl<$Res>
    implements $VerifyEmailStateCopyWith<$Res> {
  _$VerifyEmailStateCopyWithImpl(this._self, this._then);

  final VerifyEmailState _self;
  final $Res Function(VerifyEmailState) _then;

/// Create a copy of VerifyEmailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isChecking = null,Object? isResending = null,Object? isSigningOut = null,Object? message = freezed,}) {
  return _then(VerifyEmailState(
isChecking: null == isChecking ? _self.isChecking : isChecking // ignore: cast_nullable_to_non_nullable
as bool,isResending: null == isResending ? _self.isResending : isResending // ignore: cast_nullable_to_non_nullable
as bool,isSigningOut: null == isSigningOut ? _self.isSigningOut : isSigningOut // ignore: cast_nullable_to_non_nullable
as bool,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as VerifyEmailMessage?,
  ));
}

}


/// Adds pattern-matching-related methods to [VerifyEmailState].
extension VerifyEmailStatePatterns on VerifyEmailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerifyEmailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerifyEmailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerifyEmailState value)  $default,){
final _that = this;
switch (_that) {
case _VerifyEmailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerifyEmailState value)?  $default,){
final _that = this;
switch (_that) {
case _VerifyEmailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isChecking,  bool isResending,  bool isSigningOut,  VerifyEmailMessage? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerifyEmailState() when $default != null:
return $default(_that.isChecking,_that.isResending,_that.isSigningOut,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isChecking,  bool isResending,  bool isSigningOut,  VerifyEmailMessage? message)  $default,) {final _that = this;
switch (_that) {
case _VerifyEmailState():
return $default(_that.isChecking,_that.isResending,_that.isSigningOut,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isChecking,  bool isResending,  bool isSigningOut,  VerifyEmailMessage? message)?  $default,) {final _that = this;
switch (_that) {
case _VerifyEmailState() when $default != null:
return $default(_that.isChecking,_that.isResending,_that.isSigningOut,_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _VerifyEmailState implements VerifyEmailState {
  const _VerifyEmailState({this.isChecking = false, this.isResending = false, this.isSigningOut = false, this.message});
  

/// 「確認しました」の問い合わせ中
@override@JsonKey() final  bool isChecking;
/// 確認メールの再送中
@override@JsonKey() final  bool isResending;
/// 「ログイン画面へ」のログアウト中
@override@JsonKey() final  bool isSigningOut;
/// スナックバーに出すメッセージ。画面が表示したら [VerifyEmailViewModel.clearMessage] で消す
@override final  VerifyEmailMessage? message;

/// Create a copy of VerifyEmailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerifyEmailStateCopyWith<_VerifyEmailState> get copyWith => __$VerifyEmailStateCopyWithImpl<_VerifyEmailState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerifyEmailState&&(identical(other.isChecking, isChecking) || other.isChecking == isChecking)&&(identical(other.isResending, isResending) || other.isResending == isResending)&&(identical(other.isSigningOut, isSigningOut) || other.isSigningOut == isSigningOut)&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isChecking,isResending,isSigningOut,message);
}

@override
String toString() {
    return 'VerifyEmailState(isChecking: $isChecking, isResending: $isResending, isSigningOut: $isSigningOut, message: $message)';
}


}

/// @nodoc
abstract mixin class _$VerifyEmailStateCopyWith<$Res> implements $VerifyEmailStateCopyWith<$Res> {
  factory _$VerifyEmailStateCopyWith(_VerifyEmailState value, $Res Function(_VerifyEmailState) _then) = __$VerifyEmailStateCopyWithImpl;
@override @useResult
$Res call({
 bool isChecking, bool isResending, bool isSigningOut, VerifyEmailMessage? message
});




}
/// @nodoc
class __$VerifyEmailStateCopyWithImpl<$Res>
    implements _$VerifyEmailStateCopyWith<$Res> {
  __$VerifyEmailStateCopyWithImpl(this._self, this._then);

  final _VerifyEmailState _self;
  final $Res Function(_VerifyEmailState) _then;

/// Create a copy of VerifyEmailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isChecking = null,Object? isResending = null,Object? isSigningOut = null,Object? message = freezed,}) {
  return _then(_VerifyEmailState(
isChecking: null == isChecking ? _self.isChecking : isChecking // ignore: cast_nullable_to_non_nullable
as bool,isResending: null == isResending ? _self.isResending : isResending // ignore: cast_nullable_to_non_nullable
as bool,isSigningOut: null == isSigningOut ? _self.isSigningOut : isSigningOut // ignore: cast_nullable_to_non_nullable
as bool,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as VerifyEmailMessage?,
  ));
}


}

// dart format on
