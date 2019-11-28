import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Idea from Official Documentation. Link: https://bloclibrary.dev/#/fluttertodostutorial
abstract class GoogleInfoEvent extends Equatable {
  @override
  List<Object> get props => [];

  const GoogleInfoEvent();
}

class InitializeGoogleInfoEvent extends GoogleInfoEvent {
  final Function callback;

  const InitializeGoogleInfoEvent({this.callback});

  @override
  String toString() => 'InitializeGoogleInfoEvent';
}

class RemoveGoogleInfoEvent extends GoogleInfoEvent {
  final Function callback;

  RemoveGoogleInfoEvent(this.callback);

  @override
  List<Object> get props => [];

  @override
  String toString() => 'RemoveGoogleInfoEvent';
}

// GetOwnGoogleInfoEvent

class GetOwnGoogleInfoEvent extends GoogleInfoEvent {
  final Function callback;

  GetOwnGoogleInfoEvent(this.callback);

  @override
  List<Object> get props => [];

  @override
  String toString() => 'RemoveGoogleInfoEvent';
}