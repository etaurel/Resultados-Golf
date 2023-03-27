import 'dart:async';
import 'dart:convert';
import 'package:connection_status_bar/connection_status_bar.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:golfguidescorecard/gps/hoyo_V1.dart';
import 'package:golfguidescorecard/gps/hoyo_V2.dart';
import 'package:golfguidescorecard/gps/hoyo_V3.dart';
import 'package:golfguidescorecard/gps/hoyo_V4.dart';
import 'package:golfguidescorecard/gps/hoyo_V5.dart';
import 'package:golfguidescorecard/main.dart';
import 'package:golfguidescorecard/mod_serv/model.dart';
import 'package:golfguidescorecard/models/postTorneo.dart';
import 'package:golfguidescorecard/scoresCard/agregarJugadores.dart';
import 'package:golfguidescorecard/scoresCard/agregarModalidad.dart';
import 'package:golfguidescorecard/scoresCard/firma.dart';
import 'package:golfguidescorecard/scoresCard/leaderBoardMP.dart';
import 'package:golfguidescorecard/scoresCard/parcheConexion.dart';
import 'package:golfguidescorecard/scoresCard/tablaResultadosFin.dart';
import 'package:golfguidescorecard/scoresCard/tablaResultadosSF.dart';
import 'package:golfguidescorecard/scoresCard/torneo.dart';
import 'package:golfguidescorecard/services/db-admin.dart';
import 'package:golfguidescorecard/services/db-api.dart';
import 'package:golfguidescorecard/utilities/display-functions.dart';
import 'package:golfguidescorecard/utilities/global-data.dart';
import 'package:golfguidescorecard/utilities/language/lan.dart';
import 'package:golfguidescorecard/utilities/messages-toast.dart';
import 'package:golfguidescorecard/utilities/user-funtions.dart';
import 'package:page_transition/page_transition.dart';
import 'package:golfguidescorecard/herramientas/bottonNavigator.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';

class ScoreCard extends StatefulWidget {
  ScoreCard() : super();
  @override
  ScoreCardState createState() => ScoreCardState();
}

class ScoreCardState extends State<ScoreCard> with WidgetsBindingObserver {
  int idClubCancha;
  bool _controlClickPress=false;
  MessagesToast mToast;
  Lan lan = new Lan();
  AppLifecycleState _notification;
  bool _estadoFrmIsOk = true;
  PostUser postUser;
  PostTorneo postTorneo;
  List<DataJugadorScore> _jugadores;
  ScoreCardState();
  List<DataJugadorScore> _dataJugadoresScore = [];
  GlobalKey<ScaffoldState> _scaffoldKey;
  List<TextEditingController> _controllerHoyo = [];
  bool _isupdating;
  Timer _timer;
  int _id_torneo = 0;
  int _id_user = 0;
  String _matriculas = '';

  bool isLoading = false;

  @override
  void dispose() {
    Torneo.dataJugadoresScore = _dataJugadoresScore;
    _timer.cancel();
    print('lost focus in dispose');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_timer.isActive==true) {
          print(
              "app in resumed---------------------ACTIVO-----------------------------timer");
        } else {
          print(
              "app in resumed------------------NOOOO---ACTIVO------------------------timer");
          _timer =
              new Timer.periodic(new Duration(seconds: 5), _getControlScore);
        }
        print(
            "-----------------------------------------------------------app in resumed");
        break;
      case AppLifecycleState.inactive:
        _timer.cancel();
        print(
            "-----------------------------------------------------------app in inactive");
        break;
      case AppLifecycleState.paused:
        print(
            "--------------------------------------------------------------app in paused");
        break;
      case AppLifecycleState.detached:
        print(
            "--------------------------------------------------------------app in detached");
        break;
    }
    setState(() {
      _notification = state;
    });
  }

  @override
  Future<void> initState() {
    super.initState();
    // Inicializa la variable "idClubCancha" con el ID del club de la cancha en juego
    idClubCancha = int.parse(Torneo.postTorneoJuego.id_club_cancha);

    this.postUser = GlobalData.postUser;
    postTorneo = Torneo.postTorneoJuego;

    /// VERIFICAR SI HAY TARJETAS ACTIVAS
    ///
    if (Torneo.dataJugadoresScore == null) {
      print('VOLVER NO HAY Jugadores');
      Navigator.of(context).pop();


    } else {
      _dataJugadoresScore = Torneo.dataJugadoresScore;
      _dataJugadoresScore.forEach((jugador) {
        _controllerHoyo.add(TextEditingController());
        _controllerHoyo[_controllerHoyo.length - 1].text = '';
      });

      _controlTry();
    }
    _id_torneo = int.parse(Torneo.postTorneoJuego.id_torneo);
    _id_user = int.parse(postUser.matricula);
    _dataJugadoresScore.forEach((dJS) {
      if (_matriculas.length > 1) {
        _matriculas = _matriculas + ', ';
      }
      _matriculas = _matriculas + ' ' + dJS.matricula.trim();
    });

    _isupdating = false;
    _scaffoldKey = GlobalKey(); // key to get the context to show a SnackBar

    if (_timer==null ||_timer.isActive==false) {
      _timer = new Timer.periodic(new Duration(seconds: 5) ,_getControlScore);
    }
    WidgetsBinding.instance.addObserver(this);
  }

  void _selectText(TextEditingController controller) {
    controller.selection = TextSelection(
        baseOffset: 0, extentOffset: controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);
    int idClubCancha = int.parse(Torneo.postTorneoJuego.id_club_cancha);

    mToast = MessagesToast(context: context);
    var _marcadorData = {
      'ida': '',
      'vuelta': '',
      'gross': '',
      'hcp': '',
      'netoAlPar': ''
    };
    if (_dataJugadoresScore.length > 1) {
      _marcadorData = {
        'ida': _dataJugadoresScore[1].ida.toString(),
        'vuelta': _dataJugadoresScore[1].vuelta.toString(),
        'gross': _dataJugadoresScore[1].gross.toString(),
        'hcp': _dataJugadoresScore[1].hcpTorneo.toString(),
        'netoAlPar':
            UserFunctions.scoreZeroToParE(_dataJugadoresScore[1].netoAlPar)
      };
    }

    return WillPopScope(
      onWillPop: () => Future.value(false),
          child: Scaffold(
        backgroundColor: Color(0xFFE1E1E1),
        key: _scaffoldKey,
        body: SingleChildScrollView(
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    stackImage(
                        clubImage: Torneo.postTorneoJuego.postClub.imagen,
                        clubLogo: Torneo.postTorneoJuego.postClub.logo,
                        assetImage: 'assets/clubes/logocolor.png'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          children: [
                            RaisedButton(
                              elevation: 5.0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50.0)),
                              color: Colors.lightGreenAccent,
//                        color: Color(0xFFFF0030),
                              child: Container(
                                width: 50,
                                height: 60,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Image.asset('assets/ico_leaderboardN.png', scale: 1),
                                  ],
                                ),
                              ),
                              onPressed: () {
                                _toLeaderboard(context);
                              },
                            ),
                            Container(
                              height: 5,
                            ),
                            Container(
                              color: Colors.lightGreenAccent,
                              child: Text(' LEADERBOARD ',
                                textScaleFactor: 1.0,
                                textAlign: TextAlign.center,
                                style:
                                TextStyle(fontSize: 12.0, color: Colors.black)),
                            ),
                            Container(
                              height: 5,
                            ),
                          ],
                        ),
                        Container(
                          width: 15,
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: ConnectionStatusBar(),
                    ),
                  ],
                ),
                Container(
                  color: Color(0xFFDDDDDD),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Container(
                        height: 20,
                        width: 160,
                        color: Color(0xFFFF0030),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              languageProvider.translate('MI SCORE'),
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(),
                      ),
                      Container(
                        height: 20,
                        width: 160,
                        color: Color(0xFF02A7FB),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                        languageProvider.translate('SCORE JUGADOR 2'),
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ), // NOMBRE JyM
                Container(
                  color: Color(0xFFE1E2E2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Container(
                        height: 25,
                        width: 30,
                        color: Color(0xFF3C3C3C),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              languageProvider.translate('IDA'),
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 25,
                        width: 30,
                        color: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              languageProvider.translate('VTA'),
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 25,
                        width: 35,
                        color: Color(0xFF3C3C3C),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'GRS',
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 25,
                        width: 30,
                        color: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'HCP',
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 25,
                        width: 35,
                        color: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'TOT',
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(),
                      ),
                      Container(
                        height: 25,
                        width: 30,
                        color: Color(0xFF3C3C3C),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              languageProvider.translate('IDA'),
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 25,
                        width: 30,
                        color: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              languageProvider.translate('VTA'),
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 25,
                        width: 35,
                        color: Color(0xFF3C3C3C),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'GRS',
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 25,
                        width: 30,
                        color: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'HCP',
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 25,
                        width: 35,
                        color: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'TOT',
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ), // IDA VTA
                Container(
                  color: Color(0xFFEAEBEB),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Container(
                        height: 30,
                        width: 30,
                        color: Color(0xFFFF0030),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              _dataJugadoresScore[0].ida.toString(),
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 30,
                        color: Color(0xFFCF0707),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              _dataJugadoresScore[0].vuelta.toString(),
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 35,
                        color: Color(0xFF760000),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              _dataJugadoresScore[0].gross.toString(),
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 30,
                        color: Color(0xFFEAEBEB),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "${(double.parse(_dataJugadoresScore[0].hcpTorneo.toString() ?? '')).toStringAsFixed(0)}",
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFCF0707)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 35,
                        color: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              UserFunctions.scoreZeroToParE(
                                  _dataJugadoresScore[0].netoAlPar),
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(),
                      ),
                      Container(
                        height: 30,
                        width: 30,
                        color: Color(0xFF02A7FB),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              //UserFunctions.miif(_dataJugadoresScore.length>1, _dataJugadoresScore[(_dataJugadoresScore.length-1)].ida, '')??'',
                              _marcadorData['ida'].toString() ?? '',
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 30,
                        color: Colors.blue,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              //_dataJugadoresScore[1].vuelta.toString()??'',
                              _marcadorData['vuelta'].toString() ?? '',
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 35,
                        color: Color(0xFF00528B),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              //_dataJugadoresScore[1].gross.toString()??'',
                              _marcadorData['gross'].toString() ?? '',
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 30,
                        color: Color(0xFFEAEBEB),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              //"${(double.parse(_dataJugadoresScore[1].hcpTorneo.toString() ?? '')).toStringAsFixed(0)}",
                              _marcadorData['hcp'].toString() ?? '',
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 30,
                        width: 35,
                        color: Colors.black,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              //UserFunctions.scoreZeroToParE(_dataJugadoresScore[1].netoAlPar),
                              _marcadorData['netoAlPar'] ?? '',
                              textScaleFactor: 1.0,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ), // NUMEROS

                Container(
                  child: Row(
                    children: <Widget>[
                      /// Datos Matricula
                      DataTable(
                        columnSpacing: 0,
                        horizontalMargin: 0,
                        // headingRowHeight: 82, /// CON O SIN GPS
                        headingRowHeight: 110,
                        dataRowHeight: 70,
                        columns: [
                          DataColumn(
                            label: Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 8),
                              child: Container(
                                width: 150,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                Container (
                                  alignment: Alignment.center,
                                  child: Text( languageProvider.translate('Código de Torneo'), textAlign: TextAlign.center, textScaleFactor: 1, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
                                ),
                                Container (
                                  alignment: Alignment.center,
                                  child: Text("${(Torneo.postTorneoJuego.codigo_torneo)}", textAlign: TextAlign.center, textScaleFactor: 1, style: TextStyle(fontSize: 35, color: Colors.red, fontWeight: FontWeight.w800),),
                                  ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        rows: _dataJugadoresScore
                            .map(
                              (jugador) => DataRow(cells: [
                                DataCell(
                                  Container(
                                      height: 70,
                                      width: 155,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: <Widget>[
                                          Container(
                                            height: 100,
                                            width: 8,
                                            decoration: BoxDecoration(
                                              color: UserFunctions
                                                  .resolverColorTee(
                                                      jugador.postTee.tee??''),
                                              border: Border.all(
                                                  color: Colors.black,
                                                  width: 0.5),
                                            ),
                                          ),
                                          Container(
                                            width: 3,
                                          ),
                                          CircleAvatar(
                                            radius: 25,
                                            backgroundImage: NetworkImage(
                                                jugador.images.trim() ?? ''),
                                            backgroundColor: Colors.black,
                                          ),
                                          Container(
                                            alignment: Alignment.centerLeft,
                                            padding: EdgeInsets.only(left: 3),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Container(
                                                  width: 90,
                                                  height: 20,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    jugador.nombre_juga
                                                            .trim()
                                                            .toLowerCase()
                                                            .titleCase ??
                                                        '',
                                                    textScaleFactor: 1,
                                                    style: TextStyle(
                                                        fontFamily:
                                                            'DIN Condensed',
                                                        fontSize: 19,
                                                        color: Colors.black),
                                                    textAlign: TextAlign.left,
                                                  ),
                                                ),
                                                Container(
                                                  width: 90,
                                                  height: 32,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: Text(
                                                    jugador.matricula,
                                                    textScaleFactor: 1,
                                                    style: TextStyle(
                                                        fontFamily:
                                                            'DIN Condensed',
                                                        fontSize: 26,
                                                        color: Colors.black),
                                                    textAlign: TextAlign.left,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )),
                                  onTap: () {
                                    _llamandoResultado(jugador, context);
                                  },
                                ),
                              ]),
                            )
                            .toList(),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[
                          Container(
                            child: _dataBody(),
                            width: MediaQuery.of(context).size.width - 175,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.only(left: 10, top: 5),
                  height: 30,
                  child: Row(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: UserFunctions
                              .colorCirculoScoreCardPendiente, //  Colors.amberAccent,
                          border: Border.all(color: Colors.black, width: 0.3),
                        ),
                        height: 15,
                        width: 15,
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 5, right: 5),
                        child: Text(
                           languageProvider.translate('Falta Score'),
                          style: TextStyle(fontSize: 12),
                          textScaleFactor: 1,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: UserFunctions
                              .colorCirculoScoreCardDiferencia, //  Colors.greenAccent,
                          border: Border.all(color: Colors.black, width: 0.3),
                        ),
                        height: 15,
                        width: 15,
                      ),
                      Container(
                        padding: EdgeInsets.only(left: 5, right: 5),
                        child: Text(
                           languageProvider.translate('Diferencia Score'),
                          style: TextStyle(fontSize: 12),
                          textScaleFactor: 1,
                        ),
                      )
                    ],
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 150,
                  color: Colors.transparent,
                  child: Image.network(
                      'http://scoring.com.ar/app/images/publi/scoringadm/logo_ScoreCard.png',
                      fit: BoxFit.fitHeight),
                ),
                Container(
                  height: 50,
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
        floatingActionButton: SpeedDial(
          marginBottom: 50,
          elevation: 5,
          animatedIconTheme: IconThemeData(size: 30),
          animatedIcon: AnimatedIcons.menu_close,
          onOpen: () => print('Open'),
          onClose: () {
            print('Close ddd');
            // _timer.cancel();
          },
          visible: true,
          overlayColor: Colors.black54,
          backgroundColor: Colors.black,
          curve: Curves.elasticInOut,
          children: [
            SpeedDialChild(
              child: Icon(Icons.menu, color: Colors.black),
              backgroundColor: Colors.lightGreenAccent,
              onTap: () {
                _toLeaderboard(context);
              },
              label: 'LEADERBOARD',
              labelStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              labelBackgroundColor: Colors.black45,
            ),
            SpeedDialChild(
              child: Icon(Icons.add, color: Color(0xFFFF0030), size: 30,),
              backgroundColor: Colors.white,
              onTap: () {

                _timer.cancel();
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    child: AgregaJuga(
                      postTorneo: postTorneo,
                    ),
                  ),
                );
              },
              label: languageProvider.translate('+++ JUGADOR'),
              labelStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              labelBackgroundColor: Colors.black45,
            ),
            SpeedDialChild(
              child: Icon(Icons.sports_golf, color: Color(0xFFFF0030), size: 35,),
              backgroundColor: Colors.white,
              onTap: () {

                _timer.cancel();
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    child: AgregaModalidad(
                      postTorneo: postTorneo,
                    ),
                  ),
                );
              },
              label: languageProvider.translate('MODALIDAD JUEGO'),
              labelStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              labelBackgroundColor: Colors.black45,
            ),
            SpeedDialChild(
              child: Icon(Icons.person, color: Colors.black),
              backgroundColor: Colors.greenAccent,
              onTap: () {
                _timer.cancel();
                Navigator.pushAndRemoveUntil(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    child:Publi(),
                  ),
                  ModalRoute.withName('/')
                );
              },

              label: languageProvider.translate('Menú Principal'),
              labelStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              labelBackgroundColor: Colors.black45,
            ),
          ],
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
            color: Color(0xFF000001),
            buttonBackgroundColor: Color(0xFF000001),
            backgroundColor: Colors.transparent,
            animationCurve: Curves.easeInOut,
            animationDuration: Duration(milliseconds: 600),
          ),
      ),
    );
  }

  Future<void> _toLeaderboard(BuildContext context) async {
    if (_controlClickPress==true){
      print('locked _controlClickPress');
      return;
    }
    _controlClickPress=true;
    print('in _controlClickPress');

    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: LeaderboardMP(
            idTorneo: int.parse(Torneo.postTorneoJuego.id_torneo)
        ),
      ),
    );
    await Future.delayed(
        Duration(seconds: 3),
            () {});
    _controlClickPress=false;
    print('out _controlClickPress');
  }

  void _llamandoResultado(DataJugadorScore jugador, BuildContext context) async {
    if (_controlClickPress==true){
      print('locked _controlClickPress');
      return;
    }
    _controlClickPress=true;
    print('in _controlClickPress');

    int indiceJuga=_dataJugadoresScore
        .indexWhere((juga) => juga.matricula
        .contains(jugador.matricula));
    DataJugadorScore dSCJugador =
        _dataJugadoresScore[indiceJuga];

    print(indiceJuga);
    /// verificar si hay firma de su marcador
    String matricula_marcador = '';
    if (_dataJugadoresScore.length > 1) {
      matricula_marcador =
          _dataJugadoresScore[1].matricula;
    }
    await DBAdmin.getFirmaMarcador(
        dSCJugador,
        dSCJugador.idTorneo,
        int.parse(
            GlobalData.postUser.idjuga_arg),
        matricula_marcador);

    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: ResultadosSF(
          dataSCJugadores: _dataJugadoresScore,
          logo: Torneo
              .postTorneoJuego.postClub.logo,
          image: Torneo
              .postTorneoJuego.postClub.imagen,
            indiceJuga: indiceJuga
        ),
      ),
    );
    print('out _controlClickPress');
    _controlClickPress=false;
  }

  void _llamandoResultadoFinal(DataJugadorScore jugador, BuildContext context) async {
    if (_controlClickPress==true){
      print('locked _controlClickPress');
      return;
    }
    _controlClickPress=true;
    print('in _controlClickPress');

    int indiceJuga=_dataJugadoresScore
        .indexWhere((juga) => juga.matricula
        .contains(jugador.matricula));
    DataJugadorScore dSCJugador =
    _dataJugadoresScore[indiceJuga];

    print(indiceJuga);
    /// verificar si hay firma de su marcador
    String matricula_marcador = '';
    if (_dataJugadoresScore.length > 1) {
      matricula_marcador =
          _dataJugadoresScore[1].matricula;
    }
    await DBAdmin.getFirmaMarcador(
        dSCJugador,
        dSCJugador.idTorneo,
        int.parse(
            GlobalData.postUser.idjuga_arg),
        matricula_marcador);

    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        child: ResultadosFin(
            dataSCJugadores: _dataJugadoresScore,
            logo: Torneo
                .postTorneoJuego.postClub.logo,
            image: Torneo
                .postTorneoJuego.postClub.imagen,
            indiceJuga: indiceJuga
        ),
      ),
    );
    print('out _controlClickPress');
    _controlClickPress=false;
  }

  /// CON GPS *****************************************************
  /// HOYOS *****************************************************
  DataTable _dataTable(int hoyoNro) {
    return DataTable(
      columnSpacing: 0,
      horizontalMargin: 0,
      // headingRowHeight: 82, /// CON O SIN GPS
      headingRowHeight: 110,
      dataRowHeight: 70,
      columns: [
        DataColumn(
          label: Padding(
            padding:
            const EdgeInsets.only(top: 8.0, right: 8, bottom: 8, left: 16),
            child: Container(
              width: 65,
              alignment: Alignment.center,
              child: Column(
                children: <Widget>[
                  GestureDetector(
                    child: Container(
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [ /// CON O SIN GPS
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(Icons.gps_fixed, size: 20, color: Colors.black),
                              Text(
                                ' GPS ',
                                textScaleFactor: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black),
                              ),
                            ],
                          ),
                          Text(
                            'H' + hoyoNro.toString(),
                            textScaleFactor: 1,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.red),
                          ),
                          Container(
                            alignment: Alignment.center,
                            color: Color(0xFFDDDDDD),
                            height: 20,
                            width: 65,
                            child: Text(
                              "Par ${(_dataJugadoresScore[0].hoyos[hoyoNro - 1].par.toString())}",
                              textScaleFactor: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                          ),
                          Container(
                            alignment: Alignment.center,
                            color: Color(0xFFDDDDDD),
                            height: 20,
                            width: 65,
                            child: Text(
                              "HCP ${(_dataJugadoresScore[0].hoyos[hoyoNro - 1].handicap.toString())}",
                              textScaleFactor: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      // _timer.cancel();
                      // TODO ------------------------------------------------------------
                      Navigator.push(
                        context,
                        PageTransition(
                          type: PageTransitionType.fade,
                          // child: dialogGPS(context, hoyoNro), ///GPS LINK
                          child:MapsPageV1(hoyoNro), ///GPS LINK
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
      rows: _dataJugadoresScore
          .map(
            (jugador) => DataRow(cells: [
              DataCell(
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Row(
                    children: [
                      Container( /// CIRCULOS HOYOS PARA ANOTAR
                        alignment: Alignment.center,
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            color: UserFunctions.resolverColorCirculoScore(
                                jugador.hoyos[hoyoNro - 1].scoreState,
                                _dataJugadoresScore.indexOf(jugador)),
                            // borderRadius: BorderRadius.circular(60),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black45.withOpacity(.6),
                                  blurRadius: 6,
                                  offset: Offset(2, 2)),
                            ]),
                        padding: EdgeInsets.all(10),
                        child:
                        // TextField( /// ANOTACION HOYOS
                        //   autofocus: true,
                        //   onTap: () => _selectText(_controllerHoyo[_dataJugadoresScore.indexOf(jugadorItem)]),
                        //   controller: _controllerHoyo[_dataJugadoresScore.indexOf(jugadorItem)],
                        //   textAlign: TextAlign.center,
                        //   style: TextStyle(
                        //       fontSize: 20,
                        //       color: UserFunctions.resolverColorFontCirculoScore(
                        //           0,
                        //           _dataJugadoresScore.indexOf(jugadorItem))),
                        //   decoration: InputDecoration.collapsed(
                        //       hintText: ' ',
                        //       hintStyle: TextStyle(
                        //           fontSize: 10,
                        //           color: Colors.white)),
                        //   keyboardType: TextInputType.number,
                        // ),
                        Text(
                          UserFunctions.scoreZeroToEmpty(
                              jugador.hoyos[hoyoNro - 1].score),
                          textScaleFactor: 1,
                          style: TextStyle(
                              fontSize: 20,
                              color: UserFunctions.resolverColorFontCirculoScore(
                                  jugador.hoyos[hoyoNro - 1].scoreState,
                                  _dataJugadoresScore.indexOf(jugador))),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Container(
                        width: 5,
                      ),
                      Container(
                        width: 5,
                        alignment: Alignment.topLeft,
                        child:
                        Text(
                          UserFunctions.scoreZeroToEmpty(jugador.hoyos[hoyoNro - 1].golpesHcp), /// 100% HCP
                          // UserFunctions.scoreZeroToEmpty(jugador.hoyos[hoyoNro - 1].golpesHcpStb), /// 85% STABLEFORD
                          textScaleFactor: 1,
                          style: TextStyle(
                              fontSize: 22,
                              color: Colors.black), textAlign: TextAlign.start,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () {
                  dialogScoreHoyo(context, hoyoNro);
                  setState(() {
                    _isupdating = true;
                  });
                },
              ),
            ]),
          )
          .toList(),
    );
  }

  /// TODOS LOS DATOS
  SingleChildScrollView _dataBody() {
    var languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      /// HOYO 1
                      _dataTable(1),
                      _dataTable(2),
                      _dataTable(3),
                      _dataTable(4),
                      _dataTable(5),
                      _dataTable(6),
                      _dataTable(7),
                      _dataTable(8),
                      _dataTable(9),
                      _dataTable(10),
                      _dataTable(11),
                      _dataTable(12),
                      _dataTable(13),
                      _dataTable(14),
                      _dataTable(15),
                      _dataTable(16),
                      _dataTable(17),
                      _dataTable(18),
                      DataTable(
                        columnSpacing: 0,
                        horizontalMargin: 0,
                        // headingRowHeight: 82,  /// CON O SIN GPS
                        headingRowHeight: 110,
                        dataRowHeight: 70,
                        columns: [
                          DataColumn(
                            label: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: 60,
                                alignment: Alignment.center,
                                child: Text(
                                  'GROSS',
                                  textScaleFactor: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                          // Lets add one more column to show a delete button
                        ],
                        rows: _dataJugadoresScore
                            .map(
                              (jugador) => DataRow(cells: [
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 50,
                                      width: 70,
                                      decoration: BoxDecoration(
                                          color: Colors.black,
                                          // borderRadius:
                                          //     BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black45
                                                    .withOpacity(.6),
                                                blurRadius: 6,
                                                offset: Offset(2, 2)),
                                          ]),
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                        UserFunctions.scoreZeroToEmpty(
                                            jugador.gross),
                                        textScaleFactor: 1,
                                        style: TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            )
                            .toList(),
                      ), // GROSS
                      DataTable(
                        columnSpacing: 0,
                        horizontalMargin: 0,
                        // headingRowHeight: 82, /// CON O SIN GPS
                        headingRowHeight: 110,
                        dataRowHeight: 70,
                        columns: [
                          DataColumn(
                            label: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: 84,
                                alignment: Alignment.center,
                                child: Text(
                                  'TOTAL',
                                  textScaleFactor: 1,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                          // Lets add one more column to show a delete button
                        ],
                        rows: _dataJugadoresScore
                            .map(
                              (jugador) => DataRow(cells: [
                                DataCell(
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Container(
                                      alignment: Alignment.center,
                                      height: 50,
                                      width: 70,
                                      decoration: BoxDecoration(
                                          color: Colors.black,
                                          // borderRadius:
                                          //     BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black45
                                                    .withOpacity(.6),
                                                blurRadius: 6,
                                                offset: Offset(2, 2)),
                                          ]),
                                      padding: EdgeInsets.all(10),
                                      child: Text(
                                        UserFunctions.scoreZeroToEmpty(
                                            (int.parse(jugador.postTee.par) +
                                                jugador.netoAlPar)),
                                        textScaleFactor: 1,
                                        style: TextStyle(
                                            fontSize: 25,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              ]),
                            )
                            .toList(),
                      ),
                      Column(
                        children: [
                          SizedBox(
                            width: 10,
                          ),
                        ],
                      ),
                      DataTable(
                        columnSpacing: 0,
                        horizontalMargin: 0,
                        // headingRowHeight: 82, /// CON O SIN GPS
                        headingRowHeight: 110,
                        dataRowHeight: 70,
                        columns: [
                          DataColumn(
                            label: Padding(
                              padding:
                              const EdgeInsets.only(top: 8.0, bottom: 8),
                              child: Container(
                                width: 150,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container (
                                      alignment: Alignment.center,
                                       child: Text(languageProvider.translate('FIRMAR TARJETAS'), textAlign: TextAlign.center, textScaleFactor: 1, style: TextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.w800),),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Lets add one more column to show a delete button
                        ],
                        rows: _dataJugadoresScore
                            .map(
                              (jugador) => DataRow(cells: [
                            DataCell(
                              Container(
                                  height: 50,
                                  width: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Container(
                                      alignment: Alignment.center,
                                      height: 80,
                                      width: 150,
                                      decoration: BoxDecoration(
                                          color: Color(0xFFCF0707),
                                          borderRadius:
                                          BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black45
                                                    .withOpacity(.6),
                                                blurRadius: 6,
                                                offset: Offset(2, 2)),
                                          ]),
                                      padding: EdgeInsets.all(0),

                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: <Widget>[
                                        Container(
                                          width: 170,
                                          height: 20,
                                          alignment:
                                          Alignment.center,
                                          child: Text(
                                            jugador.nombre_juga
                                                .trim()
                                                .toLowerCase()
                                                .titleCase ??
                                                '',
                                            textScaleFactor: 1,
                                            style: TextStyle(
                                                fontFamily:
                                                'DIN Condensed',
                                                fontSize: 15,
                                                color: Colors.white),
                                            textAlign: TextAlign.left,
                                          ),
                                        ),
                                        Container(
                                          width: 150,
                                          height: 30,
                                          alignment:
                                          Alignment.center,
                                          child: Text(
                                            languageProvider.translate('FIRMAR'),
                                            textScaleFactor: 1,
                                            style: TextStyle(
                                                fontFamily:
                                                'DIN Condensed',
                                                fontSize: 20,
                                                color: Colors.black),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    )),
                              ),
                              onTap: () {
                                _llamandoResultadoFinal(jugador, context);
                              },
                            ),
                          ]),
                        )
                            .toList(),
                      ),
                      Column(
                        children: [
                          SizedBox(
                            width: 20,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          SizedBox(
                            // height: 42, /// CON O SIN GPS
                            height: 70,
                          ),
                          Container(
                            alignment: Alignment.center,
                            height: 80,
                            width: 180,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black45
                                          .withOpacity(.6),
                                      blurRadius: 6,
                                      offset: Offset(2, 2)),
                                ]),
                            padding: EdgeInsets.all(10),
                            child: GestureDetector(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(languageProvider.translate('SI QUEDA GIRANDO'),
                                    textScaleFactor: 1,
                                    style: TextStyle(
                                        fontSize: 13,
fontWeight: FontWeight.w900,
                                    color: Colors.red
                                ),
                                textAlign: TextAlign.center,
                              ),
                                  Text(languageProvider.translate('FALLO SU CONEXION'),
                                    textScaleFactor: 1,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
Text(languageProvider.translate('HAGA CLICK AQUI'),
                                    textScaleFactor: 1,
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.red
                                    ),
                                    textAlign: TextAlign.center,
                                  ),

                                ],
                            ),
                              onTap: () {

                                _timer.cancel();
                                Navigator.push(
                                  context,
                                  PageTransition(
                                    type: PageTransitionType.fade,
                                    child: ParcheConexion(
                                      postTorneo: postTorneo,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ), /// Boton Reset

                          Container(
                            alignment: Alignment.center,
                            height: 10,
                          ),
                          Container(
                            child: Icon(Icons.arrow_downward_rounded, size: 35, color: Colors.red),
                          ),
                          Container(
                            alignment: Alignment.center,
                            height: 10,
                          ),
                          Container(
                            alignment: Alignment.center,
                            height: 80,
                            width: 180,
                            decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius:
                                BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black45
                                          .withOpacity(.6),
                                      blurRadius: 6,
                                      offset: Offset(2, 2)),
                                ]),
                            padding: EdgeInsets.all(10),
                            child: isLoading
                                ? Center(
                              child: CircularProgressIndicator(
                              ),
                            )
                                : new
                            GestureDetector(
                              child: Text(languageProvider.translate('PRESENTAR TARJETAS'),
                                textScaleFactor: 1,
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white
                                ),
                                textAlign: TextAlign.center,
                              ),
                              onTap: () {
                                _presentarTajetas();
                              },
                            ),
                          ), /// Presenta Tarjeta
                        ],
                      ),
                      Column(
                        children: [
                          SizedBox(
                            width: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Crear Alerta GPS SELECT CANCHA
  dialogGPS(BuildContext context, int _nroHoyo) async {
    _dataJugadoresScore[0].nombre_juga;
    //int idxController=0;
    _dataJugadoresScore.forEach((jugadorItem) {
      String valorH = jugadorItem.hoyos[_nroHoyo - 1].score.toString();
      if (jugadorItem.hoyos[_nroHoyo - 1].score == 0) {
        valorH = '';
      }
      _controllerHoyo[_dataJugadoresScore.indexOf(jugadorItem)].text = valorH;
    });

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: Container(
              height: 250,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding:
                      EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 5),
                      color: Colors.black54,
                      child: Text('GPS | H $_nroHoyo',
                          style: TextStyle(color: Colors.white, fontSize: 35),
                          textScaleFactor: 1,
                          textAlign: TextAlign.center),
                    ),
                    Container(
                      height: 8,
                      child: SizedBox(),
                    ),
                    GestureDetector(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding:
                        EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 5),
                        color: Colors.black,
                        child: Text('Vieja | Agua',
                            style: TextStyle(color: Colors.white, fontSize: 25),
                            textScaleFactor: 1,
                            textAlign: TextAlign.center),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            child: MapsPageV2(_nroHoyo), ///GPS LINK
                          ),
                        );
                      },
                    ),
                    Container(
                      height: 8,
                      child: SizedBox(),
                    ),
                    GestureDetector(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding:
                        EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 5),
                        color: Colors.black,
                        child: Text('Agua | Larga',
                            style: TextStyle(color: Colors.white, fontSize: 25),
                            textScaleFactor: 1,
                            textAlign: TextAlign.center),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            child:MapsPageV3(_nroHoyo), ///GPS LINK
                          ),
                        );
                      },
                    ),
                    Container(
                      height: 8,
                      child: SizedBox(),
                    ),
                    GestureDetector(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding:
                        EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 5),
                        color: Colors.black,
                        child: Text('Larga | Vieja',
                            style: TextStyle(color: Colors.white, fontSize: 25),
                            textScaleFactor: 1,
                            textAlign: TextAlign.center),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            child:MapsPageV4(_nroHoyo), ///GPS LINK
                          ),
                        );
                      },
                    ),
                    Container(
                      height: 8,
                      child: SizedBox(),
                    ),
                    GestureDetector(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        padding:
                        EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 5),
                        color: Colors.black,
                        child: Text('Campeonato',
                            style: TextStyle(color: Colors.white, fontSize: 25),
                            textScaleFactor: 1,
                            textAlign: TextAlign.center),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            child:MapsPageV5(_nroHoyo), ///GPS LINK
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }

  /// Crear Alerta SCORE ANOTACION
  dialogScoreHoyo(BuildContext context, int _nroHoyo) async {
    var languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    _dataJugadoresScore[0].nombre_juga;
    //int idxController=0;
    _dataJugadoresScore.forEach((jugadorItem) {
      String valorH = jugadorItem.hoyos[_nroHoyo - 1].score.toString();
      if (jugadorItem.hoyos[_nroHoyo - 1].score == 0) {
        valorH = '';
      }
      _controllerHoyo[_dataJugadoresScore.indexOf(jugadorItem)].text = valorH;
    });

    void _selectText(TextEditingController controller) {
      controller.selection = TextSelection(
          baseOffset: 0, extentOffset: controller.text.length);
    }

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            content: Container(
              height: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding:
                          EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 5),
                      color: Colors.black54,
                      child: Text('H $_nroHoyo',
                          style: TextStyle(color: Colors.white, fontSize: 45),
                          textScaleFactor: 1,
                          textAlign: TextAlign.center),
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      padding:
                          EdgeInsets.only(top: 5, left: 5, right: 5, bottom: 5),
                      color: Colors.white70,
                      child: Text(
                          "Par ${(_dataJugadoresScore[0].hoyos[_nroHoyo - 1].par.toString())} • ${(_dataJugadoresScore[0].hoyos[_nroHoyo - 1].distancia.toString())} Yds | Hcp ${(_dataJugadoresScore[0].hoyos[_nroHoyo - 1].handicap.toString())}",
                          style: TextStyle(color: Colors.black, fontSize: 13),
                          textScaleFactor: 1,
                          textAlign: TextAlign.center),
                    ),
                    _isupdating
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Expanded(
                          child: FlatButton(
                            color: Colors.black,
                            child: Text(
                              languageProvider.translate('GUARDAR SCORE'),
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              textScaleFactor: 1,
                            ),
                            onPressed: () {
                              okInputScore(_nroHoyo, context); /// GRABA DATOS EN BASE DE DATOS
                            },
                          ),
                        ),
                      ],
                    )
                        : Container(),
                    ///*****************************
                    DataTable(
                      columnSpacing: 0,
                      horizontalMargin: 10,
                      headingRowHeight: 0,
                      dataRowHeight: 80,
                      columns: [
                        DataColumn(
                          label: Text(''),
                        ),
                        // Lets add one more column to show a delete button
                      ],
                      rows: _dataJugadoresScore
                          .map(
                            (jugadorItem) => DataRow(cells: [
                              DataCell(
                                Container(
                                    height: 70,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundImage: NetworkImage(
                                              jugadorItem.images.trim() ?? ''),
                                          backgroundColor: Colors.black,
                                        ),
                                        Container(
                                          alignment: Alignment.centerLeft,
                                          padding: EdgeInsets.only(left: 5),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              Container(
                                                width: 70,
                                                height: 17,
//                                            alignment: Alignment.centerLeft,
                                                child: Text(
                                                  jugadorItem.nombre_juga
                                                          .trim()
                                                          .toLowerCase()
                                                          .titleCase ??
                                                      '',
                                                  textAlign: TextAlign.left,
                                                  textScaleFactor: 1,
                                                  overflow: TextOverflow.clip,
                                                  style: TextStyle(
                                                      fontSize: 15,
                                                      fontFamily:
                                                          'DIN Condensed',
                                                      color: Colors.black),
                                                ),
                                              ),
                                              Container(
                                                width: 70,
                                                height: 25,
                                                child: Text(
                                                  jugadorItem.matricula
                                                          .trim() ??
                                                      '',
                                                  textAlign: TextAlign.left,
                                                  textScaleFactor: 1,
                                                  style: TextStyle(
                                                      fontFamily:
                                                          'DIN Condensed',
                                                      fontSize: 23,
                                                      color: Colors.black),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          width: 65,
                                          height: 65,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                              color: UserFunctions
                                                  .resolverColorCirculoScore(
                                                      0,
                                                      _dataJugadoresScore
                                                          .indexOf(
                                                              jugadorItem)),
                                              borderRadius:
                                                  BorderRadius.circular(60),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.black45
                                                        .withOpacity(.6),
                                                    blurRadius: 6,
                                                    offset: Offset(3, 3)),
                                              ]),
                                          padding: EdgeInsets.only(
                                              left: 5, right: 5),
                                          child: TextField( /// ANOTACION HOYOS
                                            autofocus: true,
                                            onTap: () => _selectText(_controllerHoyo[_dataJugadoresScore.indexOf(jugadorItem)]),
                                            controller: _controllerHoyo[_dataJugadoresScore.indexOf(jugadorItem)],
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 30,
                                                color: UserFunctions.resolverColorFontCirculoScore(
                                                    0,
                                                    _dataJugadoresScore.indexOf(jugadorItem))),
                                            decoration: InputDecoration.collapsed(
                                                hintText: ' ',
                                                hintStyle: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white)),
                                            keyboardType: TextInputType.number,
                                          ),
                                          // child: TextField(
                                          //   controller: _controllerHoyo[
                                          //       _dataJugadoresScore
                                          //           .indexOf(jugadorItem)],
                                          //   textAlign: TextAlign.center,
                                          //   style: TextStyle(
                                          //       fontSize: 30,
                                          //       color: UserFunctions
                                          //           .resolverColorFontCirculoScore(
                                          //               0,
                                          //               _dataJugadoresScore
                                          //                   .indexOf(
                                          //                       jugadorItem))),
                                          //   decoration:
                                          //       InputDecoration.collapsed(
                                          //           hintText: ' ',
                                          //           hintStyle: TextStyle(
                                          //               fontSize: 10,
                                          //               color: Colors.white)),
                                          //   keyboardType: TextInputType.number,
                                          // ),
                                        ),
                                        Container(
                                          width: 5,
                                        ),
                                        Text(
                                          UserFunctions.scoreZeroToEmpty(jugadorItem.hoyos[_nroHoyo - 1].golpesHcp), /// 100% HCP
                                          // " ${(jugadorItem.hoyos[_nroHoyo - 1].golpesHcpStb.toString())}", /// 85% STABLEFORD
                                          textScaleFactor: 1,
                                          //style: TextStyle(fontSize: 45, color: Colors.white),
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.black), textAlign: TextAlign.start,
                                        ),

                                      ],
                                    )),
                              ),
                            ]),
                          )
                          .toList(),
                    ),

                    Container(
                      height: 8,
                      child: SizedBox(),
                    ),
                    Text(
                      languageProvider.translate('Debe ingresar los Scores de ambos jugadores. Si uno no finaliza el hoyo, ingresar "0" (Cero).'),
                        style: TextStyle(fontSize: 30,
                            fontFamily: 'DIN Condensed'),
                        textAlign: TextAlign.center,
                        textScaleFactor: 1),
                  ],
                ),
              ),
            ),
          );
        });
  }

  void okInputScore(int _nroHoyo, BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    bool _isValido = true;
_dataJugadoresScore.forEach((jugadorItem) {
      var datoN = int.parse(_controllerHoyo[
      _dataJugadoresScore
          .indexOf(jugadorItem)]
          .text);
      if (datoN > 36) {
        _isValido = false;
        mToast.showToast(languageProvider.translate("Si un jugador levanta pelota, anotar Cero"));

      } else {
        jugadorItem.setScore(
            _nroHoyo,
            int.parse(_controllerHoyo[
            _dataJugadoresScore
                .indexOf(jugadorItem)]
                .text));
      }
    });
    if (_isValido == true) {
      Navigator.of(context).pop();

    }
  }

  String _valida(int i) {
    return '';
  }

  String validatePassword(String value) {
    if (!(value.length > 5) && value.isNotEmpty) {
      return "Password should contains more then 5 character";
    }
    return null;
  }

  Future<void> _getControlScore(Timer timer) async {
    print('print(_estadoFrmIsOk);------>' + _estadoFrmIsOk.toString());
    print('_getControlScore ------------------------');
    List<PostControlSC> postControlSC = await Torneo.getControlSC(
        _id_torneo, _id_user, _matriculas, 'distinto');
    if (postControlSC == null) {
      print('getControlSC --> no hay datos');
    } else {
      bool hayCambios = false;
      postControlSC.forEach((cSC) {
        // if(cSC.score>0) {
        for (DataJugadorScore djsP in _dataJugadoresScore) {
          if (djsP.matricula == cSC.matricula) {
            _dataJugadoresScore[_dataJugadoresScore.indexOf(djsP)]
                .setScoreControl(cSC.hoyo_nro, cSC.score);
            hayCambios = true;
            //print('***********');
          }
          // }
        }
      });
      if (hayCambios == true) {
        setState(() {});
      }
    }
  }

  void _controlTry() async {
    try {
      await DBAdmin.dbTarjetaInitialize(
          _dataJugadoresScore,
          int.parse(Torneo.postTorneoJuego.id_torneo),
          int.parse(postUser.idjuga_arg));
      GlobalData.dbConn.dbClubAndTeesInsert(
          Torneo.postTorneoJuego.postClub, Torneo.postTorneoJuego.tees);
    } on Exception catch (exception) {
      print(
          '******** error 111********************--> ' + exception.toString());
      _estadoFrmIsOk = false;
    } catch (error) {
      print('******** error ********************--> ' + error.toString());
      _estadoFrmIsOk = false;
    }
    _estadoFrmIsOk = true;
  }

  Future<void> _presentarTajetas() async {
    var languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    setState(() {
isLoading = true;
    });

    /// Verificar si:
    ///
    /// Hay integridad entre bases para todos
    /// Tiene todos los hoyos con score
    /// Firma de al menos el user
    print(' vericicar scores ');
    bool okScore = await _controlarScores();
    if (okScore == false) {
      return;
    }
    _dataJugadoresScore.forEach((djs) {
      djs.hoyos.forEach((hoyo) {
        //print('>>>>>>>>>>>>>>>>>>>>>>>  '+hoyo.scoreState.toString());
        if (hoyo.scoreState>0){
          //if (hoyo.score!=hoyo.scoreCtrol){
            mToast.showToast(languageProvider.translate("DIFERENCIA DE SCORE ENTRE AMBOS JUGADORES"));
            print('error score ----------------------------');
            return;
          //}
        }
      });

    });

    setState(() {
      isLoading = false;
    });

    bool grabar = true;
    grabar = await _verificarFirmas(grabar);
    if (grabar == false) {
      print('*** NOTIFICACION *** Saliendo por falta de firmas ');
//      mToast.showToast('Faltan firmas');
      return;
    }

    String hoyosFaltantes = '';
    String firmasFaltantes = '';
    String firmaMarcador = '';

    List<Map<String, dynamic>> statusAll = [];

    _dataJugadoresScore.forEach((jugador) {
      jugador.status_med = '';
      bool entro = false;
      if (jugador.firmaUserImage.length < 10) {
        firmasFaltantes += ' / ' + jugador.nombre_juga.trim();
      }
      if (jugador.firmaMarcadorImage.length < 10) {
        firmaMarcador += ' / ' + jugador.nombre_juga.trim();
      }
      jugador.hoyos.forEach((hoyo) {
        if (hoyo.score <= 0 || hoyo.score == null) {
          jugador.status_med = 'LP';
          if (entro == false) {
            hoyosFaltantes +=
                ' / ' + jugador.nombre_juga.trim() + ' => hoyos: ';
          }
          entro = true;
          hoyosFaltantes += hoyo.hoyoNro.toString() + ', ';
        }
      });

      Map<String, dynamic> status = {
        'statusMed': jugador.status_med,
        'statusSta': jugador.status_sta,
        'statusMch': jugador.status_mch,
        'matricula': jugador.matricula
      };
      statusAll.add(status);
    });

    print('*** NOTIFICACION *** FALTA SCORE --> ' + hoyosFaltantes);
    print('*** NOTIFICACION *** FALTAN FIRMAS --> ' + firmasFaltantes);
    print('*** NOTIFICACION *** FALTA FIRMA MARCADOR --> ' + firmaMarcador);

    /// NOTA: que hacer si faltan hoyos?
    /// si es medal LP en status_mp
    /// si stableford null en status_st
    ///
    /// ver otros estatus (descalificado, etc)  status_mp, status_st
    ///
    /// NOTA: que hacer si faltan firmas?

    var _pasaDato = await dialogoOkCancel(
        context: context,
        title: lan.dialogTarjetaPresentacionTitle,
        question: lan.dialogTarjetaPresentacionQuestion);
    if (_pasaDato == false) {
      print('*** NOTIFICACION *** Presentación cancelada');
      mToast.showToast(languageProvider.translate('PRESENTACION CANCELADA'));
      return;
    }
    //print(statusAll);


    String retGrabarTF =
        await DBApi.saveTarjetaFinal(idTorneo: _id_torneo, idUser: _id_user,statusAll:statusAll);
    if (retGrabarTF == null) {


      print('*** NOTIFICACION *** Error de Comunicación (465435443)');
      mToast.showToast(languageProvider.translate("No se realizo la Presentación, intentelo nuevamente... (641321)"));
      return;
    } else {
      if (json.decode(retGrabarTF)['datos'] != null) {
        if (json.decode(retGrabarTF)['datos'] == false) {
          print('*** NOTIFICACION *** No se realizo la Presentación, intentelo nuevamente... (641943)');
          mToast.showToast(languageProvider.translate("No se realizo la Presentación, intentelo nuevamente... (641943)"));
          return;
        }else {
          String sRetGraba = json.decode(retGrabarTF)['datos']['resultado']
              .toString();
          print(sRetGraba+'<<<<<<<<<<<<<<<<<<<<<<<<<<<' );

          if (sRetGraba == 'OK') {
            print(retGrabarTF);
            GlobalData.dbConn.dbTarjetaTruncate();
          } else {
            print('*** NOTIFICACION *** Error de Comunicación (856245643)');
            mToast.showToast(languageProvider.translate("No se realizo la Presentación, intentelo nuevamente... (856245643)"));
            return;
          }
        }
      } else {
        print('*** NOTIFICACION *** Error de Comunicación (546745643)');
        mToast.showToast(languageProvider.translate("No se realizo la Presentación, intentelo nuevamente... (546745643)"));
        return;
      }
    }

    GlobalData.dbConn.dbTarjetaTruncate();
    GlobalData.dbConn.dbTorneoTruncate();
    //DBApi.TarjetaDelete(int.parse(GlobalData.postUser.idjuga_arg));
    UserFunctions.clearAmbiente();
    print('*** NOTIFICACION *** Presentación realizada...');
    mToast.showToast(languageProvider.translate('PRESENTACION REALIZADA'));

    _timer.cancel();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BottonNav()),
    );
  }

  Future<bool> _verificarFirmas(bool grabar) async {
    var languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    Map<dynamic, bool> rowRet = await _verificarFirmasDB();
if (rowRet['faltaFirmaUser'] == true) {
      grabar = false;
      print('*** NOTIFICACION *** FALTA FIRMA USER');
    }
    if (rowRet['faltaFirmaUserMarcador'] == true) {
      //grabar=false;
      print('*** NOTIFICACION *** FALTA FIRMA JUGADOR - MARKER');
      mToast.showToast(languageProvider.translate('*** NOTIFICACION *** FALTA FIRMA JUGADOR - MARCADOR'));
    }
    if (rowRet['faltaFirmaMarcador'] == true) {
      //grabar=false;
      print('*** NOTIFICACION *** FALTA FIRMA MARCADOR');
    }
    if (rowRet['faltaFirmaMarcadorUser'] == true) {
      //grabar=false;
      print('*** NOTIFICACION *** FALTA FIRMA MARCADOR - USER');
    }
    return grabar;
  }

  Future<bool> _controlarScores() async {
    print(
        '***********************************************controlarScores **************');
    List<PostControlSC> postControlSC =
        await Torneo.getControlSC(_id_torneo, _id_user, _matriculas, 'igual');
    if (postControlSC == null) {
      print('ControlarSC --> posible api error 84654321');
      return false;
    } else {
      if (postControlSC.length == 0) {
        print('ControlarSC --> no hay datos 641654131');
        return false;
      }
      int cantIntentos = 3;
      int intentos = 0;
      bool salidaOk = false;
      while (intentos < cantIntentos && salidaOk == false) {
        intentos++;
        salidaOk = true;
        postControlSC.forEach((cSC) {
          for (DataJugadorScore djsP in _dataJugadoresScore) {
            if (djsP.matricula == cSC.matricula) {
              int scoreLocal =
                  _dataJugadoresScore[_dataJugadoresScore.indexOf(djsP)]
                      .getScore(cSC.hoyo_nro);

              int scoreDB = cSC.score;
              if (scoreLocal != scoreDB) {
                print(cSC.matricula +
                    ' DIFERENCIA EN EL HOYO ' +
                    cSC.hoyo_nro.toString() +
                    ': ' +
                    scoreLocal.toString() +
                    ' <-> ' +
                    scoreDB.toString());

                /// grabar y reverificar
                _dataJugadoresScore[_dataJugadoresScore.indexOf(djsP)]
                    .setScore(cSC.hoyo_nro, scoreLocal);

                salidaOk = false;
              } else {
                print(cSC.matricula +
                    ' Ok hoyo ' +
                    cSC.hoyo_nro.toString() +
                    ': ' +
                    scoreLocal.toString() +
                    ' <-> ' +
                    scoreDB.toString());
              }
            }
          }
        });
      }
      if (salidaOk == false) {
        print('ControlarSC --> posible connection error 934151365');
        return false;
      }
    }
    return true;
  }

  Future<Map<dynamic, bool>> _verificarFirmasDB() async {
    bool faltaFirmaUser = true;
    bool faltaFirmaUserMarcador = true;
    bool faltaFirmaMarcador = true;
    bool faltaFirmaMarcadorUser = true;

    List<DataJugadorScore> dataJSCTrolFirm =
        await DBApi.getTarjetasControlFirma(
            _matriculas,
            int.parse(postUser.idjuga_arg),
            int.parse(Torneo.postTorneoJuego.id_torneo));
    if (dataJSCTrolFirm != null) {
      dataJSCTrolFirm.forEach((dJSCFirm) {
        //print(dJSCFirm.firmaUserImage.toString());
        if (dJSCFirm.firmaUserImage.length > 10) {
//          print(int.parse(dJSCFirm.matricula).toString() + '......' + int.parse(postUser.idjuga_arg).toString());

          if (int.parse(dJSCFirm.matricula) == int.parse(postUser.idjuga_arg)) {
            //print('*** NOTIFICACION ***------------------------- --> ');
            faltaFirmaUser = false;
          }
          if (dJSCFirm.role == 2) {
            faltaFirmaMarcador = false;
          }
        }
        if (dJSCFirm.firmaMarcadorImage.length > 10) {
          if (int.parse(dJSCFirm.matricula) == int.parse(postUser.idjuga_arg)) {
            faltaFirmaUserMarcador = false;
          }
          if (dJSCFirm.role == 2) {
            faltaFirmaMarcadorUser = false;
          }
        }
      });
    }
    Map<dynamic, bool> rowRet = {
      'faltaFirmaUser': faltaFirmaUser,
      'faltaFirmaUserMarcador': faltaFirmaUserMarcador,
      'faltaFirmaMarcador': faltaFirmaMarcador,
      'faltaFirmaMarcadorUser': faltaFirmaMarcadorUser,
    };
    return rowRet;
  }

  void _verificaTees() async {
    var languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    bool _isOk = true;
    String matriculas = '';
    List<String> _cTee = [];
    List<String> _cMat = [];

    _jugadores.forEach((juga) {
      //print(juga.pathTeeColor);
      if (juga.pathTeeColor == null || juga.pathTeeColor.length <= 5) {
        mToast.showToast(languageProvider.translate('FALTA SELECCIONAR TEE DE: ') + juga.nombre_juga);
        print('*** NOTIFICAR ***:  FALTA SELECCIONAR TEE DE: ' +
            juga.nombre_juga);
        _isOk = false;
      }
      if (matriculas.length > 1) {
        matriculas = matriculas + ', ';
      }
      matriculas = matriculas + ' ' + juga.matricula.trim();
      _cTee.insert(0, juga.pathTeeColor);
      _cMat.insert(0, juga.matricula);
    });
    List<DataJugadorScore> dataJSCTrolTee = await DBApi.getTarjetasControlTee(
        matriculas,
        int.parse(postUser.idjuga_arg),
        int.parse(Torneo.postTorneoJuego.id_torneo));
    if (dataJSCTrolTee != null) {
      dataJSCTrolTee.forEach((dJSCTee) {
        for (int IdP = 0; IdP < _cMat.length; IdP++) {
          if (dJSCTee.matricula == _cMat[IdP]) {
            if (dJSCTee.pathTeeColor != _cTee[IdP]) {
              print('*** NOTIFICAR ***:  DIFERENCIA EN LOS TEE DE: ' +
                  dJSCTee.nombre_juga);

              mToast.showToastCancel(
                  languageProvider.translate('DIFERENCIA EN LOS TEE DE: ') + dJSCTee.nombre_juga);
              _isOk = false;
            }
          }
        }
      });
    }
    if (_isOk == true) {
      print('PASS CONTROL DE LOS TEES ');
      Torneo.dataJugadoresScore = _jugadores;
      Navigator.push(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          child: ScoreCard(),
        ),
      );
    }
  }

}
