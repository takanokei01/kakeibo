import 'package:flutter/material.dart';
import 'SecondPage.dart';

class FirstPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title : Text("ページ(1)")
      ),
      body : Center(
        child: TextButton(
          child: Text("2ページに進む"),
          onPressed: (){
  Navigator.pushReplacement(context,MaterialPageRoute(
      builder: (context) => SecondPage(),
    ));
}
        ),
      )
    );
  }
}