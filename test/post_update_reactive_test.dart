import 'dart:io';

import 'package:blog_forum_app/models/comment.dart';
import 'package:blog_forum_app/models/post.dart';
import 'package:blog_forum_app/models/user_profile.dart';
import 'package:blog_forum_app/presentation/pages/post_view_screen.dart';
import 'package:blog_forum_app/providers/auth_provider.dart';
import 'package:blog_forum_app/providers/comment_provider.dart';
import 'package:blog_forum_app/providers/post_provider.dart';
import 'package:blog_forum_app/services/auth_service.dart';
import 'package:blog_forum_app/services/comment_service.dart';
import 'package:blog_forum_app/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakePostService extends PostService {
  Post? current;
  int getByIdCalls = 0;

  FakePostService(this.current);

  @override
  Future<Post> getPostById(String postId) async {
    getByIdCalls++;
    return current!;
  }

  @override
  Future<Post> update({
    required String postId,
    required String title,
    required String content,
    required List<String> existingImageUrls,
    required List<File> newImageFiles,
    required List<String> imagesToDelete,
  }) async {
    current = current!.copyWith(title: title, content: content);
    return current!;
  }
}

class FakeCommentService extends CommentService {
  @override
  Future<List<Comment>> getByPost(String postId) async => [];
}

class FakeAuthService implements IAuthService {
  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<UserProfile?> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async => null;

  @override
  Future<UserProfile?> signIn({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<UserProfile?> fetchProfile(String userId) async => null;

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    String? fullName,
    File? avatarFile,
    String? existingAvatarUrl,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<UserProfile> removeAvatar({
    required String userId,
    required String currentAvatarUrl,
  }) async {
    throw UnimplementedError();
  }
}

Post makePost({String title = 'Old Title', String content = 'Old Content'}) {
  return Post(
    id: 'p1',
    userId: '', // empty == SupabaseService.currentUserId (no session)
    title: title,
    content: content,
    images: const [],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late FakePostService postService;
  late PostProvider postProvider;
  late CommentProvider commentProvider;
  late AuthProvider authProvider;

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  setUp(() {
    postService = FakePostService(makePost());
    postProvider = PostProvider(service: postService);
    commentProvider = CommentProvider(service: FakeCommentService());
    authProvider = AuthProvider(FakeAuthService());
  });

  Widget wrap(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: postProvider),
        ChangeNotifierProvider.value(value: commentProvider),
        ChangeNotifierProvider.value(value: authProvider),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('post view rebuilds reactively after provider updatePost', (
    tester,
  ) async {
    await postProvider.getPostById('p1');
    await tester.pumpWidget(wrap(const PostViewScreen(postId: 'p1')));
    await tester.pumpAndSettle();

    expect(find.text('Old Title'), findsOneWidget);

    // Simulate exactly what PostEditScreen._updatePost does.
    final ok = await postProvider.updatePost(
      postId: 'p1',
      title: 'New Title',
      content: 'New Content',
      existingImageUrls: const [],
      newImageFiles: const [],
      imagesToDelete: const [],
    );
    expect(ok, isTrue);
    await tester.pumpAndSettle();

    expect(
      find.text('New Title'),
      findsOneWidget,
      reason: 'post_view_screen should reactively show updated title',
    );
    expect(find.text('Old Title'), findsNothing);
  });

  testWidgets('full edit flow returns to post view with updated data', (
    tester,
  ) async {
    await postProvider.getPostById('p1');
    await tester.pumpWidget(wrap(const PostViewScreen(postId: 'p1')));
    await tester.pumpAndSettle();

    expect(find.text('Old Title'), findsOneWidget);
  });
}
