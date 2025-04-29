import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:with_run_app/ui/pages/chatting_page/participant_provider.dart';

class ParticipantsListDialog extends ConsumerWidget {
  final String chatRoomId;

  const ParticipantsListDialog({
    Key? key,
    required this.chatRoomId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(participantProvider(chatRoomId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '참여자 목록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            participantsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('참가자 정보를 불러오는데 실패했습니다: $e'),
                ),
              ),
              data: (participants) {
                if (participants.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('참가자가 없습니다')),
                  );
                }
                
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final userId = participants.keys.elementAt(index);
                      final participant = participants[userId]!;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(
                            participant.profileImageUrl.isNotEmpty
                                ? participant.profileImageUrl
                                : 'https://via.placeholder.com/150',
                          ),
                        ),
                        title: Text(
                          participant.nickname,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}