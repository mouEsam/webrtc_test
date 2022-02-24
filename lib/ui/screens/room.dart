import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc_test/blocs/models/available_room.dart';
import 'package:webrtc_test/providers/room/room_notifier.dart';
import 'package:webrtc_test/providers/room/room_renderer.dart';
import 'package:webrtc_test/providers/room/room_states.dart';

class RoomScreen extends ConsumerStatefulWidget {
  final String name;
  final AvailableRoom? availableRoom;
  final String? roomName;

  const RoomScreen({
    Key? key,
    required this.name,
    this.availableRoom,
    this.roomName,
  }) : super(key: key);

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  @override
  void initState() {
    super.initState();
    final state = ref.read(roomRendererProvider);
    state.openUserMedia();
    connect();
  }

  Future<void> connect() {
    final notifier = ref.read(roomNotifierProvider.notifier);
    if (widget.availableRoom != null) {
      return notifier.joinRoom(widget.availableRoom!, widget.name);
    } else {
      return notifier.createRoom(widget.roomName ?? 'New Room', widget.name);
    }
  }

  @override
  Widget build(context) {
    final state = ref.watch(roomNotifierProvider);
    ref.listen<RoomState>(roomNotifierProvider, (previous, next) {
      if (next is NoRoomState) {
        AutoRouter.of(context).pop();
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: _buildBody(context, ref, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, RoomState state) {
    final renderer = ref.watch(roomRendererProvider);
    final roomController = ref.read(roomNotifierProvider.notifier);
    if (state is ConnectedRoomState) {
      return Column(
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                child: const Text("Open camera & microphone"),
                onPressed: renderer.openUserMedia,
              ),
              const SizedBox(
                width: 8,
              ),
              ElevatedButton(
                child: const Text("Hangup"),
                onPressed: roomController.exitRoom,
              )
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          border: Border.all(width: 5, color: Colors.green),
                        ),
                        child:
                            RTCVideoView(renderer.localRenderer, mirror: true),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          border: Border.all(width: 5, color: Colors.red),
                        ),
                        child: RTCVideoView(renderer.remoteRenderer),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: state.room.attendees,
            builder: (context, _) {
              return SizedBox(
                height: 50,
                child: ListView.builder(
                  itemCount: state.room.attendees.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final attendee = state.room.attendees.items[index];
                    return Text(attendee.name);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      );
    } else if (state is LoadingRoomState) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Center(
        child: ElevatedButton(
          child: const Text('Retry'),
          onPressed: connect,
        ),
      );
    }
  }
}
