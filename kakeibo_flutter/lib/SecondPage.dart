import 'package:flutter/material.dart';
import 'ThirdPage.dart';

class SecondPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title : Text("ページ(2)")
      ),
      body : Center(
        child: TextButton(
          child: Text("3ページに進む"),
          onPressed: (){
           Navigator.push(context, MaterialPageRoute(
              builder: (context) => ThirdPage()
           ));
          },
        ),
      )
    );
  }
}