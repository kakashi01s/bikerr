import 'package:bikerr/config/constants.dart';
import 'package:bikerr/core/theme.dart';
import 'package:bikerr/features/map/presentation/bloc/map_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class ActionBar extends StatelessWidget {
  final VoidCallback onMessageTap;

  final bool isThisDevice;
  const ActionBar({super.key, required this.onMessageTap, required this.isThisDevice});

  @override
  Widget build(BuildContext context) {

    return BlocBuilder<MapBloc,MapState>(
      builder: (context,state) {

        if (state is MapLoaded) {
          final speed = state.traccarDevicePositions[state.selectedDeviceId]?.speed;
          final deviceSpeed = state.currentDevicePosition?.speed;
          return Container(
            alignment: Alignment.centerLeft,
            color: AppColors.bikerrbgColor,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 20.0),
                      child: SvgPicture.asset(AppLogos.drawer, height: 30),
                    ),
                    Row(
                      children: [
                        SvgPicture.asset(AppLogos.post, height: 30),
                        const SizedBox(width: 12),
                        SvgPicture.asset(AppLogos.notification, height: 30),
                        const SizedBox(width: 12),
                        GestureDetector(
                          child: SvgPicture.asset(
                              AppLogos.messages, height: 30),
                          onTap: onMessageTap,
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      style: TextStyle(color: Colors.white, ),
                      isThisDevice
                          ? (deviceSpeed != null ? '${deviceSpeed.toStringAsFixed(1)} km/h' : '')
                          : (speed != null ? '${speed.toStringAsFixed(1)} km/h' : ''),
                    )             ,


                  ],
                )
              ],
            ),
          );
        }
        else {
          return SizedBox.shrink();
        }
      }
    );
  }
}

