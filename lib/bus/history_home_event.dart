import 'package:event_taxi/event_taxi.dart';
import 'package:dragginator/network/model/response/address_txs_response.dart';

class HistoryHomeEvent implements Event {
  final List<AddressTxsResponseResult>? items;

  HistoryHomeEvent({this.items});
}