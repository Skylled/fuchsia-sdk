// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_modular/fidl_async.dart' as fidl_modular;
import 'package:fidl_fuchsia_sys/fidl_async.dart' as fidl_sys;
import 'package:fuchsia_logger/logger.dart';
import 'package:fuchsia_services/services.dart' as fuchsia_services;

import '../internal/_component_context.dart';

/// Connect to the service specified by [serviceProxy] and implemented by the
/// agent with [agentUrl].
///
/// The agent will be launched if it's not already running.
void connectToAgentService<T>(
  String agentUrl,
  AsyncProxy<T> serviceProxy,
) {
  if (agentUrl == null || agentUrl.isEmpty) {
    throw Exception(
        'agentUrl must not be null or empty in call to connectToAgentService');
  }
  if (serviceProxy == null) {
    throw Exception(
        'serviceProxy must not be null in call to connectToAgentService');
  }

  final serviceProviderProxy = fidl_sys.ServiceProviderProxy();
  final agentControllerProxy = fidl_modular.AgentControllerProxy();

  // Creates an interface request and binds one of the channels. Binding this
  // channel prior to connecting to the agent allows the developer to make
  // proxy calls without awaiting for the connection to actually establish.
  final serviceProxyRequest = serviceProxy.ctrl.request();

  // Connect to the agent with agentUrl
  getComponentContext()
      .connectToAgent(
    agentUrl,
    serviceProviderProxy.ctrl.request(),
    agentControllerProxy.ctrl.request(),
  )
      .then((_) {
    // Connect to the service
    fuchsia_services
        .connectToService(
      serviceProviderProxy,
      serviceProxy.ctrl.$serviceName,
      serviceProxy.ctrl.$interfaceName,
      serviceProxyRequest,
    )
        .then((_) {
      // Close agent controller when the service proxy is closed
      serviceProxy.ctrl.whenClosed.then((_) {
        log.info('Service proxy [${serviceProxy.ctrl.$serviceName}] is closed. '
            'Closing the associated AgentControllerProxy.');
        agentControllerProxy.ctrl.close();
      });

      // Close all unnecessary bindings
      serviceProviderProxy.ctrl.close();
    });
  }).catchError((e) {
    serviceProviderProxy.ctrl.close();
    agentControllerProxy.ctrl.close();
    serviceProxyRequest.close();
    throw e;
  });
}
