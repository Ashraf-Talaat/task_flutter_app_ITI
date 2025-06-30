import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PostSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [IconButton(onPressed: () => query = '', icon: Icon(Icons.clear))];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error fetching posts."));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No posts available."));
        }

        final results = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final text = data['text']?.toString().toLowerCase() ?? '';
          final name = data['name']?.toString().toLowerCase() ?? '';
          return text.contains(query.toLowerCase()) ||
              name.contains(query.toLowerCase());
        }).toList();

        if (results.isEmpty) {
          return Center(child: Text("No matching posts found."));
        }

        return ListView(
          children: results.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: ListTile(
                title: Text(data['name'] ?? 'Unknown'),
                subtitle: Text(data['text'] ?? 'No text'),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
