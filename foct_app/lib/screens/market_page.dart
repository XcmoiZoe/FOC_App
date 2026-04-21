import 'dart:html' as html;
import 'package:flutter/material.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      html.window.location.href = "https://artbiglobalph.com/atomy";
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}