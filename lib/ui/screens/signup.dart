import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webrtc_test/blocs/providers/signup/signup_field.dart';
import 'package:webrtc_test/helpers/providers/page_state.dart';
import 'package:webrtc_test/helpers/ui/focus.dart';
import 'package:webrtc_test/themes/dimensions.dart';

class SignupScreen extends ConsumerWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  Widget build(context, ref) {
    final pageNotifier = ref.read(signupFieldProvider.notifier);
    final state = ref.watch(signupFieldProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign up'),
      ),
      body: _buildBody(context, ref, pageNotifier, state),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, SignupField notifier,
      PageState state) {
    final Widget page = SingleChildScrollView(
      padding: const EdgeInsets.all(kSpaceLarge),
      child: Column(
        children: [
          const SizedBox.square(
            dimension: kSpaceXLarge,
          ),
          TextFormField(
            controller: notifier.nameField,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox.square(
            dimension: kSpaceXLarge,
          ),
          TextFormField(
            controller: notifier.emailField,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox.square(
            dimension: kSpaceXLarge,
          ),
          TextFormField(
            controller: notifier.passwordField,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox.square(
            dimension: kSpaceXLarge,
          ),
          ElevatedButton(
            child: const Text('Sign up'),
            onPressed: context.loseFocusWrapper(notifier.signup),
          ),
        ],
      ),
    );

    return Stack(
      children: [
        page,
        if (state is LoadingPageState)
          Container(
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          )
      ],
    );
  }
}
