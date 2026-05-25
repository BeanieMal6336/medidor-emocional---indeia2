// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mood_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userProfileNotifierHash() =>
    r'16cfaf5c85495b350644b64a1d7c3a63051e0980';

/// See also [UserProfileNotifier].
@ProviderFor(UserProfileNotifier)
final userProfileNotifierProvider =
    AutoDisposeAsyncNotifierProvider<UserProfileNotifier, UserProfile>.internal(
  UserProfileNotifier.new,
  name: r'userProfileNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$userProfileNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserProfileNotifier = AutoDisposeAsyncNotifier<UserProfile>;
String _$moodNotifierHash() => r'1c476ccd8cb1f50156ddbd3d64c58b76ddb26696';

/// See also [MoodNotifier].
@ProviderFor(MoodNotifier)
final moodNotifierProvider =
    AutoDisposeAsyncNotifierProvider<MoodNotifier, List<EmotionEntry>>.internal(
  MoodNotifier.new,
  name: r'moodNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$moodNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MoodNotifier = AutoDisposeAsyncNotifier<List<EmotionEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
