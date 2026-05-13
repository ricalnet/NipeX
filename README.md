<p align="center">
  <img src="https://heitorgouvea.me/images/projects/nipe/logo.png">
  <p align="center">An engine to make Tor Network your default gateway.</p>
  <p align="center">
    <a href="/LICENSE.md">
      <img src="https://img.shields.io/badge/license-MIT-blue.svg">
    </a>
    <a href="https://github.com/htrgouvea/nipe/releases">
      <img src="https://img.shields.io/badge/version-0.9.8-blue.svg">
    </a>
     <br/>
    <img src="https://github.com/htrgouvea/nipe/actions/workflows/linter.yml/badge.svg">
    <img src="https://github.com/htrgouvea/nipe/actions/workflows/zarn.yml/badge.svg">
    <img src="https://github.com/htrgouvea/nipe/actions/workflows/security-gate.yml/badge.svg">
    <img src="https://github.com/htrgouvea/nipe/actions/workflows/test-on-ubuntu.yml/badge.svg">
  </p>
</p>

---

### Ringkasan

Proyek Tor memungkinkan pengguna untuk menjelajah Internet, mengobrol, dan mengirim pesan instan secara anonim melalui mekanismenya sendiri. Tor digunakan oleh berbagai macam individu, perusahaan, dan organisasi, baik untuk aktivitas yang sah maupun tujuan terlarang lainnya. Tor telah banyak digunakan oleh badan intelijen, kelompok peretas, aktivitas kriminal, dan bahkan pengguna biasa yang peduli dengan privasi mereka di dunia digital.

Nipe adalah sebuah mesin, yang dikembangkan dalam Perl, yang bertujuan menjadikan jaringan Tor sebagai gerbang jaringan default Anda. Nipe dapat merutekan lalu lintas dari mesin Anda ke Internet melalui jaringan Tor, sehingga Anda dapat menjelajah Internet dengan pendirian yang lebih tangguh terhadap privasi dan anonimitas di dunia maya.

Nipe mendukung perutean lalu lintas IPv4 dan IPv6 melalui jaringan Tor. Hanya lalu lintas yang ditujukan untuk alamat lokal dan/atau loopback yang tidak dirutekan melalui Tor. Semua lalu lintas UDP/ICMP non-lokal juga diblokir oleh proyek Tor.

Nipe menggunakan iptables dan ip6tables untuk menerapkan aturan pengalihan masing-masing untuk lalu lintas IPv4 dan IPv6. Jika Anda memiliki aturan yang diterapkan pada utilitas ini, konflik mungkin terjadi selama proses dimulai. Saat Anda menghentikan layanan Nipe, semua aturan keberangkatan dihapus, tanpa membedakan antara aturan yang sudah ada dan aturan Nipe.

**NipeX (Nipe Extended)** adalah fork dari [Nipe](https://github.com/htrgouvea/nipe) oleh Heitor Gouvêa, yang diperluas dengan berbagai alat privasi & keamanan tambahan. Dibangun untuk sistem Debian, NipeX mengintegrasikan Nipe dengan alat-alat penting lainnya untuk membersihkan metadata, mengelola MAC address, mengonfigurasi firewall (UFW), memantau lalu lintas, memindai rootkit, dan banyak lagi, semua dari satu antarmuka yang mudah digunakan.

Selain menggunakan Tor sebagai gateway default, Anda juga dapat men-deploy bridge obfs4 Anda sendiri menggunakan Docker untuk meningkatkan ketahanan terhadap sensor dan pemblokiran jaringan Tor. Fitur ini memungkinkan Anda menjalankan bridge obfs4 pribadi yang dapat membantu pengguna lain mengakses jaringan Tor di lingkungan dengan pembatasan ketat.

---

### Unduh dan Pasang

```bash
  # Unduh repositori NipeX
  $ git clone https://github.com/ricalnet/nipex && cd nipex
    
  # Pasang pustaka dan dependensi
  $ sudo apt install -y cpanminus && sudo cpanm --installdeps .

  # Nipe harus dijalankan sebagai root
  $ sudo perl nipe.pl install
  
  # Jalankan NipeX
  $ ./main.sh
```

---

### Perintah:
```
╔═════════════════════════════════════════════════════════╗
║                    ____    _______                      ║
║                   /    \  |       \                     ║
║                  |  ()  | | PRIVACY!                    ║
║                   \____/  |_______/                     ║
║                                                         ║
║               N I P E   E X T E N D E D                 ║
║              Privacy & Security Toolkit                 ║
║                                                         ║
║           https://github.com/ricalnet/nipex/            ║
╚═════════════════════════════════════════════════════════╝

PRIVACY TOOLS
  1) Ganti hostname
  2) Ganti zona waktu
  3) Atur DNS (LibreDNS+Quad9)
  4) Manajemen MAC (acak/kustom)
  5) Hapus metadata file (MAT2)

SECURITY TOOLS
  6) Periksa integritas file
  7) Generator password
  8) Firewall (UFW)
  9) Monitor lalu lintas (tcpdump)
 10) Rootkit Hunter (rkhunter)
 11) Status layanan
 12) Monitor sistem (htop)

MAIN TOOLS
 13) Main Tools (Nipe)
 14) Deploy obfs4-Docker

  0) Keluar

Pilih menu [0-14]: 
```

---

### Deploy Bridge obfs4 Anda Sendiri

NipeX menyertakan dukungan untuk men-deploy bridge obfs4 Anda sendiri menggunakan Docker. Bridge obfs4 adalah jenis bridge Tor yang menggunakan protokol obfuscation untuk menyembunyikan lalu lintas Tor, membuatnya lebih sulit dideteksi dan diblokir. Dengan men-deploy bridge obfs4 Anda sendiri, Anda dapat:

- Membantu pengguna lain mengakses jaringan Tor di lingkungan dengan sensor ketat
- Meningkatkan ketahanan jaringan Tor secara keseluruhan
- Menjalankan bridge pribadi yang dapat Anda gunakan sendiri atau bagikan

Untuk men-deploy bridge obfs4:

1. Pastikan Docker dan Docker Compose telah terinstall di sistem Anda. Jika belum, Anda dapat menggunakan skrip instalasi yang disediakan:
   ```bash
   # Untuk Debian
   ./install-docker-engine-on-debian.sh
   
   # Atau untuk Ubuntu
   ./install-docker-engine-on-ubuntu.sh
   ```
2. Edit dan sesuaikan file `.env` dari direktori `obfs4-docker`:
   ```bash
   cd obfs4-docker
   cp .env.example .env
   nano .env  # atau gunakan editor teks pilihan Anda
   ```
   Sesuaikan variabel seperti `OR_PORT`, `PT_PORT`, `NICKNAME`, `EMAIL`, dan lainnya sesuai kebutuhan Anda.
3. Jalankan NipeX dan pilih menu **14) Deploy obfs4-Docker**
4. Gunakan opsi **Start** untuk menjalankan container bridge obfs4
5. Verifikasi bahwa bridge berjalan dengan baik menggunakan opsi **Verify**
6. Bridge Anda akan tersedia dan dapat digunakan oleh klien Tor yang membutuhkan

---

### Kontribusi

Kontribusi dan saran Anda sangat kami sambut ♥. [Lihat panduan kontribusi di sini.](/.github/CONTRIBUTING.md) Silakan laporkan bug melalui [halaman isu](https://github.com/ricalnet/NipeX/issues) dan untuk isu keamanan, lihat [kebijakan keamanan di sini.](/SECURITY.md) (✿ ◕‿◕)

---

### Lisensi

Karya ini dilisensikan di bawah [Lisensi MIT.](/LICENSE.md)