import 'package:flutter/foundation.dart';

import 'sign_video_entry.dart';

@immutable
class SignLanguageCatalog {
  final List<SignVideoEntry> entries;

  const SignLanguageCatalog({required this.entries});

  SignVideoEntry? findExact(String query) {
    final clean = query.trim().toLowerCase();
    for (final entry in entries) {
      if (entry.label.toLowerCase() == clean) return entry;
    }
    return null;
  }

  SignVideoEntry? findByAlias(String query) {
    final clean = query.trim().toLowerCase();
    for (final entry in entries) {
      for (final alias in entry.aliases) {
        if (alias.toLowerCase() == clean) return entry;
      }
    }
    return null;
  }

  SignVideoEntry? findBestMatch(String query) {
    return findExact(query) ?? findByAlias(query);
  }

  List<SignVideoEntry> getByCategory(String category) {
    final clean = category.trim().toLowerCase();
    return entries.where((e) => e.category.toLowerCase() == clean).toList();
  }

  factory SignLanguageCatalog.defaultCatalog() {
    const baseUrl = 'https://hajicare-sign.web.app/videos/bisindo';

    const rawList = <SignVideoEntry>[
      // Salam & Sapaan
      SignVideoEntry(
        id: 'halo',
        label: 'Halo',
        aliases: ['hai', 'hei', 'hallo'],
        category: 'salam',
        assetPath: 'assets/videos/bisindo/halo_v1.mp4',
        remoteUrl: '$baseUrl/halo_v1.mp4',
      ),
      SignVideoEntry(
        id: 'terima_kasih',
        label: 'Terima Kasih',
        aliases: ['makasih', 'nuhun', 'thank you', 'trims', 'matur nuwun'],
        category: 'salam',
        assetPath: 'assets/videos/bisindo/terima_kasih_v1.mp4',
        remoteUrl: '$baseUrl/terima_kasih_v1.mp4',
      ),
      SignVideoEntry(
        id: 'sama_sama',
        label: 'Sama-Sama',
        aliases: ['terima kasih kembali', 'kembali', 'sama sama'],
        category: 'salam',
        assetPath: 'assets/videos/bisindo/sama_sama_v1.mp4',
        remoteUrl: '$baseUrl/sama_sama_v1.mp4',
      ),
      SignVideoEntry(
        id: 'selamat_pagi',
        label: 'Selamat Pagi',
        aliases: ['pagi'],
        category: 'salam',
        assetPath: 'assets/videos/bisindo/selamat_pagi_v1.mp4',
        remoteUrl: '$baseUrl/selamat_pagi_v1.mp4',
      ),
      SignVideoEntry(
        id: 'sampai_jumpa',
        label: 'Sampai Jumpa',
        aliases: ['dadah', 'bye', 'selamat tinggal'],
        category: 'salam',
        assetPath: 'assets/videos/bisindo/sampai_jumpa_v1.mp4',
        remoteUrl: '$baseUrl/sampai_jumpa_v1.mp4',
      ),

      // Layanan Publik & Administrasi
      SignVideoEntry(
        id: 'ktp',
        label: 'KTP',
        aliases: [
          'kartu tanda penduduk',
          'identitas',
          'e-ktp',
          'kartu identitas',
        ],
        category: 'layanan_publik',
        assetPath: 'assets/videos/bisindo/ktp_v1.mp4',
        remoteUrl: '$baseUrl/ktp_v1.mp4',
      ),
      SignVideoEntry(
        id: 'kartu_keluarga',
        label: 'Kartu Keluarga',
        aliases: ['kk', 'surat keluarga'],
        category: 'layanan_publik',
        assetPath: 'assets/videos/bisindo/kartu_keluarga_v1.mp4',
        remoteUrl: '$baseUrl/kartu_keluarga_v1.mp4',
      ),
      SignVideoEntry(
        id: 'tiket',
        label: 'Tiket',
        aliases: ['karcis', 'tiket masuk', 'karcis parkir', 'tiket krl'],
        category: 'layanan_publik',
        assetPath: 'assets/videos/bisindo/tiket_v1.mp4',
        remoteUrl: '$baseUrl/tiket_v1.mp4',
      ),
      SignVideoEntry(
        id: 'bantu',
        label: 'Bantu',
        aliases: ['tolong', 'bantuan', 'mohon bantuan', 'tolong bantu'],
        category: 'layanan_publik',
        assetPath: 'assets/videos/bisindo/bantu_v1.mp4',
        remoteUrl: '$baseUrl/bantu_v1.mp4',
      ),
      SignVideoEntry(
        id: 'silakan',
        label: 'Silakan',
        aliases: ['silahkan', 'mari', 'mangga'],
        category: 'layanan_publik',
        assetPath: 'assets/videos/bisindo/silakan_v1.mp4',
        remoteUrl: '$baseUrl/silakan_v1.mp4',
      ),
      SignVideoEntry(
        id: 'tunjukkan',
        label: 'Tunjukkan',
        aliases: ['perlihatkan', 'kasih lihat', 'tunjukkan berkas'],
        category: 'layanan_publik',
        assetPath: 'assets/videos/bisindo/tunjukkan_v1.mp4',
        remoteUrl: '$baseUrl/tunjukkan_v1.mp4',
      ),
      SignVideoEntry(
        id: 'asli',
        label: 'Asli',
        aliases: ['original', 'berkas asli'],
        category: 'layanan_publik',
        assetPath: 'assets/videos/bisindo/asli_v1.mp4',
        remoteUrl: '$baseUrl/asli_v1.mp4',
      ),

      // Belanja & Transaksi Harian
      SignVideoEntry(
        id: 'beli',
        label: 'Beli',
        aliases: ['membeli', 'pembelian', 'order'],
        category: 'belanja',
        assetPath: 'assets/videos/bisindo/beli_v1.mp4',
        remoteUrl: '$baseUrl/beli_v1.mp4',
      ),
      SignVideoEntry(
        id: 'bayar',
        label: 'Bayar',
        aliases: ['membayar', 'pembayaran', 'lunas'],
        category: 'belanja',
        assetPath: 'assets/videos/bisindo/bayar_v1.mp4',
        remoteUrl: '$baseUrl/bayar_v1.mp4',
      ),
      SignVideoEntry(
        id: 'qris',
        label: 'QRIS',
        aliases: ['scan barcode', 'barcode', 'qris bca', 'scan qr'],
        category: 'belanja',
        assetPath: 'assets/videos/bisindo/qris_v1.mp4',
        remoteUrl: '$baseUrl/qris_v1.mp4',
      ),
      SignVideoEntry(
        id: 'harga',
        label: 'Harga',
        aliases: ['berapa harga', 'tarif', 'biaya'],
        category: 'belanja',
        assetPath: 'assets/videos/bisindo/harga_v1.mp4',
        remoteUrl: '$baseUrl/harga_v1.mp4',
      ),
      SignVideoEntry(
        id: 'berapa',
        label: 'Berapa',
        aliases: ['seberapa', 'jumlahnya'],
        category: 'belanja',
        assetPath: 'assets/videos/bisindo/berapa_v1.mp4',
        remoteUrl: '$baseUrl/berapa_v1.mp4',
      ),
      SignVideoEntry(
        id: 'total',
        label: 'Total',
        aliases: ['semuanya', 'totalnya', 'jumlah'],
        category: 'belanja',
        assetPath: 'assets/videos/bisindo/total_v1.mp4',
        remoteUrl: '$baseUrl/total_v1.mp4',
      ),

      // Kesehatan & Darurat
      SignVideoEntry(
        id: 'sakit',
        label: 'Sakit',
        aliases: ['nyeri', 'keluhan', 'pedih'],
        category: 'kesehatan',
        assetPath: 'assets/videos/bisindo/sakit_v1.mp4',
        remoteUrl: '$baseUrl/sakit_v1.mp4',
      ),
      SignVideoEntry(
        id: 'dokter',
        label: 'Dokter',
        aliases: ['tenaga medis', 'medis', 'mantri'],
        category: 'kesehatan',
        assetPath: 'assets/videos/bisindo/dokter_v1.mp4',
        remoteUrl: '$baseUrl/dokter_v1.mp4',
      ),
      SignVideoEntry(
        id: 'rumah_sakit',
        label: 'Rumah Sakit',
        aliases: ['rs', 'puskesmas', 'klinik'],
        category: 'kesehatan',
        assetPath: 'assets/videos/bisindo/rumah_sakit_v1.mp4',
        remoteUrl: '$baseUrl/rumah_sakit_v1.mp4',
      ),
      SignVideoEntry(
        id: 'obat',
        label: 'Obat',
        aliases: ['resep', 'farmasi'],
        category: 'kesehatan',
        assetPath: 'assets/videos/bisindo/obat_v1.mp4',
        remoteUrl: '$baseUrl/obat_v1.mp4',
      ),

      // Percakapan Harian / Pronoun
      SignVideoEntry(
        id: 'saya',
        label: 'Saya',
        aliases: ['aku', 'gue', 'kulo'],
        category: 'harian',
        assetPath: 'assets/videos/bisindo/saya_v1.mp4',
        remoteUrl: '$baseUrl/saya_v1.mp4',
      ),
      SignVideoEntry(
        id: 'mau',
        label: 'Mau',
        aliases: ['ingin', 'hendak', 'pengen'],
        category: 'harian',
        assetPath: 'assets/videos/bisindo/mau_v1.mp4',
        remoteUrl: '$baseUrl/mau_v1.mp4',
      ),
      SignVideoEntry(
        id: 'anda',
        label: 'Anda',
        aliases: ['kamu', 'saudara', 'bapak', 'ibu'],
        category: 'harian',
        assetPath: 'assets/videos/bisindo/anda_v1.mp4',
        remoteUrl: '$baseUrl/anda_v1.mp4',
      ),
      SignVideoEntry(
        id: 'nama',
        label: 'Nama',
        aliases: ['nama saya', 'namaku'],
        category: 'harian',
        assetPath: 'assets/videos/bisindo/nama_v1.mp4',
        remoteUrl: '$baseUrl/nama_v1.mp4',
      ),
      SignVideoEntry(
        id: 'ya',
        label: 'Ya',
        aliases: ['iya', 'benar', 'betul', 'oke'],
        category: 'harian',
        assetPath: 'assets/videos/bisindo/ya_v1.mp4',
        remoteUrl: '$baseUrl/ya_v1.mp4',
      ),
      SignVideoEntry(
        id: 'tidak',
        label: 'Tidak',
        aliases: ['bukan', 'enggak', 'nggak'],
        category: 'harian',
        assetPath: 'assets/videos/bisindo/tidak_v1.mp4',
        remoteUrl: '$baseUrl/tidak_v1.mp4',
      ),
      SignVideoEntry(
        id: 'baik',
        label: 'Baik',
        aliases: ['bagus', 'siap', 'alhamdulillah'],
        category: 'harian',
        assetPath: 'assets/videos/bisindo/baik_v1.mp4',
        remoteUrl: '$baseUrl/baik_v1.mp4',
      ),
    ];

    return const SignLanguageCatalog(entries: rawList);
  }
}
