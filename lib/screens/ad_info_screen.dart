import 'package:cab_buddy/chats/chat_screen.dart';

import 'package:cab_buddy/widgets/info_card.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:overlay_support/overlay_support.dart';
import '../models/loggedIn_user_info.dart';
import 'dart:ui' as ui show Color;

class AdInfoScreen extends StatefulWidget {
  var ss;
  final isDeleteAllowed;
  final isJoinable;
  AdInfoScreen(this.ss, this.isDeleteAllowed, this.isJoinable);

  @override
  _AdInfoScreenState createState() => _AdInfoScreenState();
}

class _AdInfoScreenState extends State<AdInfoScreen> {
  TextEditingController _textFieldController = TextEditingController();
  String _fare = null;

  @override
  void initState() {
    final fbm = FirebaseMessaging();
    fbm.subscribeToTopic(LoggedInUserInfo.id);
    fbm.requestNotificationPermissions();
    fbm.configure(onMessage: (msg) {
      showSimpleNotification(Text(msg['notification']['body']),
          background: Colors.black87);
    }, onLaunch: (msg) {
      print(msg);
    }, onResume: (msg) {
      print(msg);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: widget.isDeleteAllowed
          ? FloatingActionButton.extended(
              backgroundColor: ui.Color(0xff1b1a17),
              onPressed: () {
                inputFare(context);
              },
              label: Text(
                'Finish Trip',
                style: TextStyle(color: Colors.white),
              ),
            )
          : Container(
              height: 0,
            ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          centerTitle: true,
          title: Text("Passengers"),
          actions: [
            widget.isJoinable
                ? FlatButton(
                    onPressed: () {
                      sendOrDeleteRequest();
                    },
                    child: widget.ss['requestedUsers']
                            .contains(LoggedInUserInfo.id)
                        ? Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          )
                        : Text(
                            'Join',
                            style: TextStyle(color: Colors.white),
                          ),
                  )
                : IconButton(
                    icon: Icon(Icons.chat),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => ChatScreen(widget.ss.documentID)));
                    },
                  ),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: Firestore.instance
            .collection('Ads')
            .document(widget.ss.documentID)
            .snapshots(),
        builder: (ctx, snapshot) {
          widget.ss = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container();
          }

          return ListView.builder(
            itemCount: snapshot.data['joinedUsers'].length,
            itemBuilder: (ctx, idx) {
              return FutureBuilder(
                future: Firestore.instance
                    .collection('users')
                    .document(snapshot.data['joinedUsers'][idx])
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  }
                  return InfoCard(
                    snapshot: snapshot,
                    isDeletable: widget.isDeleteAllowed,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> sendOrDeleteRequest() async {
    String id = widget.ss.documentID;
    List l = widget.ss['requestedUsers'];
    if (l.contains(LoggedInUserInfo.id)) {
      l.remove(LoggedInUserInfo.id);
      await Firestore.instance
          .collection('userRequestedAds')
          .document(LoggedInUserInfo.id)
          .delete();
      await Firestore.instance
          .collection('Ads')
          .document(id)
          .updateData({'requestedUsers': l});
      setState(() {});

      return;
    }
    final doc1 = await Firestore.instance
        .collection('userJoinedAds')
        .document(LoggedInUserInfo.id)
        .get();
    if (doc1.exists) {
      setState(() {});

      return;
    }
    final doc2 = await Firestore.instance
        .collection('userRequestedAds')
        .document(LoggedInUserInfo.id)
        .get();
    if (doc2.exists) {
      setState(() {});

      return;
    }
    l.add(LoggedInUserInfo.id);
    await Firestore.instance
        .collection('Ads')
        .document(id)
        .updateData({'requestedUsers': l});

    await Firestore.instance
        .collection('userRequestedAds')
        .document(LoggedInUserInfo.id)
        .setData({"adId": id});

    setState(() {});
  }

  inputFare(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, sets) {
          return AlertDialog(
            title: _fare == null
                ? Text('Enter the total Amount')
                : Text('Trip Fare for each Passenger'),
            content: _fare == null
                ? TextField(
                    controller: _textFieldController,
                    decoration: InputDecoration(hintText: "Fare"),
                    keyboardType: TextInputType.number,
                  )
                : Text(
                    '${int.parse(_fare) / (widget.ss['joinedUsers'].length + 1)}'),
            actions: <Widget>[
              _fare == null
                  ? FlatButton(
                      child: Text(
                        "Confirm",
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () {
                        sets(() {});
                        _fare = _textFieldController.text == ''
                            ? null
                            : _textFieldController.text;
                      },
                    )
                  : FlatButton(
                      child: Text(
                        'Finish',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        finishTrip();
                        Navigator.of(context).pop();
                      },
                    ),
              FlatButton(
                child: Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
                onPressed: () {
                  _textFieldController = TextEditingController();
                  _fare = null;
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> finishTrip() async {
    try {
      for (int i = 0; i < widget.ss['requestedUsers'].length; i++) {
        await Firestore.instance
            .collection('userRequestedAds')
            .document(widget.ss['requestedUsers'][i])
            .delete();
      }
      List l = widget.ss['joinedUsers'];
      while (l.length < 3) {
        String s = "DummySeat" + l.length.toString();
        l.add(s);
      }
      await Firestore.instance.collection('FinishedTrips').add(
        {
          'creator': widget.ss.documentID,
          'passengers': l,
          'fare': '${int.parse(_fare) / (widget.ss['joinedUsers'].length + 1)}',
        },
      );
      print(l.length);
      print(widget.ss['joinedUsers'].length);
      for (int i = 0; i < widget.ss['joinedUsers'].length; i++) {
        await Firestore.instance
            .collection('userJoinedAds')
            .document(widget.ss['joinedUsers'][i])
            .delete();
      }
      await Firestore.instance
          .collection('Chats')
          .document(widget.ss.documentID)
          .delete();
      await Firestore.instance
          .collection('Ads')
          .document(widget.ss.documentID)
          .delete();
    } catch (err) {
      print(err);
    }
  }
}
