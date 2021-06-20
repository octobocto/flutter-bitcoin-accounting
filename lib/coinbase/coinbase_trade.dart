// To parse this JSON data, do
//
//     final coinbaseProTrade = coinbaseProTradeFromJson(jsonString);

import 'dart:convert';

List<CoinbaseProTrade> coinbaseProTradeFromJson(String str) =>
    List<CoinbaseProTrade>.from(
        json.decode(str).map((x) => CoinbaseProTrade.fromJson(x)));

String coinbaseProTradeToJson(List<CoinbaseProTrade> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class CoinbaseProTrade {
  CoinbaseProTrade({
    this.tradeId,
    this.productId,
    this.price,
    this.size,
    this.orderId,
    this.createdAt,
    this.liquidity,
    this.fee,
    this.settled,
    this.side,
  });

  int tradeId;
  String productId;
  String price;
  String size;
  String orderId;
  DateTime createdAt;
  String liquidity;
  String fee;
  bool settled;
  String side;

  factory CoinbaseProTrade.fromJson(Map<String, dynamic> json) =>
      CoinbaseProTrade(
        tradeId: json["trade_id"],
        productId: json["product_id"],
        price: json["price"],
        size: json["size"],
        orderId: json["order_id"],
        createdAt: DateTime.parse(json["created_at"]),
        liquidity: json["liquidity"],
        fee: json["fee"],
        settled: json["settled"],
        side: json["side"],
      );

  Map<String, dynamic> toJson() => {
        "trade_id": tradeId,
        "product_id": productId,
        "price": price,
        "size": size,
        "order_id": orderId,
        "created_at": createdAt.toIso8601String(),
        "liquidity": liquidity,
        "fee": fee,
        "settled": settled,
        "side": side,
      };
}
