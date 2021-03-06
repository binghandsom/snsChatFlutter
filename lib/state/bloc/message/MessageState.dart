import 'package:equatable/equatable.dart';
import 'package:snschat_flutter/objects/index.dart';

abstract class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object> get props => [];
}

class MessageLoading extends MessageState {}

class MessagesLoaded extends MessageState {
  final List<Message> messageList;

  const MessagesLoaded([this.messageList = const []]);

  @override
  List<Object> get props => [messageList];

  @override
  String toString() => 'MessagesLoaded {messageList: $messageList}';
}

class MessagesNotLoaded extends MessageState {}
