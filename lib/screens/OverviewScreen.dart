import 'package:flutter/material.dart';
import '../widgets/OverviewCategoryCard.dart';

class OverviewScreen extends StatefulWidget {
  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late TabController _tabController;

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blueGrey[900],
        flexibleSpace: Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TabBar(
                overlayColor: MaterialStateProperty.resolveWith((states) {
                  return Colors.grey.withOpacity(0.1);
                }),
                controller: _tabController,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.grey[700],
                ),
                tabs: [
                  Tab(text: 'Income'),
                  Tab(text: 'Expense'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Icon and Buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {
                        // Open filter dialog or navigate to filter screen
                      },
                    ),
                    Text(
                      "Current Filter: All", // Update this based on the selected filter
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                // Optional: Add more filter or sort buttons here
                IconButton(
                  icon: Icon(Icons.sort, color: Colors.white),
                  onPressed: () {
                    // Open sort dialog or action
                  },
                ),
              ],
            ),
          ),
          // Tab Views for Income and Expense
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CategoryList(type: 'Income', animation: _animation),
                CategoryList(type: 'Expense', animation: _animation),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryList extends StatelessWidget {
  final String type;
  final Animation<double> animation;
  final categories = {'Groceries': 100, 'Entertainment': 200, 'Travel': 100};
  final totalAmount = 300;

  CategoryList({required this.type, required this.animation});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        String category = categories.keys.elementAt(index);
        int amount = categories.values.elementAt(index);
        double percentage = (amount / totalAmount);

        return buildAnimatedCategoryCard(category, amount, percentage);
      },
    );
  }

  Widget buildAnimatedCategoryCard(String category, int amount, double percentage) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.scale(
            scale: animation.value,
            child: OverviewCategoryCard(
              category: category,
              amount: amount,
              percentage: percentage,
            ),
          ),
        );
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: OverviewScreen(),
    theme: ThemeData.dark(),
  ));
}
