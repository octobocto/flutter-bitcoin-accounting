// To parse this JSON data, do
//
//     final coinbaseProTransfer = coinbaseProTransferFromJson(jsonString);

import 'dart:convert';

List<CoinbaseProTransfer> coinbaseProTransferFromJson(String str) =>
    List<CoinbaseProTransfer>.from(
        json.decode(str).map((x) => CoinbaseProTransfer.fromJson(x)));

String coinbaseProTransferToJson(List<CoinbaseProTransfer> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CoinbaseProTransfer {
  CoinbaseProTransfer({
    this.id,
    this.type,
    this.createdAt,
    this.completedAt,
    this.canceledAt,
    this.processedAt,
    this.accountId,
    this.userId,
    this.userNonce,
    this.amount,
    this.details,
  });

  String id;
  String type;
  String createdAt;
  String completedAt;
  dynamic canceledAt;
  String processedAt;
  String accountId;
  String userId;
  dynamic userNonce;
  String amount;
  Details details;

  factory CoinbaseProTransfer.fromJson(Map<String, dynamic> json) =>
      CoinbaseProTransfer(
        id: json["id"],
        type: json["type"],
        createdAt: json["created_at"],
        completedAt: json["completed_at"],
        canceledAt: json["canceled_at"],
        processedAt: json["processed_at"],
        accountId: json["account_id"],
        userId: json["user_id"],
        userNonce: json["user_nonce"],
        amount: json["amount"],
        details: Details.fromJson(json["details"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "type": type,
        "created_at": createdAt,
        "completed_at": completedAt,
        "canceled_at": canceledAt,
        "processed_at": processedAt,
        "account_id": accountId,
        "user_id": userId,
        "user_nonce": userNonce,
        "amount": amount,
        "details": details.toJson(),
      };
}

class Details {
  Details({
    this.cryptoAddress,
    this.destinationTag,
    this.coinbaseAccountId,
    this.destinationTagName,
    this.cryptoTransactionId,
    this.coinbaseTransactionId,
    this.cryptoTransactionHash,
  });

  String cryptoAddress;
  String destinationTag;
  String coinbaseAccountId;
  String destinationTagName;
  String cryptoTransactionId;
  String coinbaseTransactionId;
  String cryptoTransactionHash;

  factory Details.fromJson(Map<String, dynamic> json) => Details(
        cryptoAddress: json["crypto_address"],
        destinationTag: json["destination_tag"],
        coinbaseAccountId: json["coinbase_account_id"],
        destinationTagName: json["destination_tag_name"],
        cryptoTransactionId: json["crypto_transaction_id"],
        coinbaseTransactionId: json["coinbase_transaction_id"],
        cryptoTransactionHash: json["crypto_transaction_hash"],
      );

  Map<String, dynamic> toJson() => {
        "crypto_address": cryptoAddress,
        "destination_tag": destinationTag,
        "coinbase_account_id": coinbaseAccountId,
        "destination_tag_name": destinationTagName,
        "crypto_transaction_id": cryptoTransactionId,
        "coinbase_transaction_id": coinbaseTransactionId,
        "crypto_transaction_hash": cryptoTransactionHash,
      };
}
