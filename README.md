# Blog Forum App

A modern, secure blog/forum application built with **Flutter**, **Provider**, **GoRouter**, and **Supabase**.

---

## Table of Contents

1. [Project Structure](#1-project-structure)
2. [Flutter Concepts Used](#2-flutter-concepts-used)
3. [Dart Language Features](#3-dart-language-features)
4. [Provider State Management](#4-provider-state-management)
5. [Supabase Integration](#5-supabase-integration)
6. [Routing (GoRouter)](#6-routing-gorouter)
7. [How to Create a New Provider](#7-how-to-create-a-new-provider)
8. [How to Add a New Page](#8-how-to-add-a-new-page)
9. [Image Upload Flow](#9-image-upload-flow)
10. [Adding a New Feature — Post Likes](#10-adding-a-new-feature--post-likes)
11. [Architecture Overview](#11-architecture-overview)

---

## 1. Project Structure

```
lib/
├── main.dart                          # Entry point — loads .env, init Supabase, runs App
├── app.dart                           # Root widget — MultiProvider + MaterialApp.router
│
├── core/
│   ├── config.dart                    # Env vars, limits, allowed types (AppConfig)
│   ├── constants.dart                 # AppConstants (padding, radius, durations)
│   ├── exceptions.dart                # Sealed exception hierarchy (Auth, DB, Storage, etc.)
│   ├── logger.dart                    # Simple logger (no PII, silent in release)
│   ├── sanitizers.dart                # Input sanitization (cleanText, cleanName, escapeHtml)
│   ├── supabase_client.dart           # Singleton SupabaseService (client, auth, storage)
│   └── validators.dart                # Validation (email, password, name, title, content)
│
├── models/
│   ├── base_model.dart                # Abstract base with toJson()
│   ├── post.dart                      # Post model (id, userId, title, content, images, author)
│   ├── comment.dart                   # Comment model (id, postId, userId, content, images)
│   └── user_profile.dart              # UserProfile model (id, email, fullName, avatarUrl)
│
├── repositories/
│   ├── generic_repository.dart        # Abstract GenericRepository<T> (CRUD contract)
│   ├── post_repository.dart           # Post CRUD — Supabase queries with profile join
│   ├── comment_repository.dart        # Comment CRUD — Supabase queries with profile join
│   └── profile_repository.dart        # Profile CRUD — upsert, ensureProfileExists
│
├── services/
│   ├── auth_service.dart              # Auth: signUp, signIn, signOut, updateProfile, removeAvatar
│   └── storage_service.dart           # Storage: uploadImage, deleteImage, deleteImages
│
├── providers/
│   ├── auth_provider.dart             # Auth state (unknown/authenticated/unauthenticated)
│   ├── post_provider.dart             # Post list with Paginator, create/update/delete
│   └── comment_provider.dart          # Comments per post (Map<String, List<Comment>>)
│
├── middleware/
│   └── auth_guard.dart                # GoRouter redirect — protects routes from unauthenticated users
│
├── routes/
│   └── app_router.dart                # GoRouter config — all routes defined here
│
├── theme/
│   └── app_theme.dart                 # Material 3 theme (light + dark, seed color #4F46E5)
│
├── ui/
│   ├── pages/
│   │   ├── home_screen.dart           # Main feed — infinite scroll, pull-to-refresh, responsive
│   │   ├── login_screen.dart          # Login form with email/password validation
│   │   ├── register_screen.dart       # Registration form with name/email/password
│   │   ├── post_create_screen.dart    # Create post — title, content, image picker
│   │   ├── post_edit_screen.dart      # Edit post — update title, content, images
│   │   ├── post_view_screen.dart      # View post — full content, comments, comment composer
│   │   └── profile_screen.dart        # Edit profile — avatar, name
│   └── widgets/
│       ├── post_card.dart             # Post preview card (list item)
│       ├── comment_card.dart          # Comment display card
│       ├── image_picker_widget.dart   # Reusable image grid with add/remove
│       ├── error_banner.dart          # Error display with optional retry
│       └── empty_state.dart           # Empty state placeholder
│
└── utils/
    ├── date_utils.dart                # AppDate.relative() — "just now", "5m ago", "2d ago"
    ├── image_utils.dart               # Image validation (magic bytes, MIME, extension, size)
    ├── pagination.dart                # Reusable Paginator<T> class (reset, loadMore, prepend, replace)
    └── url_utils.dart                 # extractStorageKey, isSafeDisplayUrl
```

---

## 2. Flutter Concepts Used

### 2.1 StatelessWidget vs StatefulWidget

**StatelessWidget** — no mutable state. Used for widgets that don't change:

```dart
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [...],
      child: MaterialApp.router(...),
    );
  }
}
```

**StatefulWidget** — has mutable state. Used for screens with forms, scroll controllers, or lifecycle:

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load data after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().loadInitial();
    });
    _scroll.addListener(_onScroll); // infinite scroll listener
  }
}
```

### 2.2 BuildContext

The context of a widget in the widget tree. Used to access providers, theme, and navigation:

```dart
context.read<AuthProvider>().signOut();   // access provider without listening
context.watch<PostProvider>();            // listen for changes (rebuilds on change)
context.push('/login');                   // go_router navigation
Theme.of(context).primaryColor;           // access theme
MediaQuery.of(context).size;              // screen dimensions
```

### 2.3 MaterialApp.router

Instead of the traditional `routes: {}` map, GoRouter is integrated via `routerConfig`:

```dart
MaterialApp.router(
  title: 'Blog Forum',
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.system,
  routerConfig: AppRouter.router,     // ← GoRouter instance
)
```

### 2.4 LayoutBuilder — Responsive Design

Adjusts layout based on available width:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    _isMobile = constraints.maxWidth < 800;
    return Scaffold(
      drawer: _isMobile ? _buildDrawer(loggedIn) : null,
      // mobile → drawer, desktop → AppBar actions
    );
  },
);
```

### 2.5 ScrollController — Infinite Scroll

```dart
void _onScroll() {
  if (_scroll.position.pixels >=
      _scroll.position.maxScrollExtent - AppConstants.loadMoreThreshold) {
    context.read<PostProvider>().loadMore();
  }
}
```

### 2.6 RefreshIndicator — Pull-to-Refresh

```dart
RefreshIndicator(
  onRefresh: () => posts.loadInitial(),
  child: _buildBody(posts, loggedIn),
);
```

### 2.7 BuildContext.mounted

Safety check after async operations to prevent calling methods on disposed widgets:

```dart
await auth.signOut();
if (context.mounted) context.go('/');
```

---

## 3. Dart Language Features

### 3.1 Named Constructors + Factory

```dart
class Post extends BaseModel {
  const Post({...});                                    // default constructor

  factory Post.fromJson(Map<String, dynamic> json) {    // factory — flexible creation
    return Post(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      // ...
    );
  }
```

### 3.2 copyWith — Immutable Pattern

Creates a new instance with some fields changed, keeping the rest:

```dart
Post copyWith({String? title, String? content, List<String>? images}) {
  return Post(
    id: id,                            // keep original
    title: title ?? this.title,        // override if provided
    content: content ?? this.content,
    images: images ?? this.images,
    // ...
  );
}
```

### 3.3 Sealed Exceptions

```dart
sealed class AppException implements Exception {
  final String message;
  const AppException(this.message);
}
class AuthException extends AppException { const AuthException(super.message); }
class DatabaseException extends AppException {
  final String? code;
  const DatabaseException(super.message, {this.code});
}
class StorageException extends AppException { const StorageException(super.message); }
```

### 3.4 Getters (Computed Properties)

```dart
bool get isLoggedIn => _status == AuthStatus.authenticated;
bool get hasMore => _paginator.hasMore;
int get likeCount => _likes.length;
```

### 3.5 Private Members with `_`

```dart
final _repo = PostRepository();         // private field
final _storage = StorageService();

void _setBusy(bool v) {                 // private method
  _busy = v;
  notifyListeners();
}
```

### 3.6 Type Casting from JSON

Since Supabase returns `Map<String, dynamic>`, explicit casting is required:

```dart
(json['title'] as String?) ?? ''
(json['images'] as List?)?.whereType<String>().toList() ?? []
```

### 3.7 Cascade Notation `..`

Calling multiple methods on the same object:

```dart
_paginator..reset(load: fn)..loadMore(load: fn);
```

---

## 4. Provider State Management

### 4.1 What is Provider?

Provider is a **dependency injection + state management** system. It uses `ChangeNotifier` + `InheritedWidget` to broadcast state changes down the widget tree.

### 4.2 ChangeNotifier + notifyListeners()

```dart
class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserProfile? _profile;
  bool _busy = false;

  AuthStatus get status => _status;
  bool get isLoggedIn => _status == AuthStatus.authenticated;

  Future<bool> signIn(String email, String password) async {
    _setBusy(true);
    try {
      _profile = await _service.signIn(email: email, password: password);
      _error = null;
      return true;
    } finally {
      _setBusy(false);   // ← calls notifyListeners()
    }
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();   // ← tells all listeners to rebuild
  }
}
```

### 4.3 MultiProvider Registration

All providers are registered at the root of the app:

```dart
// lib/app.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
    ChangeNotifierProvider(create: (_) => PostProvider()),
    ChangeNotifierProvider(create: (_) => CommentProvider()),
  ],
  child: MaterialApp.router(...),
)
```

### 4.4 context.watch vs context.read

| Method | Rebuilds Widget? | When to Use |
|---|---|---|
| `context.watch<T>()` | Yes | When displaying data from the provider |
| `context.read<T>()` | No | When triggering an action (onPressed, initState) |

```dart
// WATCH — rebuilds when data changes
final posts = context.watch<PostProvider>();

// READ — call once to trigger action
context.read<PostProvider>().loadInitial();
```

### 4.5 The 3 States of Every Feature

Every provider should expose three states:

| State | Variable | UI Response |
|---|---|---|
| Loading | `_loading` or `_loadingPosts` | Show `CircularProgressIndicator` |
| Error | `_error` string | Show `ErrorBanner` or `SnackBar` |
| Data | actual data (list, map, etc.) | Show the content |

UI pattern:

```dart
if (provider.isLoading) return const Center(child: CircularProgressIndicator());
if (provider.error != null) return ErrorBanner(message: provider.error!);
if (provider.items.isEmpty) return EmptyState(icon: Icons.info, title: 'Nothing here');
return ListView(...);  // render data
```

### 4.6 Paginator — Reusable Pagination

```dart
class Paginator<T> {
  final List<T> _items = [];
  int _page = 0;
  int _pageSize;
  bool hasMore = true;

  List<T> get items => List.unmodifiable(_items);

  Future<void> reset({required Future<List<T>> Function(int page, int limit) load}) async {
    _page = 0;
    _items.clear();
    final data = await load(_page, _pageSize);
    _items.addAll(data);
    hasMore = data.length >= _pageSize;
  }

  Future<void> loadMore({required Future<List<T>> Function(int page, int limit) load}) async {
    _page++;
    final data = await load(_page, _pageSize);
    _items.addAll(data);
    hasMore = data.length >= _pageSize;
  }

  void prepend(T item) => _items.insert(0, item);
  void replace(T item) {
    final idx = _items.indexWhere((e) => e.id == item.id);  // assumes .id
    if (idx != -1) _items[idx] = item;
  }
  void removeWhere(bool Function(T) test) => _items.removeWhere(test);
}
```

### 4.7 Data Flow Diagram

```
User taps button
    ↓
Widget calls context.read<Provider>().method()
    ↓
Provider calls Service/Repository
    ↓
Service calls Supabase API
    ↓
Supabase returns data
    ↓
Provider updates private fields + calls notifyListeners()
    ↓
All widgets using context.watch<Provider>() rebuild
    ↓
UI updates with new data
```

---

## 5. Supabase Integration

### 5.1 Initialization (main.dart)

```dart
await Supabase.initialize(
  url: AppConfig.supabaseUrl,
  publishableKey: AppConfig.supabaseAnonKey,
  authOptions: const FlutterAuthClientOptions(
    authFlowType: AuthFlowType.pkce,   // PKCE — more secure than implicit flow
    autoRefreshToken: true,
  ),
);
```

### 5.2 SupabaseService — Singleton Wrapper

```dart
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;
  static String get currentUserId => client.auth.currentUser?.id ?? '';
  static bool get isAuthenticated => client.auth.currentUser != null;
}
```

### 5.3 Database Tables

**Table: `profiles`**
```
id          UUID (PK)   ← matches auth.users.id
email       TEXT
full_name   TEXT
avatar_url  TEXT
created_at  TIMESTAMPTZ
updated_at  TIMESTAMPTZ
```

**Table: `posts`**
```
id          UUID (PK)
user_id     UUID (FK → profiles.id)
title       TEXT
content     TEXT
images      TEXT[]          ← array of image URLs
created_at  TIMESTAMPTZ
updated_at  TIMESTAMPTZ
```

**Table: `comments`**
```
id          UUID (PK)
post_id     UUID (FK → posts.id)
user_id     UUID (FK → profiles.id)
content     TEXT
images      TEXT[]
created_at  TIMESTAMPTZ
updated_at  TIMESTAMPTZ
```

### 5.4 Relationships

```
profiles.id  ←── posts.user_id       (one-to-many: user has many posts)
profiles.id  ←── comments.user_id     (one-to-many: user has many comments)
posts.id     ←── comments.post_id     (one-to-many: post has many comments)
```

### 5.5 SELECT with JOIN (Foreign Key)

Using Supabase's dot notation:

```dart
final res = await SupabaseService.client
    .from('posts')
    .select('*, profiles:user_id(full_name, avatar_url)')
    //    ↑     ↑        ↑       ↑
    //  all cols  alias   FK   selected columns from profiles
    .order('created_at', ascending: false)
    .range(from, to);
```

Result:

```json
{
  "id": "abc-123",
  "user_id": "user-456",
  "title": "My Post",
  "profiles": {
    "full_name": "Rodz Paano",
    "avatar_url": "https://..."
  }
}
```

### 5.6 INSERT with Return Value

```dart
final res = await client
    .from('posts')
    .insert({'user_id': uid, 'title': 'Hello', 'content': 'World', 'images': []})
    .select('*, profiles:user_id(full_name, avatar_url)')  // ← return inserted row
    .single();                                              // ← expect exactly 1 row
```

### 5.7 UPDATE with Return Value

```dart
final res = await client
    .from('posts')
    .update({'title': 'New Title', 'updated_at': DateTime.now().toUtc().toIso8601String()})
    .eq('id', postId)                                       // ← WHERE clause
    .select('*, profiles:user_id(full_name, avatar_url)')
    .single();
```

### 5.8 DELETE

```dart
await client.from('posts').delete().eq('id', postId);
```

### 5.9 Pagination with .range()

```dart
final from = page * pageSize;        // page 0 → 0, page 1 → 10
final to = from + pageSize - 1;      // page 0 → 9, page 1 → 19
final res = await client
    .from('posts')
    .select('*')
    .order('created_at', ascending: false)
    .range(from, to);
```

### 5.10 Auth — Sign Up with Metadata

```dart
final res = await SupabaseService.auth.signUp(
  email: cleanEmail,
  password: password,
  data: {'full_name': cleanName},   // stored in auth.users.raw_user_meta_data
);
```

### 5.11 Auth — Realtime Listener

```dart
_service.authStateChanges.listen((event) async {
  final session = event.session;
  if (session != null) {
    _profile = await _service.fetchProfile(session.user.id);
    _status = AuthStatus.authenticated;
  } else {
    _profile = null;
    _status = AuthStatus.unauthenticated;
  }
  notifyListeners();
});
```

### 5.12 Storage — Upload (Cross-Platform)

```dart
Future<String> uploadImage(XFile file, {required String folder}) async {
  final bytes = await file.readAsBytes();

  // Validate
  if (!await ImageUtils.isValidImage(file)) throw StorageException(...);
  if (bytes.length > AppConfig.maxImageBytes) throw StorageException(...);

  // Generate unique path
  final ext = '.jpg';
  final fileName = '${folder}/${uuid.v4()}$ext';

  // Web vs Mobile
  if (kIsWeb) {
    await storage.from(bucket).uploadBinary(fileName, bytes,
        fileOptions: FileOptions(contentType: mime));
  } else {
    await storage.from(bucket).upload(fileName, io.File(file.path),
        fileOptions: FileOptions(contentType: mime));
  }

  return storage.from(bucket).getPublicUrl(fileName);
}
```

### 5.13 Storage — Delete by URL

```dart
Future<void> deleteImageByUrl(String publicUrl) async {
  final key = UrlUtils.extractStorageKey(publicUrl, bucket: bucket);
  if (key == null || key.isEmpty || key.contains('..')) return;
  await SupabaseService.storage.from(bucket).remove([key]);
}
```

### 5.14 Supabase Query Cheatsheet

| Operation | Code |
|---|---|
| SELECT all | `.from('table').select('*')` |
| SELECT with join | `.select('*, profiles:user_id(name)')` |
| WHERE | `.eq('column', value)` |
| ORDER BY | `.order('col', ascending: false)` |
| Pagination | `.range(from, to)` |
| INSERT | `.insert({...}).select().single()` |
| UPDATE | `.update({...}).eq('id', id).select().single()` |
| DELETE | `.delete().eq('id', id)` |

---

## 6. Routing (GoRouter)

### 6.1 What is GoRouter?

GoRouter is a declarative routing package. All routes are defined in one place, with support for path parameters, redirects, and deep linking.

### 6.2 Route Configuration

```dart
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) => AuthGuard.redirect(context, state),
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/post/new', builder: (_, __) => const PostCreateScreen()),
      GoRoute(
        path: '/post/:id',                                   // ← dynamic segment
        builder: (_, s) => PostViewScreen(postId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/post/:id/edit',
        builder: (_, s) => PostEditScreen(postId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(                    // ← 404 page
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(child: Text('No route: ${state.uri}')),
    ),
  );
}
```

### 6.3 Navigation Methods

```dart
context.push('/post/new');        // push — can go back
context.push('/post/123');        // with ID parameter
context.go('/');                  // go — replaces current route, no back
context.pop();                    // pop — go back to previous route
```

### 6.4 Dynamic Route Parameters

The `:id` in the path becomes available via `pathParameters`:

```dart
GoRoute(
  path: '/post/:id',
  builder: (_, s) => PostViewScreen(postId: s.pathParameters['id']!),
)
```

### 6.5 Auth Redirect Middleware

Every navigation triggers the `redirect` callback:

```dart
class AuthGuard {
  AuthGuard._();

  static String? redirect(BuildContext context, GoRouterState state) {
    final auth = context.read<AuthProvider>();
    final loggedIn = auth.isLoggedIn;
    final goingToAuth =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (auth.status == AuthStatus.unknown) return null;
    // → still loading auth state, don't redirect yet

    if (!loggedIn && !goingToAuth) return '/login';
    // → not logged in and not going to auth page → redirect to login

    if (loggedIn && goingToAuth) return '/';
    // → logged in but going to login/register → redirect to home

    return null;  // → proceed to requested route
  }
}
```

**Flow:**
1. User clicks "New Post" → `context.push('/post/new')`
2. GoRouter calls `redirect` callback
3. `AuthGuard` returns `null` (proceed) if logged in, or `'/login'` if not

### 6.6 Adding a New Route

```dart
// 1. Import the screen
import '../ui/pages/about_screen.dart';

// 2. Add to routes list
GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),

// 3. Navigate from anywhere
context.push('/about');
```

---

## 7. How to Create a New Provider

### Step-by-Step: Creating a "LikeProvider"

### Step 1: Create the file

```
lib/providers/like_provider.dart
```

### Step 2: Write the Provider class

```dart
import 'package:flutter/foundation.dart';

class LikeProvider extends ChangeNotifier {
  // --- Private state ---
  final Map<String, Set<String>> _likes = {};  // postId → set of userIds
  final Set<String> _loadingPosts = {};
  String? _error;

  // --- Public getters ---
  bool isLiked(String postId, String userId) =>
      _likes[postId]?.contains(userId) ?? false;

  int likeCount(String postId) => _likes[postId]?.length ?? 0;

  bool isLoadingFor(String postId) => _loadingPosts.contains(postId);

  String? get error => _error;

  // --- Methods ---

  Future<void> loadLikes(String postId) async {
    _loadingPosts.add(postId);
    notifyListeners();
    try {
      final data = await _repo.getLikes(postId);
      _likes[postId] = data.toSet();
      _error = null;
    } catch (e) {
      _error = 'Failed to load likes';
    } finally {
      _loadingPosts.remove(postId);
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId, String userId) async {
    final currentlyLiked = isLiked(postId, userId);

    // Optimistic update — update UI immediately
    if (currentlyLiked) {
      _likes[postId]?.remove(userId);
    } else {
      _likes.putIfAbsent(postId, () => {}).add(userId);
    }
    notifyListeners();

    try {
      if (currentlyLiked) {
        await _repo.unlike(postId, userId);
      } else {
        await _repo.like(postId, userId);
      }
    } catch (e) {
      // Revert on error
      if (currentlyLiked) {
        _likes.putIfAbsent(postId, () => {}).add(userId);
      } else {
        _likes[postId]?.remove(userId);
      }
      _error = 'Failed to update like';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
```

### Step 3: Register in MultiProvider

```dart
ChangeNotifierProvider(create: (_) => LikeProvider()),  // add to list
```

### Step 4: Use in UI

```dart
final likes = context.watch<LikeProvider>();
final userId = SupabaseService.currentUserId;

IconButton(
  icon: Icon(
    likes.isLiked(postId, userId)
        ? Icons.favorite
        : Icons.favorite_border,
    color: likes.isLiked(postId, userId) ? Colors.red : null,
  ),
  onPressed: () => likes.toggleLike(postId, userId),
),
Text('${likes.likeCount(postId)}'),
```

### Key Rules for Building a Provider

| Rule | Explanation |
|---|---|
| Always call `notifyListeners()` | Otherwise the UI won't know something changed |
| Use `_` prefix for private state | `_posts`, `_loading`, `_error` |
| Provide public getters | Don't expose private fields directly |
| Handle errors gracefully | Store in `_error` instead of throwing |
| Clean up in `dispose()` | Cancel streams, close controllers |

---

## 8. How to Add a New Page

### Step 1: Create the screen file

```
lib/ui/pages/about_screen.dart
```

```dart
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blog Forum App',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Version 1.0.0\n'
              'Built with Flutter, Provider, GoRouter, and Supabase.\n\n'
              'A secure, modern blog/forum platform.',
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 2: Register the route

```dart
// lib/routes/app_router.dart
import '../ui/pages/about_screen.dart';

// Add to routes:
GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
```

### Step 3: Add navigation button

```dart
ElevatedButton(
  onPressed: () => context.push('/about'),
  child: const Text('About'),
),
```

### Anatomy of a Complete Screen

```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  @override
  void initState() {
    super.initState();
    // 1. Load data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SomeProvider>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 2. Watch provider
    final data = context.watch<SomeProvider>();

    // 3. Handle 3 states
    if (data.isLoading) return const Center(child: CircularProgressIndicator());
    if (data.error != null) return ErrorBanner(message: data.error!, onRetry: () => data.loadData());
    if (data.items.isEmpty) return EmptyState(icon: Icons.info, title: 'Nothing here');

    // 4. Show data
    return Scaffold(
      appBar: AppBar(title: const Text('My Screen')),
      body: ListView.builder(
        itemCount: data.items.length,
        itemBuilder: (_, i) => ListTile(title: Text(data.items[i].toString())),
      ),
    );
  }

  @override
  void dispose() {
    // 5. Clean up
    super.dispose();
  }
}
```

---

## 9. Image Upload Flow

### Complete Flow

```
User picks image from gallery
    ↓
ImagePicker returns XFile
    ↓
StorageService reads bytes
    ↓
Validate: magic bytes, size, extension, MIME
    ↓
Generate UUID filename with correct extension
    ↓
Upload to Supabase Storage (Web: uploadBinary, Mobile: upload)
    ↓
Get public URL from Supabase
    ↓
Return URL to Provider
    ↓
Provider saves URL to database via Repository
    ↓
UI displays image via CachedNetworkImage
```

### Step 1: Pick Image

```dart
import 'package:image_picker/image_picker.dart';

final picker = ImagePicker();
final XFile? picked = await picker.pickImage(
  source: ImageSource.gallery,
  maxWidth: 2048,
  maxHeight: 2048,
);
```

### Step 2: Validate Magic Bytes

```dart
class ImageUtils {
  static Future<bool> isValidImage(XFile file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 4) return false;

    return matchesJpeg(bytes) || matchesPng(bytes) ||
           matchesGif(bytes) || matchesWebP(bytes);
  }

  static bool matchesJpeg(Uint8List b) =>
      b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;

  static bool matchesPng(Uint8List b) =>
      b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;
}
```

### Step 3: Upload to Supabase

```dart
final bytes = await file.readAsBytes();

// Validate
if (!await ImageUtils.isValidImage(file)) throw StorageException('Invalid image');
if (bytes.length > AppConfig.maxImageBytes) throw StorageException('Image too large');

// Detect MIME from bytes
final mime = lookupMimeType(file.name, headerBytes: bytes) ?? 'image/jpeg';

// Generate unique filename
final fileName = '${folder}/${uuid.v4()}$ext';

// Upload — platform-specific
if (kIsWeb) {
  await storage.from(bucket).uploadBinary(fileName, bytes,
      fileOptions: FileOptions(contentType: mime));
} else {
  await storage.from(bucket).upload(fileName, io.File(file.path),
      fileOptions: FileOptions(contentType: mime));
}

// Get public URL
return storage.from(bucket).getPublicUrl(fileName);
```

### Step 4: Display with CachedNetworkImage

```dart
CachedNetworkImage(
  imageUrl: post.images[0],
  placeholder: (_, __) => const SizedBox(
    height: 200,
    child: Center(child: CircularProgressIndicator()),
  ),
  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 64),
  fit: BoxFit.cover,
)
```

### Step 5: Delete Images

```dart
// Extract object key from public URL
// "https://.../storage/v1/object/public/blog-media/posts/abc.jpg"
// → "posts/abc.jpg"
final key = UrlUtils.extractStorageKey(publicUrl, bucket: bucket);
await storage.from(bucket).remove([key]);
```

### ImagePickerWidget (Reusable)

```dart
class ImagePickerWidget extends StatelessWidget {
  final List<String> existingUrls;         // already uploaded
  final List<File> newFiles;               // not yet uploaded
  final Function() onAdd;
  final Function(int) onRemoveExisting;
  final Function(int) onRemoveNew;

  // Displays existing images + new files in a horizontal scroll
  // Each has an X button to remove
  // Plus an "Add" button
}
```

---

## 10. Adding a New Feature — Post Likes

End-to-end walkthrough for adding a like feature to the existing app.

### Step 1: Create Supabase Table

```sql
CREATE TABLE post_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(post_id, user_id)   -- one like per user per post
);
```

### Step 2: Create Repository

```
lib/repositories/like_repository.dart
```

```dart
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import '../core/exceptions.dart';
import '../core/supabase_client.dart';

class LikeRepository {
  Future<Set<String>> getLikes(String postId) async {
    final res = await SupabaseService.client
        .from('post_likes')
        .select('user_id')
        .eq('post_id', postId);
    return (res as List).map((e) => e['user_id'] as String).toSet();
  }

  Future<void> like(String postId, String userId) async {
    try {
      await SupabaseService.client
          .from('post_likes')
          .insert({'post_id': postId, 'user_id': userId});
    } on PostgrestException catch (e) {
      if (e.code == '23505') return; // unique violation — already liked
      rethrow;
    }
  }

  Future<void> unlike(String postId, String userId) async {
    await SupabaseService.client
        .from('post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }
}
```

### Step 3: Create Provider

```
lib/providers/like_provider.dart
```

(See full implementation in [Section 7](#7-how-to-create-a-new-provider))

### Step 4: Register in MultiProvider

```dart
ChangeNotifierProvider(create: (_) => LikeProvider()),
```

### Step 5: Add Like Button to PostCard

```dart
final likes = context.watch<LikeProvider>();
final userId = SupabaseService.currentUserId;

Row(
  children: [
    IconButton(
      icon: Icon(
        likes.isLiked(post.id, userId)
            ? Icons.favorite
            : Icons.favorite_border,
        color: likes.isLiked(post.id, userId) ? Colors.red : null,
      ),
      onPressed: () => likes.toggleLike(post.id, userId),
    ),
    Text('${likes.count(post.id)}'),
  ],
)
```

### Step 6: Load Likes

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    for (final post in context.read<PostProvider>().posts) {
      context.read<LikeProvider>().loadLikes(post.id);
    }
  });
}
```

### Architecture for This Feature

```
post_card.dart
  ← context.watch<LikeProvider>()
  ← IconButton → toggleLike(postId, userId)
       ↓
like_provider.dart (ChangeNotifier)
  ← optimistic update + notifyListeners()
  ← calls LikeRepository
       ↓
like_repository.dart
  ← Supabase CRUD on post_likes table
       ↓
Supabase: post_likes table
  ← insert / delete / select
```

---

## 11. Architecture Overview

### Layer Separation

```
┌──────────────────────────────────┐
│         UI (Pages + Widgets)     │  ← context.watch/read, rebuild
├──────────────────────────────────┤
│       Providers (State)          │  ← ChangeNotifier, notifyListeners
├──────────────────────────────────┤
│  Services (Business Logic)       │  ← AuthService, StorageService
├──────────────────────────────────┤
│  Repositories (Data Access)      │  ← CRUD vs Supabase
├──────────────────────────────────┤
│    Models (Data Classes)         │  ← Post, Comment, UserProfile
├──────────────────────────────────┤
│     Supabase (Backend)           │  ← Auth, DB, Storage
└──────────────────────────────────┘
```

### Dependency Flow

```
Screen → Provider → Service → Repository → Supabase SDK
                                          ← JSON response
                               ← Model (fromJson)
                    ← data/model
          ← notifyListeners()
← rebuild
```

### Key Patterns Used

| Pattern | Where Used |
|---|---|
| **Singleton** | `SupabaseService` (static getters) |
| **Repository pattern** | `PostRepository`, `CommentRepository`, `ProfileRepository` |
| **Abstract base class** | `GenericRepository<T>` |
| **Factory constructor** | `Post.fromJson()`, `Comment.fromJson()` |
| **Immutable models** | `copyWith()` pattern |
| **Enums** | `AuthStatus { unknown, authenticated, unauthenticated }` |
| **Stream subscription** | `authStateChanges.listen()` in `AuthProvider` |
| **Error mapping** | All raw exceptions → `AppException` subclass |
| **Input sanitization** | `Sanitizers.cleanText()`, `Sanitizers.cleanName()` |
| **Input validation** | `Validators.email()`, `Validators.password()` |
| **Optimistic update** | Like toggle — update UI first, revert on failure |
| **Pagination** | `Paginator<T>` with Supabase `.range()` |

### End-to-End Example: User Creates a Post

1. User fills form in `PostCreateScreen`, presses "Publish"
2. Screen calls `context.read<PostProvider>().createPost(title, content, files)`
3. `PostProvider` sanitizes input → uploads images via `StorageService` → calls `PostRepository.create()`
4. `PostRepository` inserts into Supabase `posts` table → returns created `Post` with joined profile
5. `PostProvider` adds to `_paginator` via `prepend()` → calls `notifyListeners()`
6. `HomeScreen` (using `context.watch<PostProvider>()`) rebuilds → new post appears
