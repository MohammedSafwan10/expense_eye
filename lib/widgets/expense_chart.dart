import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_eye/models/expense.dart';
import 'package:expense_eye/providers/expense_provider.dart';
import 'package:intl/intl.dart';

class ExpenseChart extends StatefulWidget {
  // Constructor for the ExpenseChart widget.
  const ExpenseChart({super.key});

  // Creates the mutable state for this widget.
  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

// The state class for the ExpenseChart widget, managing its visual representation and animations.
class _ExpenseChartState extends State<ExpenseChart>
    with SingleTickerProviderStateMixin {
  // Animation controller for animating the chart.
  late final AnimationController _animationController;
  // Animation object to control the progress of the animation.
  late final Animation<double> _animation;
  // Keeps track of the currently touched pie chart section.
  int touchedIndex = -1;
  bool _showPieChart = true;
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  // Called once when the stateful widget is created.
  @override
  void initState() {
    super.initState();
    // Initialize the animation controller with a duration.
    _animationController = AnimationController(
      vsync: this, // Required for TickerProvider.
      duration: const Duration(milliseconds: 1200),
    );
    // Create a curved animation to provide a smooth animation effect.
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubicEmphasized, // Use an ease-in-out cubic curve.
    );
    // Start the animation when the widget is initialized.
    _animationController.forward();
  }

  // Called when the stateful widget is removed from the widget tree.
  // It's important to dispose of the animation controller to release resources.
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Returns a color based on the provided ExpenseCategory using AppTheme-like colors
  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFFF43F5E); // Rose
      case ExpenseCategory.transportation:
        return const Color(0xFF06B6D4); // Cyan
      case ExpenseCategory.utilities:
        return const Color(0xFFFACC15); // Yellow
      case ExpenseCategory.entertainment:
        return const Color(0xFF8B5CF6); // Violet
      case ExpenseCategory.shopping:
        return const Color(0xFF10B981); // Emerald
      case ExpenseCategory.health:
        return const Color(0xFFEC4899); // Pink
      case ExpenseCategory.education:
        return const Color(0xFF6366F1); // Indigo
      case ExpenseCategory.other:
        return const Color(0xFF94A3B8); // Slate
    }
  }

  // Builds the UI for the ExpenseChart.
  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen for changes in the ExpenseProvider.
    return Consumer<ExpenseProvider>(
      builder: (context, expenseProvider, child) {
        // Get the list of expenses from the provider.
        final expenses = expenseProvider.expenses;
        // If there are no expenses, display a message indicating no data.
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.pie_chart_outline,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                Text(
                  'No data to display',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Add some expenses to see charts',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
          );
        }

        // Get the total expenses grouped by category.
        final categoryExpenses = expenseProvider.getExpensesByCategory();
        // Get the total sum of all expenses.
        final totalExpense = expenseProvider.getTotalExpenses();

        // Prepare data for weekly bar chart
        final today = DateTime.now();
        final startOfWeek = today.subtract(
          Duration(days: today.weekday - 1),
        );

        Map<int, double> weeklyData = {};
        for (int i = 0; i < 7; i++) {
          final day = startOfWeek.add(Duration(days: i));
          weeklyData[i] = expenseProvider.getDailyTotal(day);
        }

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12), // Reduced for mobile
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chart type selection
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12), // Reduced for mobile
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment<bool>(
                                  value: true,
                                  icon: Icon(Icons.pie_chart, size: 20),
                                  tooltip: 'Category',
                                ),
                                ButtonSegment<bool>(
                                  value: false,
                                  icon: Icon(Icons.bar_chart, size: 20),
                                  tooltip: 'Time',
                                ),
                              ],
                              selected: {_showPieChart},
                              onSelectionChanged: (Set<bool> selected) {
                                setState(() {
                                  _showPieChart = selected.first;
                                  // Reset animation when changing chart type
                                  _animationController.reset();
                                  _animationController.forward();
                                });
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16), // Reduced for mobile
                        AnimatedCrossFade(
                          firstChild: _buildPieChart(
                            context,
                            categoryExpenses,
                            totalExpense,
                          ),
                          secondChild:
                              _buildBarChart(context, weeklyData, totalExpense),
                          crossFadeState: _showPieChart
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          duration: const Duration(milliseconds: 400),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Total Spending',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  currencyFormat.format(totalExpense),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Reduced for mobile
                if (_showPieChart)
                  _buildCategoryBreakdown(
                      context, categoryExpenses, totalExpense)
                else
                  _buildTimeBreakdown(context, weeklyData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPieChart(
    BuildContext context,
    Map<ExpenseCategory, double> categoryExpenses,
    double totalExpense,
  ) {
    final sections = categoryExpenses.entries.map((entry) {
      final percentage = (entry.value / totalExpense) * 100;
      final isSelected = touchedIndex >= 0 &&
          categoryExpenses.keys.toList().indexOf(entry.key) == touchedIndex;

      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: isSelected
            ? '${percentage.toStringAsFixed(1)}%'
            : '', // Only show percentage on selected
        radius: isSelected ? 75 : 65, // Smaller for mobile
        titleStyle: TextStyle(
          fontSize: isSelected ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withValues(
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0.5, // Increase shadow opacity for better readability
              ),
              blurRadius: 4, // Increase blur radius
            ),
          ],
        ),
        badgeWidget: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _getCategoryEmoji(entry.key),
            style: TextStyle(fontSize: isSelected ? 14 : 12),
          ),
        ),
        badgePositionPercentageOffset: 0.95, // Push emoji badges further out
      );
    }).toList();

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height:
              280, // Increased height significantly to prevent "cut off" and clustering
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 3, // Slightly more space between sections
                    centerSpaceRadius:
                        55, // Larger center space for cleaner look
                    sections: sections.map((section) {
                      return PieChartSectionData(
                        color: section.color,
                        value: section.value * _animation.value,
                        title: _animation.value > 0.8 ? section.title : '',
                        radius: section.radius * _animation.value,
                        titleStyle: section.titleStyle,
                        badgeWidget:
                            _animation.value > 0.7 ? section.badgeWidget : null,
                        badgePositionPercentageOffset:
                            section.badgePositionPercentageOffset,
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Category legend
              if (_animation.value > 0.9 && touchedIndex == -1)
                Container(
                  height: 40,
                  margin: const EdgeInsets.only(top: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: categoryExpenses.entries.map((entry) {
                        final category = entry.key;
                        final color = _getCategoryColor(category);
                        final percentage = (entry.value / totalExpense) * 100;

                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(
                              red: color.r.toDouble(),
                              green: color.g.toDouble(),
                              blue: color.b.toDouble(),
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Text(
                                _getCategoryEmoji(category),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getCategoryEmoji(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return '🍽️';
      case ExpenseCategory.transportation:
        return '🚗';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.entertainment:
        return '🎮';
      case ExpenseCategory.shopping:
        return '🛍️';
      case ExpenseCategory.health:
        return '🏥';
      case ExpenseCategory.education:
        return '📚';
      case ExpenseCategory.other:
        return '📝';
    }
  }

  Widget _buildBarChart(
    BuildContext context,
    Map<int, double> weeklyData,
    double totalExpense,
  ) {
    final maxValue = weeklyData.values.fold<double>(
        0,
        (previousValue, element) =>
            element > previousValue ? element : previousValue);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 200, // Smaller height for mobile
          padding: const EdgeInsets.only(top: 16, right: 16, left: 8),
          child: Column(
            children: [
              Expanded(
                child: BarChart(
                  BarChartData(
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (barGroup) =>
                            Theme.of(context).colorScheme.surface,
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final day = DateFormat('EEEE').format(
                            DateTime.now().subtract(
                              Duration(
                                  days:
                                      DateTime.now().weekday - 1 - groupIndex),
                            ),
                          );
                          return BarTooltipItem(
                            '$day\n',
                            const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: currencyFormat.format(rod.toY),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const weekdays = [
                              'M',
                              'T',
                              'W',
                              'T',
                              'F',
                              'S',
                              'S'
                            ];
                            final today = DateTime.now();
                            final dayIndex = today.weekday - 1;
                            final isToday = value.toInt() == dayIndex;

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: isToday
                                    ? BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(
                                              red: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .r
                                                  .toDouble(),
                                              green: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .g
                                                  .toDouble(),
                                              blue: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .b
                                                  .toDouble(),
                                              alpha: 0.3,
                                            ),
                                        borderRadius: BorderRadius.circular(4),
                                      )
                                    : null,
                                child: Text(
                                  weekdays[value.toInt()],
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(
                                          red: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .r
                                              .toDouble(),
                                          green: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .g
                                              .toDouble(),
                                          blue: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .b
                                              .toDouble(),
                                          alpha: isToday ? 1.0 : 0.7,
                                        ),
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35, // Increased from 30
                          getTitlesWidget: (value, meta) {
                            if (maxValue == 0) return const SizedBox.shrink();

                            if (value == 0) {
                              return const Text('0');
                            } else if (value == maxValue) {
                              return Text(
                                currencyFormat.format(maxValue).split('.')[0],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(
                                        red: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .r
                                            .toDouble(),
                                        green: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .g
                                            .toDouble(),
                                        blue: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .b
                                            .toDouble(),
                                        alpha: 0.7,
                                      ),
                                ),
                              );
                            } else if (value == maxValue / 2) {
                              return Text(
                                currencyFormat
                                    .format(maxValue / 2)
                                    .split('.')[0],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(
                                        red: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .r
                                            .toDouble(),
                                        green: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .g
                                            .toDouble(),
                                        blue: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .b
                                            .toDouble(),
                                        alpha: 0.7,
                                      ),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxValue / 4, // Show 4 grid lines
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color:
                              Theme.of(context).colorScheme.outline.withValues(
                                    red: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .r
                                        .toDouble(),
                                    green: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .g
                                        .toDouble(),
                                    blue: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .b
                                        .toDouble(),
                                    alpha: 0.2,
                                  ),
                          strokeWidth: 1,
                          dashArray: [5, 5], // Dashed line
                        );
                      },
                    ),
                    barGroups: weeklyData.entries.map((entry) {
                      final weekday = entry.key;
                      final value = entry.value;

                      return BarChartGroupData(
                        x: weekday,
                        barRods: [
                          BarChartRodData(
                            toY: value * _animation.value,
                            width: 14,
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.6),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxValue == 0 ? 100 : maxValue,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.05),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              // Legend showing today's value
              const SizedBox(height: 8),
              Container(
                height: 30,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Today's Spending",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currencyFormat
                          .format(weeklyData[DateTime.now().weekday - 1] ?? 0),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdown(
    BuildContext context,
    Map<ExpenseCategory, double> categoryExpenses,
    double totalExpense,
  ) {
    final sortedEntries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced for mobile
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Removed 'Category Breakdown' Title for cleaner look
            const SizedBox(height: 4),
            ...sortedEntries.map((entry) {
              final category = entry.key;
              final amount = entry.value;
              final percentage = (amount / totalExpense) * 100;
              final color = _getCategoryColor(category);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12), // Reduced
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36, // Smaller for mobile
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(
                              red: color.r.toDouble(),
                              green: color.g.toDouble(),
                              blue: color.b.toDouble(),
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              _getCategoryEmoji(category),
                              style: const TextStyle(fontSize: 16), // Smaller
                            ),
                          ),
                        ),
                        const SizedBox(width: 12), // Reduced
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: Text(
                                      category.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    flex: 3,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        currencyFormat.format(amount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).colorScheme.surface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: percentage / 100,
                                    child: AnimatedBuilder(
                                      animation: _animation,
                                      builder: (context, child) {
                                        return FractionallySizedBox(
                                          widthFactor: _animation.value,
                                          child: Container(
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeBreakdown(
    BuildContext context,
    Map<int, double> weeklyData,
  ) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(
      Duration(days: today.weekday - 1),
    );

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Weekly Overview',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d').format(startOfWeek.add(const Duration(days: 6)))}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...weeklyData.entries.map((entry) {
              final weekday = entry.key;
              final amount = entry.value;
              final day = startOfWeek.add(Duration(days: weekday));
              final isToday = day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isToday
                            ? Theme.of(context).colorScheme.primary.withValues(
                                  red: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .r
                                      .toDouble(),
                                  green: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .g
                                      .toDouble(),
                                  blue: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .b
                                      .toDouble(),
                                  alpha: 0.15,
                                )
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(day)[0],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              day.day.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.EEEE().format(day),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: 14,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (amount > 0)
                            Text(
                              currencyFormat.format(amount),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(
                                          red: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .r
                                              .toDouble(),
                                          green: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .g
                                              .toDouble(),
                                          blue: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .b
                                              .toDouble(),
                                          alpha: 0.7,
                                        ),
                                  ),
                              overflow: TextOverflow.ellipsis,
                            )
                          else
                            Text(
                              'No expenses',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(
                                          red: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .r
                                              .toDouble(),
                                          green: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .g
                                              .toDouble(),
                                          blue: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .b
                                              .toDouble(),
                                          alpha: 0.5,
                                        ),
                                    fontStyle: FontStyle.italic,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    if (amount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.primary.withValues(
                                    red: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .r
                                        .toDouble(),
                                    green: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .g
                                        .toDouble(),
                                    blue: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .b
                                        .toDouble(),
                                    alpha: 0.1,
                                  ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            currencyFormat.format(amount),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
