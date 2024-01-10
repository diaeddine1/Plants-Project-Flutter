import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_plants/HomePage.dart';

class Comment {
  final String documentId; // Unique identifier for the comment document
  final String userEmail;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.documentId,
    required this.userEmail,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Comment(
      documentId: doc.id,
      userEmail: data['userEmail'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

class PlantDetailPage extends StatefulWidget {
  final Plant plant;

  PlantDetailPage({required this.plant});

  @override
  _PlantDetailPageState createState() => _PlantDetailPageState();
}

class _PlantDetailPageState extends State<PlantDetailPage> {
  TextEditingController _commentController = TextEditingController();
  late User _currentUser;
  bool _isNewToOldOrder = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text(widget.plant.name)),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              child: Image.network(
                widget.plant.imageUrl,
                fit: BoxFit.fill,
              ),
            ),
            Card(
              margin: EdgeInsets.all(16.0),
              elevation: 5.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 12.0),
                    Text(
                      'Category: ${widget.plant.category}',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      'Properties: ${widget.plant.properties}',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'Uses: ${widget.plant.uses}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'Precautions: ${widget.plant.precautions}',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.0),
            _buildCommentInput(),
            SizedBox(height: 16.0),
            _buildCommentList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput() {
    return Card(
      margin: EdgeInsets.all(16.0),
      elevation: 5.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                ),
              ),
            ),
            SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: _postComment,
              child: Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  // Update the _postComment method
void _postComment() {
  String commentText = _commentController.text.trim();

  if (commentText.isNotEmpty) {
    Comment comment = Comment(
      documentId: '', // This will be set after adding to Firestore
      userEmail: _currentUser.email ?? '',
      text: commentText,
      timestamp: DateTime.now(),
    );

    FirebaseFirestore.instance
        .collection('plants')
        .doc(widget.plant.name)
        .collection('comments')
        .add({
      'userEmail': comment.userEmail,
      'text': comment.text,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((value) {
      // Create a new instance with the updated documentId
      Comment updatedComment = Comment(
        documentId: value.id,
        userEmail: comment.userEmail,
        text: comment.text,
        timestamp: comment.timestamp,
      );

      setState(() {
        _commentController.clear();
      });
    });
  }
}


 Widget _buildCommentList() {
  return Column(
    children: [
      _buildSortDropdown(),
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('plants')
            .doc(widget.plant.name)
            .collection('comments')
            .orderBy(
              'timestamp',
              descending: _isNewToOldOrder,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          var comments = snapshot.data!.docs.map((doc) {
            return Comment.fromFirestore(doc);
          }).toList();

          return Column(
            children: comments.map((comment) {
              bool isCurrentUserComment =
                  comment.userEmail == _currentUser.email;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(
                    comment.userEmail,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.text,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18.0,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Posted on: ${_formatTimestamp(comment.timestamp)}',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 12.0,
                            ),
                          ),
                          if (isCurrentUserComment)
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _editComment(comment),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteComment(comment),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    ],
  );
}

void _editComment(Comment comment) {
  TextEditingController _editController = TextEditingController(text: comment.text);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Edit Comment'),
        content: TextField(
          controller: _editController,
          decoration: InputDecoration(
            hintText: 'Edit your comment...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              String editedText = _editController.text.trim();
              if (editedText.isNotEmpty) {
                _performEditComment(comment, editedText);
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      );
    },
  );
}

void _performEditComment(Comment comment, String editedText) {
  FirebaseFirestore.instance
      .collection('plants')
      .doc(widget.plant.name)
      .collection('comments')
      .doc(comment.documentId)
      .update({
    'text': editedText,
    'timestamp': DateTime.now(), 
  });
}




  void _deleteComment(Comment comment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Comment'),
          content: Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _performDeleteComment(comment);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _performDeleteComment(Comment comment) {
    FirebaseFirestore.instance
        .collection('plants')
        .doc(widget.plant.name)
        .collection('comments')
        .doc(comment.documentId)
        .delete();

    // You may want to refresh the comment list after deletion
    // Fetch comments again or use setState if using a StreamBuilder
  }

  Widget _buildSortDropdown() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Sort Order:'),
        SizedBox(width: 8.0),
        DropdownButton<bool>(
          value: _isNewToOldOrder,
          onChanged: (value) {
            setState(() {
              _isNewToOldOrder = value!;
            });
          },
          items: [
            DropdownMenuItem(
              value: true,
              child: Text('Newest First'),
            ),
            DropdownMenuItem(
              value: false,
              child: Text('Oldest First'),
            ),
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute}';
  }
}
