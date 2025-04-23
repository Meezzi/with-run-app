import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/ui/navigation/bottom_navigation.dart';
import 'package:with_run_app/ui/pages/chat_list/chat_list_page.dart';
import 'package:with_run_app/ui/pages/home/home_view_model.dart';
import 'package:with_run_app/ui/pages/map/map_page.dart';
import 'package:with_run_app/ui/pages/profile/profile_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final currentIndex = ref.watch(homeViewModel);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [MapPage(), ChatListPage(), ProfilePage()],
      ),
      bottomNavigationBar: HomeBottomNavigationBar(),
    );
  }
}
