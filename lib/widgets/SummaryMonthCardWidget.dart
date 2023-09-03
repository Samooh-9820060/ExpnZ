import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SummaryMonthCardWidget extends StatefulWidget {
  final List<double> data;
  final Color graphLineColor;
  final IconData iconData;
  final String title;
  final String total;
  final double width;

  SummaryMonthCardWidget({
    required this.data,
    required this.graphLineColor,
    required this.iconData,
    required this.title,
    required this.total,
    required this.width,
  });

  @override
  _SummaryMonthCardWidgetState createState() => _SummaryMonthCardWidgetState();
}

class _SummaryMonthCardWidgetState extends State<SummaryMonthCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _numberController;
  late Animation<double> _numberAnimation;

  @override
  void initState() {
    super.initState();
    _numberController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _numberAnimation = Tween<double>(begin: 0, end: 1).animate(_numberController);
    _numberController.forward();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  String _animatedNumberString(double animationValue, String targetValue) {
    int value = (double.parse(targetValue.replaceAll(RegExp(r'[\$,]'), '')) * animationValue).toInt();
    final formatter = NumberFormat("#,###");
    return '\$' + formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _numberController,
      builder: (context, child) {
        return SizedBox(
          width: widget.width,
          height: 120,
          child: Card(
            color: Colors.grey[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.graphLineColor,
                                ),
                              ),
                              Icon(widget.iconData, color: Colors.white, size: 24),
                            ],
                          ),
                          SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.title,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _animatedNumberString(_numberAnimation.value, widget.total),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.center,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            clipData: FlClipData.all(), // Set clip behavior
                            minX: widget.data.asMap().keys.first.toDouble(), // Set min and max to cover your data
                            maxX: widget.data.asMap().keys.last.toDouble(),
                            minY: 0,
                            maxY: 6,
                            lineBarsData: [
                              LineChartBarData(
                                spots: widget.data
                                    .asMap()
                                    .entries
                                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                                    .toList(),
                                isCurved: true,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(show: false),
                                color: widget.graphLineColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
