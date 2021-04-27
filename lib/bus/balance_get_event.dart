import 'package:event_taxi/event_taxi.dart';
import 'package:dragginator/model/db/account.dart';
import 'package:dragginator/network/model/response/balance_get_response.dart';

class BalanceGetEvent implements Event {
  final Account? account;
  final BalanceGetResponse? response;

  BalanceGetEvent({this.response, this.account});
}