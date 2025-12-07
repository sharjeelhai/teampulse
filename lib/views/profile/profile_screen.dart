import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_overlay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthViewModel>(context, listen: false).currentUser;
    _nameController.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final vm = Provider.of<AuthViewModel>(context, listen: false);
    final ok = await vm.updateProfile(name: _nameController.text.trim());
    if (ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(vm.errorMessage ?? 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Consumer<AuthViewModel>(
        builder: (context, vm, child) {
          return LoadingOverlay(
            isLoading: vm.isLoading,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF6C63FF),
                    child: Text(
                      vm.currentUser?.avatarInitials ?? 'U',
                      style: const TextStyle(color: Colors.white, fontSize: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppInput(
                    label: 'Full Name',
                    controller: _nameController,
                    readOnly: false,
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    label: 'Email',
                    controller: TextEditingController(
                      text: vm.currentUser?.email ?? '',
                    ),
                    enabled: false,
                    readOnly: true,
                  ),
                  const SizedBox(height: 24),
                  AppButton(text: 'Save', onPressed: _save),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
