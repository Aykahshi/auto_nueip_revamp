import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class DeveloperInfoScreen extends StatelessWidget {
  const DeveloperInfoScreen({super.key});

  // URLs
  static const String _email = 'pshakya87@gmail.com';
  static const String _githubUrl = 'https://github.com/aykahshi';

  Future<void> _launchUri(BuildContext context, Uri url) async {
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('無法開啟連結: ${url.toString()}')));
      }
    }
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text, {
    Uri? url,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20, color: colorScheme.secondary),
        const Gap(10),
        Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: url != null ? colorScheme.primary : null,
            decoration: url != null ? TextDecoration.underline : null,
            decorationColor: url != null ? colorScheme.primary : null,
          ),
        ),
      ],
    );

    if (url != null) {
      return InkWell(
        onTap: () => _launchUri(context, url),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: content,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final Uri emailUri = Uri.parse('mailto:$_email');
    final Uri githubUri = Uri.parse(_githubUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('開發者資訊'),
        leading: const AutoLeadingButton(),
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                    radius: 80,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: const AssetImage('assets/images/dash.png'),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    delay: 200.ms,
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),

              const Gap(32),

              // Name
              Text(
                    'Aykahshi (aka Zack)',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),

              const Gap(24),

              // Info Rows
              _buildInfoRow(
                    context,
                    Icons.email_outlined,
                    _email,
                    url: emailUri,
                  )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 500.ms)
                  .slideX(begin: -0.5, end: 0, curve: Curves.easeOut),

              const Gap(12),

              _buildInfoRow(
                    context,
                    Icons.link_outlined,
                    _githubUrl,
                    url: githubUri,
                  )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 500.ms)
                  .slideX(begin: 0.5, end: 0, curve: Curves.easeOut),

              const Spacer(), // Push content towards center if space allows
            ],
          ),
        ),
      ),
    );
  }
}
