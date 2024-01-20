import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/AccountsDB.dart';
import '../models/TransactionsModel.dart';
import '../widgets/AppWidgets/AccountCard.dart';

class AccountsScreen extends StatefulWidget {
  @override
  _AccountsScreenState createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen>
    with TickerProviderStateMixin {
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
              .collection(AccountsDB.collectionName)
              .where(AccountsDB.uid, isEqualTo: FirebaseAuth.instance.currentUser!.uid) // Filter by user UID
              .snapshots(),          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.credit_card,
                      color: Colors.grey,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No accounts available.',
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
                final account = snapshot.data!.docs[index];
                Map<String, dynamic> accountData =
                    account.data() as Map<String, dynamic>;
                Map<String, dynamic> currencyMap =
                    jsonDecode(accountData[AccountsDB.accountCurrency]);

                return buildAnimatedAccountCard(
                  documentId: account.id,
                  currencyMap: currencyMap,
                );
              },
            );
          }),
    );
  }

  Widget buildAnimatedAccountCard({
    required String documentId,
    required Map<String, dynamic> currencyMap,
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
              child: ModernAccountCard(
                documentId: documentId,
                currencyMap: currencyMap,
              ),
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
          title: Text("Delete Account"),
          content: Text(
              "Are you sure you want to delete this account? \n\nThis will delete all transactions associated with this account"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () async {
                AccountsDB().deleteAccount(documentId);

                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
