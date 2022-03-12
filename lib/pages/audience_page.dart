import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:shihab/utils/utils.dart';

class AudiencePage extends StatefulWidget {
  final String channelName;
  final String userName;
  const AudiencePage(
      {Key? key, required this.channelName, required this.userName})
      : super(key: key);

  @override
  _AudiencePageState createState() => _AudiencePageState();
}

class _AudiencePageState extends State<AudiencePage> {
  late RtcEngine _rtcEngine;
  late AgoraRtmClient? _rtmClient;
  late AgoraRtmChannel? _rtmChannel;
  bool _isJoined = false;
  @override
  void initState() {
    sendRequestForPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audience'),
      ),
      body: Center(
        child: !_isJoined
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(),
                  Text("waiting to join channel"),
                  SizedBox(
                      child: CircularProgressIndicator(),
                      height: 50,
                      width: 50),
                ],
              )
            : Container(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(),
                    Text("Join request accepted"),
                  ],
                ),
              ),
      ),
    );
  }

  void sendRequestForPermission() async {
    _rtmClient = await AgoraRtmClient.createInstance(APP_ID);
    print("rtm client created");
    await _rtmClient?.login(null, widget.userName);
    print("rtm client logged in");
    _rtmChannel = await _rtmClient?.createChannel(widget.channelName);
    await _rtmChannel?.join();
    print("rtm channel created");
    await _rtmChannel?.sendMessage(
        AgoraRtmMessage.fromText("PERMISSION_REQUEST-${widget.userName}"));
    await Future.delayed(Duration(seconds: 1));
    _rtmClient?.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print("Message Received:${message.toString()}");
      print("Message Received:${message.text}");
      if (message.text == "PERMISSION_GRANTED-${widget.userName}") {
        setState(() {
          _isJoined = true;
        });
      } else if (message.text == "PERMISSION_DENIED-${widget.userName}") {
        setState(() {
          _isJoined = false;
        });
      }
    };
  }

  @override
  void dispose() {
    // clear users
    // destroy sdks
    _rtcEngine.leaveChannel();
    _rtcEngine.destroy();
    _rtmClient?.destroy();
    _rtmChannel?.leave();
    super.dispose();
  }
}
