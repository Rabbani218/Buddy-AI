import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';

final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('Isar instance has not been initialized');
});

Future<Isar> initIsar() async {
  final directory = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [ChatMessageSchema, ChatSessionSchema],
    directory: directory.path,
  );
  return isar;
}
