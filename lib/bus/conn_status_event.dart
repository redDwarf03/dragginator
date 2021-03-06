// Package imports:
import 'package:event_taxi/event_taxi.dart';

// Bus event for connection status changing
enum ConnectionStatus { CONNECTED, DISCONNECTED }

class ConnStatusEvent implements Event {
  final ConnectionStatus? status;
  final String? server;

  ConnStatusEvent({this.status, this.server});
}
