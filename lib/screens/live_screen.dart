import 'dart:async';

import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_live_streaming/utils/utils.dart';

class LiveScreen extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String channelName;

  /// non-modifiable client role of the page
  final ClientRole role;

  /// Creates a call page with given channel name.
  const LiveScreen({Key key, this.channelName, this.role}) : super(key: key);

  @override
  _LiveScreenState createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  bool videoMuted = false;
  RtcEngine _engine;

  @override
  void dispose() {
    // clear users
    _users.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
  }

  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await _engine.enableVideo();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    configuration.dimensions = VideoDimensions(1920, 1080);
    await _engine.setVideoEncoderConfiguration(configuration);
    await _engine.joinChannel(Token, widget.channelName, null, 0);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(APP_ID);
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role);
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(
      error: (code) {
        setState(() {
          final info = 'onError: $code';
          _infoStrings.add(info);
          print("error occurred $info---------------------------");
        });
      },
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          final info = 'onJoinChannel: $channel, uid: $uid';
          _infoStrings.add(info);
          print("joinChannelSuccess: $info ---------------------------");
        });
      },
      leaveChannel: (stats) {
        setState(() {
          _infoStrings.add('onLeaveChannel');
          _users.clear();
        });
      },
      userJoined: (uid, elapsed) {
        setState(() {
          final info = 'userJoined: $uid';
          _infoStrings.add(info);
          _users.add(uid);
          print("userJoined: $info---------------------------");
        });
      },
      userOffline: (uid, elapsed) {
        setState(() {
          final info = 'userOffline: $uid';
          _infoStrings.add(info);
          _users.remove(uid);
          print("userOffline: $info---------------------------");
        });
      },
      firstRemoteVideoFrame: (uid, width, height, elapsed) {
        setState(() {
          final info = 'firstRemoteVideo: $uid ${width}x $height';
          _infoStrings.add(info);
        });
      },
    ));
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onToggleLocalVideoMute() {
    setState(() {
      videoMuted = !videoMuted;
    });
    _engine.enableLocalVideo(!videoMuted);
    //  _engine.muteLocalVideoStream(videoMuted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
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
              Color(0xfff160C2F),
              Colors.black54,
            ])),
        child: Scaffold(
            backgroundColor: Colors.transparent,
            body: (widget.role == ClientRole.Broadcaster)
                ? ListView(
                    children: [
                      appbarView(),
                      SizedBox(
                        height: 10,
                      ),
                      remoteHostView(),
                      descriptionView(),
                      localHostView(),
                      SizedBox(
                        height: 30,
                      ),
                      tooBar(context)
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: RawMaterialButton(
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
            ),
          ),
        ],
      ),
    );
  }

  /// layout for interaction buttons
  Align tooBar(BuildContext context) {
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
                muted ? Icons.mic_off : Icons.mic,
                color: muted ? Colors.white : Colors.blueAccent,
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
                color: Colors.blueAccent,
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
                videoMuted
                    ? Icons.videocam_off_outlined
                    : Icons.videocam_outlined,
                color: videoMuted ? Colors.white : Colors.blueAccent,
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
        height: 200,
        child: Card(
          elevation: 2,
          color: Colors.grey[900],
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.white, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Container(
            height: 180,
            width: 150,
            child: RtcLocalView.SurfaceView(),
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
  Padding remoteHostView() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        height: 120,
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
                        height: 100,
                        width: 100,
                        color: Colors.red,
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
            widget.channelName,
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
            label: Text("200"),
          ),
        ],
      ),
    );
  }
}
