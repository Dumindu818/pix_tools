import 'package:flutter_bloc/flutter_bloc.dart';
import 'pix/bloc/pix_bloc.dart';
import 'tools/debugger/bloc/debugger_bloc.dart';
import 'pix/view/pix_screen.dart';
import 'tools/debugger/view/debugger_screen.dart';
import 'tools/editor/bloc/editor_bloc.dart';
import 'tools/editor/view/editor_screen.dart';
import 'package:flutter/material.dart';

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
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF5e17eb),
            titleTextStyle: TextStyle(
              color: Color(0xFFd7c4ff),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            iconTheme: IconThemeData(color: Color(0xFFd7c4ff)),
            actionsIconTheme: IconThemeData(color: Color(0xFFd7c4ff)),
          ),
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

  final List<Widget> pages = const [
    PixScreen(),
    DebuggerScreen(),
    EditorScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PIX TOOLS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // default font color on colored background
          ),
        ),
        backgroundColor: const Color(0xFF5e17eb),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        color: const Color(0xFF5e17eb),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          backgroundColor: const Color(0xFF5e17eb),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: const Color(0xFFd7c4ff),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.qr_code), label: 'QR Gen'),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Debugger',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Editor'),
          ],
        ),
      ),
    );
  }
}
