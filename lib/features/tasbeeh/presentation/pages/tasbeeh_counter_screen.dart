import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/di/service_locator.dart';
import '../cubit/tasbeeh_cubit.dart';
import '../cubit/tasbeeh_state.dart';

class TasbeehCounterScreen extends StatelessWidget {
  const TasbeehCounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TasbeehCubit>(
      create: (_) => getIt<TasbeehCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: Text('common.tasbeeh_counter'.tr())),
        body: BlocBuilder<TasbeehCubit, TasbeehState>(
          builder: (context, state) {
            if (state.status == TasbeehStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Text(
                    'tasbeeh.default_phrase'.tr(),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.tertiary,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${state.count}',
                        style: Theme.of(
                          context,
                        ).textTheme.displayLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.read<TasbeehCubit>().increment(),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(220, 56),
                    ),
                    child: Text('tasbeeh.tap_to_count'.tr()),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.read<TasbeehCubit>().reset(),
                    icon: const Icon(Icons.refresh),
                    label: Text('common.reset'.tr()),
                  ),
                  const Spacer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
