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

### Kontribusi

Kontribusi dan saran Anda sangat kami sambut ♥. [Lihat panduan kontribusi di sini.](/.github/CONTRIBUTING.md) Silakan laporkan bug melalui [halaman isu](https://github.com/ricalnet/NipeX/issues) dan untuk isu keamanan, lihat [kebijakan keamanan di sini.](/SECURITY.md) (✿ ◕‿◕)

---

### Lisensi

Karya ini dilisensikan di bawah [Lisensi MIT.](/LICENSE.md)