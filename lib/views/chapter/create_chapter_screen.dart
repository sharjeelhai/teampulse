import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teampulse/viewmodels/auth_viewmodel.dart';
import 'package:teampulse/viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/chapter_viewmodel.dart';
import '../../repositories/user_repository.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../utils/validators.dart';

class CreateChapterScreen extends StatefulWidget {
  final String? leadId;

  const CreateChapterScreen({super.key, this.leadId});

  @override
  State<CreateChapterScreen> createState() => _CreateChapterScreenState();
}

class _CreateChapterScreenState extends State<CreateChapterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final TextEditingController _leadIdController;

  @override
  void initState() {
    super.initState();
    _leadIdController = TextEditingController(text: widget.leadId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _leadIdController.dispose();
    super.dispose();
  }

  Future<void> _createChapter() async {
    if (!_formKey.currentState!.validate()) return;
    final vm = Provider.of<ChapterViewModel>(context, listen: false);
    final userRepository = UserRepository();
    final dashboardVM = Provider.of<DashboardViewModel>(context, listen: false);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    String leadIdToUse;

    if (widget.leadId != null) {
      // Auto-filled with user ID, use it directly (for backwards compatibility)
      leadIdToUse = widget.leadId!;
    } else {
      // User entered an email, look up the user ID
      final email = _leadIdController.text.trim();
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter chapter lead email')),
        );
        return;
      }

      final user = await userRepository.getUserByEmail(email);
      if (user == null) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user found with this email')),
        );
        return;
      }

      leadIdToUse = user.id;
    }

    final id = await vm.createChapter(
      name: _nameController.text.trim(),
      leadId: leadIdToUse,
    );

    if (id != null) {
      if (!mounted) return;

      // Refresh dashboard stats to reflect the new chapter
      if (authVM.currentUser != null) {
        await dashboardVM.refreshStats(authVM.currentUser!);
      }

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(true); // Return true to indicate success
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chapter created successfully')),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Failed to create chapter')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Chapter')),
      body: Consumer<ChapterViewModel>(
        builder: (context, vm, child) {
          return LoadingOverlay(
            isLoading: vm.isLoading,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppInput(
                      label: 'Chapter Name',
                      controller: _nameController,
                      validator: Validators.validateName,
                      readOnly: false,
                    ),
                    const SizedBox(height: 16),
                    AppInput(
                      label: widget.leadId != null
                          ? 'Lead Email (auto-filled)'
                          : 'Lead Email (optional)',
                      controller: _leadIdController,
                      hint: 'chapterlead@example.com',
                      keyboardType: TextInputType.emailAddress,
                      readOnly: widget.leadId != null,
                      validator: widget.leadId != null
                          ? null
                          : Validators.validateEmail,
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      text: 'Create Chapter',
                      onPressed: _createChapter,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
