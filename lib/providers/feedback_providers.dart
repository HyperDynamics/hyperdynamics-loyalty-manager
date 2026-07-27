import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ToastTone { success, error, info }

class ToastMessage {
  const ToastMessage(this.message, this.tone);
  final String message;
  final ToastTone tone;
}

/// Transient toast — mirrors the prototype's `this.toast(msg, tone)`,
/// auto-dismissing after ~3.4s.
class ToastNotifier extends Notifier<ToastMessage?> {
  Timer? _timer;

  @override
  ToastMessage? build() => null;

  void show(String message, [ToastTone tone = ToastTone.success]) {
    _timer?.cancel();
    state = ToastMessage(message, tone);
    _timer = Timer(const Duration(milliseconds: 3400), () => state = null);
  }
}

final toastProvider = NotifierProvider<ToastNotifier, ToastMessage?>(ToastNotifier.new);

/// Global "busy" overlay — mirrors the prototype's `this.withLoading(msg, fn)`.
/// null = idle; non-null = show full-screen spinner with this message.
class BusyNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void start(String message) => state = message;
  void stop() => state = null;

  /// Runs [action], showing [message] for at least [minDuration] so fast
  /// operations don't just flash the overlay.
  Future<T> run<T>(String message, Future<T> Function() action,
      {Duration minDuration = const Duration(milliseconds: 500)}) async {
    start(message);
    final started = DateTime.now();
    try {
      final result = await action();
      final elapsed = DateTime.now().difference(started);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
      return result;
    } finally {
      stop();
    }
  }
}

final busyProvider = NotifierProvider<BusyNotifier, String?>(BusyNotifier.new);
