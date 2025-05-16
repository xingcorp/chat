part of 'locale_cubit.dart';

/// State class for LocaleCubit representing the current locale configuration
class LocaleState extends Equatable {
  /// The currently selected locale, or null for system default
  final Locale? locale;

  /// Creates a LocaleState instance
  /// 
  /// [locale] is the currently selected locale, or null for system default
  const LocaleState({this.locale});

  /// Creates a copy of this state with the specified locale
  /// 
  /// [locale] is the new locale to set
  LocaleState copyWith({
    Locale? locale,
  }) {
    return LocaleState(
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [locale];
} 