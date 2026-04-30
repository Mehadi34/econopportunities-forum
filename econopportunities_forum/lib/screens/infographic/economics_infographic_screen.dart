import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_theme.dart';

class EconomicsInfographicScreen extends StatelessWidget {
  const EconomicsInfographicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Economics Infographic'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header banner
            _HeaderBanner(),
            const SizedBox(height: 20),

            // Key indicators
            _SectionTitle(title: 'Key Global Economic Indicators'),
            const SizedBox(height: 12),
            _KeyIndicatorsGrid(),
            const SizedBox(height: 24),

            // GDP by region bar chart
            _SectionTitle(title: 'GDP Growth by Region (2024, %)'),
            const SizedBox(height: 12),
            _GdpBarChart(),
            const SizedBox(height: 24),

            // Economic sectors pie chart
            _SectionTitle(title: 'Global Economic Sectors'),
            const SizedBox(height: 12),
            _EconomicSectorsPieChart(),
            const SizedBox(height: 24),

            // Economic concepts
            _SectionTitle(title: 'Core Economic Concepts'),
            const SizedBox(height: 12),
            _EconomicConceptsList(),
            const SizedBox(height: 24),

            // Opportunity metrics
            _SectionTitle(title: 'Economic Opportunity Metrics'),
            const SizedBox(height: 12),
            _OpportunityMetrics(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HeaderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Economics at a Glance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Explore key indicators, sector breakdowns, and opportunity metrics '
            'that shape today\'s global economy.',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section title
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

// ---------------------------------------------------------------------------
// Key indicators grid
// ---------------------------------------------------------------------------

class _KeyIndicatorsGrid extends StatelessWidget {
  static const _indicators = [
    _Indicator(
      icon: Icons.trending_up,
      label: 'Global GDP Growth',
      value: '3.2%',
      subtitle: '2024 estimate (IMF)',
      color: AppColors.success,
    ),
    _Indicator(
      icon: Icons.price_change_outlined,
      label: 'Avg. Inflation',
      value: '5.8%',
      subtitle: 'Global CPI (2024)',
      color: AppColors.warning,
    ),
    _Indicator(
      icon: Icons.work_outline,
      label: 'Unemployment',
      value: '5.1%',
      subtitle: 'Global rate (ILO)',
      color: AppColors.info,
    ),
    _Indicator(
      icon: Icons.public,
      label: 'World Trade Vol.',
      value: '+2.6%',
      subtitle: 'Growth (WTO 2024)',
      color: AppColors.secondary,
    ),
    _Indicator(
      icon: Icons.attach_money,
      label: 'World GDP',
      value: '\$105T',
      subtitle: 'Nominal USD',
      color: AppColors.primary,
    ),
    _Indicator(
      icon: Icons.person_outline,
      label: 'GDP per Capita',
      value: '\$13K',
      subtitle: 'Global average',
      color: AppColors.accent,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.55,
      ),
      itemCount: _indicators.length,
      itemBuilder: (_, i) => _IndicatorCard(indicator: _indicators[i]),
    );
  }
}

class _Indicator {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _Indicator({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });
}

class _IndicatorCard extends StatelessWidget {
  final _Indicator indicator;
  const _IndicatorCard({required this.indicator});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(indicator.icon, color: indicator.color, size: 20),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: indicator.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              indicator.value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: indicator.color,
                  ),
            ),
            Text(
              indicator.label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              indicator.subtitle,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GDP bar chart
// ---------------------------------------------------------------------------

class _GdpBarChart extends StatelessWidget {
  static const _data = [
    _RegionGdp('N. America', 2.5),
    _RegionGdp('Europe', 1.4),
    _RegionGdp('Asia Pac', 4.5),
    _RegionGdp('Lat. Am', 2.2),
    _RegionGdp('Africa', 3.8),
    _RegionGdp('Mid. East', 3.1),
  ];

  static const _colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.warning,
    AppColors.success,
    AppColors.info,
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: 6,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: AppColors.primaryDark,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${_data[groupIndex].region}\n${rod.toY.toStringAsFixed(1)}%',
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 2,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}%',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= _data.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _data[idx].region,
                          style: const TextStyle(
                              fontSize: 9, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: AppColors.divider,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(_data.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: _data[i].growth,
                      color: _colors[i % _colors.length],
                      width: 22,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionGdp {
  final String region;
  final double growth;
  const _RegionGdp(this.region, this.growth);
}

// ---------------------------------------------------------------------------
// Economic sectors pie chart
// ---------------------------------------------------------------------------

class _EconomicSectorsPieChart extends StatefulWidget {
  @override
  State<_EconomicSectorsPieChart> createState() =>
      _EconomicSectorsPieChartState();
}

class _EconomicSectorsPieChartState extends State<_EconomicSectorsPieChart> {
  int _touchedIndex = -1;

  static const _sectors = [
    _Sector('Services', 63, AppColors.primary),
    _Sector('Industry', 27, AppColors.secondary),
    _Sector('Agriculture', 6, AppColors.success),
    _Sector('Other', 4, AppColors.warning),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sections: List.generate(_sectors.length, (i) {
                    final isTouched = i == _touchedIndex;
                    final radius = isTouched ? 80.0 : 70.0;
                    return PieChartSectionData(
                      color: _sectors[i].color,
                      value: _sectors[i].share.toDouble(),
                      title: '${_sectors[i].share}%',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 14 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }),
                  sectionsSpace: 3,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _sectors
                  .map((s) => _LegendItem(color: s.color, label: s.name))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Sector {
  final String name;
  final int share;
  final Color color;
  const _Sector(this.name, this.share, this.color);
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Economic concepts
// ---------------------------------------------------------------------------

class _EconomicConceptsList extends StatelessWidget {
  static const _concepts = [
    _Concept(
      icon: Icons.show_chart,
      color: AppColors.primary,
      title: 'Supply & Demand',
      description:
          'The relationship between product availability and consumer desire '
          'determines market price and quantity.',
    ),
    _Concept(
      icon: Icons.account_balance,
      color: AppColors.secondary,
      title: 'Monetary Policy',
      description:
          'Central banks manage the money supply and interest rates to control '
          'inflation and stabilise the economy.',
    ),
    _Concept(
      icon: Icons.receipt_long,
      color: AppColors.accent,
      title: 'Fiscal Policy',
      description:
          'Government spending and taxation decisions that influence economic '
          'activity and redistribute resources.',
    ),
    _Concept(
      icon: Icons.swap_horiz,
      color: AppColors.warning,
      title: 'International Trade',
      description:
          'Exchange of goods and services across borders that allows countries '
          'to specialise and benefit from comparative advantage.',
    ),
    _Concept(
      icon: Icons.lightbulb_outline,
      color: AppColors.success,
      title: 'Innovation & Growth',
      description:
          'Technological progress and human capital investment are primary '
          'drivers of long-run economic growth.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _concepts
          .map((c) => _ConceptCard(concept: c))
          .toList(),
    );
  }
}

class _Concept {
  final IconData icon;
  final Color color;
  final String title;
  final String description;

  const _Concept({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });
}

class _ConceptCard extends StatelessWidget {
  final _Concept concept;
  const _ConceptCard({required this.concept});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: concept.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(concept.icon, color: concept.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    concept.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    concept.description,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Opportunity metrics
// ---------------------------------------------------------------------------

class _OpportunityMetrics extends StatelessWidget {
  static const _metrics = [
    _Metric('Youth Employment Rate', 0.58, '58%', AppColors.primary),
    _Metric('Financial Inclusion', 0.76, '76%', AppColors.secondary),
    _Metric('Digital Economy Access', 0.63, '63%', AppColors.accent),
    _Metric('SME Contribution to GDP', 0.50, '50%', AppColors.warning),
    _Metric('Women in Workforce', 0.47, '47%', AppColors.success),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: _metrics.map((m) => _MetricRow(metric: m)).toList(),
        ),
      ),
    );
  }
}

class _Metric {
  final String label;
  final double value;
  final String display;
  final Color color;

  const _Metric(this.label, this.value, this.display, this.color);
}

class _MetricRow extends StatelessWidget {
  final _Metric metric;
  const _MetricRow({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  metric.label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                metric.display,
                style: TextStyle(
                  color: metric.color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: metric.value,
              minHeight: 10,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(metric.color),
            ),
          ),
        ],
      ),
    );
  }
}
