// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';

import 'service_connection.dart';
import 'startup_context.dart';

/// Connects to the environment service specified by [serviceProxy].
///
/// Environment services are services that are implemented by the framework
/// itself.
void connectToEnvironmentService<T>(AsyncProxy<T> serviceProxy) {
  if (serviceProxy == null) {
    throw Exception(
        'serviceProxy must not be null in call to connectToEnvironmentService');
  }
  // Creates an interface request and binds one of the channels. Binding this
  // channel prior to connecting to the agent allows the developer to make
  // proxy calls without awaiting for the connection to actually establish.
  final serviceProxyRequest = serviceProxy.ctrl.request();

  connectToService(
    StartupContext.fromStartupInfo().environmentServices,
    serviceProxy.ctrl.$serviceName,
    serviceProxy.ctrl.$interfaceName,
    serviceProxyRequest,
  ).catchError((e) {
    serviceProxyRequest.close();
    throw e;
  });
}
