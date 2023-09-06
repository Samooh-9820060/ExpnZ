import 'package:flutter/material.dart';

class MenuDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100.0, left: 15),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlutterLogo(
              size: MediaQuery.of(context).size.width / 4,
            ),
            Row(
              children: [
                Text(
                  "EXPENZ",
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  " APP",
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.blue[200],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 40),
            ),
            Text(
              "Home Screen",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
            ),
            Text(
              "Screen 2",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
            ),
            Divider(
              color: Colors.blueGrey[700],
              thickness: 2,
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20),
            ),
            Text(
              "About",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
