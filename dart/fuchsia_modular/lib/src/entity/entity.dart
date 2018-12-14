// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:uuid/uuid.dart';

import 'entity_codec.dart';
import 'internal/_link_entity.dart';

/// An [Entity] provides a mechanism for communicating
/// data between compoonents.
///
/// Note: this is a preliminary API that is likely to change.
@experimental
abstract class Entity<T> {
  /// Creates an entity that will live for the scope of this story.
  /// The entity that is created will be backed by the framework and
  /// can be treated as if it was received from any other entity provider.
  factory Entity({
    @required EntityCodec<T> codec,
  }) {
    // This is temporary and go away when we remove link entities.
    final linkName = Uuid().v4().toString();
    return LinkEntity<T>(linkName: linkName, codec: codec);
  }

  /// Returns the data stored in the entity.
  Future<T> getData();

  /// Writes the object stored in value
  Future<void> write(T object);

  /// Watches the entity for updates.
  ///
  /// An new value will be added to the stream whenever
  /// the entity is updated.
  ///
  /// The returned stream is a single subscription stream
  /// which, when closed, will close the underlying fidl
  /// connection.
  Stream<T> watch();
}

/// An exception which is thrown when an Entity does not
/// support a given type.
class EntityTypeException implements Exception {
  /// The unsuported type.
  final String type;

  /// Create a new [EntityTypeException].
  EntityTypeException(this.type);

  @override
  String toString() =>
      'EntityTypeError: type "$type" is not available for Entity';
}
