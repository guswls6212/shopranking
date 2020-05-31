// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';

import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title:Text('네이버 쇼핑 상품 랭킹 검색'),
            backgroundColor: Colors.blue,
          ),
          body:MyTextInputForm(),
        ),
    );
  }
}

class TextInputScreen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: MyTextInputForm(),
      ),
    );
  }

}

class MyTextInputForm extends StatefulWidget {
  @override
  MyTextInputFormState createState() => new MyTextInputFormState();
}

class MyTextInputFormState extends State<MyTextInputForm>{
  final _mallNameTC = TextEditingController();
  final _keyWordTC = TextEditingController();

  double _formProgress = 0;
  String result0 = "네이버쇼핑 랭킹순 40개씩보기 기준으로";
  String result1 = "1 ~ 10 페이지내에 있는 상품만 검색 가능";
  String result2 = "";
  /*
    텍스트창 입력 상황 표시 UI
   */
  void _updateFormProgress(){
    var progress = 0.0;
    var controllers = [
      _mallNameTC,
      _keyWordTC
    ];

    for(var controller in controllers){
      if(controller.value.text.isNotEmpty){
        progress += 1 / controllers.length;
      }
    }
    //상태 변환(쇼핑몰명, 상품명 입력시)
    setState((){
      _formProgress = progress;
    });
  }

  void _searchOnClick() async {
    String keyword = _keyWordTC.text.trim();
    setState(() {
      result0 = "검색중......";
      result1 = "";
      result2 = "";
      _keyWordTC.clear();
    });
    String encodeResult = "";

    //검색어 인코딩
    encodeResult = Uri.encodeComponent(keyword);
    print(encodeResult);

    //검색URL
    String urlPath = "https://search.shopping.naver.com/search/all.nhn?";

    String shopID = "";
    int pagingIndex;
    List<dom.Element> linksA;
    List<dom.Element> linksLi;
    // 1-10페이지까지 검색
    for( pagingIndex = 1 ; pagingIndex <= 10; pagingIndex++){
    String StrPagingIndex = pagingIndex.toString();
    //GET방식 쿼리스트링
    String urlData = "origQuery=" + encodeResult +
        "&pagingIndex=$StrPagingIndex&pagingSize=40&viewType=list&sort=rel&query=" +
        encodeResult;
    http.Response response = await http.get(urlPath + urlData)
        .catchError((error) {
      print(error);
    });
    dom.Document document = parser.parse(response.body);

    /*
     *  ~ 20200531 웹 크롤링 셀렉터
     */
    //쇼핑몰명 취득 위한 쿼리 셀렉터
    linksA = document.querySelectorAll('p.mall_txt > a.mall_more');
    //쇼핑몰 순위 취득 위한 쿼리 셀렉터
    linksLi = document.querySelectorAll('li._itemSection');

     /*
      *  20200531 ~ 웹 크롤링 셀렉터
      */
//     linksA = document.querySelectorAll('basicList_mall_grade__31CEX');

    //쇼핑몰명 존재여부 확인
    for (var mallName in linksA) {
      // ~ 20200531 웹 크롤링 셀렉터
      if (mallName.attributes['title'] == _mallNameTC.text.trim()) {
        print('success');
        shopID = mallName.attributes['data-filter-value'];
        print(shopID);
        break;
      }
      // 20200531 ~ 웹 크롤링 셀렉터

    }
    if(shopID != ""){
      break;
    }
  }

    if(shopID == ""){
        setState(() {
          result0 = "일치하는 쇼핑몰이 없거나";
          result1 = "10페이지 이내에 상품이 없습니다.";
        });
        return;
      } else{
        //페이지 표시 위치
        int showRank = 1;
        String exposeRank = "";
        for(var dataRank in linksLi){
          if(dataRank.attributes['data-mall-seq'] == shopID){
            exposeRank = dataRank.attributes['data-expose-rank'];
            break;
          }
          showRank++;
        }
        if(exposeRank == ""){
          setState(() {
            result1 = "노출랭킹 에러";
          });
        }

        setState(() {
          result0 = "검색명    : $keyword";
          result1 = "노출랭킹: $exposeRank위";
          result2 = "상품위치: $pagingIndex페이지 $showRank번째";
        });
      }


      print('linksLi ${linksLi.length}');
      print('linksA ${linksA.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      onChanged: () => _updateFormProgress(),
      child:Column(
        mainAxisSize: MainAxisSize.max,
           children: [
             AnimatedProgressIndicator(value: _formProgress),
             Padding(
               padding: EdgeInsets.all(8.0),
               child: TextFormField(
                 controller: _mallNameTC,
                 decoration: InputDecoration(
                     labelText: '쇼핑몰명',
                     labelStyle: TextStyle(
                         fontFamily: 'Montserrat',
                         fontWeight: FontWeight.bold,
                         color: Colors.green
                     )
                 ),
               ),
             ),
             Padding(
               padding: EdgeInsets.all(8.0),
               child: TextFormField(
                 controller: _keyWordTC,
                 decoration: InputDecoration(
                     labelText: '검색키워드',
                     labelStyle: TextStyle(
                         fontFamily: 'Montserrat',
                         fontWeight: FontWeight.bold,
                         color: Colors.green
                     )
                 ),
               ),
             ),
             FlatButton(
               color: Colors.blue,
               textColor: Colors.white,
               onPressed: _formProgress == 1 ? _searchOnClick : null,
               child: Text('검색'),
             ),
             SizedBox(
               width:350,
               child:Text(
                 result0,
                 style: TextStyle(height: 1, fontSize: 20),
               ),
             ),
             SizedBox(
               width:350,
               child:Text(
                 result1,
                 style: TextStyle(height: 1, fontSize: 20),
               ),
             ),
             SizedBox(
               width:350,
               child:Text(
                 result2,
                 style: TextStyle(height: 1, fontSize: 20),
               ),
             )
           ],
          ),
        );
  }

}

// 텍스트창 입력 상황 표시 애니메이션
class AnimatedProgressIndicator extends StatefulWidget {
  final double value;

  AnimatedProgressIndicator({
    @required this.value,
  });

  @override
  State<StatefulWidget> createState() {
    return _AnimatedProgressIndicatorState();
  }
}

class _AnimatedProgressIndicatorState extends State<AnimatedProgressIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Color> _colorAnimation;
  Animation<double> _curveAnimation;

  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: Duration(milliseconds: 1200), vsync: this);

    var colorTween = TweenSequence([
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.red, end: Colors.orange),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: Colors.orange, end: Colors.green),
        weight: 1,
      ),
    ]);

    _colorAnimation = _controller.drive(colorTween);
    _curveAnimation = _controller.drive(CurveTween(curve: Curves.easeIn));
  }

  void didUpdateWidget(oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.animateTo(widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => LinearProgressIndicator(
        value: _curveAnimation.value,
        valueColor: _colorAnimation,
        backgroundColor: _colorAnimation.value.withOpacity(0.4),
      ),
    );
  }
}