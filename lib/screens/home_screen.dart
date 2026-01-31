import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/match_card.dart';
import '../widgets/competitor_card.dart';
import '../widgets/weekly_stats_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Row(
          children: [
            Text(
              'P',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            Text(
              'GO',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
        ],
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(50)),
        child: Container(
          color: AppColors.white,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección principal - Iniciar Match
                _buildInitiateMatchSection(),

                // Último match
                _buildLastMatchSection(),

                // Semanal
                _buildWeeklySection(),

                // Sugerencias para ti
                _buildSuggestionsSection(),

                // Competidores sugeridos
                _buildCompetitorsSection(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // SECCIÓN: Iniciar Match
  Widget _buildInitiateMatchSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.greyLight,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'ESTÁS A PARTIDA DE SUMAR PUNTOS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(
            height: 16,
            width: 100,
          ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(52),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.secondary,
                    AppColors.secondaryDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'INICIAR\nMATCH',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Requisito: 4ito Categoria',
              style: TextStyle(
                color: AppColors.info,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SECCIÓN: Último match
  Widget _buildLastMatchSection() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Último match',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: MatchCard(
                  title: 'Torneo Cuenca',
                  subtitle: 'hace 2 días',
                  isLastMatch: true,
                ),
              ),
              SizedBox(width: 12),
            ],
          ),
        ],
      ),
    );
  }

  // SECCIÓN: Semanal
  Widget _buildWeeklySection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: WeeklyStatsChart(),
    );
  }

  // SECCIÓN: Sugerencias para ti
  Widget _buildSuggestionsSection() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sugerencias para ti',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Torneo ideal para tu nivel',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 12),
          MatchCard(
            title: 'Torneo PGO',
            subtitle: 'Ligas 6.30 desde desde del Sábado',
            imageUrl: 'https://via.placeholder.com/400x150?text=Torneo+PGO',
          ),
        ],
      ),
    );
  }

  // SECCIÓN: Torneo PGO
  Widget _buildTournamentSection() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: MatchCard(
        title: 'Torneo PGO',
        subtitle: 'Ligas 6:30 desde Sábado',
        imageUrl: 'https://via.placeholder.com/400x200?text=Torneo+PGO',
      ),
    );
  }

  // SECCIÓN: Competidores sugeridos
  Widget _buildCompetitorsSection() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Competidores sugeridos',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CompetitorCard(
                  name: 'Oto Padel Joaquín',
                  imageUrl: 'https://via.placeholder.com/150x150?text=Padel',
                  level: '4.0 nivel',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: CompetitorCard(
                  name: 'Marcos del Padel',
                  imageUrl: 'https://via.placeholder.com/150x150?text=Padel',
                  level: '4.5 nivel',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: CompetitorCard(
                  name: 'Inka Padel',
                  imageUrl: 'https://via.placeholder.com/150x150?text=Padel',
                  level: '5.0 nivel',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home, 0),
              _buildNavItem(Icons.emoji_events, 1),
              _buildNavItem(Icons.people, 2),
              _buildNavItem(Icons.person, 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? AppColors.secondary.withOpacity(0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color:
              _selectedIndex == index ? AppColors.secondary : AppColors.white,
          size: 24,
        ),
      ),
    );
  }
}
