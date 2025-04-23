import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/ui/pages/home/home_view_model.dart';

class HomeBottomNavigationBar extends ConsumerWidget {
  const HomeBottomNavigationBar({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final index = ref.watch(homeViewModel);
    final vm = ref.read(homeViewModel.notifier);

    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: vm.onIndexChanged,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: '지도',
        ),
        NavigationDestination(
          icon: Icon(CupertinoIcons.chat_bubble_2),
          selectedIcon: Icon(CupertinoIcons.chat_bubble_2_fill),
          label: '채팅',
        ),
        NavigationDestination(
          icon: Icon(CupertinoIcons.person),
          selectedIcon: Icon(CupertinoIcons.person_fill),
          label: '프로필',
        ),
      ],
      height: 64,
    );
  }
}
