import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../shared/app_card.dart';
import '../../../shared/i18n.dart';

// GET /api/reports/export requires the Bearer token (same as every other route) — a bare
// external-browser link (the original plan's assumption) can't carry that, since the token
// lives in secure storage, not a cookie the browser would send. Downloading via dio (which
// already attaches it) and handing the bytes to the OS share sheet avoids that mismatch
// entirely, and needs no on-device file-write step either.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _downloading = false;
  String? _error;

  Future<void> _export() async {
    setState(() {
      _downloading = true;
      _error = null;
    });
    try {
      final res = await dio.get<List<int>>(
        '/reports/export',
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = Uint8List.fromList(res.data!);
      final today = DateTime.now().toIso8601String().split('T').first;
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv', name: 'screening-history-$today.csv')],
      ));
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t('reports'))),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.t('exportReportsDesc')),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: _downloading ? null : _export,
                icon: _downloading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download),
                label: Text(AppStrings.t('exportToExcel')),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
