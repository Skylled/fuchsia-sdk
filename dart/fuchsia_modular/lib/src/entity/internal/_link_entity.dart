// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fidl/fidl.dart';
import 'package:fidl_fuchsia_mem/fidl_async.dart' as fuchsia_mem;
import 'package:fidl_fuchsia_modular/fidl_async.dart' as fidl;
import 'package:meta/meta.dart';
import 'package:zircon/zircon.dart';

import '../../internal/_component_context.dart';
import '../../module/internal/_module_context.dart';
import '../entity.dart';
import '../entity_codec.dart';

/// An [Entity] implementation which supports
/// data that lives inside links.
///
/// Note: This is a temporary solution that will go away when links are removed.
class LinkEntity<T> implements Entity<T> {
  /// The name of the link to pull data from
  final String linkName;

  /// The codec used to decode/encode data
  final EntityCodec codec;

  fidl.Link _link;

  /// Constructor
  LinkEntity({
    @required this.linkName,
    @required this.codec,
  })  : assert(linkName != null),
        assert(codec != null);

  @override
  Future<T> getData() async => _getSnapshot();

  @override
  Stream<T> watch() {
    final link = _getLink();
    final controller = StreamController<fuchsia_mem.Buffer>();
    final watcher = _LinkWatcher(onNotify: (buffer) async {
      controller.add(buffer);
    });

    link.watch(watcher.getInterfaceHandle());

    // if the user closed the stream we close the binding to the watcher
    controller.onCancel = watcher.binding.close;

    // if the connection closes then we close the stream
    watcher.binding.whenClosed.then((_) {
      if (!controller.isClosed) {
        controller.close();
      }
    });

    // Use _getSnapshot here instead of using the buffer directly because
    // most uses of links are using the entityRef value on the link instead
    // of raw json.
    return controller.stream.asyncMap((_) => _getSnapshot());
  }

  @override
  Future<void> write(T value) async {
    final link = _getLink();

    // Convert the object to raw bytes
    final bytes = codec.encode(value);

    // need to base64 encode so we can encode it as json.
    final b64ByteString = base64.encode(bytes);
    final jsonString = json.encode(b64ByteString);

    // convert the json encoded string into bytes so we can put it in a vmo
    final jsonData = Uint8List.fromList(utf8.encode(jsonString));
    final vmo = SizedVmo.fromUint8List(jsonData);
    final buffer = fuchsia_mem.Buffer(vmo: vmo, size: jsonData.length);

    await link.set(null, buffer);
  }

  Future<T> _getEntityData<T>(String entityReference) async {
    final resolver = fidl.EntityResolverProxy();
    await getComponentContext().getEntityResolver(resolver.ctrl.request());

    final entity = fidl.EntityProxy();
    await resolver.resolveEntity(entityReference, entity.ctrl.request());

    final types = await entity.getTypes();
    if (!types.contains(codec.type)) {
      throw EntityTypeException(codec.type);
    }

    final buffer = await entity.getData(codec.type);
    final dataVmo = SizedVmo(buffer.vmo.handle, buffer.size);
    final result = dataVmo.read(buffer.size);

    if (result.status != 0) {
      throw new Exception('Failed to read VMO');
    }

    dataVmo.close();

    return codec.decode(result.bytesAsUint8List());
  }

  T _getJsonData<T>(fuchsia_mem.Buffer jsonBuffer) {
    final vmo = SizedVmo(jsonBuffer.vmo.handle, jsonBuffer.size);
    final result = vmo.read(jsonBuffer.size);
    if (result.status != 0) {
      throw Exception('Failed to read VMO');
    }
    vmo.close();

    final resultBytes = result.bytesAsUint8List();
    Uint8List bytesToDecode;

    try {
      // Try to decode the values in the format that this entity encoded them
      final utf8String = utf8.decode(resultBytes);
      final jsonDecoded = json.decode(utf8String);
      bytesToDecode = base64.decode(jsonDecoded);
    } on Exception catch (_) {
      bytesToDecode = resultBytes;
    }

    return codec.decode(bytesToDecode);
  }

  fidl.Link _getLink() {
    if (_link != null) {
      return _link;
    }

    // Store the Link instead of the LinkProxy to avoid closing.
    fidl.LinkProxy linkProxy = fidl.LinkProxy();
    _link = linkProxy;
    getModuleContext().getLink(linkName, linkProxy.ctrl.request());

    return _link;
  }

  Future<T> _getSnapshot() async {
    final link = _getLink();

    final buffer = await link.get(null);
    if (buffer == null) {
      final entityReference = await link.getEntity();
      if (entityReference == null) {
        return null;
      }
      return _getEntityData(entityReference);
    }
    return _getJsonData(buffer);
  }
}

class _LinkWatcher extends fidl.LinkWatcher {
  final fidl.LinkWatcherBinding binding = fidl.LinkWatcherBinding();
  final Future<void> Function(fuchsia_mem.Buffer) onNotify;

  _LinkWatcher({@required this.onNotify}) : assert(onNotify != null);

  InterfaceHandle<fidl.LinkWatcher> getInterfaceHandle() {
    if (binding.isBound) {
      throw Exception(
          'Attempting to call _LinkWatcher.getInterfaceHandle on already bound binding');
    }
    return binding.wrap(this);
  }

  @override
  Future<void> notify(fuchsia_mem.Buffer data) => onNotify(data);
}
