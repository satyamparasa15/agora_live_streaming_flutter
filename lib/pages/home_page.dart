import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_live_streaming/pages/live_stream_page.dart';

import 'package:flutter_live_streaming/utils/utils.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// create a userNController to retrieve text value
  final _userController = TextEditingController();

  /// create a channelController to retrieve text value
  final _channelController = TextEditingController();

  /// if channel textField is validated to have error
  bool _isValidUser = false;
  bool _isValidChannel = false;

  /// client role
  bool _isBroadcaster = false;

  @override
  void dispose() {
    // dispose input controller
    _channelController.dispose();
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xfff160C2F),
        title: Text("Agora Live Streaming"),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          height: MediaQuery.of(context).size.width * 0.9,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                      child: TextField(
                    controller: _userController,
                    decoration: InputDecoration(
                      errorText: _isValidUser ? 'User name is mandatory' : null,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(width: 1),
                      ),
                      hintText: 'User name',
                    ),
                  ))
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                children: <Widget>[
                  Expanded(
                      child: TextField(
                    controller: _channelController,
                    decoration: InputDecoration(
                      errorText:
                          _isValidChannel ? 'Channel name is mandatory' : null,
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(width: 1),
                      ),
                      hintText: 'Channel name',
                    ),
                  ))
                ],
              ),
              Container(
                width: MediaQuery.of(context).size.width * 0.65,
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SwitchListTile(
                    title:
                        _isBroadcaster ? Text('Broadcaster') : Text('Audience'),
                    value: _isBroadcaster,
                    activeColor: primaryColor,
                    secondary: _isBroadcaster
                        ? Icon(
                            Icons.account_circle,
                            color: primaryColor,
                          )
                        : Icon(Icons.account_circle),
                    onChanged: (value) {
                      setState(() {
                        _isBroadcaster = value;
                        print(_isBroadcaster);
                      });
                    }),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onJoin,
                        child: Text('Join'),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> onJoin() async {
    // update input validation
    setState(() {
      _channelController.text.isEmpty
          ? _isValidChannel = true
          : _isValidChannel = false;
      _userController.text.isEmpty ? _isValidUser = true : _isValidUser = false;
    });
    if (_channelController.text.isNotEmpty && _userController.text.isNotEmpty) {
      // await for camera and mic permissions before pushing video page
      await _handleCameraAndMic(Permission.camera);
      await _handleCameraAndMic(Permission.microphone);
      // push video page with given channel name
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LiveStreamPage(
            channelName: _channelController.text,
            userName: _userController.text,
            isBroadcaster: _isBroadcaster,
          ),
        ),
      );
    }
  }

  Future<void> _handleCameraAndMic(Permission permission) async {
    final status = await permission.request();
    print(status);
  }
}
