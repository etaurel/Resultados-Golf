import 'dart:convert';
import 'dart:typed_data';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'Dart:ui' as ui;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:golfguidescorecard/models/postTorneo.dart';
import 'package:golfguidescorecard/scoresCard/firma.dart';
import 'package:golfguidescorecard/services/db-api.dart';
import 'package:golfguidescorecard/utilities/display-functions.dart';
import 'package:golfguidescorecard/utilities/fecha.dart';
import 'package:golfguidescorecard/utilities/functions.dart';
import 'package:golfguidescorecard/utilities/global-data.dart';
import 'package:golfguidescorecard/utilities/language/lan.dart';
import 'package:golfguidescorecard/utilities/user-funtions.dart';
import 'package:page_transition/page_transition.dart';
import 'package:path_provider/path_provider.dart';

class ResultadosSF extends StatefulWidget {
  @override
  List<DataJugadorScore> dataJugadoresScore;
  String logo;
  String image;
  int indiceJuga;

  ResultadosSF({List<DataJugadorScore> dataSCJugadores, String logo, String image, int indiceJuga}) {
    print(indiceJuga);
    dataJugadoresScore = dataSCJugadores;
    this.logo = logo;
    this.image = image;
    this.indiceJuga=indiceJuga;
  }

  _ResultadosSFState createState() => _ResultadosSFState(
      dataSCJugadores: dataJugadoresScore, logo: logo, image: image, indiceJuga: indiceJuga);
}

class _ResultadosSFState extends State<ResultadosSF> {
  static GlobalKey previewContainer = new GlobalKey();
  Lan lan = new Lan();
  List<DataJugadorScore> _dataJugadoresLinea;
  DataJugadorScore dataJugadorScore;
  String logo;
  String image;
  int indiceJuga=0;

  _ResultadosSFState(
      {List<DataJugadorScore> dataSCJugadores, String logo, String image,int indiceJuga}) {
    _dataJugadoresLinea= dataSCJugadores;
    //print([1,2,8,6].reduce(max));
    //dataJugadorScore = dataSCJugadores[indiceJuga];
    dataJugadorScore = dataSCJugadores[maxInt(0,indiceJuga)];
    this.logo = logo;
    this.image = image;
    this.indiceJuga=indiceJuga;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: previewContainer,
      child: new Scaffold(
        backgroundColor: Color(0xFFE1E1E1),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              stackImage2(
                  clubImage: image,
                  clubLogo: logo,
                  assetImage: 'assets/ScoreCard2.png'),
              Container(
                padding: EdgeInsets.only(top: 5, left: 15, right: 15),
                alignment: Alignment.center,
                color: Colors.black,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Power by ',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                      textScaleFactor: 1,
                    ),
                    Container(
                      padding: EdgeInsets.only(top: 3, bottom: 3),
                      height: 25,
                      child: Image.network(
                        'http://scoring.com.ar/app/images/publi/scoringpro/leaderboard.jpg',
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(left: 10, right: 10),
                child: Column(
                  children: <Widget>[
                    Container(
                      height: 10,
                    ),
                    Row(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(
                              dataJugadorScore.images.trim() ?? ''),
                          backgroundColor: Colors.black,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                width: 220,
                                child: Text(
                                  dataJugadorScore.nombre_juga,
                                  maxLines: 1,
                                  textScaleFactor: 1,
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w300),
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      dataJugadorScore.matricula +
                                          ' • ' +
                                          dataJugadorScore.hcpTorneo
                                              .toString() +
                                          ' | ',
                                      textScaleFactor: 1,
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w400),
                                    ),
                                    Text(
                                      Fecha.fechaHoyStringLarge,
                                      textScaleFactor: 1,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
//                            width: 35,
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              //Share.text('CODIGO ', '', 'text/plain');
                              _sendTarjetaApp(context);
                              //_sendMailTarjeta(context);
                            },
                            child: Icon(
                              Icons.system_update_alt,
                              size: 30,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 10,
                    ),

                    /// Hoyos 1-9
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          width: MediaQuery.of(context).size.width - 20,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1),
                            color: Color(0xFF1f2f50),
                          ),
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 35,
                                  child: Text(
                                    'Hoyo',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                    textScaleFactor: 1,
                                  ),
                                ),
                              ),
                              _expandHoyoLabel(1),
                              _expandHoyoLabel(2),
                              _expandHoyoLabel(3),
                              _expandHoyoLabel(4),
                              _expandHoyoLabel(5),
                              _expandHoyoLabel(6),
                              _expandHoyoLabel(7),
                              _expandHoyoLabel(8),
                              _expandHoyoLabel(9),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 25,
                                  child: Text(
                                    'IN',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                    textScaleFactor: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// Par del Hoyo
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          width: MediaQuery.of(context).size.width - 20,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 35,
                                  child: Text(
                                    'Par',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 15,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400),
                                    textScaleFactor: 1,
                                  ),
                                ),
                              ),
                              _expandHoyoPar(1),
                              _expandHoyoPar(2),
                              _expandHoyoPar(3),
                              _expandHoyoPar(4),
                              _expandHoyoPar(5),
                              _expandHoyoPar(6),
                              _expandHoyoPar(7),
                              _expandHoyoPar(8),
                              _expandHoyoPar(9),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 25,
                                  child: Text(
                                    UserFunctions.sumParIda(
                                            dataJugadorScore.postTee)
                                        .toString(),
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 15,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400),
                                    textScaleFactor: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// Handicaps
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white54,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          width: MediaQuery.of(context).size.width - 20,
                          height: 30,
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 35,
                                  child: Text(
                                    'Hcp',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 15,
                                        color: Colors.black87),
                                    textScaleFactor: 1,
                                  ),
                                ),
                              ),
                              _expandHoyoHcp(1),
                              _expandHoyoHcp(2),
                              _expandHoyoHcp(3),
                              _expandHoyoHcp(4),
                              _expandHoyoHcp(5),
                              _expandHoyoHcp(6),
                              _expandHoyoHcp(7),
                              _expandHoyoHcp(8),
                              _expandHoyoHcp(9),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 25,
                                  child: Text(
                                    '',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 15,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600),
                                    textScaleFactor: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// Resultado
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          width: MediaQuery.of(context).size.width - 20,
                          height: 30,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 35,
                                  child: Text(
                                    'MP',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 18,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600),
                                    textScaleFactor: 1,
                                  ),
                                ),
                              ),
                              _expandHoyoScore(1),
                              _expandHoyoScore(2),
                              _expandHoyoScore(3),
                              _expandHoyoScore(4),
                              _expandHoyoScore(5),
                              _expandHoyoScore(6),
                              _expandHoyoScore(7),
                              _expandHoyoScore(8),
                              _expandHoyoScore(9),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 25,
                                  child: Text(
                                    UserFunctions.scoreZeroToEmpty(
                                        dataJugadorScore.ida),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 18,
                                        color: Colors.black),
                                    textScaleFactor: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// Stableford
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          width: MediaQuery.of(context).size.width - 20,
                          height: 30,
                          child: Row(
                            children: <Widget>[
                              Container(
                                color: Colors.black45,
                                padding: EdgeInsets.all(5.0),
                                width: 45,
                                child: Text(
                                  'ST',
                                  style: TextStyle(
                                      fontFamily: 'DIN Condensed',
                                      fontSize: 18,
                                      color: Colors.white,
//                                      color: Color(0xFF1f2f50),
                                      fontWeight: FontWeight.w800),
                                  textScaleFactor: 1,
                                ),
                              ),
//                            ),
                              _expandHoyoST(1),
                              _expandHoyoST(2),
                              _expandHoyoST(3),
                              _expandHoyoST(4),
                              _expandHoyoST(5),
                              _expandHoyoST(6),
                              _expandHoyoST(7),
                              _expandHoyoST(8),
                              _expandHoyoST(9),

                              Container(
                                color: Colors.black45,
                                padding: EdgeInsets.all(5.0),
                                width: 35,
                                child: Text(
                                  UserFunctions.stablefordZeroToEmpty(
                                      dataJugadorScore.stablefordIda,
                                      dataJugadorScore.ida),
                                  style: TextStyle(
                                      fontFamily: 'DIN Condensed',
                                      fontSize: 18,
                                      color: Colors.white,
//                                      color: Color(0xFF1f2f50),
                                      fontWeight: FontWeight.w800),
                                  textScaleFactor: 1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Container(
                      height: 30,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'MP: MEDAL PLAY (Stroke Play) | ST: STABLEFORD',
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.black,
                            fontWeight: FontWeight.bold),
                        textScaleFactor: 1,
                        textAlign: TextAlign.left,
                      ),
                    ),

                    /// Hoyos 10-18
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          width: MediaQuery.of(context).size.width - 20,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1),
                            color: Color(0xFF1f2f50),
                          ),
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 35,
                                  child: Text(
                                    'Hoyo',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                    textScaleFactor: 1,
                                  ),
                                ),
                              ),
                              _expandHoyoLabel(10),
                              _expandHoyoLabel(11),
                              _expandHoyoLabel(12),
                              _expandHoyoLabel(13),
                              _expandHoyoLabel(14),
                              _expandHoyoLabel(15),
                              _expandHoyoLabel(16),
                              _expandHoyoLabel(17),
                              _expandHoyoLabel(18),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 25,
                                  child: Text(
                                    'OUT',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                    textScaleFactor: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// Par del Hoyo
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          width: MediaQuery.of(context).size.width - 20,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 35,
                                  child: Text(
                                    'Par',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 15,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400),
                                    textScaleFactor: 1,
                                  ),
                                ),
                              ),
                              _expandHoyoPar(10),
                              _expandHoyoPar(11),
                              _expandHoyoPar(12),
                              _expandHoyoPar(13),
                              _expandHoyoPar(14),
                              _expandHoyoPar(15),
                              _expandHoyoPar(16),
                              _expandHoyoPar(17),
                              _expandHoyoPar(18),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 25,
                                  child: Text(
                                    UserFunctions.sumParVuelta(
                                            dataJugadorScore.postTee)
                                        .toString(),
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 18,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w400),
                                    textScaleFactor: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// Handicaps
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1),
                            color: Colors.white54,
                          ),
                          width: MediaQuery.of(context).size.width - 20,
                          height: 30,
                          child: Row(
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 35,
                                  child: Text(
                                    'Hcp',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 15,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w300),
                                    textScaleFactor: 1,
                                  ),
                                ),
                              ),
                              _expandHoyoHcp(10),
                              _expandHoyoHcp(11),
                              _expandHoyoHcp(12),
                              _expandHoyoHcp(13),
                              _expandHoyoHcp(14),
                              _expandHoyoHcp(15),
                              _expandHoyoHcp(16),
                              _expandHoyoHcp(17),
                              _expandHoyoHcp(18),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 25,
                                  child: Text(
                                    '',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 15,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600),
                                    textScaleFactor: 1,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// Resultado
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1),
                            color: Colors.transparent,
                          ),
                          width: MediaQuery.of(context).size.width - 20,
                          height: 30,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 35,
                                  child: Text(
                                    'MP',
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 18,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600),
                                    textScaleFactor: 1,
                                  ),
                                ),
                              ),
                              _expandHoyoScore(10),
                              _expandHoyoScore(11),
                              _expandHoyoScore(12),
                              _expandHoyoScore(13),
                              _expandHoyoScore(14),
                              _expandHoyoScore(15),
                              _expandHoyoScore(16),
                              _expandHoyoScore(17),
                              _expandHoyoScore(18),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Container(
                                  width: 25,
                                  child: Text(
                                    UserFunctions.scoreZeroToEmpty(
                                        dataJugadorScore.vuelta),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontFamily: 'DIN Condensed',
                                        fontSize: 18,
                                        color: Colors.black),
                                    textScaleFactor: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    /// Stableford
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 1),
                            color: Colors.black26,
                          ),
                          width: MediaQuery.of(context).size.width - 20,
                          height: 30,
                          child: Row(
                            children: <Widget>[
                              Container(
                                color: Colors.black45,
                                padding: EdgeInsets.all(5.0),
                                width: 45,
                                child: Text(
                                  'ST',
                                  style: TextStyle(
                                      fontFamily: 'DIN Condensed',
                                      fontSize: 18,
                                      color: Colors.white,
//                                      color: Color(0xFF1f2f50),
                                      fontWeight: FontWeight.w800),
                                  textScaleFactor: 1,
                                ),
                              ),
                              _expandHoyoST(10),
                              _expandHoyoST(11),
                              _expandHoyoST(12),
                              _expandHoyoST(13),
                              _expandHoyoST(14),
                              _expandHoyoST(15),
                              _expandHoyoST(16),
                              _expandHoyoST(17),
                              _expandHoyoST(18),
                              Container(
                                color: Colors.black45,
                                padding: EdgeInsets.all(5.0),
                                width: 35,
                                child: Text(
                                  UserFunctions.stablefordZeroToEmpty(
                                      dataJugadorScore.stablefordVuelta,
                                      dataJugadorScore.vuelta),
                                  style: TextStyle(
                                      fontFamily: 'DIN Condensed',
                                      fontSize: 18,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800),
                                  textScaleFactor: 1,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    Container(
                      height: 10,
                    ),

                    /// Resultado FINAL
                    Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              width: MediaQuery.of(context).size.width - 20,
                              height: 30,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    alignment: Alignment.center,
                                    color: Colors.black54,
//                                    height: 30,
                                    width: 50,
                                    child: Text(
                                      'GROSS',
                                      style: TextStyle(
                                          fontFamily: 'DIN Condensed',
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                      textScaleFactor: 1,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      alignment: Alignment.center,
                                      color: Colors.black, height: 50,
//                                  width: 70,
                                      child: Text(
                                        'TOTAL MEDAL PLAY',
                                        style: TextStyle(
                                            fontFamily: 'DIN Condensed',
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                        textScaleFactor: 1,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(5),
                                      alignment: Alignment.center,
                                      color: Colors.black, height: 50,
//                                  height: 50,
//                                  width: 70,
                                      child: Text(
                                        'TOTAL STABLEFORD',
                                        style: TextStyle(
                                            fontFamily: 'DIN Condensed',
                                            fontSize: 16,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                        textScaleFactor: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              width: MediaQuery.of(context).size.width - 20,
                              height: 50,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Container(
                                    alignment: Alignment.center,
                                    color: Colors.black12,
                                    width: 50,
                                    child: Text(
                                      UserFunctions.scoreZeroToEmpty(
                                          dataJugadorScore.gross),
                                      style: TextStyle(
                                          fontFamily: 'DIN Condensed',
                                          fontSize: 25,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600),
                                      textAlign: TextAlign.center,
                                      textScaleFactor: 1,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.center,
                                      color: Color(0xFFFF0030),
                                      child: Text(
                                        //UserFunctions.scoreZeroToEmpty(UserFunctions.miif(dataJugadorScore.neto>40, dataJugadorScore.neto, 0)),
                                        _scoreNeto(),

                                        // NOTA: definir que mostrar ¿?
                                        style: TextStyle(
                                            fontSize: 35,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                        textScaleFactor: 1,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: Container(
                                      alignment: Alignment.center,
                                      color: Color(0xFFFF0030),
                                      child: Text(
                                        UserFunctions.stablefordZeroToEmpty(
                                            dataJugadorScore.stableford,
                                            dataJugadorScore.gross),

                                        // NOTA: definir que mostrar ¿?
                                        style: TextStyle(
                                            fontSize: 35,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600),
                                        textAlign: TextAlign.center,
                                        textScaleFactor: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Container(
                          height: 10,
                        ),
                        // Row(
                        //   mainAxisAlignment: MainAxisAlignment.center,
                        //   children: <Widget>[
                        //     new GestureDetector(
                        //       onTap: () {
                        //         _llamaFirma(context);
                        //       },
                        //       child: Container(
                        //         decoration: BoxDecoration(
                        //             border: Border.all(
                        //                 color: Colors.black, width: 1),
                        //             color: Colors.white),
                        //         width: 140,
                        //         height: 80,
                        //         child: _mostraFirma(
                        //             dataJugadorScore.firmaUserImage),
                        //       ),
                        //     ),
                        //     Container(
                        //       width: 5,
                        //     ),
                        //     Container(
                        //       decoration: BoxDecoration(
                        //           border:
                        //               Border.all(color: Colors.black, width: 1),
                        //           color: Colors.white),
                        //       width: 140,
                        //       height: 80,
                        //       child: _mostraFirma(
                        //           dataJugadorScore.firmaMarcadorImage),
                        //     ),
                        //   ],
                        // ),
                        Container(
                          height: 10,
                        ),
                      ],
                    ),
                    Container(
                      child: SizedBox(
                        height: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: FloatingActionButton(
          child: Icon(
            Icons.keyboard_arrow_left,
            size: 40,
          ),
          backgroundColor: Colors.black,
          onPressed: () {
            Navigator.of(context).pop();
            //Navigator.of(context).popUntil((route) => false);
          },
        ),
        bottomNavigationBar: CurvedNavigationBar(
          index: 0,
          height: 60.0,
          items: <Widget>[
            Builder(builder: (context) {
              return IconButton(
                icon: Icon(Icons.golf_course, size: 30, color: Colors.white),

              );
            }),
          ],
          color: Color(0xFF1f2f50),
//        color: Color(0xFFFF0030),
          buttonBackgroundColor: Color(0xFF1f2f50),
//        buttonBackgroundColor: Color(0xFFFF0030),
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeInOut,
          animationDuration: Duration(milliseconds: 600),
        ),

      ),
    );
  }

  String _scoreNeto() {
//    print('dataJugadorScore.status_med');
//    print(dataJugadorScore.status_med);
//    print('dataJugadorScore.status_med');

    if (dataJugadorScore.status_med != null) {
      if (dataJugadorScore.status_med.trim().length > 0) {
        return dataJugadorScore.status_med;
      }
    }
    return UserFunctions.scoreZeroToEmpty(
        (int.parse(dataJugadorScore.postTee.par) + dataJugadorScore.netoAlPar));
  }

  // void _llamaFirma(BuildContext context) async {
  //   if (indiceJuga==-1){
  //     return;
  //   }
  //
  //   //print('doble presssss');
  //   List<DataJugadorScore> datJureSco = [];
  //   datJureSco.add(dataJugadorScore);
  //   Navigator.push(
  //     context,
  //     PageTransition(
  //       type: PageTransitionType.fade,
  //       child: Firma(dataJugadoresScore:_dataJugadoresLinea,indiceJuga: indiceJuga,),
  //     ),
  //   ).then((value) => {Navigator.of(context).pop()});
  //   //print('passs    doble presssss');
  // }

  _expandHoyoLabel(int hoyoNro) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Text(
          hoyoNro.toString(),
          style: TextStyle(
              fontFamily: 'DIN Condensed',
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
          textScaleFactor: 1,
        ),
      ),
    );
  }

  _expandHoyoHcp(int pHcpHoyo) {
    var hcpHoyo = dataJugadorScore.hoyos[pHcpHoyo - 1].handicap;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Text(
          hcpHoyo.toString(),
          style: TextStyle(
              fontFamily: 'DIN Condensed', fontSize: 15, color: Colors.black87),
          textAlign: TextAlign.center,
          textScaleFactor: 1,
        ),
      ),
    );
  }

  _expandHoyoPar(int pParHoyo) {
    var parHoyo = dataJugadorScore.hoyos[pParHoyo - 1].par;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Text(
          parHoyo.toString(),
          style: TextStyle(
              fontFamily: 'DIN Condensed',
              fontSize: 15,
              color: Colors.black,
              fontWeight: FontWeight.w400),
          textAlign: TextAlign.center,
          textScaleFactor: 1,
        ),
      ),
    );
  }

  _expandHoyoScore(int pScoreHoyo) {
    var scoreHoyo = dataJugadorScore.hoyos[pScoreHoyo - 1].score;
    Color colorScoreBack = UserFunctions.resolverColorScore(
        scoreHoyo, dataJugadorScore.hoyos[pScoreHoyo - 1].par);
    Color colorScoreFont = UserFunctions.resolverColorScore(
        scoreHoyo, dataJugadorScore.hoyos[pScoreHoyo - 1].par,
        isFont: true);
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 0.3),
          color: colorScoreBack,
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.all(5.0),
        child: Text(
          UserFunctions.scoreZeroToEmpty(scoreHoyo),
          style: TextStyle(
              fontFamily: 'DIN Condensed', fontSize: 18, color: colorScoreFont),
          textAlign: TextAlign.center,
          textScaleFactor: 1,
        ),
      ),
    );
  }

  _expandHoyoST(int pSTHoyo) {
    var stHoyo = dataJugadorScore.hoyos[pSTHoyo - 1].stableford;
    var scoreHoyo = dataJugadorScore.hoyos[pSTHoyo - 1].score;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 0.1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Text(
            UserFunctions.stablefordZeroToEmpty(stHoyo, scoreHoyo),
            style: TextStyle(
                fontFamily: 'DIN Condensed',
                fontSize: 18,
                color: Colors.white,
//                color: Color(0xFF1f2f50) ,
                fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
            textScaleFactor: 1,
          ),
        ),
      ),
    );
  }

  // _mostraFirma(Uint8List firma) {
  //   //print('************************************' + firma.length.toString());
  //   if (firma == null || firma.length < 10) {
  //     return Container(
  //       color: Colors.black12,
  //       child: Center(
  //         child: Text(
  //           'Falta Firma',
  //           style: TextStyle(fontSize: 15, color: Colors.black45),
  //           textAlign: TextAlign.center,
  //           textScaleFactor: 1,
  //         ),
  //       ),
  //     );
  //   } else {
  //     return Padding(
  //       padding: EdgeInsets.all(0.0),
  //       child: Image.memory(firma),
  //     );
  //   }
  // }

  // Future<void> _sendMailTarjeta(BuildContext context) async {
  //   print('envio de la tarjeta por e-mail');
  //   var _pasaDato = await dialogoOkCancel(
  //       context: context,
  //       title: lan.dialogTarjetaEnvioMailTitle,
  //       question: lan.dialogTarjetaEnvioMailQuestion);
  //   if (_pasaDato == true) {
  //     print('*** NOTIFICACION *** Enviando Tarjeta');
  //     Uint8List imagenScreen = await takeScreenShot();
  //     //print(base64Encode(imagenScreen));
  //     DBApi.sendMailTarjeta(
  //         imagenScreen, dataJugadorScore, dataJugadorScore.matricula);
  //   }
  //   print('paso');
  //   //tarjeta
  // }

  Future<void> _sendTarjetaApp(BuildContext context) async {
    print('envio de la tarjeta por app');
//    var _pasaDato = await dialogoOkCancel(
//        context: context,
//        title: lan.dialogTarjetaEnvioMailTitle,
//        question: lan.dialogTarjetaEnvioMailQuestion);
//    if (_pasaDato == true) {
      print('*** NOTIFICACION *** Enviando Tarjeta');
      Uint8List imagenScreen = await takeScreenShot();
      await Share.file('TARJETA', 'tarjeta.png', imagenScreen, 'image/png');
//    }
  }

  /// fin clase
  ///
  ///
  Future<Uint8List> takeScreenShot() async {
    RenderRepaintBoundary boundary =
        previewContainer.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    final directory = (await getApplicationDocumentsDirectory()).path;
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    print(pngBytes);
    return pngBytes;
//    File imgFile =new File('$directory/screenshot.png');
//    imgFile.writeAsBytes(pngBytes);
  }
}
