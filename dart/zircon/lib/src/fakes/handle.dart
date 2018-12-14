// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of zircon_fakes;

// ignore_for_file: public_member_api_docs

class Handle {
  // No public constructor - this can only be created from native code.
  Handle._();

  // Create an invalid handle object.
  Handle.invalid();

  int get _handle => -1;

  @override
  String toString() => 'Handle($_handle)';

  @override
  bool operator ==(Object other) =>
      (other is Handle) && (_handle == other._handle);

  @override
  int get hashCode => _handle.hashCode;

  // Common handle operations.
  bool get isValid => false;
  int close() {
    return 0;
  }
  HandleWaiter asyncWait(int signals, AsyncWaitCallback callback) {
    throw new UnimplementedError(
        'Handle.asyncWait() is not implemented on this platform.');
  }
}
