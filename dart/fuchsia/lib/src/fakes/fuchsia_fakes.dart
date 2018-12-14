// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library fuchsia_fakes;

import 'dart:io' as io;

import 'package:zircon/zircon.dart';

// ignore_for_file: public_member_api_docs

class MxStartupInfo {
  static Handle takeEnvironment() => new Handle.invalid();

  static Handle takeOutgoingServices() => new Handle.invalid();
}

void exit(int returnCode) {
  io.exit(returnCode);
}
