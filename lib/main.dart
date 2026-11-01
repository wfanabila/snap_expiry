
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/router/app_router.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SnapExpiryApp());
}

class SnapExpiryApp extends StatelessWidget {
  const SnapExpiryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) => AuthCubit(AuthRepository()),
      child: MaterialApp.router(
        title: 'SnapExpiry',
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
