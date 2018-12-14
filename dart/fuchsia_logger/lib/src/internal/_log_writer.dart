// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

/// A concrete implementation of [LogWriter] which sends logs to
/// the fuchsia system logger. This log writer will buffer logs until
/// a connection has been established at which time it will send all
/// the buffered logs.
class FuchsiaLogWriter extends LogWriter {
  /// Constructor
  FuchsiaLogWriter({@required Logger logger})
      : assert(logger != null),
        super(
          logger: logger,
          shouldBufferLogs: true,
        ) {
    _connectToSysLogger();
  }

  void _connectToSysLogger() {
    // TODO(MS-2258) connect to the system logger
    _startListening(_onMessage);
  }

  @override
  // TODO(MS-2259) send logs to system logger
  void _onMessage(_LogMessage message) => throw UnimplementedError();
}

/// The base class for which log writers will inherit from. This class is
/// used to pipe logs from the onRecord stream
abstract class LogWriter {
  List<String> _globalTags = const [];

  StreamController<_LogMessage> _controller;

  /// If set to true, this method will include the stack trace
  /// in each log record so we can later extract out the call site.
  /// This is a heavy operation and should be used with caution.
  bool forceShowCodeLocation = false;

  /// Constructor
  LogWriter({
    @required Logger logger,
    bool shouldBufferLogs = false,
  }) : assert(logger != null) {
    void Function(_LogMessage) onMessageFunc;

    if (shouldBufferLogs) {
      // create single subscription stream controller so that we buffer calls to the
      // stream while we connect to the logger. This avoids dropping logs that
      // come in while we wait.
      _controller = StreamController<_LogMessage>();

      onMessageFunc = _controller.add;
    } else {
      onMessageFunc = _onMessage;
    }
    logger.onRecord.listen(
        (record) => onMessageFunc(_messageFromRecord(record)),
        onDone: () => _controller?.close());
  }

  /// The global tags to add to each log record.
  set globalTags(List<String> tags) => _globalTags = _verifyGlobalTags(tags);

  /// Remaps the level string to the ones used in FTL.
  String _getLevelString(Level level) {
    if (level == null) {
      return null;
    }

    if (level == Level.FINE) {
      return 'VLOG(1)';
    } else if (level == Level.FINER) {
      return 'VLOG(2)';
    } else if (level == Level.FINEST) {
      return 'VLOG(3)';
    } else if (level == Level.SEVERE) {
      return 'ERROR';
    } else if (level == Level.SHOUT) {
      return 'FATAL';
    } else {
      return level.toString();
    }
  }

  _LogMessage _messageFromRecord(LogRecord record) => _LogMessage(
        record: record,
        tags: _globalTags,
        callSiteTrace: forceShowCodeLocation ? StackTrace.current : null,
      );

  void _onMessage(_LogMessage message);

  void _startListening(void Function(_LogMessage) onMessage) =>
      _controller.stream.listen(_onMessage);

  List<String> _verifyGlobalTags(List<String> incomingTags) {
    //TODO(MS-2261) need to verify the incoming global tags
    return incomingTags;
  }

  //ignore: unused_element
  String _codeLocationFromStackTrace(StackTrace stackTrace) {
    // TODO(MS-2260) need to extract out the call site from the stack trace
    return '';
  }
}

/// A concrete implementation of [LogWriter] which prints the logs to stdout.
class StdoutLogWriter extends LogWriter {
  /// Constructor
  StdoutLogWriter({@required Logger logger})
      : assert(logger != null),
        super(
          logger: logger,
          shouldBufferLogs: false,
        );

  @override
  void _onMessage(_LogMessage message) {
    final scopes = [
      _getLevelString(message.record.level),
    ];

    if (message.record.loggerName.isNotEmpty) {
      scopes.add(message.record.loggerName);
    }
    // if (message.codeLocation != null) {
    // scopes.add(message.codeLocation);
    // }
    message.tags.forEach(scopes.add);
    String scopesString = scopes.join(':');
    if (message.record.error != null) {
      print(
          '[$scopesString] ${message.record.message}: ${message.record.error}');
    } else {
      print('[$scopesString] ${message.record.message}');
    }

    if (message.record.stackTrace != null) {
      print('${message.record.stackTrace}');
    }
  }
}

/// A wrapper around [LogRecord] which appends additional data. This
/// is what is sent to the log writer when a record is received.
class _LogMessage {
  /// The initial log record
  final LogRecord record;

  /// Any additional tags to append to the record.
  final List<String> tags;

  /// The stack trace at the call site. This is not to be confused with
  /// the stack trace in the [record] which is a stack trace that is being
  /// logged. This variable is used to later extract the code location
  /// to include in the message.
  final StackTrace callSiteTrace;

  _LogMessage({this.record, this.tags, this.callSiteTrace});
}
