import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Wiggle2/screens/home/searchScreen.dart';
import 'package:Wiggle2/shared/constants.dart';
import 'package:Wiggle2/screens/authenticate/helper.dart';
import 'package:Wiggle2/services/database.dart';
import 'package:Wiggle2/screens/home/conversationScreen.dart';
import 'package:provider/provider.dart';
import 'package:Wiggle2/models/user.dart';
import 'package:Wiggle2/models/wiggle.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

final f = new DateFormat('h:mm a');
String email;
Wiggle currentwiggle;
String roomid;
String email1;
String email2;

class _ChatsScreenState extends State<ChatScreen> {
  //snapshots returns a stream
  Stream chatsScreenStream;

  Widget chatRoomList(List<Wiggle> wiggles) {
    return StreamBuilder(
        stream: chatsScreenStream,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? ListView.builder(
                  itemCount: snapshot.data.documents.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    email1 = snapshot.data.documents[index].data["users"][0];
                    email2 = snapshot.data.documents[index].data["users"][1];
                    if (email1 == Constants.myEmail) {
                      email = email2;
                    } else {
                      email = email1;
                    }
                    roomid = snapshot.data.documents[index].data["chatRoomId"];

                    for (int i = 0; i < wiggles.length; i++) {
                      if (wiggles[i].email == email) {
                        currentwiggle = wiggles[i];
                      }
                    }

                    return chatScreenTile(
                      wiggles: wiggles,
                      email: email,
                      chatRoomId: roomid,
                      currentWiggle: currentwiggle,
                    );
                  },
                )
              : Container();
        });
  }

  @override
  void initState() {
    getUserInfo();
    super.initState();
  }

  getUserInfo() async {
    // final user = Provider.of<UserData>(context);
    Constants.myEmail = await Helper.getUserEmailSharedPreference();
    Constants.myName = await Helper.getUserNameSharedPreference();
    DatabaseService().getChatRooms(Constants.myEmail).then((val) {
      setState(() {
        chatsScreenStream = val;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final wiggles = Provider.of<List<Wiggle>>(context) ?? [];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        title: Text("C H A T",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w100)),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                FadeRoute(page: SearchScreen(wiggles: wiggles)),
                ModalRoute.withName('SearchScreen'),
              );
            },
          ),
        ],
      ),
      body: chatRoomList(wiggles),
    );
  }
}

class chatScreenTile extends StatelessWidget {
  final String email;
  final String chatRoomId;
  final Wiggle currentWiggle;
  final List<Wiggle> wiggles;
  Stream chatMessagesStream;
  final f = new DateFormat('h:mm a');
  String latestMsg;
  String latestTime;

  chatScreenTile({
    this.wiggles,
    this.email,
    this.chatRoomId,
    this.currentWiggle,
  });

  Widget getLatestMsg() {
    DatabaseService().getConversationMessages(chatRoomId).then((val) {
      chatMessagesStream = val;
    });
    return StreamBuilder(
      stream: chatMessagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.documents.length - 1 < 0) {
            return Text('');
          } else {
            String msg = snapshot.data
                .documents[snapshot.data.documents.length - 1].data["message"];
            return Text(msg.length >= 20 ? '...' : msg,
                style: TextStyle(color: Colors.grey));
          }
        } else {
          return Container();
        }
      },
    );
  }

  Widget getLatestTime() {
    DatabaseService().getConversationMessages(chatRoomId).then((val) {
      chatMessagesStream = val;
    });
    return StreamBuilder(
      stream: chatMessagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.documents.length - 1 < 0) {
            return Text('');
          } else {
            return Text(
                f
                    .format(snapshot
                        .data
                        .documents[snapshot.data.documents.length - 1]
                        .data["time"]
                        .toDate())
                    .toString(),
                style: TextStyle(color: Colors.black));
          }
        } else {
          return Container();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    return StreamBuilder<UserData>(
        stream: DatabaseService(uid: user.uid).userData,
        builder: (context, snapshot) {
          UserData userData = snapshot.data;
          return GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                FadeRoute(
                  page: ConversationScreen(
                    wiggles: wiggles,
                    wiggle: currentWiggle,
                    chatRoomId: chatRoomId,
                    userData: userData,
                  ),
                ),
                ModalRoute.withName('ConversationScreen'),
              );
            },
            child: Container(
              margin: EdgeInsets.only(top: 5, bottom: 5, right: 10, left:10),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(30)),
                        child: ClipOval(
                          child: new SizedBox(
                            width: 180,
                            height: 180,
                            child: Image.network(
                                  currentWiggle.dp,
                                  fit: BoxFit.fill,
                                ) ??
                                Image.asset('assets/images/profile1.png',
                                    fit: BoxFit.fill),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            currentWiggle.name,
                            style: TextStyle(color: Colors.black),
                          ),
                          getLatestMsg()
                        ],
                      )
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      getLatestTime(),
                    ],
                  )
                ],
              ),
            ),
          );
        });
  }
}
