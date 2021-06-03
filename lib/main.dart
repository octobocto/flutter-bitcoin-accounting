// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:bitcoin_accounting/coinbase_accounts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      theme: ThemeData(primaryColor: Colors.blue),
      home: Scaffold(
        body: Center(child: TradeList()),
      ),
    );
  }
}

class Balance extends StatefulWidget {
  const Balance(this.category, this.amountBitcoin) : super();

  final String category;
  final double amountBitcoin;

  @override
  _BalanceState createState() => _BalanceState();
}

class _BalanceState extends State<Balance> {
  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Text(
        widget.amountBitcoin.toString(),
        style: TextStyle(fontSize: 14.0),
      ),
      Text(
        "kr" + (widget.amountBitcoin * 440000).toInt().toString(),
        style: TextStyle(fontSize: 12.0),
      ),
      Text(
        widget.category,
        style: TextStyle(fontSize: 10.0),
      ),
    ]);
  }
}

class Trade extends StatefulWidget {
  const Trade(
    this.price,
    this.amountBitcoin,
    this.side,
    this.description,
  ) : super();

  final double price;
  final double amountBitcoin;
  final String side;
  final String description;

  @override
  _TradeState createState() => _TradeState();
}

class _TradeState extends State<Trade> with SingleTickerProviderStateMixin {
  AnimationController _controller;

  _TradeState() {
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.description),
      trailing: Row(
        children: <Widget>[
          Text("kr" + (widget.price * widget.amountBitcoin).toStringAsFixed(0)),
          Text("~"),
          Text(widget.amountBitcoin.toString()),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
      ),
    );
  }
}

final coinbaseKey = dotenv.env["COINBASE_KEY"];
final coinbaseSecret = dotenv.env["COINBASE_SECRET"];

String generateRequestSignature(
    int timestamp, String method, String requestPath, String body) {
  final toBeSigned = timestamp.toString() + method + requestPath + body;

  final hmacSha256 = crypto.Hmac(crypto.sha256, utf8.encode(coinbaseSecret));
  final signedString = hmacSha256.convert(utf8.encode(toBeSigned));

  return signedString.toString();
}

Future<CoinbaseAccounts> fetchAccounts() async {
  final String url = "https://api.coinbase.com/v2/accounts";

  final timestamp = (new DateTime.now().millisecondsSinceEpoch / 1000).round();
  final signature =
      generateRequestSignature(timestamp, "GET", "/v2/accounts", "");

  final response = await http.get(Uri.parse(url), headers: {
    "Content-Type": "application/json",
    "CB-ACCESS-SIGN": signature,
    "CB-ACCESS-TIMESTAMP": timestamp.toString(),
    "CB-ACCESS-KEY": coinbaseKey,
  });

  if (response.statusCode == 200) {
    return coinbaseAccountsFromJson((response.body));
  } else {
    throw Exception("Failed to load coinbase accounts ${response.body}");
  }
}

/*
Future<Transaction> loadTransactions() async {
  final String apiURL =
      "https://api.coinbase.com/v2/accounts/:account_id/transactions"; // TODO: Find account id

      return Transaction()
}
*/

class TradeList extends StatefulWidget {
  @override
  _TradeListState createState() => _TradeListState();
}

class _TradeListState extends State<TradeList> {
  Future<CoinbaseAccounts> futureAccounts;

  final _trades = <Trade>[
    Trade(450000, 0.003290000, "sell", "KLARNA, MAT"),
    Trade(440000, 0.003290000, "sell", "div"),
    Trade(430000, 0.003290000, "sell", "Forbrukslån"),
    Trade(450000, 0.003290000, "sell", "Kredittkort")
  ];
  final _biggerFont = TextStyle(fontSize: 18.0);

  final TextEditingController keyController = TextEditingController(text: "");
  final TextEditingController secretController =
      TextEditingController(text: "");

  @override
  void initState() {
    super.initState();
    futureAccounts = fetchAccounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Balance("INNTEKT", 0.103232),
            Balance("UTGIFTER", 0.059289),
            Balance("BALANSE", 0.043943),
          ],
        ),
        actions: [IconButton(icon: Icon(Icons.list), onPressed: _pushSaved)],
      ),
      body: _buildList(),
    );
  }

  ListView _buildList() {
    return ListView(padding: EdgeInsets.all(16.0), children: <Widget>[
      ..._trades,
      TextField(controller: keyController),
      TextField(
        controller: secretController,
      ),
      FutureBuilder<CoinbaseAccounts>(
        future: futureAccounts,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data?.data.toString() ?? "no data");
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // by default, show a loading spinner.
          return CircularProgressIndicator();
        },
      )
    ]);
  }

  void _pushOther() {
    _loadSavedData();

    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
          appBar: AppBar(
            title: Text('App Routes'),
          ),
          body: ListView(children: <Widget>[
            Padding(
                padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
                child: TextField(
                    onChanged: (text) {
                      _saveField("api_key", text);
                    },
                    decoration: InputDecoration(
                        labelText: "API Key",
                        border: InputBorder.none,
                        hintText: 'API Key on Coinbase'))),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
                child: TextField(
                    onChanged: (text) {
                      _saveField("api_secret", text);
                    },
                    decoration: InputDecoration(
                        labelText: "API Secret",
                        border: InputBorder.none,
                        hintText: 'API Secret on Coinbase'))),
          ]));
    }));
  }

  void _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    // TODO: Set in api key field
  }

  void _saveField(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, value);
  }

  void _pushAPIKeys() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
          appBar: AppBar(
            title: Text('App Routes'),
          ),
          body: ListView(children: <Widget>[
            TextField(
                decoration: InputDecoration(
                    border: InputBorder.none, hintText: 'Enter a search term')),
            TextField(
                decoration: InputDecoration(
                    border: InputBorder.none, hintText: 'Enter a search term')),
          ]));
    }));
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          final tiles = <ListTile>[
            ListTile(
              onTap: _pushAPIKeys,
              title: Text(
                "API Keys",
                style: _biggerFont,
              ),
            ),
            ListTile(
              onTap: _pushOther,
              title: Text(
                "Some Other Path",
                style: _biggerFont,
              ),
            ),
          ];
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          return Scaffold(
            appBar: AppBar(
              title: Text('App Routes'),
            ),
            body: ListView(children: divided),
          );
        }, // ...to here.
      ),
    );
  }
}
