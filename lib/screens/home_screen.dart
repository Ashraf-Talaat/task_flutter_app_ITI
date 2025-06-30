import 'dart:typed_data';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:day_6_app/screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'comments_screen.dart';
import 'search_delegate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final postController = TextEditingController();
  Uint8List? selectedImageBytes;
  String? selectedImageName;
  bool showForm = false;

  Future pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        selectedImageBytes = bytes;
        selectedImageName = picked.name;
      });
    }
  }

  void addPost() async {
    final text = postController.text.trim();
    if (text.isEmpty && selectedImageBytes == null) return;

    final base64Image = selectedImageBytes != null
        ? base64Encode(selectedImageBytes!)
        : '';

    await FirebaseFirestore.instance.collection('posts').add({
      'uid': user?.uid,
      'name': user?.displayName ?? '',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
      'imageBase64': base64Image,
    });

    postController.clear();
    selectedImageBytes = null;
    selectedImageName = null;
    setState(() => showForm = false);
  }

  void toggleLike(String postId, List likes) async {
    final uid = user!.uid;
    final ref = FirebaseFirestore.instance.collection('posts').doc(postId);

    if (likes.contains(uid)) {
      await ref.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await ref.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: PostSearchDelegate());
            },
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (showForm)
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: postController,
                    decoration: InputDecoration(
                      hintText: "What's on your mind?",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  if (selectedImageBytes != null)
                    Image.memory(selectedImageBytes!, height: 100),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: Icon(Icons.image),
                        label: Text("Pick Image"),
                      ),
                      SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: addPost,
                        icon: Icon(Icons.send),
                        label: Text("Post"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No posts yet"));
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final data = posts[index].data() as Map<String, dynamic>;
                    final postId = posts[index].id;
                    final likes = List.from(data['likes'] ?? []);
                    final isLiked = likes.contains(user?.uid);

                    return Card(
                      margin: EdgeInsets.all(10),
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['name'] ?? '',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(data['text'] ?? ''),
                            if (data['imageBase64'] != null &&
                                data['imageBase64'].toString().isNotEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Image.memory(
                                  base64Decode(data['imageBase64']),
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked ? Colors.red : null,
                                  ),
                                  onPressed: () => toggleLike(postId, likes),
                                ),
                                IconButton(
                                  icon: Icon(Icons.comment),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CommentsScreen(postId: postId),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(postId)
                                  .collection('comments')
                                  .orderBy('timestamp', descending: true)
                                  .snapshots(),
                              builder: (context, commentSnapshot) {
                                if (!commentSnapshot.hasData) {
                                  return SizedBox.shrink();
                                }

                                final comments = commentSnapshot.data!.docs;

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: comments.map((c) {
                                    final d = c.data() as Map<String, dynamic>;
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.person, size: 18),
                                          SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              "${d['name'] ?? ''}: ${d['text'] ?? ''}",
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => showForm = !showForm),
        child: Icon(showForm ? Icons.close : Icons.add),
      ),
    );
  }
}
