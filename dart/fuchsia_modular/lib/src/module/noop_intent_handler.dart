// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'intent.dart';
import 'intent_handler.dart';

/// A concrete implementation of the [IntentHandler] class. This class
/// is intended to be used a a signal that the module will explicitly
/// __not__ handle an intent.
///
/// ```
/// void main() {
///   Module()
///    ..registerIntentHandler(NoopIntentHandler());
/// }
/// ```
class NoopIntentHandler extends IntentHandler {
  @override
  void handleIntent(Intent intent) {}
}
