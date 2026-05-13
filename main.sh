#!/usr/bin/env bash
# =============================================================================
#  NipeX extends Nipe with comprehensive privacy & security tools for Debian.
#  Repo   : https://github.com/ricalnet/nipex/
# =============================================================================
set -o pipefail

# ─────────────────────────── Configuration ──────────────────────────────────
readonly LOGFILE="$HOME/.nipex.log"
readonly VERSION="2.0"
readonly DEPENDENCIES=("macchanger" "mat2" "ufw" "tcpdump" "rkhunter" "htop" "openssl" "xclip")

# ─────────────────────────── Color Palette ──────────────────────────────────
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# ──────────────────────── Dynamic paths ─────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OBFS4_DIR="$SCRIPT_DIR/obfs4-docker"

# ─────────────────────────── Utility Functions ─────────────────────────────
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOGFILE"; }
info() { echo -e "${CYAN}[i]${NC} $*"; log "INFO: $*"; }
ok()  { echo -e "${GREEN}[✓]${NC} $*"; log "OK: $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*" >&2; log "WARN: $*"; }
err() { echo -e "${RED}[✗]${NC} $*" >&2; log "ERROR: $*"; }
banner_msg() { echo -e "\n${BOLD}${BLUE}─── $* ───${NC}\n"; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        warn "Aksi ini memerlukan hak akses root. Meminta sudo..."
        sudo bash "$0" "$@"
        exit $?
    fi
}

not_empty() { [[ -n "$1" ]] && return 0 || return 1; }

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while ps -p "$pid" > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

press_enter() {
    echo
    read -rsp $'\033[0;35mTekan Enter untuk melanjutkan...\033[0m'
    echo
}

ensure_deps() {
    local missing=()
    for cmd in "${DEPENDENCIES[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        warn "Dependensi berikut tidak ditemukan: ${missing[*]}"
        read -rp "Install sekarang? [Y/n] " ans
        if [[ "$ans" =~ ^[yY]?$ ]]; then
            sudo apt update -qq && sudo apt install -y "${missing[@]}" && \
                ok "Semua dependensi terinstall." || err "Gagal install dependensi."
        else
            warn "Beberapa fitur mungkin tidak berfungsi."
        fi
    fi
}

# ──────────────────────── Tampilan Header ────────────────────────────────────
display_header() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
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
EOF
    echo -e "${NC}"
}

# ─────────────────────────── PRIVACY TOOLS ──────────────────────────────────

change_hostname() {
    display_header
    banner_msg "Ganti Hostname"
    local current
    current=$(hostname)
    info "Hostname saat ini: ${BOLD}$current${NC}"
    read -rp "Masukkan hostname baru (kosong untuk batal): " new_host
    if ! not_empty "$new_host"; then
        warn "Dibatalkan."
        press_enter
        return
    fi
    require_root
    read -rp "Konfirmasi: ubah hostname menjadi '$new_host'? [y/N] " confirm
    if [[ "$confirm" =~ ^[yY] ]]; then
        hostnamectl set-hostname "$new_host" && \
            ok "Hostname berhasil diubah menjadi: $new_host" || \
            err "Gagal mengubah hostname."
    else
        warn "Dibatalkan."
    fi
    press_enter
}

change_timezone() {
    display_header
    banner_msg "Ganti Zona Waktu"
    local current
    current=$(timedatectl show --property=Timezone --value)
    info "Zona waktu saat ini: ${BOLD}$current${NC}"
    echo -e "${CYAN}Mencari zona waktu... (tekan q untuk keluar dari daftar)${NC}"
    timedatectl list-timezones | less
    read -rp "Ketik zona waktu yang diinginkan (contoh: Asia/Jakarta): " tz
    if ! not_empty "$tz"; then
        warn "Dibatalkan."
        press_enter
        return
    fi
    require_root
    if timedatectl set-timezone "$tz" 2>/dev/null; then
        ok "Zona waktu berhasil diubah ke $tz"
    else
        err "Zona waktu '$tz' tidak valid."
    fi
    press_enter
}

default_dns() {
    display_header
    banner_msg "Atur DNS Default (LibreDNS & Quad9)"
    info "DNS yang akan diterapkan: ${BOLD}116.202.176.26 (LibreDNS), 9.9.9.9 (Quad9)${NC}"
    if command -v resolvectl >/dev/null 2>&1; then
        info "DNS saat ini (systemd-resolved):"
        resolvectl dns 2>/dev/null || true
    fi

    read -rp "Lanjutkan menerapkan DNS? [Y/n] " apply
    if [[ ! "$apply" =~ ^[yY]?$ ]]; then
        warn "Dibatalkan."
        press_enter
        return
    fi

    require_root
    if command -v resolvectl >/dev/null 2>&1; then
        local iface
        iface=$(ip -o -4 route show default | awk '{print $5}' | head -1)
        if [[ -z "$iface" ]]; then
            warn "Tidak dapat mendeteksi interface default."
            read -rp "Masukkan nama interface (contoh: eth0, wlan0): " iface
        fi
        resolvectl dns "$iface" 116.202.176.26 9.9.9.9
        resolvectl domain "$iface" "~."
        ok "DNS systemd-resolved untuk $iface telah diperbarui."
    else
        warn "systemd-resolved tidak aktif. Mengubah /etc/resolv.conf (mungkin ditimpa DHCP)."
        {
            echo "nameserver 116.202.176.26"
            echo "nameserver 9.9.9.9"
        } | sudo tee /etc/resolv.conf > /dev/null
        ok "/etc/resolv.conf diperbarui."
    fi
    press_enter
}

manage_mac() {
    display_header
    banner_msg "Manajemen MAC Address"
    check_dep macchanger
    info "Interface jaringan yang tersedia:"
    ip -o link show | awk -F': ' '!/lo/ {print $2}' | nl -w2 -s') '
    read -rp "Pilih interface (kosong untuk batal): " iface
    if ! not_empty "$iface"; then
        warn "Dibatalkan."
        press_enter
        return
    fi
    if ! ip link show "$iface" >/dev/null 2>&1; then
        err "Interface '$iface' tidak ditemukan."
        press_enter
        return
    fi

    echo "1) MAC acak"
    echo "2) MAC kustom"
    read -rp "Pilihan [1-2]: " mac_choice
    require_root

    case "$mac_choice" in
        1)
            sudo ifconfig "$iface" down
            sudo macchanger -r "$iface"
            sudo ifconfig "$iface" up
            ok "MAC acak diterapkan pada $iface."
            ;;
        2)
            read -rp "Masukkan MAC (format: 00:11:22:33:44:55): " mac_addr
            if [[ ! "$mac_addr" =~ ^([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}$ ]]; then
                err "Format MAC tidak valid."
                press_enter
                return
            fi
            sudo ifconfig "$iface" down
            sudo macchanger -m "$mac_addr" "$iface"
            sudo ifconfig "$iface" up
            ok "MAC kustom diterapkan pada $iface."
            ;;
        *)
            warn "Pilihan tidak valid."
            ;;
    esac
    press_enter
}

manage_metadata() {
    display_header
    banner_msg "Pembersihan Metadata dengan MAT2"
    check_dep mat2
    read -rp "Masukkan file/direktori target: " target
    if [[ ! -e "$target" ]]; then
        err "Lokasi '$target' tidak ada."
        press_enter
        return
    fi
    info "Membersihkan metadata... (mungkin perlu waktu)"
    mat2 --inplace "$target" 2>&1 | tee /tmp/mat2.log | tail -5
    ok "Metadata dibersihkan. Log lengkap: /tmp/mat2.log"
    press_enter
}

# ─────────────────────────── SECURITY TOOLS ──────────────────────────────────

check_file_integrity() {
    display_header
    banner_msg "Pemeriksaan Integritas File"
    read -rep "Masukkan path file: " fpath
    if [[ ! -f "$fpath" ]]; then
        err "File tidak ditemukan."
        press_enter
        return
    fi
    local hashfile="${fpath}.sha256"

    echo "1) Buat hash SHA256"
    echo "2) Verifikasi dengan file .sha256"
    read -rp "Pilihan [1-2]: " int_choice
    case "$int_choice" in
        1)
            sha256sum "$fpath" > "$hashfile"
            ok "Hash disimpan di $hashfile"
            ;;
        2)
            if [[ ! -f "$hashfile" ]]; then
                err "File hash $hashfile tidak ditemukan. Buat dulu."
                press_enter
                return
            fi
            if sha256sum -c "$hashfile" --quiet 2>/dev/null; then
                ok "Integritas file OK."
            else
                err "File telah dimodifikasi!"
            fi
            ;;
        *)
            warn "Pilihan tidak valid."
            ;;
    esac
    press_enter
}

generate_password() {
    display_header
    banner_msg "Generator Password"
    read -rp "Panjang password (default 20): " length
    length=${length:-20}
    if ! [[ "$length" =~ ^[0-9]+$ ]] || [ "$length" -lt 4 ]; then
        err "Panjang harus angka >= 4."
        press_enter
        return
    fi
    local pass
    pass=$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' | head -c "$length")
    echo -e "\n${GREEN}Password:${NC} ${BOLD}$pass${NC}\n"
    if command -v xclip >/dev/null 2>&1; then
        echo -n "$pass" | xclip -selection clipboard
        ok "Password disalin ke clipboard."
    fi
    press_enter
}

manage_firewall() {
    display_header
    banner_msg "Manajemen Firewall (UFW)"
    check_dep ufw
    require_root
    while true; do
        echo -e "${BOLD}UFW Firewall${NC}"
        echo "--------------------------"
        echo "1) Lihat status"
        echo "2) Aktifkan firewall"
        echo "3) Nonaktifkan firewall"
        echo "4) Izinkan port/layanan"
        echo "5) Blokir port/layanan"
        echo "6) Hapus aturan"
        echo "7) Reset UFW (hati-hati!)"
        echo "8) Kembali ke menu utama"
        read -rp "Pilih [1-8]: " fw_choice
        case "$fw_choice" in
            1) ufw status verbose; press_enter ;;
            2) ufw enable; ok "Firewall diaktifkan."; press_enter ;;
            3) ufw disable; warn "Firewall dinonaktifkan."; press_enter ;;
            4) read -rp "Port/layanan (contoh: 80/tcp, ssh): " rule
               ufw allow $rule && ok "Aturan ditambahkan." || err "Gagal menambahkan aturan."
               press_enter ;;
            5) read -rp "Port/layanan (contoh: 80/tcp, ssh): " rule
               ufw deny $rule && ok "Aturan ditambahkan." || err "Gagal menambahkan aturan."
               press_enter ;;
            6) ufw status numbered
               read -rp "Nomor aturan yang akan dihapus: " num
               ufw delete $num && ok "Aturan dihapus." || err "Gagal menghapus."
               press_enter ;;
            7) read -rp "Ketik 'YA' untuk mereset semua aturan UFW: " conf
               if [[ "$conf" == "YA" ]]; then
                   ufw --force reset && ok "UFW direset ke default." || err "Reset gagal."
               else
                   warn "Reset dibatalkan."
               fi
               press_enter ;;
            8) break ;;
            *) warn "Pilihan tidak valid."; sleep 1 ;;
        esac
    done
}

monitor_traffic() {
    display_header
    banner_msg "Monitor Lalu Lintas dengan tcpdump"
    check_dep tcpdump
    info "Interface yang tersedia:"
    ip -o link show | awk -F': ' '!/lo/ {print $2}' | nl -w2 -s') '
    read -rp "Interface (default: eth0): " iface
    iface=${iface:-eth0}
    read -rp "Filter BPF (opsional, contoh: 'port 80'): " filter
    require_root
    echo -e "${YELLOW}Memulai capture... Tekan Ctrl+C untuk berhenti.${NC}"
    sleep 1
    if [[ -n "$filter" ]]; then
        sudo tcpdump -i "$iface" "$filter"
    else
        sudo tcpdump -i "$iface"
    fi
    ok "Capture selesai."
    press_enter
}

run_rkhunter() {
    display_header
    banner_msg "Rootkit Hunter"
    check_dep rkhunter
    require_root
    echo "1) Pindai sistem (--check-all)"
    echo "2) Perbarui database properti file (--propupd)"
    read -rp "Pilihan [1-2]: " rk_choice
    case "$rk_choice" in
        1)
            info "Pindai rootkit... (dapat memakan waktu beberapa menit)"
            sudo rkhunter --check-all &
            spinner $!
            ok "Pemindaian selesai. Hasil di atas."
            ;;
        2)
            sudo rkhunter --propupd
            ok "Database properti diperbarui."
            ;;
        *)
            warn "Pilihan tidak valid."
            ;;
    esac
    press_enter
}

service_status() {
    display_header
    banner_msg "Status Layanan Sistem"
    require_root
    if command -v systemctl >/dev/null 2>&1; then
        systemctl list-units --type=service --state=running --no-pager | less
    else
        sudo service --status-all 2>&1 | less
    fi
    press_enter
}

system_monitor() {
    display_header
    check_dep htop
    exec htop
}

# ─────────────────────────── MAIN TOOLS (NIPE) ──────────────────────────────
main_tools_menu() {
    display_header
    banner_msg "Main Tools - Nipe (Anonymity)"
    if [[ ! -f "./nipe.pl" ]]; then
        err "File nipe.pl tidak ditemukan di direktori saat ini."
        press_enter
        return
    fi
    while true; do
        echo -e "${BOLD}Nipe Control${NC}"
        echo "  1) Start Nipe"
        echo "  2) Stop Nipe"
        echo "  3) Restart Nipe"
        echo "  4) Status Nipe"
        echo "  0) Kembali ke menu utama"
        echo
        read -rp "Pilih [0-4]: " nipe_choice
        case "$nipe_choice" in
            1) sudo perl nipe.pl start; press_enter ;;
            2) sudo perl nipe.pl stop; press_enter ;;
            3) sudo perl nipe.pl restart; press_enter ;;
            4) sudo perl nipe.pl status; press_enter ;;
            0) break ;;
            *) warn "Pilihan tidak valid."; sleep 1 ;;
        esac
    done
}

# ──────────────────────── DEPLOY OBFS4-DOCKER ───────────────────────────────
manage_obfs4() {
    display_header
    banner_msg "Deploy obfs4-Docker"

    # Basic checks
    if ! command -v docker >/dev/null 2>&1; then
        err "Docker tidak terinstall. Silakan install Docker dan Docker Compose terlebih dahulu."
        press_enter
        return
    fi

    if [[ ! -d "$OBFS4_DIR" ]]; then
        err "Direktori obfs4-docker tidak ditemukan di: $OBFS4_DIR"
        press_enter
        return
    fi

    if [[ ! -f "$OBFS4_DIR/docker-compose.yml" ]]; then
        err "File docker-compose.yml tidak ditemukan di dalam $OBFS4_DIR"
        press_enter
        return
    fi

    while true; do
        echo -e "${BOLD}obfs4-Docker Control${NC}"
        echo "  1) Start  (docker compose up -d)"
        echo "  2) Stop   (docker compose down)"
        echo "  3) Restart(docker compose restart)"
        echo "  4) Logs   (docker compose logs -f)"
        echo "  5) Verify (./verify.sh)"
        echo "  0) Kembali ke menu utama"
        echo
        read -rp "Pilih [0-5]: " obfs_choice

        case "$obfs_choice" in
            1)
                info "Memulai container obfs4..."
                (cd "$OBFS4_DIR" && docker compose up -d) && \
                    ok "Container obfs4 berjalan." || err "Gagal menjalankan container."
                press_enter
                ;;
            2)
                info "Menghentikan container obfs4..."
                (cd "$OBFS4_DIR" && docker compose down) && \
                    ok "Container obfs4 dihentikan." || err "Gagal menghentikan container."
                press_enter
                ;;
            3)
                info "Merestart container obfs4..."
                (cd "$OBFS4_DIR" && docker compose restart) && \
                    ok "Container obfs4 direstart." || err "Gagal merestart container."
                press_enter
                ;;
            4)
                echo -e "${YELLOW}Menampilkan log (tekan Ctrl+C untuk keluar)...${NC}"
                sleep 1
                (cd "$OBFS4_DIR" && docker compose logs -f)
                press_enter
                ;;
            5)
                info "Menjalankan verify.sh..."
                if [[ -x "$OBFS4_DIR/verify.sh" ]]; then
                    (cd "$OBFS4_DIR" && ./verify.sh)
                else
                    bash "$OBFS4_DIR/verify.sh"
                fi
                press_enter
                ;;
            0) break ;;
            *) warn "Pilihan tidak valid."; sleep 1 ;;
        esac
    done
}

# ─────────────────────────── MENU UTAMA ─────────────────────────────────────
show_main_menu() {
    ensure_deps

    while true; do
        display_header
        echo -e "${BOLD}PRIVACY TOOLS${NC}"
        echo "  1) Ganti hostname"
        echo "  2) Ganti zona waktu"
        echo "  3) Atur DNS (LibreDNS+Quad9)"
        echo "  4) Manajemen MAC (acak/kustom)"
        echo "  5) Hapus metadata file (MAT2)"
        echo
        echo -e "${BOLD}SECURITY TOOLS${NC}"
        echo "  6) Periksa integritas file"
        echo "  7) Generator password"
        echo "  8) Firewall (UFW)"
        echo "  9) Monitor lalu lintas (tcpdump)"
        echo " 10) Rootkit Hunter (rkhunter)"
        echo " 11) Status layanan"
        echo " 12) Monitor sistem (htop)"
        echo
        echo -e "${BOLD}MAIN TOOLS${NC}"
        echo " 13) Main Tools (Nipe)"
        echo " 14) Deploy obfs4-Docker"
        echo
        echo "  0) Keluar"
        echo
        read -rp "Pilih menu [0-14]: " choice
        case "$choice" in
            1) change_hostname ;;
            2) change_timezone ;;
            3) default_dns ;;
            4) manage_mac ;;
            5) manage_metadata ;;
            6) check_file_integrity ;;
            7) generate_password ;;
            8) manage_firewall ;;
            9) monitor_traffic ;;
            10) run_rkhunter ;;
            11) service_status ;;
            12) system_monitor ;;
            13) main_tools_menu ;;
            14) manage_obfs4 ;;
            0) echo -e "${GREEN}Sampai jumpa!${NC}"; exit 0 ;;
            *) warn "Pilihan tidak valid. Coba lagi."; sleep 1 ;;
        esac
    done
}

# ─────────────────────────── DIRECT CALL HANDLER ────────────────────────────
dispatch_tool() {
    case "$1" in
        change_hostname)     change_hostname ;;
        change_timezone)     change_timezone ;;
        default_dns)         default_dns ;;
        manage_mac)          manage_mac ;;
        manage_metadata)     manage_metadata ;;
        check_file_integrity) check_file_integrity ;;
        generate_password)   generate_password ;;
        manage_firewall)     manage_firewall ;;
        monitor_traffic)     monitor_traffic ;;
        rkhunter)            run_rkhunter ;;
        service_status)      service_status ;;
        system-monitor)      system_monitor ;;
        obfs4)               manage_obfs4 ;;
        help|--help|-h)
            echo "Penggunaan: $0 [nama_alat]"
            echo "Alat yang tersedia:"
            echo "  Privacy : change_hostname, change_timezone, default_dns, manage_mac, manage_metadata"
            echo "  Security: check_file_integrity, generate_password, manage_firewall, monitor_traffic, rkhunter, service_status, system-monitor"
            echo "  Main    : nipe (hanya dari menu interaktif), obfs4 (deploy obfs4-docker)"
            ;;
        *)
            echo "Alat tidak dikenal: $1"
            echo "Jalankan '$0 help' untuk daftar alat."
            exit 1
            ;;
    esac
}

# ─────────────────────────── MAIN ───────────────────────────────────────────
if [[ $# -eq 1 ]]; then
    dispatch_tool "$1"
else
    show_main_menu
fi