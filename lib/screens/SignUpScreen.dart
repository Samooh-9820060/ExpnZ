import 'package:expnz/screens/SignInScreen.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZButton.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnZTextField.dart';
import 'package:expnz/widgets/SimpleWidgets/ExpnzSnackBar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../database/ProfileDB.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  SignUpScreenState createState() => SignUpScreenState();
}

class SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController(); // Name field controller
  final _mobileNumberController = TextEditingController(); // Mobile Number field controller
  late AnimationController _animationController;
  late Animation<double> _animation;
  final _formKey = GlobalKey<FormState>();


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  void _showVerifyEmailSentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify Your Email'),
        content: const Text('A verification email has been sent. Please check your email and verify your account. After verifying please sign in.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              // Optionally, navigate to the sign-in screen or a confirmation screen
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignInScreen()));
              },
          ),
        ],
      ),
    );
  }

  Future<void> signUpWithEmailAndPassword() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      showModernSnackBar(context: context, message: 'Name, Email and Password Cannot be blank', backgroundColor: Colors.red);
      return;
    }
    else if (_passwordController.text == _confirmPasswordController.text) {
      try {
        final UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
            email: _emailController.text, password: _passwordController.text);

        // User successfully registered, now insert details into Firestore
        final User? user = userCredential.user;
        final uid = userCredential.user?.uid;
        if (uid != null && user != null) {
          // User successfully registered, now insert details into Firestore
          await ProfileDB().createUserProfile(uid, {
            'name': _nameController.text,
            'phoneNumber': _mobileNumberController.text,
            'profileImageUrl': null,
          });

          // Send verification email
          await user.sendEmailVerification();

          // Show a message that tells the user to verify their email
          _showVerifyEmailSentDialog();
        } else {
          showModernSnackBar(context: context, message: 'An error occurred while registering', backgroundColor: Colors.red);
        }
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Auth error
        showModernSnackBar(context: context, message: e.message ?? 'An error occurred', backgroundColor: Colors.red);
      } catch (e) {
        // Log the error
        showModernSnackBar(context: context, message: 'An unexpected error occurred: ${e.toString()}', backgroundColor: Colors.red);
      }

    } else {
      // Show error for password mismatch
      showModernSnackBar(context: context, message: 'Passwords do not match', backgroundColor: Colors.red);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 80.0),
            child: Form(
              key: _formKey,
              child: _buildSignUpForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildAnimatedTitle(),
        const SizedBox(height: 40),
        ExpnzTextField(label: 'Your Name', controller: _nameController),
        //_buildNameField(),
        //SizedBox(height: 20),
        ExpnzTextField(label: 'Mobile Number', controller: _mobileNumberController, isNumber: true,),
        //_buildMobileNumberField(),
        //SizedBox(height: 20),
        ExpnzTextField(label: 'Email', controller: _emailController,),
        //_buildEmailField(),
        //SizedBox(height: 20),
        ExpnzTextField(label: 'Password', controller: _passwordController, isPassword: true,),
        //_buildPasswordField(),
        //SizedBox(height: 20),
        ExpnzTextField(label: 'Confirm Password', controller: _confirmPasswordController, isPassword: true,),
        //_buildConfirmPasswordField(),
        const SizedBox(height: 30),
        ExpnZButton(label: 'Sign Up',
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              signUpWithEmailAndPassword();
            }
          },
        ),
        //_buildSignUpButton(),
        //SizedBox(height: 20),
        _buildSignInOption(),
      ],
    );
  }

  // Example of animated title
  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: const Text(
            'Sign Up',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildSignInOption() {
    return TextButton(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SignInScreen()));
      },
      child: const Text('Already have an account? Sign in', style: TextStyle(color: Colors.white70)),
    );
  }
}