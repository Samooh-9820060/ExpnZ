import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expnz/screens/MainPage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'SignUpScreen.dart';

class SignInScreen extends StatefulWidget {
  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation, _transformAnimation;

  // Forgot password function
  Future<void> forgotPassword() async {
    if (_emailController.text.isEmpty) {
      _showErrorDialog("Please enter your email to reset your password.");
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text);
      _showMessageDialog("Password reset link has been sent to your email.");
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? "An error occurred");
    } catch (e) {
      _showErrorDialog("An unexpected error occurred: ${e.toString()}");
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _transformAnimation = Tween<double>(begin: 20.0, end: 0.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.decelerate));

    _animationController.forward();
  }

  void _showMessageDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Message'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      // Create a new credential for Firebase authentication
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Sign in to Firebase with the Google user credentials
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check Firestore for existing user by email
        final usersRef = FirebaseFirestore.instance.collection('users');
        final querySnapshot = await usersRef.where('email', isEqualTo: user.email).get();
        if (querySnapshot.docs.isEmpty) {
          // No existing user, create new user data in Firestore
          await usersRef.doc(user.uid).set({
            'name': user.displayName,
            'email': user.email,
            'phoneNumber': user.phoneNumber,
            'profileImageUrl': user.photoURL,
          });
        } else {
          // Existing user found, update existing user data
          /*await usersRef.doc(user.uid).update({
            'name': user.displayName ?? FieldValue.delete(), // Delete if null
            'phoneNumber': user.phoneNumber ?? FieldValue.delete(),
            'profileImageUrl': user.photoURL ?? FieldValue.delete(),
          });*/
        }
      }
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? "Firebase Auth error occurred.");
    } catch (e) {
      _showErrorDialog("An error occurred: ${e.toString()}");
    }
  }

  Future<void> signInWithEmailAndPassword() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog("Email and password cannot be empty");
      return;
    } else {
      try {
        final UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
            email: _emailController.text, password: _passwordController.text);

        final User? user = userCredential.user;

        // Check if user's email is verified
        if (user != null && !user.emailVerified) {
          _showErrorDialog("Email is not verified. Please check your email to verify.");
          await user.sendEmailVerification();
          return;
        }

        // Navigate to the next screen if successful
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
      } on FirebaseAuthException catch (e) {
        // Handle error
        _showErrorDialog(e.message ?? "An error occurred");
      } catch (e) {
        // Handle other errors
        print(e.toString());
        _showErrorDialog("An unexpected error occurred: ${e.toString()}");
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Implement your sign-in logic here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          return Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 80.0),
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, _transformAnimation.value),
                    child: _buildSignInForm(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignInForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Sign In',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 50),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            labelStyle: TextStyle(color: Colors.white),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green),
            ),
          ),
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 20),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(color: Colors.white),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blueAccent),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.green),
            ),
          ),
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: 10),
        TextButton(
          onPressed: () {
            forgotPassword();
          },
          child: Text('Forgot Password?'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            signInWithEmailAndPassword();
          },
          child: Text('Sign In'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SignUpScreen(),
            ));
          },
          child: Text('Sign Up'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            signInWithGoogle();
          },
          icon: Icon(Icons.login),
          label: Text('Sign in with Google'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}
