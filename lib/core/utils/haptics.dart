/// Tactical haptic feedback wrapper.
/// Gracefully degrades when haptics are unavailable.
import 'package:flutter/services.dart';

/// Light tap — tab switches, toggles.
void tapLight() {
  try {
    HapticFeedback.lightImpact();
  } catch (_) {}
}

/// Medium tap — button presses, card expand.
void tapMedium() {
  try {
    HapticFeedback.mediumImpact();
  } catch (_) {}
}

/// Heavy tap — waypoint set, important actions.
void tapHeavy() {
  try {
    HapticFeedback.heavyImpact();
  } catch (_) {}
}

/// Success — copy complete, waypoint saved.
void notifySuccess() {
  try {
    HapticFeedback.lightImpact();
  } catch (_) {}
}

/// Warning — error, invalid input.
void notifyWarning() {
  try {
    HapticFeedback.mediumImpact();
  } catch (_) {}
}

/// Error — critical failure.
void notifyError() {
  try {
    HapticFeedback.heavyImpact();
  } catch (_) {}
}

/// Selection tick — scrolling through options.
void selectionTick() {
  try {
    HapticFeedback.selectionClick();
  } catch (_) {}
}
