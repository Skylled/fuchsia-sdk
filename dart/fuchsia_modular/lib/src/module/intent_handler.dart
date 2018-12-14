// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: one_member_abstracts
import 'intent.dart';

/// The [IntentHandler] class is an abstract class which is intended to be
/// extended by module authors to handle incoming intents. The class is
/// intended to be registered with the Module class inside of the module's main
/// method.
abstract class IntentHandler {
  /// This method is intended to be implemented by subclasses.
  /// It is called in response to the module receiving an [Intent].
  void handleIntent(Intent intent);
}
