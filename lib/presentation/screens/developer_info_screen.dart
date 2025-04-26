import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/extensions/theme_extensions.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '無法開啟連結: ${url.toString()}',
              style: TextStyle(fontSize: context.sp(14)),
            ),
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text, {
    Uri? url,
  }) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: context.r(20), color: context.colorScheme.secondary),
        Gap(context.w(10)),
        Text(
          text,
          style: context.textTheme.bodyLarge?.copyWith(
            color: url != null ? context.colorScheme.primary : null,
            decoration: url != null ? TextDecoration.underline : null,
            decorationColor: url != null ? context.colorScheme.primary : null,
            fontSize: context.sp(16),
          ),
        ),
      ],
    );

    if (url != null) {
      return InkWell(
        onTap: () => _launchUri(context, url),
        borderRadius: BorderRadius.circular(context.r(8)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: context.h(8),
            horizontal: context.w(4),
          ),
          child: content,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: context.h(8),
        horizontal: context.w(4),
      ),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Uri emailUri = Uri.parse('mailto:$_email');
    final Uri githubUri = Uri.parse(_githubUrl);

    return Scaffold(
      appBar: AppBar(
        title: const Text('開發者資訊'),
        leading: const AutoLeadingButton(),
        centerTitle: true,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(context.i(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                    radius: context.r(80),
                    backgroundColor:
                        context.colorScheme.surfaceContainerHighest,
                    backgroundImage: const AssetImage('assets/images/dash.png'),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(
                    delay: 200.ms,
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  ),

              Gap(context.h(32)),

              // Name
              Text(
                    'Aykahshi (aka Zack)',
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: context.sp(24),
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 500.ms)
                  .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),

              Gap(context.h(24)),

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

              Gap(context.h(12)),

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
