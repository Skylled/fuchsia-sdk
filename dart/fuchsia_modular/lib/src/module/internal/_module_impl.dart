// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_modular/fidl_async.dart' as fidl;
import 'package:fidl_fuchsia_ui_viewsv1token/fidl_async.dart' as views_fidl;
import 'package:fuchsia_modular/lifecycle.dart';
import 'package:meta/meta.dart';

import '../embedded_module.dart';
import '../intent.dart';
import '../intent_handler.dart';
import '../module.dart';
import '../module_state_exception.dart';
import '_intent_handler_impl.dart';
import '_module_context.dart';

/// A concrete implementation of the [Module] interface. This class
/// is not intended to be used directly by authors but instead should
/// be used by the [Module] factory constructor.
class ModuleImpl implements Module {
  /// Holds a reference to the already registered intent handler
  IntentHandler _intentHandler;

  /// The intent handler host which will proxy intents to the registered
  /// intent handler
  // ignore: unused_field
  IntentHandlerImpl _intentHandlerImpl;

  /// Returns the [fidl.ModuleContext] for the running module.
  /// This variable should not be used directly. Use the
  /// [getContext()] method instead
  fidl.ModuleContext _moduleContext;

  /// The default constructor for this instance.
  ///
  /// the [moduleContext] is an optional parameter that
  /// can be supplied to override the default module context.
  /// This is mainly useful in testing scenarios.
  ModuleImpl({
    @required IntentHandlerImpl intentHandlerImpl,
    Lifecycle lifecycle,
    fidl.ModuleContext moduleContext,
  })  : _moduleContext = moduleContext,
        assert(intentHandlerImpl != null) {
    (lifecycle ??= Lifecycle()).addTerminateListener(_terminate);
    _intentHandlerImpl = intentHandlerImpl
      ..onHandleIntent = _proxyIntentToIntentHandler;
  }

  @override
  Future<fidl.ModuleController> addModuleToStory({
    @required String name,
    @required fidl.Intent intent,
    fidl.SurfaceRelation surfaceRelation = const fidl.SurfaceRelation(
      arrangement: fidl.SurfaceArrangement.copresent,
      dependency: fidl.SurfaceDependency.dependent,
      emphasis: 0.5,
    ),
  }) async {
    if (name == null || name.isEmpty) {
      throw ArgumentError.value(
          name, 'name', 'addModuleToStory should be called with a valid name');
    }
    if (intent == null) {
      throw ArgumentError.notNull('intent');
    }

    final moduleControllerProxy = fidl.ModuleControllerProxy();

    fidl.StartModuleStatus status = await _getContext().addModuleToStory(
        name, intent, moduleControllerProxy.ctrl.request(), surfaceRelation);

    _validateStartModuleStatus(status, name, intent);

    return moduleControllerProxy;
  }

  @override
  Future<EmbeddedModule> embedModule({
    @required String name,
    @required fidl.Intent intent,
  }) async {
    if (name == null || name.isEmpty) {
      throw ArgumentError.value(
          name, 'name', 'embedModule should be called with a valid name');
    }
    if (intent == null) {
      throw ArgumentError.notNull('intent');
    }

    final moduleController = fidl.ModuleControllerProxy();
    final viewOwner = new InterfacePair<views_fidl.ViewOwner>();
    final status = await _getContext().embedModule(
        name, intent, moduleController.ctrl.request(), viewOwner.passRequest());

    _validateStartModuleStatus(status, name, intent);

    return EmbeddedModule(
        moduleController: moduleController, viewOwner: viewOwner.passHandle());
  }

  @override
  void registerIntentHandler(IntentHandler intentHandler) {
    if (_intentHandler != null) {
      throw ModuleStateException(
          'Intent handler registration failed because a handler is already '
          'registered.');
    }

    _intentHandler = intentHandler;
  }

  @override
  void requestFocus() {
    _getContext().requestFocus();
  }

  @override
  void removeSelfFromStory() {
    _getContext().removeSelfFromStory();
  }

  fidl.ModuleContext _getContext() => _moduleContext ??= getModuleContext();

  void _proxyIntentToIntentHandler(Intent intent) {
    if (_intentHandler == null) {
      throw ModuleStateException(
          'Module received an intent but no intent handler was registered to '
          'receive it. If you do not intend to handle intents but you still '
          'need to use the module functionality register a NoopIntentHandler '
          'to explicitly declare that you will not handle the intent.');
    }
    _intentHandler.handleIntent(intent);
  }

  Future<void> _terminate() async {
    _intentHandler = null;
  }

  // any necessary cleanup should be done in this method.
  void _validateStartModuleStatus(
      fidl.StartModuleStatus status, String name, fidl.Intent intent) {
    switch (status) {
      case fidl.StartModuleStatus.success:
        break;
      case fidl.StartModuleStatus.noModulesFound:
        throw ModuleResolutionException(
            'no modules found for intent [$intent]');
        break;
      default:
        throw ModuleStateException(
            'unknown start module status [$status] for intent [$intent]');
    }
  }
}

/// When Module resolution fails.
class ModuleResolutionException implements Exception {
  /// Information about the failure.
  final String message;

  /// Create a new [ModuleResolutionException].
  ModuleResolutionException(this.message);
}
