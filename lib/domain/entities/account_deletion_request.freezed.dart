// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_deletion_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountDeletionRequest {

 String get userId; AccountDeletionStatus get status; DateTime get updatedAt;
/// Create a copy of AccountDeletionRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountDeletionRequestCopyWith<AccountDeletionRequest> get copyWith => _$AccountDeletionRequestCopyWithImpl<AccountDeletionRequest>(this as AccountDeletionRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AccountDeletionRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountDeletionRequest&&(identical(other.userId, _this.userId) || other.userId == _this.userId)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt));
}


@override
int get hashCode {
  final _this = this as AccountDeletionRequest;
  return Object.hash(runtimeType,_this.userId,_this.status,_this.updatedAt);
}

@override
String toString() {
  final _this = this as AccountDeletionRequest;
  return 'AccountDeletionRequest(userId: ${_this.userId}, status: ${_this.status}, updatedAt: ${_this.updatedAt})';
}


}

/// @nodoc
abstract mixin class $AccountDeletionRequestCopyWith<$Res>  {
  factory $AccountDeletionRequestCopyWith(AccountDeletionRequest value, $Res Function(AccountDeletionRequest) _then) = _$AccountDeletionRequestCopyWithImpl;
@useResult
$Res call({
 String userId, AccountDeletionStatus status, DateTime updatedAt
});




}
/// @nodoc
class _$AccountDeletionRequestCopyWithImpl<$Res>
    implements $AccountDeletionRequestCopyWith<$Res> {
  _$AccountDeletionRequestCopyWithImpl(this._self, this._then);

  final AccountDeletionRequest _self;
  final $Res Function(AccountDeletionRequest) _then;

/// Create a copy of AccountDeletionRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? status = null,Object? updatedAt = null,}) {
  return _then(AccountDeletionRequest(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AccountDeletionStatus,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountDeletionRequest].
extension AccountDeletionRequestPatterns on AccountDeletionRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountDeletionRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountDeletionRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountDeletionRequest value)  $default,){
final _that = this;
switch (_that) {
case _AccountDeletionRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountDeletionRequest value)?  $default,){
final _that = this;
switch (_that) {
case _AccountDeletionRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  AccountDeletionStatus status,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountDeletionRequest() when $default != null:
return $default(_that.userId,_that.status,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  AccountDeletionStatus status,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _AccountDeletionRequest():
return $default(_that.userId,_that.status,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  AccountDeletionStatus status,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _AccountDeletionRequest() when $default != null:
return $default(_that.userId,_that.status,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _AccountDeletionRequest implements AccountDeletionRequest {
  const _AccountDeletionRequest({required this.userId, required this.status, required this.updatedAt});
  

@override final  String userId;
@override final  AccountDeletionStatus status;
@override final  DateTime updatedAt;

/// Create a copy of AccountDeletionRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountDeletionRequestCopyWith<_AccountDeletionRequest> get copyWith => __$AccountDeletionRequestCopyWithImpl<_AccountDeletionRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountDeletionRequest&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.status, status) || other.status == status)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,userId,status,updatedAt);
}

@override
String toString() {
    return 'AccountDeletionRequest(userId: $userId, status: $status, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AccountDeletionRequestCopyWith<$Res> implements $AccountDeletionRequestCopyWith<$Res> {
  factory _$AccountDeletionRequestCopyWith(_AccountDeletionRequest value, $Res Function(_AccountDeletionRequest) _then) = __$AccountDeletionRequestCopyWithImpl;
@override @useResult
$Res call({
 String userId, AccountDeletionStatus status, DateTime updatedAt
});




}
/// @nodoc
class __$AccountDeletionRequestCopyWithImpl<$Res>
    implements _$AccountDeletionRequestCopyWith<$Res> {
  __$AccountDeletionRequestCopyWithImpl(this._self, this._then);

  final _AccountDeletionRequest _self;
  final $Res Function(_AccountDeletionRequest) _then;

/// Create a copy of AccountDeletionRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? status = null,Object? updatedAt = null,}) {
  return _then(_AccountDeletionRequest(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AccountDeletionStatus,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
