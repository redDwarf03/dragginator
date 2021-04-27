// @dart=2.9

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:dragginator/model/token_ref.dart';
import 'package:dragginator/network/model/response/address_txs_response.dart';
import 'package:dragginator/network/model/response/servers_wallet_legacy.dart';
import 'package:dragginator/network/model/response/tokens_balance_get_response.dart';
import 'package:dragginator/network/model/response/tokens_list_get_response.dart';
import 'package:dragginator/service_locator.dart';
import 'package:dragginator/util/sharedprefsutil.dart';

class HttpService {
  final Logger log = sl.get<Logger>();

  Future<ServerWalletLegacyResponse> getBestServerWalletLegacyResponse() async {
    List<ServerWalletLegacyResponse> serverWalletLegacyResponseList =
        new List<ServerWalletLegacyResponse>();
    ServerWalletLegacyResponse serverWalletLegacyResponse =
        new ServerWalletLegacyResponse();

    String walletServer = await sl.get<SharedPrefsUtil>().getWalletServer();
    if (walletServer != "auto") {
      if (walletServer.split(":").length > 1) {
        serverWalletLegacyResponse.ip = walletServer.split(":")[0];
        serverWalletLegacyResponse.port =
            int.tryParse(walletServer.split(":")[1]);
      }

      return serverWalletLegacyResponse;
    }

    HttpClient httpClient = new HttpClient();
    try {
      HttpClientRequest request = await httpClient.getUrl(
          Uri.parse("https://api.bismuth.live/servers/wallet/legacy.json"));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        //print("serverWalletLegacyResponseList=" + reply);
        serverWalletLegacyResponseList =
            serverWalletLegacyResponseFromJson(reply);

        // Best server active with less clients
        serverWalletLegacyResponseList
            .removeWhere((element) => element.active == false);
        serverWalletLegacyResponseList.sort((a, b) {
          return a.clients
              .toString()
              .toLowerCase()
              .compareTo(b.clients.toString().toLowerCase());
        });
        if (serverWalletLegacyResponseList.length > 0) {
          serverWalletLegacyResponse = serverWalletLegacyResponseList[0];
        }
      }
    } catch (e) {
      print(e);
    } finally {
      httpClient.close();
    }
    //print("Server Wallet : " +
    //    serverWalletLegacyResponse.ip +
    //    ":" +
    //    serverWalletLegacyResponse.port.toString());
    return serverWalletLegacyResponse;
  }

  Future<bool> isTokensBalance(String address) async {
    HttpClient httpClient = new HttpClient();
    try {
      String tokensApi = await sl.get<SharedPrefsUtil>().getTokensApi();
      Uri uri;
      try {
        uri = Uri.parse(tokensApi + address);
      } catch (FormatException) {
        return false;
      }

      HttpClientRequest request = await httpClient.getUrl(uri);
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        var tokensBalanceGetResponse = tokensBalanceGetResponseFromJson(reply);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<List<BisToken>> getTokensBalance(String address) async {
    List<BisToken> bisTokenList = new List<BisToken>();

    HttpClient httpClient = new HttpClient();
    try {
      String tokensApi = await sl.get<SharedPrefsUtil>().getTokensApi();
      HttpClientRequest request =
          await httpClient.getUrl(Uri.parse(tokensApi + address));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        var tokensBalanceGetResponse = tokensBalanceGetResponseFromJson(reply);

        for (int i = 0; i < tokensBalanceGetResponse.length; i++) {
          BisToken bisToken = new BisToken(
              tokenName: tokensBalanceGetResponse[i][0],
              tokensQuantity: tokensBalanceGetResponse[i][1]);
          bisTokenList.add(bisToken);
        }
      }
    } catch (e) {}
    return bisTokenList;
  }

  Future<List<TokenRef>> getTokensReflist() async {
    List<TokenRef> tokensRefList = new List<TokenRef>();

    HttpClient httpClient = new HttpClient();
    try {
      HttpClientRequest request = await httpClient
          .getUrl(Uri.parse("https://bismuth.today/api/tokens/"));
      request.headers.set('content-type', 'application/json');
      HttpClientResponse response = await request.close();
      if (response.statusCode == 200) {
        String reply = await response.transform(utf8.decoder).join();
        var tokensRefListGetResponse = tokensListGetResponseFromJson(reply);

        for (int i = 0; i < tokensRefListGetResponse.length; i++) {
          TokenRef tokenRef = new TokenRef();
          tokenRef.token = tokensRefListGetResponse.keys.elementAt(i);
          tokenRef.creator = tokensRefListGetResponse.values.elementAt(i)[0];
          tokenRef.totalSupply =
              tokensRefListGetResponse.values.elementAt(i)[1];
          tokenRef.creationDate = DateTime.fromMillisecondsSinceEpoch(
              (tokensRefListGetResponse.values.elementAt(i)[2] * 1000).toInt());
          tokensRefList.add(tokenRef);
        }
      }
    } catch (e) {}
    return tokensRefList;
  }
}
