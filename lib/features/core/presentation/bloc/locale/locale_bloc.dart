import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/app_constants.dart';
import 'locale_event.dart';
import 'locale_state.dart';

class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  final SharedPreferences sharedPreferences;

  LocaleBloc({required this.sharedPreferences}) : super(const LocaleState()) {
    on<LoadLocale>(_onLoadLocale);
    on<ChangeLocale>(_onChangeLocale);
  }

  void _onLoadLocale(LoadLocale event, Emitter<LocaleState> emit) {
    final localeCode = sharedPreferences.getString(AppConstants.localeKey) ?? 'vi';
    emit(state.copyWith(locale: Locale(localeCode)));
  }

  void _onChangeLocale(ChangeLocale event, Emitter<LocaleState> emit) {
    sharedPreferences.setString(AppConstants.localeKey, event.locale.languageCode);
    emit(state.copyWith(locale: event.locale));
  }
}
