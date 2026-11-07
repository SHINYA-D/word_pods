// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'legal_consent.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LegalConfig {

 String get termsVersion; String get privacyVersion; String get termsUrl; String get privacyUrl;
/// Create a copy of LegalConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalConfigCopyWith<LegalConfig> get copyWith => _$LegalConfigCopyWithImpl<LegalConfig>(this as LegalConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LegalConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalConfig&&(identical(other.termsVersion, _this.termsVersion) || other.termsVersion == _this.termsVersion)&&(identical(other.privacyVersion, _this.privacyVersion) || other.privacyVersion == _this.privacyVersion)&&(identical(other.termsUrl, _this.termsUrl) || other.termsUrl == _this.termsUrl)&&(identical(other.privacyUrl, _this.privacyUrl) || other.privacyUrl == _this.privacyUrl));
}


@override
int get hashCode {
  final _this = this as LegalConfig;
  return Object.hash(runtimeType,_this.termsVersion,_this.privacyVersion,_this.termsUrl,_this.privacyUrl);
}

@override
String toString() {
  final _this = this as LegalConfig;
  return 'LegalConfig(termsVersion: ${_this.termsVersion}, privacyVersion: ${_this.privacyVersion}, termsUrl: ${_this.termsUrl}, privacyUrl: ${_this.privacyUrl})';
}


}

/// @nodoc
abstract mixin class $LegalConfigCopyWith<$Res>  {
  factory $LegalConfigCopyWith(LegalConfig value, $Res Function(LegalConfig) _then) = _$LegalConfigCopyWithImpl;
@useResult
$Res call({
 String termsVersion, String privacyVersion, String termsUrl, String privacyUrl
});




}
/// @nodoc
class _$LegalConfigCopyWithImpl<$Res>
    implements $LegalConfigCopyWith<$Res> {
  _$LegalConfigCopyWithImpl(this._self, this._then);

  final LegalConfig _self;
  final $Res Function(LegalConfig) _then;

/// Create a copy of LegalConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? termsVersion = null,Object? privacyVersion = null,Object? termsUrl = null,Object? privacyUrl = null,}) {
  return _then(LegalConfig(
termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as String,privacyVersion: null == privacyVersion ? _self.privacyVersion : privacyVersion // ignore: cast_nullable_to_non_nullable
as String,termsUrl: null == termsUrl ? _self.termsUrl : termsUrl // ignore: cast_nullable_to_non_nullable
as String,privacyUrl: null == privacyUrl ? _self.privacyUrl : privacyUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LegalConfig].
extension LegalConfigPatterns on LegalConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LegalConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LegalConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LegalConfig value)  $default,){
final _that = this;
switch (_that) {
case _LegalConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LegalConfig value)?  $default,){
final _that = this;
switch (_that) {
case _LegalConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String termsVersion,  String privacyVersion,  String termsUrl,  String privacyUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LegalConfig() when $default != null:
return $default(_that.termsVersion,_that.privacyVersion,_that.termsUrl,_that.privacyUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String termsVersion,  String privacyVersion,  String termsUrl,  String privacyUrl)  $default,) {final _that = this;
switch (_that) {
case _LegalConfig():
return $default(_that.termsVersion,_that.privacyVersion,_that.termsUrl,_that.privacyUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String termsVersion,  String privacyVersion,  String termsUrl,  String privacyUrl)?  $default,) {final _that = this;
switch (_that) {
case _LegalConfig() when $default != null:
return $default(_that.termsVersion,_that.privacyVersion,_that.termsUrl,_that.privacyUrl);case _:
  return null;

}
}

}

/// @nodoc


class _LegalConfig implements LegalConfig {
  const _LegalConfig({required this.termsVersion, required this.privacyVersion, required this.termsUrl, required this.privacyUrl});
  

@override final  String termsVersion;
@override final  String privacyVersion;
@override final  String termsUrl;
@override final  String privacyUrl;

/// Create a copy of LegalConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegalConfigCopyWith<_LegalConfig> get copyWith => __$LegalConfigCopyWithImpl<_LegalConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LegalConfig&&(identical(other.termsVersion, termsVersion) || other.termsVersion == termsVersion)&&(identical(other.privacyVersion, privacyVersion) || other.privacyVersion == privacyVersion)&&(identical(other.termsUrl, termsUrl) || other.termsUrl == termsUrl)&&(identical(other.privacyUrl, privacyUrl) || other.privacyUrl == privacyUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,termsVersion,privacyVersion,termsUrl,privacyUrl);
}

@override
String toString() {
    return 'LegalConfig(termsVersion: $termsVersion, privacyVersion: $privacyVersion, termsUrl: $termsUrl, privacyUrl: $privacyUrl)';
}


}

/// @nodoc
abstract mixin class _$LegalConfigCopyWith<$Res> implements $LegalConfigCopyWith<$Res> {
  factory _$LegalConfigCopyWith(_LegalConfig value, $Res Function(_LegalConfig) _then) = __$LegalConfigCopyWithImpl;
@override @useResult
$Res call({
 String termsVersion, String privacyVersion, String termsUrl, String privacyUrl
});




}
/// @nodoc
class __$LegalConfigCopyWithImpl<$Res>
    implements _$LegalConfigCopyWith<$Res> {
  __$LegalConfigCopyWithImpl(this._self, this._then);

  final _LegalConfig _self;
  final $Res Function(_LegalConfig) _then;

/// Create a copy of LegalConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? termsVersion = null,Object? privacyVersion = null,Object? termsUrl = null,Object? privacyUrl = null,}) {
  return _then(_LegalConfig(
termsVersion: null == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as String,privacyVersion: null == privacyVersion ? _self.privacyVersion : privacyVersion // ignore: cast_nullable_to_non_nullable
as String,termsUrl: null == termsUrl ? _self.termsUrl : termsUrl // ignore: cast_nullable_to_non_nullable
as String,privacyUrl: null == privacyUrl ? _self.privacyUrl : privacyUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$LegalConsents {

 String? get termsVersion; String? get privacyVersion;
/// Create a copy of LegalConsents
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalConsentsCopyWith<LegalConsents> get copyWith => _$LegalConsentsCopyWithImpl<LegalConsents>(this as LegalConsents, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LegalConsents;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalConsents&&(identical(other.termsVersion, _this.termsVersion) || other.termsVersion == _this.termsVersion)&&(identical(other.privacyVersion, _this.privacyVersion) || other.privacyVersion == _this.privacyVersion));
}


@override
int get hashCode {
  final _this = this as LegalConsents;
  return Object.hash(runtimeType,_this.termsVersion,_this.privacyVersion);
}

@override
String toString() {
  final _this = this as LegalConsents;
  return 'LegalConsents(termsVersion: ${_this.termsVersion}, privacyVersion: ${_this.privacyVersion})';
}


}

/// @nodoc
abstract mixin class $LegalConsentsCopyWith<$Res>  {
  factory $LegalConsentsCopyWith(LegalConsents value, $Res Function(LegalConsents) _then) = _$LegalConsentsCopyWithImpl;
@useResult
$Res call({
 String? termsVersion, String? privacyVersion
});




}
/// @nodoc
class _$LegalConsentsCopyWithImpl<$Res>
    implements $LegalConsentsCopyWith<$Res> {
  _$LegalConsentsCopyWithImpl(this._self, this._then);

  final LegalConsents _self;
  final $Res Function(LegalConsents) _then;

/// Create a copy of LegalConsents
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? termsVersion = freezed,Object? privacyVersion = freezed,}) {
  return _then(LegalConsents(
termsVersion: freezed == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as String?,privacyVersion: freezed == privacyVersion ? _self.privacyVersion : privacyVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LegalConsents].
extension LegalConsentsPatterns on LegalConsents {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LegalConsents value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LegalConsents() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LegalConsents value)  $default,){
final _that = this;
switch (_that) {
case _LegalConsents():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LegalConsents value)?  $default,){
final _that = this;
switch (_that) {
case _LegalConsents() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? termsVersion,  String? privacyVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LegalConsents() when $default != null:
return $default(_that.termsVersion,_that.privacyVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? termsVersion,  String? privacyVersion)  $default,) {final _that = this;
switch (_that) {
case _LegalConsents():
return $default(_that.termsVersion,_that.privacyVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? termsVersion,  String? privacyVersion)?  $default,) {final _that = this;
switch (_that) {
case _LegalConsents() when $default != null:
return $default(_that.termsVersion,_that.privacyVersion);case _:
  return null;

}
}

}

/// @nodoc


class _LegalConsents implements LegalConsents {
  const _LegalConsents({this.termsVersion, this.privacyVersion});
  

@override final  String? termsVersion;
@override final  String? privacyVersion;

/// Create a copy of LegalConsents
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegalConsentsCopyWith<_LegalConsents> get copyWith => __$LegalConsentsCopyWithImpl<_LegalConsents>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LegalConsents&&(identical(other.termsVersion, termsVersion) || other.termsVersion == termsVersion)&&(identical(other.privacyVersion, privacyVersion) || other.privacyVersion == privacyVersion));
}


@override
int get hashCode {
    return Object.hash(runtimeType,termsVersion,privacyVersion);
}

@override
String toString() {
    return 'LegalConsents(termsVersion: $termsVersion, privacyVersion: $privacyVersion)';
}


}

/// @nodoc
abstract mixin class _$LegalConsentsCopyWith<$Res> implements $LegalConsentsCopyWith<$Res> {
  factory _$LegalConsentsCopyWith(_LegalConsents value, $Res Function(_LegalConsents) _then) = __$LegalConsentsCopyWithImpl;
@override @useResult
$Res call({
 String? termsVersion, String? privacyVersion
});




}
/// @nodoc
class __$LegalConsentsCopyWithImpl<$Res>
    implements _$LegalConsentsCopyWith<$Res> {
  __$LegalConsentsCopyWithImpl(this._self, this._then);

  final _LegalConsents _self;
  final $Res Function(_LegalConsents) _then;

/// Create a copy of LegalConsents
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? termsVersion = freezed,Object? privacyVersion = freezed,}) {
  return _then(_LegalConsents(
termsVersion: freezed == termsVersion ? _self.termsVersion : termsVersion // ignore: cast_nullable_to_non_nullable
as String?,privacyVersion: freezed == privacyVersion ? _self.privacyVersion : privacyVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$LegalConsentRequirement {

 bool get termsRequired; bool get privacyRequired;/// 判定に使った現行の規約の情報（送信する版数と、閲覧画面の URL に使う）
 LegalConfig get config;
/// Create a copy of LegalConsentRequirement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LegalConsentRequirementCopyWith<LegalConsentRequirement> get copyWith => _$LegalConsentRequirementCopyWithImpl<LegalConsentRequirement>(this as LegalConsentRequirement, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LegalConsentRequirement;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LegalConsentRequirement&&(identical(other.termsRequired, _this.termsRequired) || other.termsRequired == _this.termsRequired)&&(identical(other.privacyRequired, _this.privacyRequired) || other.privacyRequired == _this.privacyRequired)&&(identical(other.config, _this.config) || other.config == _this.config));
}


@override
int get hashCode {
  final _this = this as LegalConsentRequirement;
  return Object.hash(runtimeType,_this.termsRequired,_this.privacyRequired,_this.config);
}

@override
String toString() {
  final _this = this as LegalConsentRequirement;
  return 'LegalConsentRequirement(termsRequired: ${_this.termsRequired}, privacyRequired: ${_this.privacyRequired}, config: ${_this.config})';
}


}

/// @nodoc
abstract mixin class $LegalConsentRequirementCopyWith<$Res>  {
  factory $LegalConsentRequirementCopyWith(LegalConsentRequirement value, $Res Function(LegalConsentRequirement) _then) = _$LegalConsentRequirementCopyWithImpl;
@useResult
$Res call({
 bool termsRequired, bool privacyRequired, LegalConfig config
});


$LegalConfigCopyWith<$Res> get config;

}
/// @nodoc
class _$LegalConsentRequirementCopyWithImpl<$Res>
    implements $LegalConsentRequirementCopyWith<$Res> {
  _$LegalConsentRequirementCopyWithImpl(this._self, this._then);

  final LegalConsentRequirement _self;
  final $Res Function(LegalConsentRequirement) _then;

/// Create a copy of LegalConsentRequirement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? termsRequired = null,Object? privacyRequired = null,Object? config = null,}) {
  return _then(LegalConsentRequirement(
termsRequired: null == termsRequired ? _self.termsRequired : termsRequired // ignore: cast_nullable_to_non_nullable
as bool,privacyRequired: null == privacyRequired ? _self.privacyRequired : privacyRequired // ignore: cast_nullable_to_non_nullable
as bool,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as LegalConfig,
  ));
}
/// Create a copy of LegalConsentRequirement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LegalConfigCopyWith<$Res> get config {
  
  return $LegalConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}


/// Adds pattern-matching-related methods to [LegalConsentRequirement].
extension LegalConsentRequirementPatterns on LegalConsentRequirement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LegalConsentRequirement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LegalConsentRequirement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LegalConsentRequirement value)  $default,){
final _that = this;
switch (_that) {
case _LegalConsentRequirement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LegalConsentRequirement value)?  $default,){
final _that = this;
switch (_that) {
case _LegalConsentRequirement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool termsRequired,  bool privacyRequired,  LegalConfig config)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LegalConsentRequirement() when $default != null:
return $default(_that.termsRequired,_that.privacyRequired,_that.config);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool termsRequired,  bool privacyRequired,  LegalConfig config)  $default,) {final _that = this;
switch (_that) {
case _LegalConsentRequirement():
return $default(_that.termsRequired,_that.privacyRequired,_that.config);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool termsRequired,  bool privacyRequired,  LegalConfig config)?  $default,) {final _that = this;
switch (_that) {
case _LegalConsentRequirement() when $default != null:
return $default(_that.termsRequired,_that.privacyRequired,_that.config);case _:
  return null;

}
}

}

/// @nodoc


class _LegalConsentRequirement extends LegalConsentRequirement {
  const _LegalConsentRequirement({required this.termsRequired, required this.privacyRequired, required this.config}): super._();
  

@override final  bool termsRequired;
@override final  bool privacyRequired;
/// 判定に使った現行の規約の情報（送信する版数と、閲覧画面の URL に使う）
@override final  LegalConfig config;

/// Create a copy of LegalConsentRequirement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LegalConsentRequirementCopyWith<_LegalConsentRequirement> get copyWith => __$LegalConsentRequirementCopyWithImpl<_LegalConsentRequirement>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _LegalConsentRequirement&&(identical(other.termsRequired, termsRequired) || other.termsRequired == termsRequired)&&(identical(other.privacyRequired, privacyRequired) || other.privacyRequired == privacyRequired)&&(identical(other.config, config) || other.config == config));
}


@override
int get hashCode {
    return Object.hash(runtimeType,termsRequired,privacyRequired,config);
}

@override
String toString() {
    return 'LegalConsentRequirement(termsRequired: $termsRequired, privacyRequired: $privacyRequired, config: $config)';
}


}

/// @nodoc
abstract mixin class _$LegalConsentRequirementCopyWith<$Res> implements $LegalConsentRequirementCopyWith<$Res> {
  factory _$LegalConsentRequirementCopyWith(_LegalConsentRequirement value, $Res Function(_LegalConsentRequirement) _then) = __$LegalConsentRequirementCopyWithImpl;
@override @useResult
$Res call({
 bool termsRequired, bool privacyRequired, LegalConfig config
});


@override $LegalConfigCopyWith<$Res> get config;

}
/// @nodoc
class __$LegalConsentRequirementCopyWithImpl<$Res>
    implements _$LegalConsentRequirementCopyWith<$Res> {
  __$LegalConsentRequirementCopyWithImpl(this._self, this._then);

  final _LegalConsentRequirement _self;
  final $Res Function(_LegalConsentRequirement) _then;

/// Create a copy of LegalConsentRequirement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? termsRequired = null,Object? privacyRequired = null,Object? config = null,}) {
  return _then(_LegalConsentRequirement(
termsRequired: null == termsRequired ? _self.termsRequired : termsRequired // ignore: cast_nullable_to_non_nullable
as bool,privacyRequired: null == privacyRequired ? _self.privacyRequired : privacyRequired // ignore: cast_nullable_to_non_nullable
as bool,config: null == config ? _self.config : config // ignore: cast_nullable_to_non_nullable
as LegalConfig,
  ));
}

/// Create a copy of LegalConsentRequirement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LegalConfigCopyWith<$Res> get config {
  
  return $LegalConfigCopyWith<$Res>(_self.config, (value) {
    return _then(_self.copyWith(config: value));
  });
}
}

// dart format on
