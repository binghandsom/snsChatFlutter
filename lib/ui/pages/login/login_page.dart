import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:snschat_flutter/general/functions/validation_functions.dart';
import 'package:snschat_flutter/general/ui-component/loading.dart';
import 'package:snschat_flutter/objects/index.dart';
import 'package:snschat_flutter/state/bloc/WholeApp/WholeAppBloc.dart';
import 'package:snschat_flutter/state/bloc/WholeApp/WholeAppEvent.dart';
import 'package:snschat_flutter/state/bloc/WholeApp/WholeAppState.dart';
import 'package:snschat_flutter/state/bloc/bloc.dart';
import 'package:snschat_flutter/ui/pages/sign_up/sign_up_page.dart';
import 'package:snschat_flutter/ui/pages/verify_phone_number/verify_phone_number_page.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:date_format/date_format.dart';

import 'package:country_code_picker/country_code_picker.dart';

class LoginPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {

  WholeAppBloc wholeAppBloc;
  final _formKey = GlobalKey<FormState>();
  TextEditingController mobileNoTextController = new TextEditingController();

  CountryCode countryCode;

  String countryCodeString;

  bool deviceLocated = false;

  Color themePrimaryColor;

  StreamController<GoogleSignIn> googleSignInStreamController;
  StreamController<FirebaseAuth> firebaseAuthStreamController;
  StreamController<FirebaseUser> firebaseUserStreamController;
  StreamController<IPGeoLocation> ipGeoLocationStreamController;

  Stream<GoogleSignIn> googleSignInStream;
  Stream<FirebaseAuth> firebaseAuthStream;
  Stream<FirebaseUser> firebaseUserStream;
  Stream<IPGeoLocation> ipGeoLocationStream;

  GoogleSignIn googleSignIn;
  FirebaseAuth firebaseAuth;
  FirebaseUser firebaseUser;
  IPGeoLocation ipGeoLocation;

  String getPhoneNumber() {
    String phoneNoInitials = "";
    (BlocProvider.of<GoogleInfoBloc>(context).state as IPGeoLocationLoaded).ipGeoLocation;
    ipGeoLocationStateStream.listen((IPGeoLocationState ipGeoLocationState) {

    });
    if (isObjectEmpty(countryCode) && !isObjectEmpty(wholeAppBloc.currentState.ipGeoLocation)) {
      phoneNoInitials = wholeAppBloc.currentState.ipGeoLocation.calling_code;
    } else {
      phoneNoInitials = countryCode.dialCode;
    }
    String phoneNumber = phoneNoInitials + mobileNoTextController.value.text;
    print("REAL phoneNumber: " + phoneNumber);
    return phoneNumber;
  }

  _signIn() async {
    if (_formKey.currentState.validate()) {
      showCenterLoadingIndicator(context);
      wholeAppBloc.dispatch(CheckUserSignedUpEvent(
          callback: (bool isSignedUp) {
            if (isSignedUp) {
              wholeAppBloc.dispatch(UserSignInEvent(
                  callback: (bool signInSuccessful) {
                    if (signInSuccessful) {
                      Navigator.pop(context);
                      goToVerifyPhoneNumber();
                    } else {
                      Fluttertoast.showToast(
                          msg: 'Invalid Mobile No./matching Google account. Please try again!', toastLength: Toast.LENGTH_SHORT);
                      wholeAppBloc.dispatch(UserSignOutEvent());
                      Navigator.pop(context);
                    }
                  },
                  mobileNo: getPhoneNumber()));
            } else {
              Fluttertoast.showToast(msg: 'Invalid Mobile No./matching Google account. Please try again!', toastLength: Toast.LENGTH_SHORT);
              wholeAppBloc.dispatch(UserSignOutEvent()); // Reset everything to initial state first
              Navigator.pop(context);
//              goToSignUp();
            }
          },
          mobileNo: getPhoneNumber()));
    }
  }

  String isIPLocationExists(WholeAppState state) {
    return isObjectEmpty(state.ipGeoLocation) ? "US" : state.ipGeoLocation.country_code2;
  }

  onCountryPickerChanged(CountryCode countryCode) {
    print("onCountryPickerChanged()");
    print("countryCode: " + countryCode.toString());
    print("countryCode.code: " + countryCode.code.toString());
    print("countryCode.flagUri: " + countryCode.flagUri.toString());
    this.countryCode = countryCode;
    this.countryCodeString = countryCode.code.toString();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    BlocProvider.of<IPGeoLocationBloc>(context).listen((state) {
      if(state is IPGeoLocationLoaded) {
        IPGeoLocation ipGeoLocation = (state as IPGeoLocationLoaded).ipGeoLocation;

      }
    });
    BlocProvider.of<GoogleInfoBloc>(context).listen((state) {
      if(state is GoogleInfoLoaded) {
        GoogleSignIn googleSignIn = (state as GoogleInfoLoaded).googleSignIn;
        FirebaseAuth firebaseAuth = (state as GoogleInfoLoaded).firebaseAuth;
        FirebaseUser firebaseUser = (state as GoogleInfoLoaded).firebaseUser;

      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceWidth = MediaQuery.of(context).size.width;
    final deviceHeight = MediaQuery.of(context).size.height;

    themePrimaryColor = Theme.of(context).textTheme.title.color;

    final WholeAppBloc _wholeAppBloc = BlocProvider.of<WholeAppBloc>(context);
    wholeAppBloc = _wholeAppBloc;

    wholeAppBloc.dispatch(CheckPermissionEvent(callback: (Map<PermissionGroup, PermissionStatus> permissionResults) {
      permissionResults.forEach((PermissionGroup permissionGroup, PermissionStatus permissionStatus) {
        if (permissionGroup == PermissionGroup.contacts && permissionStatus == PermissionStatus.granted) {
          print('if(permissionGroup == PermissionGroup.contacts && permissionStatus == PermissionStatus.granted)');
          wholeAppBloc.dispatch(GetPhoneStorageContactsEvent(callback: (bool done) {}));
        }
      });
    }));

    countryCodeString = isIPLocationExists(wholeAppBloc.currentState);

    return MultiBlocListener(
      listeners: [
        BlocListener<IPGeoLocationBloc, IPGeoLocationState>(
          listener: (context, state) {},
        ),
      ],
      child: GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
          //Focuses on nothing, means disable focus and hide keyboard
          child: Material(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(padding: EdgeInsets.symmetric(vertical: 70.00)),
                Text(
                  "Login",
                  style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Padding(padding: EdgeInsets.symmetric(vertical: 20.00)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.only(left: 20.0),
                            ),
                            CountryCodePicker(
                              initialSelection: countryCodeString,
                              alignLeft: false,
                              showCountryOnly: false,
                              showFlag: true,
                              showOnlyCountryWhenClosed: false,
                              favorite: [countryCodeString],
                              onChanged: onCountryPickerChanged,
                            ),
                            Container(
                              width: deviceWidth * 0.5,
                              margin: EdgeInsetsDirectional.only(top: deviceHeight * 0.03),
                              child: Form(
                                key: _formKey,
                                child: TextFormField(
                                  controller: mobileNoTextController,
                                  validator: (value) {
                                    if (value.isEmpty) {
                                      return "Please enter your phone number";
                                    }
                                    if (value.length < 8) {
                                      return "Please enter a valid phone number format";
                                    }

                                    return null;
                                  },
                                  inputFormatters: [
                                    BlacklistingTextInputFormatter(RegExp('[\\.|\\,]')),
                                  ],
                                  maxLength: 15,
                                  decoration: InputDecoration(hintText: "Mobile Number"),
                                  autofocus: true,
                                  textAlign: TextAlign.left,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )),
                RaisedButton(
                  onPressed: () => _signIn(),
                  textColor: Colors.white,
                  splashColor: Colors.grey,
                  animationDuration: Duration(milliseconds: 500),
                  padding: EdgeInsets.only(left: 70.0, right: 70.0, top: 15.0, bottom: 15.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
                  child: Text("Next"),
                ),
                Padding(padding: EdgeInsets.symmetric(vertical: 10.00)),
                Text("Don't have account yet?"),
                FlatButton(
                    onPressed: () => goToSignUp(),
                    child: Text(
                      "Sign Up Now",
                      style: TextStyle(color: themePrimaryColor),
                    )),
                Padding(padding: EdgeInsets.symmetric(vertical: 50.00)),
                RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                          text: "Contact Support",
                          style: TextStyle(color: themePrimaryColor),
                          recognizer: TapGestureRecognizer()..onTap = () => goToContactSupport)
                    ])),
                Padding(padding: EdgeInsets.symmetric(vertical: 5.00)),
                RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                          text: "Terms and Conditions",
                          style: TextStyle(color: themePrimaryColor),
                          recognizer: TapGestureRecognizer()..onTap = () => goToTermsAndConditions())
                    ])),
                Padding(padding: EdgeInsets.symmetric(vertical: 5.00)),
                RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(children: [
                      TextSpan(
                          text: "Privacy Notice",
                          style: TextStyle(color: themePrimaryColor),
                          recognizer: TapGestureRecognizer()..onTap = () => goToPrivacyNotice())
                    ])),
              ],
            ),
          )),
    );

  }

  goToVerifyPhoneNumber() {
    Navigator.push(context, MaterialPageRoute(builder: ((context) => VerifyPhoneNumberPage(mobileNo: getPhoneNumber()))));
  }

  goToSignUp() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: ((context) => SignUpPage(mobileNo: mobileNoTextController.value.text, countryCodeString: countryCodeString))));
  }

  goToContactSupport() async {
    String now = formatDate(new DateTime.now(), [dd, '/', mm, '/', yyyy]);
    String linebreak = '%0D%0A';
    String url = 'mailto:<support@neurogine.com>?subject=Request for Contact Support ' +
        now +
        ' &body=Name: ' +
        linebreak +
        linebreak +
        'Email: ' +
        linebreak +
        linebreak +
        'Enquiry Details:';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  goToTermsAndConditions() {
    Navigator.of(context).pushNamed("terms_and_conditions_page");
  }

  goToPrivacyNotice() {
    Navigator.of(context).pushNamed("privacy_notice_page");
  }
}
