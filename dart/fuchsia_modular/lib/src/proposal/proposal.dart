// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fidl_fuchsia_modular/fidl_async.dart' as fuchsia_modular;
import 'package:meta/meta.dart';

import 'internal/_proposal_listener_impl.dart';

/// The [Proposal] class is an extension to the [fuchsia_modular.Proposal].
///
/// [Proposal]s are objects which can be submitted to the proposal publisher.
/// The proposal publisher can then make recommendations to the user about
/// actions that can be taken to enhance their user experience.
class Proposal extends fuchsia_modular.Proposal {
  /// Creates a [Proposal] object. The [id] and [headline] are both required and
  /// must not be empty. If provided, the [onProposalAccepted] function will be
  /// invoked when the proposal has been accepted by the user. Proposal
  /// affinities and story commands can be added after the proposal is created
  /// and before the proposal is submitted to the proposal publisher.
  Proposal({
    @required String id,
    @required String headline,
    String storyName,
    double confidence = 0.0,
    bool wantsRichSuggestion = false,
    String subheadline,
    String details,
    List<fuchsia_modular.SuggestionDisplayImage> icons,
    fuchsia_modular.SuggestionDisplayImage image,
    fuchsia_modular.AnnoyanceType annoyance =
        fuchsia_modular.AnnoyanceType.none,
    int color = 0x000000,
    void Function(String, String) onProposalAccepted,
  })  : assert(id != null && id.isNotEmpty),
        assert(headline != null && headline.isNotEmpty),
        super(
          id: id,
          storyName: storyName,
          affinity: [],
          onSelected: [],
          confidence: confidence,
          wantsRichSuggestion: wantsRichSuggestion,
          display: fuchsia_modular.SuggestionDisplay(
            headline: headline,
            subheadline: subheadline,
            details: details,
            color: color,
            icons: icons,
            image: image,
            annoyance: annoyance,
          ),
          listener: onProposalAccepted != null
              ? fuchsia_modular.ProposalListenerBinding()
                  .wrap(ProposalListenerImpl(onProposalAccepted))
              : null,
        );

  /// Restricts the proposal to appear only when the module identified by
  /// [moduleName] within the story identified by [storyName] is focused.
  void addModuleAffinity(String moduleName, String storyName) => affinity.add(
        fuchsia_modular.ProposalAffinity.withModuleAffinity(
          fuchsia_modular.ModuleAffinity(
            storyName: storyName,
            moduleName: [moduleName],
          ),
        ),
      );

  /// Restricts the proposal to appear only when the story identified by
  /// [storyName] is focused.
  void addStoryAffinity(String storyName) => affinity.add(
        fuchsia_modular.ProposalAffinity.withStoryAffinity(
          fuchsia_modular.StoryAffinity(storyName: storyName),
        ),
      );

  /// Adds a [fuchsia_modular.StoryCommand] to execute when the proposal is
  /// selected.
  void addStoryCommand(fuchsia_modular.StoryCommand command) =>
      addStoryCommands([command]);

  /// Adds a List of [fuchsia_modular.StoryCommand]s to execute when the
  /// proposal is selected.
  void addStoryCommands(List<fuchsia_modular.StoryCommand> commands) =>
      onSelected.addAll(commands);
}
