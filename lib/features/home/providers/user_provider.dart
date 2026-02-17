import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

final userProvider = FutureProvider<UserModel>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return await repository.getMe();
});
