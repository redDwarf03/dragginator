// @dart=2.9

import 'dart:async';
import 'package:dragginator/network/model/response/dragginator_list_from_address_response.dart';
import 'package:dragginator/service/dragginator_service.dart';
import 'package:dragginator/util/device_util.dart';
import 'package:hex/hex.dart';
import 'package:logger/logger.dart';
import 'package:dragginator/model/wallet.dart';
import 'package:event_taxi/event_taxi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dragginator/network/model/response/address_txs_response.dart';
import 'package:dragginator/network/model/response/balance_get_response.dart';
import 'package:dragginator/service/app_service.dart';
import 'package:dragginator/service/http_service.dart';
import 'package:dragginator/util/app_ffi/encrypt/crypter.dart';
import 'package:dragginator/themes.dart';
import 'package:dragginator/service_locator.dart';
import 'package:dragginator/model/available_currency.dart';
import 'package:dragginator/model/available_language.dart';
import 'package:dragginator/model/address.dart';
import 'package:dragginator/model/vault.dart';
import 'package:dragginator/model/db/appdb.dart';
import 'package:dragginator/model/db/account.dart';
import 'package:dragginator/util/sharedprefsutil.dart';
import 'package:dragginator/util/app_ffi/apputil.dart';
import 'package:dragginator/bus/events.dart';

import 'util/sharedprefsutil.dart';

class _InheritedStateContainer extends InheritedWidget {
  // Data is your entire state. In our case just 'User'
  final StateContainerState data;

  // You must pass through a child and your state.
  _InheritedStateContainer({
    Key key,
    @required this.data,
    @required Widget child,
  }) : super(key: key, child: child);

  // This is a built in method which you can use to check if
  // any state has changed. If not, no reason to rebuild all the widgets
  // that rely on your state.
  @override
  bool updateShouldNotify(_InheritedStateContainer old) => true;
}

class StateContainer extends StatefulWidget {
  // You must pass through a child.
  final Widget child;

  StateContainer({@required this.child});

  // This is the secret sauce. Write your own 'of' method that will behave
  // Exactly like MediaQuery.of and Theme.of
  // It basically says 'get the data from the widget of this type.
  static StateContainerState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_InheritedStateContainer>()
        .data;
  }

  @override
  StateContainerState createState() => StateContainerState();
}

/// App InheritedWidget
/// This is where we handle the global state and also where
/// we interact with the server and make requests/handle+propagate responses
///
/// Basically the central hub behind the entire app
class StateContainerState extends State<StateContainer> {
  final Logger log = sl.get<Logger>();

  AppWallet wallet;
  Locale deviceLocale = Locale('en', 'US');
  LanguageSetting curLanguage = LanguageSetting(AvailableLanguage.DEFAULT);
  BaseTheme curTheme = DragginatorTheme();
  // Currently selected account
  Account selectedAccount =
      Account(id: 1, name: "AB", index: 0, lastAccess: 0, selected: true);
  // Two most recently used accounts
  Account recentLast;
  Account recentSecondLast;

  // Deep link changes
  StreamSubscription _deepLinkSub;

  // When wallet is encrypted
  String encryptedSecret;

  String deviceIdentifier;

  @override
  void initState() {
    super.initState();
    // Register RxBus
    _registerBus();
    _getIdentifier();

    // Get default language setting
    sl.get<SharedPrefsUtil>().getLanguage().then((language) {
      setState(() {
        curLanguage = language;
      });
    });
  }

  // Subscriptions
  StreamSubscription<BalanceGetEvent> _balanceGetEventSub;
  StreamSubscription<AccountModifiedEvent> _accountModifiedSub;
  StreamSubscription<TransactionsListEvent> _transactionsListEventSub;

  void _getIdentifier() async {
    deviceIdentifier = await DeviceUtil.getIdentifier();
  }

  // Register RX event listeners
  void _registerBus() {
    _balanceGetEventSub =
        EventTaxiImpl.singleton().registerTo<BalanceGetEvent>().listen((event) {
      //print("listen BalanceGetEvent");
      handleAddressResponse(event.response);
    });

    _transactionsListEventSub = EventTaxiImpl.singleton()
        .registerTo<TransactionsListEvent>()
        .listen((event) {
      //print("listen TransactionsListEvent");
      AddressTxsResponse addressTxsResponse = new AddressTxsResponse();
      addressTxsResponse.result =
          new List<AddressTxsResponseResult>.empty(growable: true);
      for (int i = event.response.length - 1; i >= 0; i--) {
        AddressTxsResponseResult addressTxResponseResult =
            new AddressTxsResponseResult();
        addressTxResponseResult.populate(
            event.response[i], selectedAccount.address);
        addressTxResponseResult.getBisToken();
        addressTxsResponse.result.add(addressTxResponseResult);
      }

      wallet.history.clear();

      // Iterate list in reverse (oldest to newest block)
      if (addressTxsResponse != null && addressTxsResponse.result != null) {
        for (AddressTxsResponseResult item in addressTxsResponse.result) {
          setState(() {
            wallet.history.insert(0, item);
          });
        }
      }

      setState(() {
        wallet.historyLoading = false;
        wallet.loading = false;
      });

      EventTaxiImpl.singleton().fire(HistoryHomeEvent(items: wallet.history));
    });

    // Account has been deleted or name changed
    _accountModifiedSub = EventTaxiImpl.singleton()
        .registerTo<AccountModifiedEvent>()
        .listen((event) {
      if (!event.deleted) {
        if (event.account.index == selectedAccount.index) {
          setState(() {
            selectedAccount.name = event.account.name;
          });
        } else {
          updateRecentlyUsedAccounts();
        }
      } else {
        // Remove account
        updateRecentlyUsedAccounts().then((_) {
          if (event.account.index == selectedAccount.index &&
              recentLast != null) {
            sl.get<DBHelper>().changeAccount(recentLast);
            setState(() {
              selectedAccount = recentLast;
            });
            EventTaxiImpl.singleton()
                .fire(AccountChangedEvent(account: recentLast, noPop: true));
          } else if (event.account.index == selectedAccount.index &&
              recentSecondLast != null) {
            sl.get<DBHelper>().changeAccount(recentSecondLast);
            setState(() {
              selectedAccount = recentSecondLast;
            });
            EventTaxiImpl.singleton().fire(
                AccountChangedEvent(account: recentSecondLast, noPop: true));
          } else if (event.account.index == selectedAccount.index) {
            getSeed().then((seed) {
              sl.get<DBHelper>().getMainAccount(seed).then((mainAccount) {
                sl.get<DBHelper>().changeAccount(mainAccount);
                setState(() {
                  selectedAccount = mainAccount;
                });
                EventTaxiImpl.singleton().fire(
                    AccountChangedEvent(account: mainAccount, noPop: true));
              });
            });
          }
        });
        updateRecentlyUsedAccounts();
      }
    });
  }

  @override
  void dispose() {
    _destroyBus();
    super.dispose();
  }

  void _destroyBus() {
    if (_balanceGetEventSub != null) {
      _balanceGetEventSub.cancel();
    }
    if (_accountModifiedSub != null) {
      _accountModifiedSub.cancel();
    }
    if (_deepLinkSub != null) {
      _deepLinkSub.cancel();
    }
    if (_transactionsListEventSub != null) {
      _transactionsListEventSub.cancel();
    }
  }

  // Update the global wallet instance with a new address
  Future<void> updateWallet({Account account}) async {
    //print("updateWallet");
    String address;
    address = AppUtil().seedToAddress(await getSeed(), account.index);
    account.address = address;
    selectedAccount = account;
    updateRecentlyUsedAccounts();

    setState(() {
      wallet = AppWallet(address: address, loading: true);
      requestUpdateDragginatorList();
      requestUpdateHistory();
    });
  }

  Future<void> updateRecentlyUsedAccounts() async {
    List<Account> otherAccounts =
        await sl.get<DBHelper>().getRecentlyUsedAccounts(await getSeed());
    if (otherAccounts != null && otherAccounts.length > 0) {
      if (otherAccounts.length > 1) {
        setState(() {
          recentLast = otherAccounts[0];
          recentSecondLast = otherAccounts[1];
        });
      } else {
        setState(() {
          recentLast = otherAccounts[0];
          recentSecondLast = null;
        });
      }
    } else {
      setState(() {
        recentLast = null;
        recentSecondLast = null;
      });
    }
  }

  // Change language
  void updateLanguage(LanguageSetting language) {
    setState(() {
      curLanguage = language;
    });
  }

  // Set encrypted secret
  void setEncryptedSecret(String secret) {
    setState(() {
      encryptedSecret = secret;
    });
  }

  // Reset encrypted secret
  void resetEncryptedSecret() {
    setState(() {
      encryptedSecret = null;
    });
  }

  /// Handle address response
  void handleAddressResponse(BalanceGetResponse response) {
    setState(() {
      if (wallet != null) {
        if (response == null) {
          wallet.accountBalance = 0;
        } else {
          wallet.accountBalance = double.tryParse(response.balance);
          sl.get<DBHelper>().updateAccountBalance(
              selectedAccount, wallet.accountBalance.toString());
        }
      }
    });
  }

  Future<void> requestUpdateDragginatorList() async {
    //print("requestUpdate");
    if (selectedAccount != null &&
        selectedAccount.address != null &&
        Address(selectedAccount.address).isValid()) {
      try {
        List<DragginatorListFromAddressResponse>
            dragginatorListFromAddressResponseList = await sl
                .get<DragginatorService>()
                .getEggsAndDragonsListFromAddress(selectedAccount.address);

        List<List> dragginatorInfosList = new List.filled(
            dragginatorListFromAddressResponseList.length, null);
        for (int i = 0;
            i < dragginatorListFromAddressResponseList.length;
            i++) {
          dragginatorInfosList[i] = new List.filled(2, null);
          dragginatorInfosList[i][0] =
              dragginatorListFromAddressResponseList[i];
          dragginatorInfosList[i][1] = await sl
              .get<DragginatorService>()
              .getInfosFromDna(dragginatorListFromAddressResponseList[i].dna);
        }
        setState(() {
          wallet.dragginatorList.clear();
          wallet.dragginatorList.addAll(dragginatorInfosList);
        });
      } catch (e) {}
    }
  }

  Future<void> requestUpdateHistory() async {
    if (wallet != null &&
        wallet.address != null &&
        Address(wallet.address).isValid()) {
      // Request account history
      int count = 30;
      try {
        sl
            .get<AppService>()
            .getBalanceGetResponse(selectedAccount.address, true);

        sl.get<AppService>().getAddressTxsResponse(wallet.address, count);

        //sl.get<AppService>().getAlias(wallet.address);

        AddressTxsResponse addressTxsResponse = new AddressTxsResponse();
        addressTxsResponse.tokens = await sl
            .get<HttpService>()
            .getTokensBalance(selectedAccount.address);
        setState(() {
          wallet.tokens.clear();
          wallet.tokens.add(
              new BisToken(tokenName: "", tokensQuantity: 0, tokenMessage: ""));
          wallet.tokens.addAll(addressTxsResponse.tokens);
        });
      } catch (e) {
        // TODO handle account history error
        sl.get<Logger>().e("account_history e", e);
      }
    }
  }

  void logOut() {
    setState(() {
      wallet = AppWallet();
      encryptedSecret = null;
    });
    sl.get<DBHelper>().dropAccounts();
  }

  Future<String> getSeed() async {
    String seed;
    if (encryptedSecret != null) {
      seed = HEX.encode(AppCrypt.decrypt(
          encryptedSecret, await sl.get<Vault>().getSessionKey()));
    } else {
      seed = await sl.get<Vault>().getSeed();
    }
    return seed;
  }

  // Simple build method that just passes this state through
  // your InheritedWidget
  @override
  Widget build(BuildContext context) {
    return _InheritedStateContainer(
      data: this,
      child: widget.child,
    );
  }
}
