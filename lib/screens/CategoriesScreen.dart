import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/models/TransactionsModel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/CategoriesDB.dart';
import '../widgets/AppWidgets/CategoryCard.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[900],
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection(CategoriesDB.collectionName)
            .where(CategoriesDB.uid, isEqualTo: FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    color: Colors.grey,
                    size: 64,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No categories available.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              //final category = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return buildAnimatedCategoryCard(
                key: ValueKey(snapshot.data!.docs[index].id),
                documentId: snapshot.data!.docs[index].id,
              );
            },
          );
        }
      ),
    );
  }

  Widget buildAnimatedCategoryCard({
    Key? key,
    required String documentId,
  }) {
    return GestureDetector(
      onLongPress: () {
        _showDeleteConfirmationDialog(context, documentId);
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Opacity(
            opacity: _animation.value,
            child: Transform.scale(
              scale: _animation.value,
              /*child: CategoryCard(
                key: key,
                documentId: documentId,
                animation: _animation,
              ),*/
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Category"),
          content: const Text("Are you sure you want to delete this category?\n\n"
              "This will remove this category from all transactions with more than 1 category and Uncategorize any transactions with this category only."),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Delete"),
              onPressed: () async {
                //await Provider.of<TransactionsModel>(context, listen: false).deleteTransactionsByCategoryId(categoryId, null, context);
                CategoriesDB().deleteCategory(documentId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
