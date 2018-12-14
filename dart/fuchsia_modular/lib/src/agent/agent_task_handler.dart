// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: one_member_abstracts

/// The [AgentTaskHandler] class is an abstract class which is intended to be
/// extended by agent authors to handle incoming tasks. The class is intended to
/// be registered with the [Agent] class inside of the agent's main method.
abstract class AgentTaskHandler {
  /// Called when some task identified by [taskId] is scheduled to run. The task
  /// was first posted by agent using [Agent.scheduleTask(...)].
  ///
  /// The future will complete when all work related to this task is completed.
  /// Note that the framework may call [Lifecycle.Terminate()] before this
  /// method returns.
  Future<void> runTask(String taskId);
}