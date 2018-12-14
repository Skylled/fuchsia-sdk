// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl_fuchsia_modular/fidl_async.dart' as fuchsia_modular;

/// A class which implements the [fuchsia_modular.ProposalListener] interface
/// and calls a callback when the proposal is accepted.
class ProposalListenerImpl implements fuchsia_modular.ProposalListener {
  final void Function(String, String) _onProposalAccepted;

  /// The default constructor
  ProposalListenerImpl(this._onProposalAccepted);

  @override
  Future<void> onProposalAccepted(String proposalId, String storyId) async {
    if (_onProposalAccepted != null) {
      _onProposalAccepted(proposalId, storyId);
    }
  }
}
