import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Model credential operator
class OperatorCredential {
  final String username;
  final String passwordHash;
  final String displayName;
  final String role;

  const OperatorCredential({
    required this.username,
    required this.passwordHash,
    required this.displayName,
    required this.role,
  });

  Map<String, dynamic> toMap() => {
        'username': username,
        'passwordHash': passwordHash,
        'displayName': displayName,
        'role': role,
      };

  factory OperatorCredential.fromMap(Map<dynamic, dynamic> map) =>
      OperatorCredential(
        username: map['username'].toString(),
        passwordHash: map['passwordHash'].toString(),
        displayName: map['displayName'].toString(),
        role: map['role'].toString(),
      );
}

/// In-memory credential store — bekerja di semua platform tanpa konfigurasi
/// tambahan. Web: tidak butuh IndexedDB. Mobile: tidak butuh Hive adapter.
class CredentialStore {
  static String _hash(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Database akun operator (in-memory, bisa diperluas ke persistent storage)
  static final Map<String, OperatorCredential> _accounts = {};

  /// Sesi aktif saat ini
  static OperatorCredential? _activeSession;

  /// Inisialisasi dan seed akun default
  static Future<void> initialize() async {
    _accounts['operator1'] = OperatorCredential(
      username: 'operator1',
      passwordHash: _hash('niceg4s'),
      displayName: 'Operator Lapangan',
      role: 'operator',
    );
    _accounts['admin'] = OperatorCredential(
      username: 'admin',
      passwordHash: _hash('admin123'),
      displayName: 'Administrator',
      role: 'admin',
    );
    debugPrint('[CredentialStore] Initialized with ${_accounts.length} accounts');
  }

  /// Login — kembalikan OperatorCredential jika valid, null jika gagal
  static Future<OperatorCredential?> login(
      String username, String password) async {
    final key = username.toLowerCase().trim();
    final cred = _accounts[key];
    if (cred == null) return null;
    if (cred.passwordHash != _hash(password)) return null;
    _activeSession = cred;
    return cred;
  }

  /// Cek sesi aktif — selalu resolve segera (tidak async blocking)
  static Future<OperatorCredential?> getActiveSession() async {
    return _activeSession;
  }

  /// Logout
  static Future<void> logout() async {
    _activeSession = null;
  }
}
