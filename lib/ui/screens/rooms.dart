import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webrtc_test/blocs/models/available_room.dart';
import 'package:webrtc_test/helpers/providers/page_state.dart';
import 'package:webrtc_test/helpers/utils/extensions.dart';
import 'package:webrtc_test/providers/rooms/rooms_notifier.dart';
import 'package:webrtc_test/routes/app_router.gr.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({Key? key}) : super(key: key);

  @override
  Widget build(context, ref) {
    final state = ref.watch(roomsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: _buildBody(context, ref, state),
      floatingActionButton: ifTrue(state is LoadedPageState, () {
        return FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              const name = "Mostafa";
              const newRoom = "New Room";
              AutoRouter.of(context).push(RoomRoute(
                name: name,
                roomName: newRoom,
              ));
            });
      }),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, PageState state) {
    Future<void> refresh() async {
      final notifier = ref.read(roomsNotifierProvider.notifier);
      return notifier.loadRooms();
    }

    if (state is LoadedPageState<List<AvailableRoom>>) {
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView.builder(
            itemCount: state.data.length,
            itemBuilder: (context, index) {
              final room = state.data[index];
              return ListTile(
                title: Text(room.name),
                onTap: () async {
                  const name = "Mostafa";
                  AutoRouter.of(context).push(RoomRoute(
                    name: name,
                    availableRoom: room,
                  ));
                },
              );
            }),
      );
    } else if (state is LoadingPageState) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Center(
        child: ElevatedButton(
          child: const Text('Load Rooms'),
          onPressed: refresh,
        ),
      );
    }
  }
}
