import 'dart:async';
import 'package:connection_status_bar/connection_status_bar.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:golfguidescorecard/loginhttp/buscar_gps.dart';
import 'package:golfguidescorecard/loginhttp/buscar_matricula.dart';
import 'package:golfguidescorecard/mod_serv/model.dart';
import 'package:golfguidescorecard/models/postTorneo.dart';
import 'package:golfguidescorecard/scoresCard/torneo.dart';
import 'package:golfguidescorecard/services/db-admin.dart';
import 'package:golfguidescorecard/services/db-api.dart';
import 'package:golfguidescorecard/utilities/Utilities.dart';
import 'package:golfguidescorecard/utilities/display-functions.dart';
import 'package:golfguidescorecard/utilities/fecha.dart';
import 'package:golfguidescorecard/utilities/functions.dart';
import 'package:golfguidescorecard/utilities/global-data.dart';
import 'package:golfguidescorecard/utilities/messages-toast.dart';
import 'package:golfguidescorecard/utilities/seguridad.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:golfguidescorecard/herramientas/myClipper.dart';
import 'package:golfguidescorecard/herramientas/bottonNavigator.dart';
import 'package:golfguidescorecard/models/model.dart';
import 'package:golfguidescorecard/services/api-cfg.dart';
import 'package:golfguidescorecard/services/service.dart';
import 'package:golfguidescorecard/loginhttp/registro.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginHttp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LoginPage();
  }
}

class LoginPage extends StatefulWidget {
  @override
  final TextEditingController ControllerNombre = TextEditingController(text: '');
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isFirstClick = true;

  MessagesToast mToast;
  @override
  TextEditingController controllerUser = new TextEditingController();
  TextEditingController controllerPass = new TextEditingController();

  bool isLoading = false;

  @override
  final TextEditingController ControllerNombre = TextEditingController(text: '');

  Widget build(BuildContext context) {
    mToast = MessagesToast(context: context);
    return WillPopScope(
        onWillPop: () => Utilities.onWillPop(context),
        child: Scaffold(
          backgroundColor: Color(0xFF262626),
          resizeToAvoidBottomPadding: false,
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  child: Stack(
                children: [
                  ClipPath(
                    clipper: MyClipper(),
                    child: Container(
                      padding: EdgeInsets.all(50.0),
                      height: 300.0,
                      decoration: BoxDecoration(
                        color: Color(0xFF1f2f50),
                        image: DecorationImage(
                            image: AssetImage('assets/clubes/logoblanco.png'),
                            fit: BoxFit.contain),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConnectionStatusBar(),
                  ),
                ],
            ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        style: TextStyle(color: Colors.white70),
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: false, signed: true),
                        textInputAction: TextInputAction.next,
                        controller: controllerUser,
                        decoration: InputDecoration(
                            icon: Icon(
                              Icons.golf_course,
                              color: Colors.white70,
                            ),
                            hintText: 'Licencia',
                            hintStyle:
                            TextStyle(fontSize: 18, color: Colors.white70)),
                      ),
                      TextFormField(
                        style: TextStyle(color: Colors.white70),
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: false, signed: true),
                        textInputAction: TextInputAction.done,
                        controller: controllerPass,
                        obscureText: true,
                        decoration: InputDecoration(
                            icon: Icon(
                              Icons.lock,
                              color: Colors.white70,
                            ),
                            hintText: 'Password',
                            hintStyle:
                            TextStyle(fontSize: 18, color: Colors.white70)
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  EdgeInsets.only(top: 5, bottom: 15, left: 20, right: 20),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 10, 20.0, 0.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 100,
                    height: 40,
                    child: isLoading
                        ? Center(
                      child: CircularProgressIndicator(),
                    )
                        : new RaisedButton(
                      elevation: 5.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0)),
                      color: Color(0xFF1f2f50),
                      child: Text('Ingresar',
                          textScaleFactor: 1.0,
                          style: TextStyle(
                              fontSize: 20.0, color: Colors.white)),
                      onPressed: _loginPressed,
                    ),
                  ),
                ),
                Container(
                  height: 10,
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0.0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 100,
                    height: 40,
                    child: RaisedButton(
                      color: Colors.grey,
                      elevation: 5.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0)),
                      child: Text('Registro',
                          textScaleFactor: 1.0,
                          style: TextStyle(color: Colors.black, fontSize: 16.0)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            child: Registro(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 5, 20.0, 0.0),
                  child: SizedBox(
                    child: RaisedButton(
                      color: Colors.white12,
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0)),
                      child: Text('Olvide Password (Ingresar Licencia)',
                          textScaleFactor: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 15.0)),
                      onPressed: () {
                        _olvideMiPass();
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.0, 0, 20.0, 0),
                  child: SizedBox(
                    child: RaisedButton(
                      color: Colors.white12,
                      elevation: 0.0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0)),
                      child: Text('Olvide Licencia',
                          textScaleFactor: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 15.0)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransition(
                            type: PageTransitionType.fade,
                            // child: GPSPage(),
                            child: MatriculaPage(),
                          ),
                        );
                      },
                      // onPressed: () {
                      //   launch(
                      //       "mailto:info@scoring.com.ar?subject=OLVIDE%20MI%20LICENCIA&body=Enviar%20matricula");
                      // },
                    ),
                  ),
                ),
                Container(
                  child: SizedBox(
                    height: 80,
                  ),
                )
              ],
            ),
          ),
          bottomNavigationBar: CurvedNavigationBar(
            index: 0,
            height: 60.0,
            items: <Widget>[
              IconButton(
                icon: Icon(Icons.golf_course, size: 30, color: Colors.white),
              ),
            ],
            color: Color(0xFF1f2f50),
            buttonBackgroundColor: Color(0xFF1f2f50),
            backgroundColor: Colors.transparent,
            animationCurve: Curves.easeInOut,
            animationDuration: Duration(milliseconds: 600),
          ),
        )
    );
  }

  void _loginPressed() async {
    if (controllerUser.text.trim().length < 1) {
      mToast.showToast('INGRESE MATRICULA o LICENCIA');
      return;
    }
    if (controllerPass.text.trim().length < 1) {
      mToast.showToast('INGRESE MISMA MATRICULA o LICENCIA');
      return;
    }

    PostJuga postJugaBusca = await DBApi.getJugador(controllerUser.text.trim());
    _isFirstClick = true;
    if (postJugaBusca != null) {
      if (postJugaBusca.level_security < 10 ) {
        mToast.showToast('MATRICULA o LICENCIA NO REGISTRADA');
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    var param = {
      "userName": controllerUser.text,
      "userPass": generateMd5(controllerUser.text.trim().toUpperCase() +
          controllerPass.text.trim()),
      "userRan": generateMd5(controllerUser.text.trim().toUpperCase() +
          controllerUser.text.trim()),
      "modOrigen": "scoring_pro",
//      "modOrigen": "club_nro",
      "deviceId": GlobalData.dispositivoIdUnique,
      "securitySchema": 1
    };
    TranferData tranferData =
    await fetchRBUser(ApiUserMethod.userLogin, param, context);
    print(tranferData);
    if (tranferData != null) {
      // es para evitar un error que no estaba expuesto
      var resBody = tranferData.responseBody;
      PostUser postUser = tranferData.postObject;
      GlobalData.dbConn.dbUserTrubate();
      GlobalData.dbConn.dbUserInsert(postUser);
      initSecurity('pos login');
      print(postUser.matricula);
      print(
          '************INGRESANDO CON USUARIO Y CLAVE ***************************************');
//      PostUser postUserPru=GlobalData.dbConn.dbUserGet() as PostUser;
//      print(postUserPru.nombre_juga);
      List<PostTorneo> postUserTorneos =
      await Torneo.getTorneos(postUser.matricula, Fecha.fechaHoy);
      GlobalData.postUserTorneos = postUserTorneos;
      List<DataJugadorScore> dataJS =
      await DBAdmin.getTarjetaJuego(postUser.matricula, Fecha.fechaHoy);
      Torneo.dataJugadoresScore = dataJS;
      if (dataJS == null) {
        //ver
      } else {
        PostTorneo postTorneo = await DBAdmin.dbTorneoGet(dataJS[0].idTorneo);
        Torneo.postTorneoJuego = postTorneo;
      }

      if (resBody.length > 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => BottonNav()),
        );
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _olvideMiPass() async {
    if (_isFirstClick == false) {
      return;
    }

    PostJuga postJugaBusca = await DBApi.getJugador(controllerUser.text.trim());
    _isFirstClick = true;
    if (postJugaBusca != null) {
      if (postJugaBusca.level_security < 10 ) {
        mToast.showToast('MATRICULA o LICENCIA NO REGISTRADA');
        return;
      }
    } else {
      mToast.showToast('INGRESE LA MATRICULA o LICENCIA VALIDA');
      // mToast.showToast('NO EXISTE ESTA MATRICULA o LICENCiA');
      return;
    }

    if (controllerUser.text.trim().length < 1) {
      mToast.showToast('INGRESE LA MATRICULA o LICENCIA');
      return;
    }
    _isFirstClick = false;
    mToast.showToast('ENVIANDO MATRICULA o LICENCIA A SU EMAIL');

    print('Verificando matricula...');

    // TODO AQUI SPINNER.ON........

    // enviar matricula y codigo imei
    _isFirstClick = false;
    print('recuperando clave....');


    Future<String> notifEve = DBApi.recuperarClave(
        postJugaBusca.matricula, GlobalData.dispositivoIdUnique);
    _isFirstClick = true;
    // TODO AQUI SPINNER.OFF........

    bool exitLoop = false;
    do {
      var _pasaDato = await dialogoInputOkCancel(
          context: context,
          title: 'INGRESE CODIGO ENVIADO POR EMAIL',
          question: 'Digite el codigo enviado por e-mail');
      if (_pasaDato.toString().length > 0) {
        print('VALIDACIÓN ');
        String notifChkCodigo = await DBApi.verifySC(
            postJugaBusca.matricula, _pasaDato.toString());
        if (notifChkCodigo == 'oksc') {
          print('cambiar clave');
          dialogUserUpdatePass(context:context, userMatricula:postJugaBusca.matricula, userName: postJugaBusca.nombre_juga,
              userHcp:postJugaBusca.hcp, userClub:postJugaBusca.idclub.toString().trim(),email: postJugaBusca.email  );
          exitLoop = true;
        } else {
          mToast.showToastCancel('Error Verifique el código');
        }
      } else {
        exitLoop = true;
      }
    } while (exitLoop == false);

  }
}
