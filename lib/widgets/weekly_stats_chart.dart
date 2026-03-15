import 'package:flutter/material.dart';
import '../constants/colors.dart';

class WeeklyStatsChart extends StatelessWidget {
  const WeeklyStatsChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    final heights = [0.4, 0.6, 0.8, 0.5, 0.9, 0.7, 0.3];
    final isToday = [false, false, false, false, false, false, true];

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Racha semanal',
            style: TextStyle(
              color: AppColors.SecondBlue,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              days.length,
              (index) => Column(
                children: [
                  Container(
                    width: 24,
                    height: 60 * heights[index],
                    decoration: BoxDecoration(
                      color: isToday[index]
                          ? AppColors.PrimaryGreen
                          : AppColors.PrimaryGreen.withOpacity(0.5),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    days[index],
                    style: TextStyle(
                      color: isToday[index]
                          ? AppColors.PrimaryGreen
                          : AppColors.SecondBlue.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Nivel actual: 🔥 Desempenando',
            style: TextStyle(
              color: AppColors.SecondBlue.withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
