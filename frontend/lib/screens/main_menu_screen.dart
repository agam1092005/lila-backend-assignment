import 'package:flutter/material.dart';
import 'package:nakama/nakama.dart';
import 'package:frontend/services/theme_manager.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/widgets/theme_toggle.dart';
import 'package:frontend/utils/responsive_helper.dart';

class MainMenuScreen extends StatefulWidget {
  final ThemeManager themeManager;
  final AuthService authService;
  final NakamaBaseClient nakamaClient;

  const MainMenuScreen({
    super.key,
    required this.themeManager,
    required this.authService,
    required this.nakamaClient,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger authentication if not already authenticated
    if (widget.authService.status == AuthStatus.unauthenticated) {
      print('[MENU] Triggering authentication...');
      widget.authService.authenticate().then((_) {
        print('[MENU] Authentication completed');
      }).catchError((e) {
        print('[MENU] Authentication error: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveHelper.isMobile(screenWidth);
    final padding = ResponsiveHelper.getPadding(screenWidth);
    final buttonHeight = ResponsiveHelper.getButtonHeight(screenWidth);
    final spacing = ResponsiveHelper.getSpacing(screenWidth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic-Tac-Toe'),
        actions: [
          ThemeToggle(themeManager: widget.themeManager),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : ResponsiveHelper.desktopMaxContentWidth,
          ),
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Text(
                'Multiplayer Tic-Tac-Toe',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 28 : 32,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing * 2),
              
              // Connection Status Indicator
              _buildConnectionStatus(isMobile),
              SizedBox(height: spacing * 2),
              
              // Find Match Button
              SizedBox(
                height: buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/matchmaking');
                  },
                  icon: Icon(Icons.search, size: isMobile ? 28 : 24),
                  label: Text(
                    'Find Match',
                    style: TextStyle(fontSize: isMobile ? 18 : 16),
                  ),
                ),
              ),
              SizedBox(height: spacing),
              
              // Leaderboard Button
              SizedBox(
                height: buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/leaderboard',
                      arguments: {
                        'session': widget.authService.session,
                      },
                    );
                  },
                  icon: Icon(Icons.leaderboard, size: isMobile ? 28 : 24),
                  label: Text(
                    'Leaderboard',
                    style: TextStyle(fontSize: isMobile ? 18 : 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(bool isMobile) {
    return StreamBuilder<AuthStatus>(
      stream: widget.authService.statusStream,
      initialData: widget.authService.status,
      builder: (context, snapshot) {
        final status = snapshot.data ?? AuthStatus.unauthenticated;
        
        Color statusColor;
        IconData statusIcon;
        String statusText;
        
        switch (status) {
          case AuthStatus.authenticated:
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusText = 'Connected';
            break;
          case AuthStatus.authenticating:
            statusColor = Colors.orange;
            statusIcon = Icons.sync;
            statusText = 'Connecting...';
            break;
          case AuthStatus.error:
            statusColor = Colors.red;
            statusIcon = Icons.error;
            statusText = 'Connection Error';
            break;
          case AuthStatus.unauthenticated:
            statusColor = Colors.grey;
            statusIcon = Icons.cloud_off;
            statusText = 'Disconnected';
            break;
        }
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 12,
            vertical: isMobile ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: isMobile ? 20 : 18),
              SizedBox(width: isMobile ? 10 : 8),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: isMobile ? 15 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
