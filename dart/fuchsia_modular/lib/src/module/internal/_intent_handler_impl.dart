// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_modular/fidl_async.dart' as fidl;
import 'package:fuchsia_services/services.dart';
import 'package:fuchsia_modular/lifecycle.dart';

import '../intent.dart';
import '_fidl_transformers.dart';

/// A concrete implementation of the [fidl.IntentHandler] interface.
/// This class not intended to be used directly by authors but instead should
/// be used by classes which need to expose the [fidl.IntentHandler] interface
/// and forward intents to handlers. See the Module class for an example of
/// this in practice.
///
/// Note: This class must be exposed to the framework before it attempts to
/// call handle intent or there is a risk of missing intents.
class IntentHandlerImpl extends fidl.IntentHandler {
  fidl.IntentHandlerBinding _intentHandlerBinding;

  /// A function which is invoked when the host receives a [handleIntent] call.
  void Function(Intent intent) onHandleIntent;

  /// The constructor for the [IntentHandlerImpl].
  /// The [startupContext] is an optional parameter that will
  /// default to using [StartupContext.fromStartupInfo] if not present.
  IntentHandlerImpl({StartupContext startupContext}) {
    _exposeService(startupContext ?? StartupContext.fromStartupInfo());
    Lifecycle().addTerminateListener(_terminate);
  }

  // Note: this method needs to run before the first iteration of
  // the event loop or the framework will not bind to it.
  @override
  Future<void> handleIntent(fidl.Intent intent) async {
    if (onHandleIntent == null) {
      return null;
    }
    // convert to the non-fidl intent.
    onHandleIntent(convertFidlIntentToIntent(intent));
  }

  void _clearBinding() {
    if (_intentHandlerBinding != null && _intentHandlerBinding.isBound) {
      _intentHandlerBinding.unbind();
      _intentHandlerBinding = null;
    }
  }

  // any necessary cleanup should be done in this method.
  void _exposeService(StartupContext startupContext) {
    startupContext.outgoingServices.addServiceForName(
      (InterfaceRequest<fidl.IntentHandler> request) {
        _clearBinding();
        _intentHandlerBinding = fidl.IntentHandlerBinding()
          ..bind(this, request);
      },
      fidl.IntentHandler.$serviceName,
    );
  }

  Future<void> _terminate() async {
    _clearBinding();
    onHandleIntent = null;
  }
}
