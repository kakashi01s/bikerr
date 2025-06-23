import 'package:bikerr/config/constants.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/base/presentation/bloc/base_bloc.dart';
import 'package:bikerr/features/home/presentation/pages/home_screen.dart';
import 'package:bikerr/features/map/presentation/pages/map_screen.dart';
import 'package:bikerr/features/profile/presentation/pages/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

List<BottomNavigationBarItem> bottomNavItems = <BottomNavigationBarItem>[
  // BottomNavigationBarItem(
  //   icon: SvgPicture.asset(AppLogos.rental),
  //   label: 'Rental',
  // ),
  BottomNavigationBarItem(
    icon: SvgPicture.asset(AppLogos.track),
    label: 'Track',
    activeIcon: SvgPicture.asset(
      AppLogos.track,
      colorFilter: ColorFilter.mode(AppColors.bikerrRedFill, BlendMode.srcIn),
    ),
  ),
  BottomNavigationBarItem(
    icon: SvgPicture.asset(AppLogos.home),
    label: 'Home',
    activeIcon: SvgPicture.asset(
      AppLogos.home,
      colorFilter: ColorFilter.mode(AppColors.bikerrRedFill, BlendMode.srcIn),
    ),
  ),
  // BottomNavigationBarItem(icon: SvgPicture.asset(AppLogos.shop), label: 'Shop'),
  // BottomNavigationBarItem(
  //   icon: SvgPicture.asset(AppLogos.report),
  //   label: 'Report',
  // ),
];

List<Widget> bottomNavScreen = <Widget>[
  MapScreen(),
  HomeScreen(),
  ProfileScreen(),
];

class BasePage extends StatelessWidget {
  const BasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BaseBloc, BaseState>(
      listener: (context, state) {
        // TODO: implement listener
      },
      builder: (context, state) {
        return Scaffold(
          body: Center(child: bottomNavScreen.elementAt(state.tabIndex)),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: AppColors.bikerrbgColor,
            items: bottomNavItems,
            currentIndex: state.tabIndex,
            selectedItemColor: AppColors.bikerrRedFill,
            unselectedItemColor: AppColors.greyText,
            onTap: (value) {
              context.read<BaseBloc>().add(TabIndexChanged(tabIndex: value));
            },
          ),
        );
      },
    );
  }
}
