// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_modular/fidl_async.dart' as fidl;
import 'package:fidl_fuchsia_ui_viewsv1token/fidl_async.dart' as views_fidl;
import 'package:meta/meta.dart';

/// The result of calling [Module#embedModule] on the Module.
///
/// This object contains a reference to a [fidl.ModuleController]
/// as well as a [views_fidl.ViewOwner] object. The combination of
/// these objects can be used to embed the new module's view into
/// your own view hierarchy.
class EmbeddedModule {
  /// The moduleController which can be used to control the embedded module.
  final fidl.ModuleController moduleController;

  /// A handle to the view owner object. This handle can be used to connect
  /// to the modules view to render its contents to screen.
  final InterfaceHandle<views_fidl.ViewOwner> viewOwner;

  /// Constructor
  EmbeddedModule({
    @required this.moduleController,
    @required this.viewOwner,
  })  : assert(moduleController != null),
        assert(viewOwner != null);
}
