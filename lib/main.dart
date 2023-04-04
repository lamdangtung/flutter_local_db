import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late final SharedPreferences prefs;
  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((value) {
      prefs = value;
    });
  }

  Future<void> _incrementCounter() async {
    setState(() {
      _counter++;
    });
    final buffer = <int>[];
    final users = Utils.genUsers();
    buffer.addAll(Utils.int64GetBytes(users.length));
    for (var user in users) {
      buffer.addAll(user.toBytes());
    }
    String data = base64.encode(buffer);
    try {
      await prefs.setString("user", data);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void readUsers() {
    final data = prefs.getString("user");
    assert(data != null);
    final buffer = base64.decode(data!);
    var users = <User>[];
    int index = 0;
    Map map;
    map = Utils.int64ReadByte(buffer, index);
    int numUsers = map["result"];
    index = map["index"];
    for (int i = 0; i < numUsers; i++) {
      var user = User.create();
      index = user.readByte(buffer, index);
      users.add(user);
      debugPrint("UserId: ${user.id}");
    }
    debugPrint("Users: ${users.length}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            ElevatedButton(
              onPressed: readUsers,
              child: Text("Read"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class Utils {
  static List<User> genUsers([int capacity = 100000]) {
    var users = <User>[];
    int numUsers = capacity;
    for (int i = 1; i <= numUsers; i++) {
      users.add(User(i, genString(6), genString(12)));
      debugPrint("User: ${i}");
    }
    return users;
  }

  static String genString(int length) {
    return getRandomString(length);
  }

  static final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static Random _rnd = Random();

  static String getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(
          length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  static List<int> stringGetBytes(String value) {
    List<int> result = [];
    List<int> buff = utf8.encode(value);
    result.addAll(int64GetBytes(buff.length));
    result.addAll(buff);
    return result;
  }

  static Map stringReadByte(List<int> buff, int index) {
    Map map = int64ReadByte(buff, index);

    // get byte count
    int num = map["result"];
    index = map["index"];

    // get string
    List<int> strBuff = buff.sublist(index, index + num);
    String result = utf8.decode(strBuff);
    index += num;

    return {"result": result, "index": index};
  }

  static List<int> int64GetBytes(int value) {
    ByteData bd = new ByteData(8);
    bd.setInt64(0, value);
    return bd.buffer.asUint8List();
  }

  static Map int64ReadByte(List<int> buff, int index) {
    Int8List list = Int8List.fromList(buff.getRange(index, index + 8).toList());
    index += 8;
    return {"result": list.buffer.asByteData().getUint64(0), "index": index};
  }
}

class User {
  int id;
  String username;
  String password;
  User(this.id, this.username, this.password);

  static User create() {
    return User(0, "", "");
  }

  List<int> toBytes() {
    List<int> result = [];
    result.addAll(Utils.int64GetBytes(id));
    result.addAll(Utils.stringGetBytes(username));
    result.addAll(Utils.stringGetBytes(password));
    return result;
  }

  int readByte(List<int> buff, int i) {
    int index = i;
    Map map;

    // id
    map = Utils.int64ReadByte(buff, index);
    this.id = map["result"];
    index = map["index"];

    // username
    map = Utils.stringReadByte(buff, index);
    this.username = map["result"];
    index = map["index"];

    // password
    map = Utils.stringReadByte(buff, index);
    this.password = map["result"];
    index = map["index"];

    return index;
  }
}
