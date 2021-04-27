import 'package:event_taxi/event_taxi.dart';
import 'package:dragginator/network/model/response/error_response.dart';

class ErrorEvent implements Event {
  final ErrorResponse? response;

  ErrorEvent({this.response});
}