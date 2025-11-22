// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => _DeviceInfo(
  platform: json['platform'] as String,
  deviceModel: json['deviceModel'] as String,
  osVersion: json['osVersion'] as String?,
  appVersion: json['appVersion'] as String?,
);

Map<String, dynamic> _$DeviceInfoToJson(_DeviceInfo instance) =>
    <String, dynamic>{
      'platform': instance.platform,
      'deviceModel': instance.deviceModel,
      'osVersion': instance.osVersion,
      'appVersion': instance.appVersion,
    };
