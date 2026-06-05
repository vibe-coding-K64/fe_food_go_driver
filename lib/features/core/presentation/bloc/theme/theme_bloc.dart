import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/app_constants.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SharedPreferences sharedPreferences;

  ThemeBloc({required this.sharedPreferences}) : super(const ThemeState()) {
    on<LoadTheme>(_onLoadTheme);
    on<ToggleTheme>(_onToggleTheme);
    on<SetTheme>(_onSetTheme);
  }

  void _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) {
    final isDark = sharedPreferences.getBool(AppConstants.themeKey) ?? false;
    emit(state.copyWith(
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
    ));
  }

  void _onToggleTheme(ToggleTheme event, Emitter<ThemeState> emit) {
    final newIsDark = !state.isDarkMode;
    sharedPreferences.setBool(AppConstants.themeKey, newIsDark);
    emit(state.copyWith(
      themeMode: newIsDark ? ThemeMode.dark : ThemeMode.light,
    ));
  }

  void _onSetTheme(SetTheme event, Emitter<ThemeState> emit) {
    sharedPreferences.setBool(AppConstants.themeKey, event.isDark);
    emit(state.copyWith(
      themeMode: event.isDark ? ThemeMode.dark : ThemeMode.light,
    ));
  }
}
