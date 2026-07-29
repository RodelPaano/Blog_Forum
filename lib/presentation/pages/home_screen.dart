import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../view/posts/post_view_list.dart';
import '../widgets/home_drawer.dart';
import '../widgets/navigation_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _drawerKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Scaffold(
      key: _drawerKey,
      appBar: NavigationWidget(
        isMobile: isMobile,
        loggedIn: loggedIn,
        drawerKey: _drawerKey,
      ),
      drawer: isMobile
          ? HomeDrawer(loggedIn: loggedIn, drawerKey: _drawerKey)
          : null,
      body: PostListView(loggedIn: loggedIn),
    );
  }
}
