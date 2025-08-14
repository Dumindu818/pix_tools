import 'package:flutter_bloc/flutter_bloc.dart';
import 'pix/bloc/pix_bloc.dart';
import 'tools/debugger/bloc/debugger_bloc.dart';
import 'pix/view/pix_screen.dart';
import 'tools/debugger/view/debugger_screen.dart';

import 'package:flutter/material.dart';
import 'tools/editor/bloc/editor_bloc.dart';
import 'tools/editor/view/editor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PixBloc()),
        BlocProvider(create: (_) => DebuggerBloc()),
        BlocProvider(create: (_) => EditorBloc()),
      ],
      child: MaterialApp(
        title: 'Pix Tools',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        home: const HomeTabs(),
      ),
    );
  }
}

class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});
  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const PixScreen(),
      const DebuggerScreen(),
      const EditorScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Pix Multi-Tool')),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code), label: 'QR Gen'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Debugger'),
          NavigationDestination(icon: Icon(Icons.edit), label: 'Editor'),
        ],
      ),
    );
  }
}
