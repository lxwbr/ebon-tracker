import 'package:meta/meta.dart';

@immutable
class MainState {
  final double loading;

  const MainState({required this.loading});

  factory MainState.initial() => const MainState(loading: 0.0);

  MainState copyWith({required double loading}) {
    return MainState(loading: loading);
  }
}
