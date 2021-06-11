import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shareacab/main.dart';
import 'package:shareacab/screens/authenticate/phoneverify.dart';
import 'package:shareacab/screens/settings.dart';
import 'package:shareacab/services/auth.dart';
import 'package:shareacab/services/database.dart';
import 'package:shareacab/shared/loading.dart';
import 'package:shareacab/utils/constant.dart';
import 'package:shareacab/components/inputs.dart';
import 'package:shareacab/components/buttons.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;
  SignIn({this.toggleView});
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  String phone = '';

  @override
  void initState() {
    super.initState();
  }

  Future<bool> isRegistered() async {
    var data = await _db.getUserbyPhone('+852' + phone);
    if (data == null) {
      return false;
    }
    return data.documents.length > 0;
  }

  Future<String> verifyPhone() async {
    String verificationId;
    final PhoneCodeAutoRetrievalTimeout autoRetrieve = (String verId) {
      verificationId = verId;
    };
    final PhoneCodeSent smsCodeSent = (String verId, [int forceCodeResend]) {
      verificationId = verId;
      //print('code has been sent');
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => PhoneVerify(
                    PhoneNumber: '+852' + phone,
                    verificationId: verificationId,
                    forceCodeResend: forceCodeResend,
                  )));
    };
    final PhoneVerificationCompleted verifySuccess = (AuthCredential user) {
      //print('verify');
    };
    final PhoneVerificationFailed verifyFail = (AuthException exception) {
      //print('${exception.message}');
      Scaffold.of(context).showSnackBar(SnackBar(
        backgroundColor: yellow_color2,
        duration: Duration(seconds: 2),
        content: Text(
          exception.message,
          style: TextStyle(color: text_color1),
        ),
      ));
    };
    await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+852' + phone,
        codeAutoRetrievalTimeout: autoRetrieve,
        codeSent: smsCodeSent,
        timeout: const Duration(minutes: 1),
        verificationCompleted: verifySuccess,
        verificationFailed: verifyFail);
    return verificationId;
  }

  void onSignIn() async {
    if (_formKey.currentState.validate()) {
      FocusScope.of(context).unfocus();
      ProgressDialog pr;
      pr = ProgressDialog(context,
          type: ProgressDialogType.Normal,
          isDismissible: false,
          showLogs: false);
      pr.style(
        message: '登錄中...',
        backgroundColor: Theme.of(context).backgroundColor,
        messageTextStyle: TextStyle(
          color: getVisibleTextColorOnScaffold(context),
        ),
      );
      await pr.show();
      await Future.delayed(Duration(seconds: 1));
      try {
        var res = await isRegistered();
        if (res == false) {
          await pr.hide();
          _scaffoldKey.currentState.hideCurrentSnackBar();
          _scaffoldKey.currentState.showSnackBar(SnackBar(
            backgroundColor: yellow_color2,
            duration: Duration(seconds: 2),
            content: Text(
              '此電話號碼尚未註冊。',
              style: TextStyle(color: text_color1),
            ),
          ));
          return;
        }
        await verifyPhone();
        await pr.hide();
      } catch (e) {
        await pr.hide();
        _scaffoldKey.currentState.hideCurrentSnackBar();
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          backgroundColor: yellow_color2,
          duration: Duration(seconds: 2),
          content: Text(
            e.toString(),
            style: TextStyle(color: text_color1),
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? Loading()
        : Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.0,
              title: Text(
                '登入',
                style: TextStyle(color: text_color1),
              ),
            ),
            body: Builder(builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(vertical: 20.0, horizontal: 25.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(height: 80.0),
                          SizedBox(height: 20.0),
                          AuthInput(
                              label: '電話號碼',
                              type: 'phone',
                              onChange: (val) {
                                setState(() => phone = val);
                              }),
                          SizedBox(height: 80.0),
                          MainBtn(
                            label: '登入',
                            height: 64,
                            onPress: () {
                              onSignIn();
                            },
                          ),
                          SizedBox(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '沒有賬戶？',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: text_color3,
                                ),
                              ),
                              TextButton(
                                  onPressed: () {
                                    widget.toggleView(3);
                                  },
                                  child: Text(
                                    '註冊',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: text_color1,
                                    ),
                                  ))
                            ],
                          ),
                          SizedBox(height: 12.0),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }));
  }
}
