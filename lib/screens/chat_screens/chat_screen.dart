import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'chat_model.dart';
import 'chat_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;
  final String currentUserId;

  const ChatScreen({
    super.key,
    required this.chatRoom,
    required this.currentUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late ScrollController _scrollController;
  late ChatRoom _currentChatRoom;
  late bool _isNewChat;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _currentChatRoom = widget.chatRoom;
    _isNewChat = widget.chatRoom.id.isEmpty;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final chatService = Provider.of<ChatService>(context, listen: false);

    if (_isNewChat) {
      final newChatRoom = await chatService.getOrCreateChatRoom(
        employerId: widget.chatRoom.employerId,
        employerName: widget.chatRoom.employerName,
        jobSeekerId: widget.chatRoom.jobSeekerId,
        jobSeekerName: widget.chatRoom.jobSeekerName,
        employerLogoUrl: widget.chatRoom.employerLogoUrl,
        jobSeekerProfileUrl: widget.chatRoom.jobSeekerProfileUrl,
        jobId: widget.chatRoom.jobId,
        jobTitle: widget.chatRoom.jobTitle,
      );

      setState(() {
        _currentChatRoom = newChatRoom;
        _isNewChat = false;
      });
    }

    await chatService.sendMessage(
      chatRoomId: _currentChatRoom.id,
      senderId: widget.currentUserId,
      message: _messageController.text.trim(),
    );

    _messageController.clear();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmployer = widget.currentUserId == _currentChatRoom.employerId;
    final otherUserName = isEmployer
        ? _currentChatRoom.jobSeekerName
        : _currentChatRoom.employerName;
    final otherUserImage = isEmployer
        ? _currentChatRoom.jobSeekerProfileUrl
        : _currentChatRoom.employerLogoUrl;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage:
              otherUserImage != null ? NetworkImage(otherUserImage) : null,
              child: otherUserImage == null
                  ? Text(
                otherUserName[0],
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              otherUserName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isNewChat
                ? const Center(
              child: Text(
                'Start a new conversation',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : StreamBuilder<List<ChatMessage>>(
              stream: Provider.of<ChatService>(context)
                  .getMessagesStream(_currentChatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.message,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${message.sentAt.hour}:${message.sentAt.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white70
                                    : Colors.black54,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
