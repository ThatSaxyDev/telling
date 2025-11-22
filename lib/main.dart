import 'package:flutter/material.dart';
import 'package:telling_logger/telling_logger.dart';
import 'dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Telling.instance.init(
    'TEST_API_KEY',
    baseUrl: 'http://localhost:8080/api/v1/logs',
  );
  Telling.instance.enableCrashReporting();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentIndex == 0
          ? _buildTestConsole()
          : const DashboardScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bug_report),
            label: 'Test Console',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
      ),
    );
  }

  Widget _buildTestConsole() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _incrementCounter();
                Telling.instance.log(
                  'Counter value is $_counter',
                  metadata: {'counter': _counter},
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log sent to Telling!')),
                );
              },
              child: const Text('Log to Telling'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Telling.instance.event(
                  'Button Clicked',
                  properties: {'counter': _counter},
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event sent to Telling!')),
                );
              },
              child: const Text('Track Event'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // This should be caught by FlutterError.onError
                throw Exception('Crash Test (FlutterError)');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
              child: const Text('Crash (FlutterError)'),
            ),
            ElevatedButton(
              onPressed: () async {
                // This should be caught by PlatformDispatcher.onError
                Future.delayed(const Duration(milliseconds: 100), () {
                  throw Exception('Crash Test (Async)');
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100),
              child: const Text('Crash (Async)'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
