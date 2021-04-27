// @dart=2.9

import 'package:dragginator/network/model/response/address_txs_response.dart';
import 'package:dragginator/network/model/response/dragginator_list_from_address_response.dart';
import 'package:dragginator/util/numberutil.dart';

/// Main wallet object that's passed around the app via state
class AppWallet {
  bool _loading; // Whether or not app is initially loading
  bool _historyLoading; // Whether or not we have received initial account history response
  String _address;
  double _accountBalance;
  List<AddressTxsResponseResult> _history;
  List<BisToken> _tokens;
  List<DragginatorListFromAddressResponse>
      _dragginatorList;

  AppWallet({String address, double accountBalance, 
                String representative, 
                List<AddressTxsResponseResult> history, bool loading, bool historyLoading, List<BisToken> tokens, List<DragginatorListFromAddressResponse>
      dragginatorList}) {
    _address = address;
    _accountBalance = accountBalance ?? 0;
    _history = history ?? new List<AddressTxsResponseResult>();
    _tokens = tokens ?? new List<BisToken>();
    _loading = loading ?? true;
    _historyLoading = historyLoading  ?? true;
    _dragginatorList = dragginatorList ?? new List<DragginatorListFromAddressResponse>();
  }

  String get address => _address;

  set address(String address) {
    _address = address;
  }

  double get accountBalance => _accountBalance;

  set accountBalance(double accountBalance) {
    _accountBalance = accountBalance;
  }

  // Get pretty account balance version
  String getAccountBalanceDisplay() {
    if (accountBalance == null) {
      return "0";
    }
    return NumberUtil.getRawAsUsableString(_accountBalance.toString());
  }

  // Get pretty account balance version
  String getAccountBalanceMoinsFeesDisplay(estimationFees) {
    if (accountBalance == null) {
      return "0";
    }
    double value = _accountBalance - estimationFees;
    return NumberUtil.getRawAsUsableString(value.toString());
  }

  List<AddressTxsResponseResult> get history => _history;

  set history(List<AddressTxsResponseResult> value) {
    _history = value;
  }

  List<BisToken> get tokens => _tokens;

  set tokens(List<BisToken> value) {
    _tokens = value;
  }

  bool get loading => _loading;

  set loading(bool value) {
    _loading = value;
  }

  bool get historyLoading => _historyLoading;

  set historyLoading(bool value) {
    _historyLoading = value;
  }

  List<DragginatorListFromAddressResponse> get dragginatorList => _dragginatorList;

  set dragginatorList(List<DragginatorListFromAddressResponse> value) {
    _dragginatorList = value;
  }

}