ShellRoute class Configuration
A route that displays a UI shell around the matching child route.

When a ShellRoute is added to the list of routes on GoRouter or GoRoute, a new Navigator is used to display any matching sub-routes instead of placing them on the root Navigator.

To display a child route on a different Navigator, provide it with a parentNavigatorKey that matches the key provided to either the GoRouter or ShellRoute constructor. In this example, the _rootNavigator key is passed to the /b/details route so that it displays on the root Navigator instead of the ShellRoute's Navigator:

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>();

  final GoRouter _router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/a',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          // This screen is displayed on the ShellRoute's Navigator.
          GoRoute(
            path: '/a',
            builder: (context, state) {
              return const ScreenA();
            },
            routes: <RouteBase>[
              // This screen is displayed on the ShellRoute's Navigator.
              GoRoute(
                path: 'details',
                builder: (BuildContext context, GoRouterState state) {
                  return const DetailsScreen(label: 'A');
                },
              ),
            ],
          ),
          // Displayed ShellRoute's Navigator.
          GoRoute(
            path: '/b',
            builder: (BuildContext context, GoRouterState state) {
              return const ScreenB();
            },
            routes: <RouteBase>[
              // Displayed on the root Navigator by specifying the
              // [parentNavigatorKey].
              GoRoute(
                path: 'details',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (BuildContext context, GoRouterState state) {
                  return const DetailsScreen(label: 'B');
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
The widget built by the matching sub-route becomes the child parameter of the builder.

For example:

ShellRoute(
  builder: (BuildContext context, GoRouterState state, Widget child) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Shell')
      ),
      body: Center(
        child: child,
      ),
    );
  },
  routes: [
    GoRoute(
      path: 'a'
      builder: (BuildContext context, GoRouterState state) {
        return Text('Child Route "/a"');
      }
    ),
  ],
),
Inheritance
Object RouteBase ShellRouteBase ShellRoute
Constructors
ShellRoute({GoRouterRedirect? redirect, ShellRouteBuilder? builder, ShellRoutePageBuilder? pageBuilder, bool notifyRootObserver = true, List<NavigatorObserver>? observers, required List<RouteBase> routes, GlobalKey<NavigatorState>? parentNavigatorKey, GlobalKey<NavigatorState>? navigatorKey, String? restorationScopeId})
Constructs a ShellRoute.
Properties
builder → ShellRouteBuilder?
The widget builder for a shell route.
final
hashCode → int
The hash code for this object.
no setterinherited
navigatorKey → GlobalKey<NavigatorState>
The GlobalKey to be used by the Navigator built for this route. All ShellRoutes build a Navigator by default. Child GoRoutes are placed onto this Navigator instead of the root Navigator.
final
notifyRootObserver → bool
Whether navigation changes will notify the GoRouter's observers.
finalinherited
observers → List<NavigatorObserver>?
The observers for a shell route.
final
pageBuilder → ShellRoutePageBuilder?
The page builder for a shell route.
final
parentNavigatorKey → GlobalKey<NavigatorState>?
An optional key specifying which Navigator to display this route's screen onto.
finalinherited
redirect → GoRouterRedirect?
An optional redirect function for this route.
finalinherited
restorationScopeId → String?
Restoration ID to save and restore the state of the navigator, including its history.
final
routes → List<RouteBase>
The list of child routes associated with this route.
finalinherited
runtimeType → Type
A representation of the runtime type of the object.
no setterinherited
Methods
buildPage(BuildContext context, GoRouterState state, ShellRouteContext shellRouteContext) → Page?
Attempts to build the Page representing this shell route.
override
buildWidget(BuildContext context, GoRouterState state, ShellRouteContext shellRouteContext) → Widget?
Attempts to build the Widget representing this shell route.
override
debugFillProperties(DiagnosticPropertiesBuilder properties) → void
Add additional properties associated with the node.
override
navigatorKeyForSubRoute(RouteBase subRoute) → GlobalKey<NavigatorState>
Returns the key for the Navigator that is to be used for the specified immediate sub-route of this shell route.
override
noSuchMethod(Invocation invocation) → dynamic
Invoked when a nonexistent method or property is accessed.
inherited
toDiagnosticsNode({String? name, DiagnosticsTreeStyle? style}) → DiagnosticsNode
Returns a debug representation of the object that is used by debugging tools and by DiagnosticsNode.toStringDeep.
inherited
toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) → String
A string representation of this object.
inherited
toStringShort() → String
A brief description of this object, usually just the runtimeType and the hashCode.
inherited
Operators
operator ==(Object other) → bool
The equality operator.
inherited