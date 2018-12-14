// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_sys/fidl_async.dart' as fidl_sys;

/// Connects to the specified service using the given [serviceProvider].
///
/// It is recommended to not use this method directly but rather to use the
/// connectToEnvironmentService method or a higher level method instead.
Future<void> connectToService<T>(
  fidl_sys.ServiceProvider serviceProvider,
  String serviceName,
  String interfaceName,
  InterfaceRequest<T> interfaceRequest,
) async {
  if (serviceName == null) {
    throw Exception("$interfaceName's "
        'proxyServiceController.\$serviceName must not be null. Check the FIDL '
        'file for a missing [Discoverable]');
  }

  return serviceProvider.connectToService(
      serviceName, interfaceRequest.passChannel());
}
