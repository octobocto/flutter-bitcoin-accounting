import 'dart:convert';
import 'dart:core';

import 'package:bitcoin_accounting/coinbase/coinbase_accounts.dart';
import 'package:bitcoin_accounting/coinbase/coinbase_trade.dart';
import 'package:bitcoin_accounting/coinbase/coinbase_transfers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'coinbase/api.dart';

Future main() async {
  await dotenv.load();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.blue),
      home: Scaffold(
        body: Center(child: DivInfoList()),
      ),
    );
  }
}

class DivInfoList extends StatefulWidget {
  @override
  _DivInfoListState createState() => _DivInfoListState();
}

final _biggerFont = TextStyle(fontSize: 18.0);

class _DivInfoListState extends State<DivInfoList> {
  Future<List<CoinbaseProAccounts>> futureAccounts;
  Future<List<CoinbaseProTransfer>> futureWithdrawals;
  Future<List<CoinbaseProTrade>> futureTrades;

  @override
  void initState() {
    super.initState();
    futureAccounts = fetchAccounts();
    futureWithdrawals = fetchWithdrawals();
    futureTrades = fetchTrades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Header(),
        actions: [IconButton(icon: Icon(Icons.list), onPressed: _toggleMenu)],
      ),
      body: _buildList(),
    );
  }

  ListView _buildList() {
    return ListView(padding: EdgeInsets.all(16.0), children: <Widget>[
      FutureBuilder<List<CoinbaseProAccounts>>(
        future: futureAccounts,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<Text> list = [];
            JsonEncoder encoder = new JsonEncoder.withIndent("  ");
            snapshot.data.forEach((account) => {
                  if (account.currency == "BTC" || account.currency == "EUR")
                    {list.add(Text(encoder.convert(account.toJson())))}
                });

            return Column(children: list);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // by default, show a loading spinner.
          return CircularProgressIndicator();
        },
      ),
      FutureBuilder<List<CoinbaseProTransfer>>(
        future: futureWithdrawals,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<Withdrawal> list = [];
            JsonEncoder encoder = new JsonEncoder.withIndent("  ");
            snapshot.data.forEach((withdrawal) => {
                  if (withdrawal.details.cryptoTransactionHash == null)
                    {
                      // a cryptoaddress of null means it is a fiat withdrawal
                      list.add(
                          Withdrawal(withdrawal.amount, withdrawal.completedAt))
                    }
                });

            return Column(children: list);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // by default, show a loading spinner.
          return CircularProgressIndicator();
        },
      ),
      FutureBuilder<List<CoinbaseProTrade>>(
        future: futureTrades,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<Text> list = [];
            JsonEncoder encoder = new JsonEncoder.withIndent("  ");
            snapshot.data.forEach((trade) => {
                  if (trade.side == "sell") {list.add(Text(trade.size))}
                });

            return Column(children: list);
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }

          // by default, show a loading spinner.
          return CircularProgressIndicator();
        },
      )
    ]);
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

  void _toggleMenu() {
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

class Header extends StatefulWidget {
  @override
  _HeaderState createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  double soldLastPeriodEUR = 0;
  double soldLastPeriodBTC = 0;
  double withdrawnLastPeriod = 0;
  double taxesLastPeriod = 0;
  DateTime periodStart = DateTime.now().subtract(Duration(days: 31));
  DateTime periodEnd = DateTime.now();

  @override
  void initState() {
    super.initState();

    getSoldLastPeriod();
    getWithdrawnLastPeriod();
  }

  void getSoldLastPeriod() async {
    final trades = await fetchTrades();
    double soldEUR = 0;
    double soldBTC = 0;

    trades.forEach(
      (element) {
        if (element.createdAt.isBefore(periodStart) ||
            element.createdAt.isAfter(periodEnd)) {
          return;
        }
        if (element.side == "sell") {
          soldEUR +=
              (double.parse(element.price) * double.parse(element.size)) -
                  double.parse(element.fee);
          soldBTC += double.parse(element.size);
        }
      },
    );

    const taxPercentage = 0.22;
    setState(() {
      soldLastPeriodEUR = soldEUR;
      soldLastPeriodBTC = soldBTC;
      taxesLastPeriod = soldEUR * taxPercentage;
    });
  }

  void getWithdrawnLastPeriod() async {
    final withdrawals = await fetchWithdrawals();
    double spent = 0;

    withdrawals.forEach((element) {
      if (DateTime.parse(element.createdAt).isBefore(periodStart) ||
          DateTime.parse(element.createdAt).isAfter(periodEnd)) {
        return;
      }
      if (element.details.cryptoTransactionHash == null) {
        // we have a fiat withdrawal of EUR!
        spent += double.parse(element.amount);
      }
    });

    setState(() {
      withdrawnLastPeriod = spent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Balance("TATT UT", withdrawnLastPeriod),
        Balance("SOLGT", soldLastPeriodEUR, soldLastPeriodBTC),
        Balance("SKATT", taxesLastPeriod),
      ],
    );
  }
}

class Withdrawal extends StatefulWidget {
  const Withdrawal(this.amountEUR, this.date) : super();

  final String amountEUR;
  final String date;

  @override
  _WithdrawalState createState() => _WithdrawalState();
}

class _WithdrawalState extends State<Withdrawal> {
  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(widget.date);

    return ListTile(
      title: Text("-" + widget.amountEUR),
      trailing: Row(
        children: <Widget>[
          Text(DateFormat("dd.MM HH:mm").format(date)),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
      ),
    );
  }
}

class Balance extends StatefulWidget {
  const Balance(this.category, this.amountEUR, [this.amountBitcoin]) : super();

  final String category;
  final double amountBitcoin;
  final double amountEUR;

  @override
  _BalanceState createState() => _BalanceState();
}

class _BalanceState extends State<Balance> {
  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Text(
        "kr " + (widget.amountEUR * 10.29).toStringAsFixed(0),
        style: TextStyle(fontSize: 14.0),
      ),
      Text(
        (widget.amountBitcoin != null
                ? widget.amountBitcoin.toStringAsFixed(8)
                : 0)
            .toString(),
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

void printWrapped(String text) {
  final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
  pattern.allMatches(text).forEach((match) => print(match.group(0)));
}

/*
* Okayy, I have what I set out to create!!
* Now
* 1. Make it possible to input api key and secret in a settings page.
* 2. Make the period configurable.
*  */
