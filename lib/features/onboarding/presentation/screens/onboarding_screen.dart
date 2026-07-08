import 'package:flutter/material.dart';
import 'package:inkognito/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../editor/domain/entities/inkling_species.dart';
import '../../../../shared/widgets/app_widgets.dart';
import '../../../../shared/widgets/inkling_avatar.dart';

/// Combined onboarding carousel + authentication entry point.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({this.startOnSignIn = false, super.key});

  final bool startOnSignIn;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  bool _showAuth = false;

  List<_Slide> _slidesFor(AppLocalizations l) => [
        _Slide(
          species: InklingSpecies.classic,
          title: l.onboardTitle1,
          body: l.onboardBody1,
        ),
        _Slide(
          species: InklingSpecies.ghost,
          title: l.onboardTitle2,
          body: l.onboardBody2,
        ),
        _Slide(
          species: InklingSpecies.dragon,
          title: l.onboardTitle3,
          body: l.onboardBody3,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _showAuth = widget.startOnSignIn;
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final slides = _slidesFor(l);
    return Scaffold(
      body: SafeArea(
        child: _showAuth
            ? _AuthPanel(onBack: () => setState(() => _showAuth = false))
            : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _page,
                      itemCount: slides.length,
                      itemBuilder: (_, i) => slides[i],
                    ),
                  ),
                  _Dots(controller: _page, count: slides.length),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: GradientButton(
                      label: l.getStarted,
                      icon: Icons.arrow_forward,
                      onPressed: () => setState(() => _showAuth = true),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.species,
    required this.title,
    required this.body,
  });

  final InklingSpecies species;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppColors.ink.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: InklingAvatar(species: species, size: 140),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.controller, required this.count});
  final PageController controller;
  final int count;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final page = controller.hasClients
            ? (controller.page ?? controller.initialPage.toDouble())
            : 0.0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (i) {
            final selected = (page.round() == i);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: selected ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected ? AppColors.ink : AppColors.textMuted,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Email/password + guest authentication form.
class _AuthPanel extends ConsumerStatefulWidget {
  const _AuthPanel({required this.onBack});
  final VoidCallback onBack;

  @override
  ConsumerState<_AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends ConsumerState<_AuthPanel> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    if (_register) {
      await controller.register(
        _email.text,
        _password.text,
        _name.text.trim(),
      );
    } else {
      await controller.signIn(_email.text, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final state = ref.watch(authControllerProvider);
    final loading = state.isLoading;

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${(next.error as Object)}')),
        );
      }
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            Text(
              _register ? l.createAccount : l.welcomeBack,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            if (_register)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: l.displayName,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? l.enterName
                      : null,
                ),
              ),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: l.email,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? l.enterValidEmail : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                hintText: l.password,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? l.minChars : null,
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: _register ? l.signUp : l.signIn,
              loading: loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _register = !_register),
              child: Text(
                _register ? l.haveAccountSignIn : l.newHereCreate,
              ),
            ),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(l.orLabel),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: loading
                  ? null
                  : () => ref
                      .read(authControllerProvider.notifier)
                      .signInAnonymously(),
              icon: const Icon(Icons.play_arrow),
              label: Text(l.continueAsGuest),
            ),
          ],
        ),
      ),
    );
  }
}
