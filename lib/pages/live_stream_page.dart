import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_live_streaming/utils/utils.dart';

class LiveStreamPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  ///
  final String? channelName;
  final String? userName;
  bool isBroadcaster;

  LiveStreamPage(
      {Key? key, this.channelName, this.userName, this.isBroadcaster = false})
      : super(key: key);

  @override
  _LiveStreamPageState createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  final _users = <int>[];
  bool _isMicMuted = false,
      _isVideoMuted = false,
      _isLocalUserJoined = false,
      _isCamSwitch = false;

  late RtcEngine _rtcEngine;
  AgoraRtmClient? _rtmClient;
  AgoraRtmChannel? _rtmChannel;

  int chanelCount = 0;

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdks
    _rtcEngine.leaveChannel();
    _rtcEngine.destroy();
    _rtmClient?.destroy();
    _rtmChannel?.leave();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initRTM();
  }

  initRTM() async {
    _rtmClient = await AgoraRtmClient.createInstance(APP_ID);
    await _rtmClient?.login(null, widget.userName ?? "");
    _rtmClient?.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print("Message Received:${message.toString()}");
    };
    _rtmClient?.onConnectionStateChanged = (int state, int reason) {
      print('Connection state changed:' +
          state.toString() +
          ', reason: ' +
          reason.toString());
      if (state == 5) {
        _rtmClient?.logout();
        print('Logout');
      }
    };
    await _createRtmChannel(widget.channelName ?? "");
    await initRTC();
  }

  _createRtmChannel(String name) async {
    _rtmChannel = await _rtmClient?.createChannel(widget.channelName ?? "");
    _rtmChannel?.join().then((value) {
      getChannelCount();
      _rtmChannel?.onMemberJoined = (AgoraRtmMember member) {
        print(
            "RTM Member Joined: ${member.userId} , Channel name ${member.channelId}");
        getChannelCount();
      };
      _rtmChannel?.onMemberLeft = (AgoraRtmMember member) {
        print("RTM Member left: " +
            member.userId +
            ', channel:' +
            member.channelId);
        getChannelCount();
      };
      _rtmChannel?.onMessageReceived =
          (AgoraRtmMessage message, AgoraRtmMember member) {
        print("RTM Received message on channel:${message.toString()}");
      };
      _rtmChannel?.onAttributesUpdated =
          (List<AgoraRtmChannelAttribute> attributes) {
        print("Channel attributes are updated");
        getChannelCount();
        getChannelAttributes();
      };
    });
  }

  Future<void> initRTC() async {
    if (APP_ID.isEmpty) {
      print("APP_ID missing, please provide your APP_ID in settings.dart");
      return;
    }
    await _initAgoraRtcEngine();
    await _rtcEngine.joinChannel(null, widget.channelName ?? "", null, 0);
    _addAgoraEventHandlers();
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _rtcEngine = await RtcEngine.create(APP_ID);
    await _rtcEngine.enableVideo();
    await _rtcEngine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _rtcEngine.setClientRole(
        widget.isBroadcaster ? ClientRole.Broadcaster : ClientRole.Audience);
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _rtcEngine.setEventHandler(RtcEngineEventHandler(error: (code) {
      print("On Error occurred: ${code.toString()}");
    }, joinChannelSuccess: (channel, uid, elapsed) {
      setState(() {
        _isLocalUserJoined = true;
      });
    }, leaveChannel: (stats) {
      setState(() {
        _users.clear();
      });
    }, userJoined: (uid, elapsed) {
      setState(() {
        _users.add(uid);
      });
    }, userOffline: (uid, elapsed) {
      setState(() {
        _users.remove(uid);
      });
    }, clientRoleChanged: (oldRole, newRole) {
      var attribute = List<AgoraRtmChannelAttribute>.generate(1, (index) {
        return AgoraRtmChannelAttribute("appKey", widget.userName ?? "");
      });
      //Updating the channel attributes
      _rtmClient?.addOrUpdateChannelAttributes(
          widget.channelName ?? "", attribute, true);
      setState(() {
        widget.isBroadcaster = true;
      });
    }));
  }

  void getChannelAttributes() {
    _rtmClient?.getChannelAttributes(widget.channelName ?? "").then((value) => {
          value.forEach((element) {
            print("Channel attributes: ${element.toString()}");
          })
        });
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      _isMicMuted = !_isMicMuted;
    });
    _rtcEngine.muteLocalAudioStream(_isMicMuted);
  }

  void _onToggleLocalVideoMute() {
    setState(() {
      _isVideoMuted = !_isVideoMuted;
    });
    _rtcEngine.muteLocalVideoStream(_isVideoMuted);
  }

  void _onSwitchCamera() {
    setState(() {
      _isCamSwitch = !_isCamSwitch;
    });
    _rtcEngine.switchCamera();
  }

  void _toChangeRole() {
    _rtcEngine.setClientRole(ClientRole.Broadcaster);
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    _users.forEach((int uid) => list.add(RtcRemoteView.SurfaceView(uid: uid)));
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  /// Video layout for Audience
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return Container(
            child: Column(
          children: <Widget>[_videoView(views[0])],
        ));
      case 2:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow([views[0]]),
            _expandedVideoRow([views[1]])
          ],
        ));
      case 3:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 3))
          ],
        ));
      case 4:
        return Container(
            child: Column(
          children: <Widget>[
            _expandedVideoRow(views.sublist(0, 2)),
            _expandedVideoRow(views.sublist(2, 4))
          ],
        ));
      default:
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              primaryColor,
              Colors.black54,
            ])),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: widget.isBroadcaster
                ? ListView(
                    children: [
                      appbarView(),
                      SizedBox(
                        height: 10,
                      ),
                      coHostsView(),
                      descriptionView(),
                      localHostView(),
                      SizedBox(
                        height: 30,
                      ),
                      toolBar(context)
                    ],
                  )
                : audienceView(context)),
      ),
    );
  }

  ///layout for audience view
  Center audienceView(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          _viewRows(),
          audienceToolBar(context),
        ],
      ),
    );
  }

  Align audienceToolBar(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RawMaterialButton(
              onPressed: () => {_onCallEnd(context)},
              child: Icon(
                Icons.call_end,
                color: Colors.white,
                size: 30.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(10.0),
            ),
            ElevatedButton(
                onPressed: () {
                  _toChangeRole();
                },
                child: Text("Join as Host"))
          ],
        ),
      ),
    );
  }

  /// layout for interaction buttons
  Align toolBar(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RawMaterialButton(
              onPressed: _onToggleMute,
              child: Icon(
                _isMicMuted ? Icons.mic_off : Icons.mic,
                color: _isMicMuted ? Colors.white : Colors.blueAccent,
                size: 20.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white24,
              padding: const EdgeInsets.all(1.0),
            ),
            RawMaterialButton(
              onPressed: () => {_onCallEnd(context)},
              child: Icon(
                Icons.call_end,
                color: Colors.white,
                size: 26.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(2.0),
            ),
            RawMaterialButton(
              onPressed: _onSwitchCamera,
              child: Icon(
                Icons.switch_camera,
                color: _isCamSwitch ? Colors.white : Colors.blue,
                size: 20.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white24,
              padding: const EdgeInsets.all(1.0),
            ),
            RawMaterialButton(
              onPressed: _onToggleLocalVideoMute,
              child: Icon(
                _isVideoMuted
                    ? Icons.videocam_off_outlined
                    : Icons.videocam_outlined,
                color: _isVideoMuted ? Colors.white : Colors.blueAccent,
                size: 20.0,
              ),
              shape: CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white24,
              padding: const EdgeInsets.all(1.0),
            ),
          ],
        ),
      ),
    );
  }

  ///layout for showing local host
  Align localHostView() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        height: MediaQuery.of(context).size.width * 0.60,
        child: Card(
          elevation: 2,
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.48,
            child:
                _isLocalUserJoined ? RtcLocalView.SurfaceView() : Container(),
          ),
        ),
      ),
    );
  }

  Padding descriptionView() {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Hey\n"
          "You’re live,\n"
          "by Agora's Interactive Live Streaming "
          " ",
          style: TextStyle(
              color: Colors.white70,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w500,
              fontSize: 18),
        ),
      ),
    );
  }

  ///layout for showing hosts
  Padding coHostsView() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: MediaQuery.of(context).size.width * 0.35,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _getRenderViews().length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Container(
                    child: Card(
                      elevation: 2,
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.30,
                        color: Colors.grey,
                        child: RtcRemoteView.SurfaceView(uid: _users[index]),
                      ),
                    ),
                  ));
            }),
      ),
    );
  }

  ///showing channel name
  Padding appbarView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            widget.channelName ?? "",
            style: TextStyle(
                color: Colors.white70,
                fontSize: 28,
                fontWeight: FontWeight.w700),
          ),
          SizedBox(
            width: 22,
          ),
          ElevatedButton(
            onPressed: () {},
            child: Text("Live"),
            style: ElevatedButton.styleFrom(
                primary: Colors.red,
                textStyle:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.remove_red_eye_outlined),
            onPressed: () {},
            style: ElevatedButton.styleFrom(
                primary: Colors.black12,
                textStyle:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            label: Text("$chanelCount"),
          ),
        ],
      ),
    );
  }

  Future<void> getChannelCount() async {
    var membersData = await _rtmChannel?.getMembers();
    setState(() {
      if (membersData != null) {
        chanelCount = membersData.length;
        print("Channel Count:$chanelCount");
      }
    });
  }
}
