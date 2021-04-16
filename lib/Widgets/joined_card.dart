import 'package:cab_buddy/commons/theme.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';

import './separator.dart';

class JoinedAd extends StatelessWidget {
  final imageUrl;
  final id;
  final name;
  final to;
  final from;
  final time;
  final vacancies;
  final l;

  JoinedAd({
    this.id,
    this.imageUrl,
    this.name,
    this.to,
    this.from,
    this.time,
    this.vacancies,
    this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(id),
      onDismissed: (direction) {
        leaveRoom();
      },
      confirmDismiss: (direction) {
        return showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: Text('Are You Sure?'),
                content: Text("Do you want to remove the item from the cart?"),
                actions: <Widget>[
                  FlatButton(
                      child: Text('No'),
                      onPressed: () {
                        Navigator.of(ctx).pop(false);
                      }),
                  FlatButton(
                      child: Text('Yes'),
                      onPressed: () {
                        Navigator.of(ctx).pop(true);
                      }),
                ],
              );
            });
      },
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red[400],
        child: Icon(Icons.delete, color: Colors.white, size: 40),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        margin: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      ),
      child: InkWell(
        onTap: () {},
        child: Container(
          height: 150,
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Stack(
            children: [
              Container(
                child: Container(
                  constraints: BoxConstraints.expand(),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                              left: 80,
                              top: 20,
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 27,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                              left: 80,
                              top: 8,
                            ),
                            child: Text(
                              'To: $to',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(
                              left: 20,
                              top: 8,
                            ),
                            child: Text(
                              'From: $from',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 4,
                      ),
                      Separator(),
                      Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(
                              left: 80,
                              top: 8,
                            ),
                            child: Text(
                              'Left: $vacancies',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(
                              left: 20,
                              top: 8,
                            ),
                            child: Text(
                              'Time: ${DateFormat.MMMMd().add_jm().format(time.toDate())}',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.start,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  height: 124,
                  margin: EdgeInsets.only(left: 46),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.rectangle,
                    borderRadius: new BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0.0, 10.0),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(
                  vertical: 16,
                ),
                alignment: FractionalOffset.centerLeft,
                child: Container(
                  width: 95,
                  height: 95,
                  decoration: new BoxDecoration(
                    shape: BoxShape.circle,
                    image: new DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> leaveRoom() async {
    try {
      l.remove(id);
      var v = int.parse(vacancies);
      v = v + 1;
      await Firestore.instance.collection('Ads').document(id).updateData({
        'joinedUsers': l,
        'vacancy': v.toString(),
      });
      Firestore.instance.collection('userJoinedAds').document(id).delete();
    } catch (err) {
      print(err);
    }
  }
}
