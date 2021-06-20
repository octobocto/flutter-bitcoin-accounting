import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'coinbase_accounts.dart';
import 'coinbase_trade.dart';
import 'coinbase_transfers.dart';

final coinbaseKey = dotenv.env["COINBASE_KEY"];
final coinbaseSecret = dotenv.env["COINBASE_SECRET"];
final coinbasePassphrase = dotenv.env["COINBASE_PASSPHRASE"];

String generateRequestSignature(
    int timestamp, String method, String requestPath, String body) {
  final toBeSigned = timestamp.toString() + method + requestPath + body;

  final decodedSecret = base64Decode(coinbaseSecret);

  final hmacSha256 = crypto.Hmac(crypto.sha256, decodedSecret);
  final signedString = hmacSha256.convert(utf8.encode(toBeSigned));

  return base64Encode(signedString.bytes);
}

Future<http.Response> doCoinbaseRequest(Uri url, String method) async {
  final timestamp = (new DateTime.now().millisecondsSinceEpoch / 1000).round();
  // get last part of URL, because that's what coinbase pro require..
  final signature = generateRequestSignature(
      timestamp, method, "/" + url.toString().split("/").last, "");

  return await http.get(url, headers: {
    "Content-Type": "application/json",
    "CB-ACCESS-KEY": coinbaseKey,
    "CB-ACCESS-SIGN": signature,
    "CB-ACCESS-TIMESTAMP": timestamp.toString(),
    "CB-ACCESS-PASSPHRASE": coinbasePassphrase,
    "CB-VERSION": coinbaseKey,
  });
}

Future<List<CoinbaseProTrade>> fetchTrades() async {
  // To begin with, I only fetch last month. Don't wanna do it all at once.
  // TODO: Add period as parameter, and paginate until all of them are found

  final url =
      Uri.https("api.pro.coinbase.com", "/fills", {"product_id": "BTC-EUR"});

  final response = await doCoinbaseRequest(url, "GET");

  if (response.statusCode == 200) {
    return coinbaseProTradeFromJson(response.body);
  } else {
    throw Exception("Failed to load coinbase transfers ${response.body}");
  }
}

enum TransferType { deposit, internal_deposit, withdraw, internal_withdraw }

Future<List<CoinbaseProTransfer>> fetchTransfers([TransferType type]) async {
  var queryString = {};
  if (type != null) {
    queryString = {"type": type};
  }
  final url = Uri.https("api.pro.coinbase.com", "/transfers", queryString);

  final response = await doCoinbaseRequest(url, "GET");

  if (response.statusCode == 200) {
    return coinbaseProTransferFromJson(response.body);
  } else {
    throw Exception("Failed to load coinbase transfers ${response.body}");
  }
}

Future<List<CoinbaseProTransfer>> fetchWithdrawals() async {
  final queryString = {"type": "withdraw"};
  final url = Uri.https("api.pro.coinbase.com", "/transfers", queryString);

  final response = await doCoinbaseRequest(url, "GET");

  if (response.statusCode == 200) {
    return coinbaseProTransferFromJson(response.body);
  } else {
    throw Exception("Failed to load coinbase transfers ${response.body}");
  }
}

Future<List<CoinbaseProTransfer>> fetchDeposits() async {
  final queryString = {"type": "deposit"};
  final url = Uri.https("api.pro.coinbase.com", "/transfers", queryString);

  final response = await doCoinbaseRequest(url, "GET");

  if (response.statusCode == 200) {
    return coinbaseProTransferFromJson(response.body);
  } else {
    throw Exception("Failed to load coinbase transfers ${response.body}");
  }
}

Future<List<CoinbaseProAccounts>> fetchAccounts() async {
  final url = Uri.parse("https://api.pro.coinbase.com/accounts");

  final response = await doCoinbaseRequest(url, "GET");

  if (response.statusCode == 200) {
    return coinbaseProAccountsFromJson(response.body);
  } else {
    throw Exception("Failed to load coinbase accounts ${response.body}");
  }
}
