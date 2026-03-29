import 'package:dia_plus/core/navigation/app_router.dart';
import 'package:dia_plus/models/invite_access_request.dart';
import 'package:dia_plus/services/auth_service.dart';
import 'package:dia_plus/services/invite_access_request_service.dart';
import 'package:flutter/material.dart';

/// After email verification: Doctor/Admin applies for access; admin approves, then they set a second password.
class ProfessionalAccessRequestPage extends StatefulWidget {
  const ProfessionalAccessRequestPage({super.key});

  @override
  State<ProfessionalAccessRequestPage> createState() =>
      _ProfessionalAccessRequestPageState();
}

class _ProfessionalAccessRequestPageState
    extends State<ProfessionalAccessRequestPage> {
  final _authService = AuthService();
  final _accessService = InviteAccessRequestService();
  final _messageController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;
  bool _routedToComplete = false;
  bool _bootstrapping = true;
  bool _emailVerified = false;
  bool _resendBusy = false;
  bool _recheckBusy = false;
  int _accessStreamTick = 0;

  @override
  void initState() {
    super.initState();
    _bootstrapEmail();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapEmail() async {
    try {
      await _authService.currentUser?.reload();
    } catch (_) {}
    if (!mounted) return;
    final v = _authService.currentUser?.emailVerified ?? false;
    setState(() {
      _emailVerified = v;
      _bootstrapping = false;
    });
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _resendBusy = true);
    try {
      await _authService.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent. Check your inbox and spam folder.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not resend: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _resendBusy = false);
    }
  }

  Future<void> _recheckEmailVerified() async {
    setState(() => _recheckBusy = true);
    try {
      await _authService.currentUser?.reload();
    } catch (_) {}
    if (!mounted) return;
    final v = _authService.currentUser?.emailVerified ?? false;
    setState(() {
      _emailVerified = v;
      _recheckBusy = false;
    });
    if (v && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified — loading your request…'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not verified yet. Open the link in the email, then tap again.'),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (!mounted) return;
    AppRouter.goToStart(context);
  }

  Future<void> _submit() async {
    final user = _authService.currentUser;
    final me = await _authService.getAppUser();
    if (user == null || me == null) return;
    if (!me.needsProfessionalInviteCompletion) {
      if (!mounted) return;
      AppRouter.goToHome(context);
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await _accessService.submitRequest(
        uid: user.uid,
        email: me.email,
        displayName: me.displayName,
        role: me.role,
        message: _messageController.text,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request submitted. An administrator will review it.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _submitting = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) AppRouter.goToStart(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_bootstrapping) {
      return Scaffold(
        appBar: AppBar(title: const Text('Professional access')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_emailVerified) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Verify your email'),
          actions: [
            TextButton(onPressed: _signOut, child: const Text('Sign Out')),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.mark_email_unread_outlined,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Confirm your Gmail / email first',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a link to:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Text(
                  'After you tap the link in that email, use “I’ve verified” below. '
                  'You can resend the message if it did not arrive.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _recheckBusy ? null : _recheckEmailVerified,
                  child: _recheckBusy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('I’ve verified — continue'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _resendBusy ? null : _resendVerificationEmail,
                  child: _resendBusy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Resend verification email'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => AppRouter.goToEmailVerification(context),
                  child: const Text('Open full verification screen'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Professional access'),
        actions: [
          TextButton(onPressed: _signOut, child: const Text('Sign Out')),
        ],
      ),
      body: StreamBuilder<InviteAccessRequest?>(
        key: ValueKey(_accessStreamTick),
        stream: _accessService.streamLatestForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final msg = snapshot.error.toString();
            final isPerm = msg.contains('permission-denied');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isPerm
                          ? 'Firestore blocked this read. Deploy the latest '
                              'security rules and indexes, then try again.'
                          : 'Could not load request status:\n$msg',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () =>
                          setState(() => _accessStreamTick++),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final latest = snapshot.data;

          if (latest != null && latest.isApproved) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || _routedToComplete) return;
              _routedToComplete = true;
              AppRouter.goToCompleteProfessionalRegistration(context);
            });
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Approved — continue to finish setup…'),
                ],
              ),
            );
          }

          if (latest != null && latest.isPending) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Request pending',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'An administrator will review your request. Keep this screen open or return later — '
                  'it will move forward automatically when you are approved.',
                  style: TextStyle(color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Submitted: ${latest.email}',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }

          if (latest != null && latest.isRejected) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(
                  Icons.cancel_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Request not approved',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (latest.rejectionReason != null &&
                    latest.rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    latest.rejectionReason!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'You can submit a new request below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 24),
                _buildApplyForm(context),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Icon(
                Icons.outgoing_mail,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Request professional access',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Submit a request so an administrator can approve your Doctor or Admin account. '
                'After approval, you will set a second password to finish signing in securely.',
                style: TextStyle(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildApplyForm(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildApplyForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _messageController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Message to admin (optional)',
            hintText: 'e.g. department, clinic name',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit request'),
        ),
      ],
    );
  }
}
