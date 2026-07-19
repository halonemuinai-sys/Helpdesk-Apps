import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/biometric_service.dart';
import '../theme/colors.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlock());
  }

  Future<void> _tryUnlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });

    final success = await BiometricService.authenticate();

    if (!mounted) return;
    setState(() => _authenticating = false);

    if (success) {
      Provider.of<AuthProvider>(context, listen: false).unlock();
    } else {
      setState(() => _error = 'Verifikasi gagal atau dibatalkan. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final name = auth.user?['name'] ?? 'Agent';

    return Scaffold(
      backgroundColor: AppColors.green50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green500.withOpacity(0.25),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _authenticating ? Icons.fingerprint : Icons.lock_outline_rounded,
                    size: 56,
                    color: AppColors.green600,
                  ),
                ).animate(target: _authenticating ? 1 : 0).scaleXY(begin: 1, end: 1.08, duration: 500.ms),
                const SizedBox(height: 24),
                Text(
                  'Selamat kembali, $name',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.slate900),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Verifikasi identitas untuk membuka workspace',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: AppColors.slate500),
                ),
                const SizedBox(height: 28),
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _authenticating ? null : _tryUnlock,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(_authenticating ? 'Memverifikasi...' : 'Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _authenticating
                      ? null
                      : () => Provider.of<AuthProvider>(context, listen: false).logout(),
                  child: const Text(
                    'Gunakan email & password',
                    style: TextStyle(color: AppColors.slate500, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
