// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl_fuchsia_sys/fidl_async.dart' as fidl;
import 'package:meta/meta.dart';
import 'package:zircon/zircon.dart';
import 'package:fidl/fidl.dart';
import 'package:fuchsia/fuchsia.dart';

import 'service_provider_impl.dart';

/// The [StartupContext] holds references to the services and connections
/// that the component was launched with. Authors can get use the startup
/// context to access useful information for connecting to other components
/// and interacting with the framework.
class StartupContext {
  static StartupContext _context;

  /// The connection to the [fidl.Environment] proxy.
  final fidl.Environment environment;

  /// The connection to the [fidl.Launcher] proxy.
  final fidl.Launcher launcher;

  /// The [fidl.ServiceProvider] which can be used to connect to
  /// the services exposed to the component on launch.
  final fidl.ServiceProvider environmentServices;

  /// The service provider which can be used to expose outgoing services
  final ServiceProviderImpl outgoingServices;

  /// Creates a new instance of [StartupContext].
  ///
  /// See [StartupContext.fromStartupInfo].
  StartupContext({
    @required this.environment,
    @required this.launcher,
    @required this.environmentServices,
    @required this.outgoingServices,
  })  : assert(environment != null),
        assert(launcher != null),
        assert(environmentServices != null),
        assert(outgoingServices != null);

  /// Returns the [StartupContext] cached instance associated with the
  /// currently running component.
  ///
  /// Authors should use this method of obtaining the [StartupContext] instead
  /// of instantiating one on their own as it will bind and connect to all the
  /// underlying services for them.
  factory StartupContext.fromStartupInfo() {
    if (_context != null) {
      return _context;
    }

    final environmentProxy = fidl.EnvironmentProxy();
    final launcherProxy = fidl.LauncherProxy();
    final environmentServicesProxy = fidl.ServiceProviderProxy();
    final outgoingServicesImpl = ServiceProviderImpl();

    _context = StartupContext(
      environment: environmentProxy,
      launcher: launcherProxy,
      environmentServices: environmentServicesProxy,
      outgoingServices: outgoingServicesImpl,
    );

    final Handle environmentHandle = MxStartupInfo.takeEnvironment();
    if (environmentHandle != null) {
      environmentProxy
        ..ctrl
            .bind(InterfaceHandle<fidl.Environment>(Channel(environmentHandle)))
        ..getLauncher(launcherProxy.ctrl.request())
        ..getServices(environmentServicesProxy.ctrl.request());
    }

    final Handle outgoingServicesHandle = MxStartupInfo.takeOutgoingServices();
    if (outgoingServicesHandle != null) {
      outgoingServicesImpl.bind(InterfaceRequest<fidl.ServiceProvider>(
          Channel(outgoingServicesHandle)));
    }

    return _context;
  }
}
