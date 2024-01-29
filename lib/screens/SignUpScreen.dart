import 'package:expnz/screens/SignInScreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../database/ProfileDB.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with SingleTickerProviderStateMixin {
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
        title: Text('Verify Your Email'),
        content: Text('A verification email has been sent. Please check your email and verify your account. After verifying please sign in.'),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              // Optionally, navigate to the sign-in screen or a confirmation screen
              Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SignInScreen()));
              },
          ),
        ],
      ),
    );
  }

  Future<void> signUpWithEmailAndPassword() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      _showErrorDialog("Name, Email and password cannot be empty");
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
          _showErrorDialog("An error occurred while registering.");
        }
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Auth error
        _showErrorDialog(e.message ?? "An error occurred");
      } catch (e) {
        // Log the error
        print(e.toString());
        _showErrorDialog("An unexpected error occurred: ${e.toString()}");
      }

    } else {
      // Show error for password mismatch
      _showErrorDialog("Passwords do not match");
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
        SizedBox(height: 40),
        _buildNameField(),
        SizedBox(height: 20),
        _buildMobileNumberField(),
        SizedBox(height: 20),
        _buildEmailField(),
        SizedBox(height: 20),
        _buildPasswordField(),
        SizedBox(height: 20),
        _buildConfirmPasswordField(),
        SizedBox(height: 30),
        _buildSignUpButton(),
        SizedBox(height: 20),
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
          child: Text(
            'Sign Up',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  // Mobile Number Field
  Widget _buildMobileNumberField() {
    return TextFormField(
      controller: _mobileNumberController,
      decoration: _inputDecoration('Mobile Number'),
      keyboardType: TextInputType.phone,
      style: TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your mobile number';
        }
        // Add more validation logic for phone number if needed
        return null;
      },
    );
  }

// Email Field
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: _inputDecoration('Email'),
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email';
        }
        // Use a regular expression to validate the email
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

// Password Field
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      decoration: _inputDecoration('Password'),
      obscureText: true,
      style: TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        if (value.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

// Confirm Password Field
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      decoration: _inputDecoration('Confirm Password'),
      obscureText: true,
      style: TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }


  // Example of a custom styled text field
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: _inputDecoration('Your Name'),
      style: TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  // Other fields similar to _buildNameField, with appropriate validators

  // Example of a custom styled button
  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          signUpWithEmailAndPassword();
        }
      },
      child: Text('Sign Up'),
      style: ElevatedButton.styleFrom(
        primary: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // Example of sign-in option
  Widget _buildSignInOption() {
    return TextButton(
      onPressed: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => SignInScreen()));
      },
      child: Text('Already have an account? Sign in', style: TextStyle(color: Colors.white70)),
    );
  }

  // Utility method for consistent input decoration
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
    );
  }
}