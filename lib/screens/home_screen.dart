import 'package:flutter/material.dart';
import 'package:internify/screens/profile_screen.dart';
import 'package:internify/screens/reclamations_list_screen.dart';
import '../theme/app_theme.dart';
import '../services/home_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late HomeController _controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = HomeController(context, setState);
    _controller.loadUser();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading || _controller.user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'Internify',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryBlue.withOpacity(0.8),
              ],
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                child: Column(
                  children: [
                    Hero(
                      tag: 'profile_pic',
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF42A5F5),
                              Color(0xFF1976D2),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _controller.user!.name.isNotEmpty
                                ? _controller.user!.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _controller.user!.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _controller.user!.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white30, height: 1, thickness: 1),
              _buildMenuItem(
                icon: Icons.dashboard_outlined,
                title: 'Dashboard',
                isSelected: _controller.selectedSection == 'Dashboard',
                onTap: () => _controller.navigateToSection('Dashboard', () {
                  Navigator.pop(context);
                  _animationController.reset();
                  _animationController.forward();
                }),
              ),
              _buildMenuItem(
                icon: Icons.report_outlined,
                title: 'Réclamation',
                isSelected: _controller.selectedSection == 'Réclamation',
                onTap: () {
                  if (_controller.user?.id != null) {
                    Navigator.pop(context); // close menu/drawer
                    _animationController.reset();
                    _animationController.forward();

                    // Push ReclamationsList safely
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReclamationsListScreen(),
                      ),
                    );
                  } else {
                    // Optionally show a warning if user is null
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not loaded yet')),
                    );
                  }
                },
              ),

              _buildMenuItem(
                icon: Icons.assignment_outlined,
                title: 'Candidature',
                isSelected: _controller.selectedSection == 'Candidature',
                onTap: () => _controller.navigateToSection('Candidature', () {
                  Navigator.pop(context);
                  _animationController.reset();
                  _animationController.forward();
                }),
              ),
              _buildMenuItem(
                icon: Icons.calendar_today_outlined,
                title: 'Agenda',
                isSelected: _controller.selectedSection == 'Agenda',
                onTap: () => _controller.navigateToSection('Agenda', () {
                  Navigator.pop(context);
                  _animationController.reset();
                  _animationController.forward();
                }),
              ),
              _buildMenuItem(
                icon: Icons.folder_outlined,
                title: 'Documents',
                isSelected: _controller.selectedSection == 'Documents',
                onTap: () => _controller.navigateToSection('Documents', () {
                  Navigator.pop(context);
                  _animationController.reset();
                  _animationController.forward();
                }),
              ),
              _buildMenuItem(
                icon: Icons.description_outlined,
                title: 'Contrats',
                isSelected: _controller.selectedSection == 'Contrats',
                onTap: () => _controller.navigateToSection('Contrats', () {
                  Navigator.pop(context);
                  _animationController.reset();
                  _animationController.forward();
                }),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white30, height: 1, thickness: 1),
              _buildMenuItem(
                icon: Icons.settings_outlined,
                title: 'Profile',
                isSelected: _controller.selectedSection == 'Profile',
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileScreen(),
                    ),
                  );
                  setState(() {
                    _controller.selectedSection = 'Profile';
                  });
                },
              ),
              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                isSelected: _controller.selectedSection == 'Help',
                onTap: () => _controller.navigateToSection('Help', () {
                  Navigator.pop(context);
                  _animationController.reset();
                  _animationController.forward();
                }),
              ),
              _buildMenuItem(
                icon: Icons.logout,
                title: 'Logout',
                isSelected: false,
                onTap: _controller.logout,
                isLogout: true,
              ),
            ],
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBodyContent(),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isLogout ? Colors.red.shade300 : Colors.white,
          size: 26,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red.shade300 : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16)
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_controller.selectedSection) {
      case 'Dashboard':
        return _buildDashboard();
      case 'Réclamation':
        return _buildSection('Réclamation', Icons.report,
            'Gérez vos réclamations', Colors.orange);
      case 'Candidature':
        return _buildSection('Candidature', Icons.assignment,
            'Suivez vos candidatures', Colors.blue);
      case 'Agenda':
        return _buildSection('Agenda', Icons.calendar_today,
            'Consultez votre agenda', Colors.green);
      case 'Documents':
        return _buildSection('Documents', Icons.folder,
            'Accédez à vos documents', Colors.purple);
      case 'Contrats':
        return _buildSection('Contrats', Icons.description,
            'Gérez vos contrats', Colors.red);
      case 'Settings':
        return _buildSection('Settings', Icons.settings,
            'Paramètres de l\'application', Colors.grey);
      case 'Help':
        return _buildSection('Help & Support', Icons.help,
            'Centre d\'aide', Colors.teal);
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back! 👋',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _controller.user!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ready to manage your internship journey?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildQuickActionCard(
                icon: Icons.report_outlined,
                title: 'Réclamation',
                color: Colors.orange,
                onTap: () => _controller.navigateToSection('Réclamation', () {
                  _animationController.reset();
                  _animationController.forward();
                }),
              ),
              _buildQuickActionCard(
                icon: Icons.assignment_outlined,
                title: 'Candidature',
                color: Colors.blue,
                onTap: () => _controller.navigateToSection('Candidature', () {
                  _animationController.reset();
                  _animationController.forward();
                }),
              ),
              _buildQuickActionCard(
                icon: Icons.calendar_today_outlined,
                title: 'Agenda',
                color: Colors.green,
                onTap: () => _controller.navigateToSection('Agenda', () {
                  _animationController.reset();
                  _animationController.forward();
                }),
              ),
              _buildQuickActionCard(
                icon: Icons.folder_outlined,
                title: 'Documents',
                color: Colors.purple,
                onTap: () => _controller.navigateToSection('Documents', () {
                  _animationController.reset();
                  _animationController.forward();
                }),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('5', 'Active', Icons.assignment_turned_in),
                    _buildStatItem('12', 'Completed', Icons.check_circle),
                    _buildStatItem('3', 'Pending', Icons.hourglass_empty),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryBlue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, String description, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Add New'),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}