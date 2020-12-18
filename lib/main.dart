import 'package:flutter/material.dart';

import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter/widgets.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Welcome to Flutter'),
        ),
        body: Posts()
      ),
    );
  }
}

class Post {
  final int id;
  final String content;

  Post({this.id, this.content});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
    };
  }
}

Future<Database> sqliteConnect() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Future<Database> database = openDatabase(
    join(await getDatabasesPath(), 'myapp_database.db'),
    onCreate: (db, version) {
      return db.execute(
        "CREATE TABLE posts(id INTEGER PRIMARY KEY, content TEXT)",
      );
    },
    version: 1,
  );
  return database;
}

Future<void> insertPost(Post post) async {
  final Database db = await sqliteConnect();

  await db.insert(
    'posts',
    post.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Post>> getPosts() async {
  final Database db = await sqliteConnect();

  final List<Map<String, dynamic>> maps = await db.query('posts');

  return List.generate(maps.length, (i) {
    return Post(
      id: maps[i]['id'],
      content: maps[i]['content'],
    );
  });
}

class Posts extends StatefulWidget {
  @override
  _PostsState createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  List<Post> posts = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List>(
        future: getPosts(),
        initialData: [],
        builder: (context, snapshot) {
          return snapshot.hasData ? new ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: snapshot.data.length,
            itemBuilder: (context, i) {
              return _buildRow(snapshot.data[i]);
            },
          ) : Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context, 
            builder: (BuildContext bc) {
              return Container(
                child: Container(
                  child: TextField(
                    onSubmitted: (String str) {
                      final post = Post(
                        content: str,
                      );

                      insertPost(post);
                      Navigator.pop(context);
                    },
                  ),
                  alignment: Alignment.topLeft,
                  constraints: BoxConstraints.expand(),
                ),
              );
            }
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildRow(Post post) {
    return new ListTile(
      title: new Text(post.content),
    );
  }
}

