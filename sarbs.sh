#!/bin/sh
## 2025-01-09 SARBS

# Sergi's automatisches Einrichtungsskript (SARBS)
# im Original von Luke Smith <luke@lukesmith.xyz> "evige Probs an dich brä"
# Lizenz: MIT

### OPTIONEN UND VARIABLEN ###

dotfilesrepo="https://github.com/Sergi-us/dotfiles.git"
progsfile="https://raw.githubusercontent.com/Sergi-us/SARBS/master/progs.csv"
aurhelper="yay"
# TODO Branch anpassen oder ergänzen
repobranch="master"
export TERM=ansi

rssurls="https://lukesmith.xyz/rss.xml
https://videos.lukesmith.xyz/feeds/videos.xml?videoChannelId=2 \"~Luke Smith (Videos)\"
https://www.youtube.com/feeds/videos.xml?channel_id=UC2eYFnH61tmytImy1mTYvhA \"~Luke Smith (YouTube)\"
https://notrelated.xyz/rss
https://based.cooking/index.xml
https://artixlinux.org/feed.php \"tech\"
https://www.archlinux.org/feeds/news/ \"tech\"
https://github.com/Sergi-US/voidrice/commits/master.atom \"~SARBS dotfiles\""

### FUNKTIONEN ###

# Installiert ein Paket mit pacman ohne Bestätigung und prüft, ob es bereits installiert ist.
installpkg() {
    pacman --noconfirm --needed -S "$1" >/dev/null 2>&1
}

# Gibt eine Fehlermeldung aus und beendet das Skript.
error() {
    printf "%s\n" "$1" >&2
    exit 1
}

# Zeigt eine Willkommensnachricht an und informiert über wichtige Hinweise.
welcomemsg() {
    whiptail --title "Willkommen!" \
        --msgbox "Willkommen bei SARBS automatischem Einrichtungsskript!\\n\\nDieses Skript installiert automatisch einen voll ausgestatteten Linux-Desktop, den ich als mein Hauptsystem verwende.\\n\\n-Sergius" 12 80

    whiptail --title "Wichtiger Hinweis!" --yes-button "Alles bereit!" \
        --no-button "Zurück..." \
        --yesno "Stelle sicher, dass der Computer, den du verwendest, aktuelle pacman-Updates und aktualisierte Arch-Schlüsselringe hat.\\n\\nFalls nicht, kann die Installation einiger Programme fehlschlagen." 8 80
}

# Fragt den Benutzer nach einem Benutzernamen und Passwort und validiert die Eingaben.
getuserandpass() {
    name=$(whiptail --inputbox "Bitte gib zuerst einen Namen für das Benutzerkonto ein." 10 60 3>&1 1>&2 2>&3 3>&1) || exit 1
    while ! echo "$name" | grep -q "^[a-z_][a-z0-9_-]*$"; do
        name=$(whiptail --nocancel --inputbox "Ungültiger Benutzername. Gib einen Benutzernamen ein, der mit einem Buchstaben beginnt und nur Kleinbuchstaben, - oder _ enthält." 10 60 3>&1 1>&2 2>&3 3>&1)
    done
    pass1=$(whiptail --nocancel --passwordbox "Gib ein Passwort für diesen Benutzer ein." 10 60 3>&1 1>&2 2>&3 3>&1)
    pass2=$(whiptail --nocancel --passwordbox "Wiederhole das Passwort." 10 60 3>&1 1>&2 2>&3 3>&1)
    while ! [ "$pass1" = "$pass2" ]; do
        unset pass2
        pass1=$(whiptail --nocancel --passwordbox "Passwörter stimmen nicht überein.\\n\\nGib das Passwort erneut ein." 10 60 3>&1 1>&2 2>&3 3>&1)
        pass2=$(whiptail --nocancel --passwordbox "Wiederhole das Passwort." 10 60 3>&1 1>&2 2>&3 3>&1)
    done
}

# Prüft, ob der Benutzer bereits existiert, und warnt den Benutzer.
usercheck() {
    ! { id -u "$name" >/dev/null 2>&1; } ||
        whiptail --title "WARNUNG" --yes-button "FORTFAHREN" \
            --no-button "Nein, warte..." \
            --yesno "Der Benutzer \`$name\` existiert bereits auf diesem System. SARBS kann für einen bereits existierenden Benutzer installieren, aber es wird alle konfliktierenden Einstellungen/Dotfiles des Benutzerkontos ÜBERSCHREIBEN.\\n\\nSARBS wird deine Benutzerdaten, Dokumente, Videos usw. NICHT überschreiben, also mach dir darum keine Sorgen, aber klicke nur auf <FORTFAHREN>, wenn du damit einverstanden bist, dass deine Einstellungen überschrieben werden.\\n\\nBeachte auch, dass SARBS das Passwort von $name auf das von dir eingegebene ändern wird." 14 80
}

# Zeigt eine letzte Bestätigungsmeldung vor der automatischen Installation an.
preinstallmsg() {
    whiptail --title "Lass uns anfangen!" --yes-button "Los geht's!" \
        --no-button "Nein, doch nicht!" \
        --yesno "Der Rest der Installation wird jetzt völlig automatisiert ablaufen, sodass du dich zurücklehnen und entspannen kannst.\\n\\nEs wird einige Zeit dauern, aber wenn es fertig ist, kannst du dich noch mehr entspannen mit deinem kompletten System.\\n\\nDrücke jetzt einfach <Los geht's!> und die Installation wird beginnen!" 13 80 || {
        clear
        exit 1
    }
}

# === Fügt den neuen Benutzer hinzu, setzt das Passwort und erstellt notwendige Verzeichnisse ===
# Gruppe backup_users
adduserandpass() {
    whiptail --infobox "Benutzer \"$name\" wird hinzugefügt..." 7 80
    useradd -m -g wheel -s /bin/zsh "$name" >/dev/null 2>&1 ||
        { usermod -a -G wheel "$name"; mkdir -p /home/"$name"; chown "$name":wheel /home/"$name"; }
    export repodir="/home/$name/.local/src"
    mkdir -p "$repodir"
    chown -R "$name":wheel "$(dirname "$repodir")"
    echo "$name:$pass1" | chpasswd
    unset pass1 pass2

    # Neue Backup-Konfiguration
    # Gruppe erstellen, falls sie nicht existiert
    if ! getent group backup_users >/dev/null; then
        whiptail --infobox "Backup-Gruppe wird erstellt..." 7 50
        groupadd backup_users
    fi

    # USB-Mount-Verzeichnis erstellen und konfigurieren, falls es nicht existiert
    if [ ! -d "/mnt/usb" ]; then
        whiptail --infobox "USB-Mount-Verzeichnis wird eingerichtet..." 7 50
        mkdir -p "/mnt/usb"
        chown root:backup_users "/mnt/usb"
        chmod 2775 "/mnt/usb"
    fi

    # Nutzer zur Backup-Gruppe hinzufügen
    usermod -aG backup_users "$name"
}

# Aktualisiert den Arch-Schlüsselring oder aktiviert Arch-Repositories auf Artix-Systemen.
refreshkeys() {
    case "$(readlink -f /sbin/init)" in
    *systemd*)
        whiptail --infobox "Arch-Schlüsselring wird aktualisiert..." 7 40
        pacman --noconfirm -S archlinux-keyring >/dev/null 2>&1
        ;;
    *)
        whiptail --infobox "Aktivierung der Arch-Repositories für eine umfangreichere Softwareauswahl..." 7 40
        pacman --noconfirm --needed -S \
            artix-keyring artix-archlinux-support >/dev/null 2>&1
        grep -q "^\[extra\]" /etc/pacman.conf ||
        echo "[extra]
Include = /etc/pacman.d/mirrorlist-arch" >>/etc/pacman.conf
        pacman -Sy --noconfirm >/dev/null 2>&1
        pacman-key --populate archlinux >/dev/null 2>&1
        ;;
    esac
}

# === Installiert ein Paket manuell, hauptsächlich für den AUR-Helper ===
# TODO --force main Option testen
manualinstall() {
    pacman -Qq "$1" && return 0
    whiptail --infobox "\"$1\" wird manuell installiert." 7 80
    sudo -u "$name" mkdir -p "$repodir/$1"
    sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
        --no-tags -q "https://aur.archlinux.org/$1.git" "$repodir/$1" ||
        {
            cd "$repodir/$1" || return 1
            sudo -u "$name" git pull --force origin master
        }
    cd "$repodir/$1" || exit 1
    sudo -u "$name" -D "$repodir/$1" \
        makepkg --noconfirm -si >/dev/null 2>&1 || return 1
}

# Installiert Programme aus dem Hauptrepository mit Fortschrittsanzeige.
maininstall() {
    whiptail --title "SARBS Installation" --infobox "\`$1\` wird installiert ($n von $total). $1 $2" 9 70
    installpkg "$1"
}

# Klont ein Git-Repository und installiert es mit make.
# TODO --force main Option testen
gitmakeinstall() {
    progname="${1##*/}"
    progname="${progname%.git}"
    dir="$repodir/$progname"
    whiptail --title "SARBS Installation" \
        --infobox "\`$progname\` wird installiert ($n von $total) via \`git\` und \`make\`. $(basename "$1") $2" 8 80
    sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
        --no-tags -q "$1" "$dir" ||
        {
            cd "$dir" || return 1
            current_branch=$(git rev-parse --abbrev-ref HEAD)
            sudo -u "$name" git pull --force origin "$current_branch"
        }
    cd "$dir" || exit 1
    make >/dev/null 2>&1
    make install >/dev/null 2>&1
    cd /tmp || return 1
}

# Installiert Pakete aus dem AUR mit dem AUR-Helper.
aurinstall() {
    whiptail --title "SARBS Installation" \
        --infobox "\`$1\` wird aus dem AUR installiert ($n von $total). $1 $2" 9 80
    echo "$aurinstalled" | grep -q "^$1$" && return 1
    sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1
}

# Installiert Python-Pakete mit pip.
pipinstall() {
    whiptail --title "SARBS Installation" \
        --infobox "Das Python-Paket \`$1\` wird installiert ($n von $total). $1 $2" 9 80
    [ -x "$(command -v "pip")" ] || installpkg python-pip >/dev/null 2>&1
    yes | pip install "$1"
}

# Installationsschleife, die alle Programme aus der progs.csv installiert.
installationloop() {
    ([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) ||
        curl -Ls "$progsfile" | sed '/^#/d' >/tmp/progs.csv
    total=$(wc -l </tmp/progs.csv)
    aurinstalled=$(pacman -Qqm)
    while IFS=, read -r tag program comment; do
        n=$((n + 1))
        echo "$comment" | grep -q "^\".*\"$" &&
            comment="$(echo "$comment" | sed -E "s/(^\"|\"$)//g")"
        case "$tag" in
        "A") aurinstall "$program" "$comment" ;;
        "G") gitmakeinstall "$program" "$comment" ;;
        "P") pipinstall "$program" "$comment" ;;
        *) maininstall "$program" "$comment" ;;
        esac
    done </tmp/progs.csv
}

# Klont ein Git-Repository und kopiert die Dateien in ein Zielverzeichnis.
putgitrepo() {
    whiptail --infobox "Konfigurationsdateien werden heruntergeladen und installiert..." 7 80
    [ -z "$3" ] && branch="master" || branch="$repobranch"
    dir=$(mktemp -d)
    [ ! -d "$2" ] && mkdir -p "$2"
    chown "$name":wheel "$dir" "$2"
    sudo -u "$name" git -C "$repodir" clone --depth 1 \
        --single-branch --no-tags -q --recursive -b "$branch" \
        --recurse-submodules "$1" "$dir"
    sudo -u "$name" cp -rfT "$dir" "$2"
}

# Installiert vim-plug und die Plugins aus der Neovim-Konfiguration.
vimplugininstall() {
    whiptail --infobox "Neovim-Plugins werden installiert..." 7 80
    mkdir -p "/home/$name/.config/nvim/autoload"
    curl -Ls "https://raw.githubusercontent.com/Sergi-US/vim-plug/master/plug.vim" > "/home/$name/.config/nvim/autoload/plug.vim"
    chown -R "$name:wheel" "/home/$name/.config/nvim"
    sudo -u "$name" nvim -c "PlugInstall|q|q"
}

# Erstellt die user.js für Firefox/Librewolf basierend auf Arkenfox ===
makeuserjs(){
    arkenfox="$pdir/arkenfox.js"
    overrides="$pdir/user-overrides.js"
    userjs="$pdir/user.js"
    ln -fs "/home/$name/.config/firefox/larbs.js" "$overrides"
    [ ! -f "$arkenfox" ] && curl -sL "https://raw.githubusercontent.com/Sergi-us/user.js/master/user.js" > "$arkenfox"
    cat "$arkenfox" "$overrides" > "$userjs"
    chown "$name:wheel" "$arkenfox" "$userjs"
    # Installieren des Aktualisierungsskripts.
    mkdir -p /usr/local/lib /etc/pacman.d/hooks
    cp "/home/$name/.local/bin/arkenfox-auto-update" /usr/local/lib/
    chown root:root /usr/local/lib/arkenfox-auto-update
    chmod 755 /usr/local/lib/arkenfox-auto-update
    # Konfiguration des pacman-Hooks zum automatischen Aktualisieren.
    echo "[Trigger]
Operation = Upgrade
Type = Package
Target = firefox
Target = librewolf
Target = librewolf-bin
[Action]
Description=Arkenfox user.js aktualisieren
When=PostTransaction
Depends=arkenfox-user.js
Exec=/usr/local/lib/arkenfox-auto-update" > /etc/pacman.d/hooks/arkenfox.hook
}

# === Installiert Librewolf-Add-ons manuell durch Herunterladen der XPI-Dateien TESTVERSION ===
installffaddons(){
    # Liste der zu installierenden Add-ons
    addonlist="ublock-origin decentraleyes istilldontcareaboutcookies vimmatic darkreader keepassxc-browser multi-account-containers styl-us chameleon-ext nighttab"
    addontmp="$(mktemp -d)"
    trap "rm -fr $addontmp" HUP INT QUIT TERM PWR EXIT
    IFS=' '
    sudo -u "$name" mkdir -p "$pdir/extensions/"
    for addon in $addonlist; do
        if [ "$addon" = "ublock-origin" ]; then
            addonurl="$(curl -sL https://api.github.com/repos/gorhill/uBlock/releases/latest | grep -E 'browser_download_url.*\.firefox\.xpi' | cut -d '"' -f 4)"
        else
            addonurl="$(curl --silent "https://addons.mozilla.org/en-US/firefox/addon/${addon}/" | grep -o 'https://addons.mozilla.org/firefox/downloads/file/[^"]*')"
        fi
        file="${addonurl##*/}"
        sudo -u "$name" curl -LOs "$addonurl" > "$addontmp/$file"
        id="$(unzip -p "$file" manifest.json | grep "\"id\"")"
        id="${id%\"*}"
        id="${id##*\"}"
        mv "$file" "$pdir/extensions/$id.xpi"
    done
    chown -R "$name:$name" "$pdir/extensions"
#category-more-from-mozilla { display: none !important }" > "$pdir/chrome/userContent.css"
}

# Zeigt eine Abschlussmeldung an, wenn die Installation beendet ist.
finalize() {
    whiptail --title "Alles erledigt!" \
        --msgbox "Glückwunsch! Sofern keine verdekten Fehler aufgetreten sind, wurde das Skript erfolgreich ausgeführt und alle Programme und Konfigurationsdateien sollten an ihrem Platz sein.\\n\\nUm die neue grafische Umgebung zu starten, reboote dein System und melde dich mit dem neu erstellten Benutzer an. SARBS wird automatisch in tty1 gestartet.\\n\\n.t Sergius" 13 80
}

### DAS EIGENTLICHE SKRIPT ###

# 1. Logdatei mit Zeitstempel im Root-Home-Verzeichnis erstellen
logfile="$HOME/install_$(date '+%Y-%m-%d_%H-%M-%S').log"
touch "$logfile"

# 2. Globale Umleitung aller Ausgaben (stdout und stderr) in die Logdatei
exec > >(stdbuf -oL tee -a "$logfile") 2>&1

# 3. Überprüft, ob der Benutzer root ist und ob das System Arch-basiert ist, installiert whiptail.
pacman --noconfirm --needed -Sy libnewt ||
    error "Bist du sicher, dass du als root-Benutzer angemeldet bist, ein Arch-basiertes System verwendest und eine Internetverbindung hast?"

# 4. Begrüßung und Auswahl der Dotfiles.
welcomemsg || error "Benutzer hat abgebrochen."

# Benutzername und Passwort abfragen.
getuserandpass || error "Benutzer hat abgebrochen."

# Überprüft, ob der Benutzer bereits existiert.
usercheck || error "Benutzer hat abgebrochen."

# Letzte Bestätigung vor Beginn der Installation.
preinstallmsg || error "Benutzer hat abgebrochen."

### Ab hier erfolgt die Installation automatisch ohne weitere Benutzereingaben.

# Aktualisiert die Arch-Schlüsselringe.
refreshkeys ||
    error "Fehler beim automatischen Aktualisieren des Arch-Schlüsselrings. Versuche es manuell."

# Installiert grundlegende Pakete, die für die Installation benötigt werden.
for x in curl ca-certificates base-devel git ntp zsh; do
    whiptail --title "SARBS Installation" \
        --infobox "\`$x\` wird installiert, das zur Installation und Konfiguration anderer Programme benötigt wird." 8 70
    installpkg "$x"
done

# Synchronisiert die Systemzeit.
whiptail --title "SARBS Installation" \
    --infobox "Systemzeit synchronisieren, um eine erfolgreiche und sichere Installation der Software zu gewährleisten..." 8 70
ntpd -q -g >/dev/null 2>&1

# Fügt den neuen Benutzer hinzu.
adduserandpass || error "Fehler beim Hinzufügen des Benutzernamens und/oder Passworts."

# Benutzer-Linger aktivieren (für Pipewire notwendig)
loginctl enable-linger "$name"

# Notwendige Umgebungsvariablen setzen
export XDG_RUNTIME_DIR="/run/user/$(id -u "$name")"

# Übernimmt neue sudoers-Datei, falls vorhanden.
[ -f /etc/sudoers.pacnew ] && cp /etc/sudoers.pacnew /etc/sudoers

# Erlaubt dem Benutzer, sudo ohne Passwort zu verwenden, notwendig für AUR-Installationen.
trap 'rm -f /etc/sudoers.d/larbs-temp' HUP INT QUIT TERM PWR EXIT
echo "%wheel ALL=(ALL) NOPASSWD: ALL
Defaults:%wheel,root runcwd=*" >/etc/sudoers.d/larbs-temp

# Konfiguriert pacman mit zusätzlichen Optionen.
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -Ei "s/^#(ParallelDownloads).*/\1 = 5/;/^#Color$/s/#//" /etc/pacman.conf

# Setzt die Anzahl der Kompilierungskerne auf die Anzahl der verfügbaren CPUs.
sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf

# Installiert den AUR-Helper manuell.
manualinstall $aurhelper || error "Fehler beim Installieren des AUR-Helfers."

# AUR-Helper konfigurieren (Stellt sicher, dass Git-Pakete aus dem AUR automatisch aktualisiert werden)
$aurhelper -Y --save --devel

# Startet die Installationsschleife für alle Programme.
installationloop

# PipeWire-Dienste und Sockets für den Benutzer aktivieren
sudo -u "$name" XDG_RUNTIME_DIR="/run/user/$(id -u "$name")" \
    systemctl --user enable --now pipewire.service pipewire.socket
sudo -u "$name" XDG_RUNTIME_DIR="/run/user/$(id -u "$name")" \
    systemctl --user enable --now pipewire-pulse.service pipewire-pulse.socket
sudo -u "$name" XDG_RUNTIME_DIR="/run/user/$(id -u "$name")" \
    systemctl --user enable --now wireplumber.service

# PulseAudio-Dienste und Sockets maskieren
# TODO überarbeiten da gewechselt auch pipewire?
sudo -u "$name" XDG_RUNTIME_DIR="/run/user/$(id -u "$name")" \
    systemctl --user mask pulseaudio.service pulseaudio.socket

# Klont die Dotfiles und entfernt unnötige Dateien.
putgitrepo "$dotfilesrepo" "/home/$name" "$repobranch"
[ -z "/home/$name/.config/newsboat/urls" ] &&
    echo "$rssurls" > "/home/$name/.config/newsboat/urls"
rm -rf "/home/$name/.git/" "/home/$name/README.md" "/home/$name/LICENSE" "/home/$name/FUNDING.yml"

# Installiert Neovim-Plugins, falls sie noch nicht installiert sind.
[ ! -f "/home/$name/.config/nvim/autoload/plug.vim" ] && vimplugininstall

# Deaktiviert den Systemlautsprecher (Piepton).
rmmod pcspkr
echo "blacklist pcspkr" >/etc/modprobe.d/nobeep.conf

# Setzt zsh als Standard-Shell für den neuen Benutzer.
chsh -s /bin/zsh "$name" >/dev/null 2>&1
sudo -u "$name" mkdir -p "/home/$name/.cache/zsh/"
sudo -u "$name" mkdir -p "/home/$name/.config/abook/"
sudo -u "$name" mkdir -p "/home/$name/.config/mpd/playlists/"

# Generiert die dbus UUID für Artix mit runit.
dbus-uuidgen >/var/lib/dbus/machine-id

# Konfiguriert Systembenachrichtigungen für den Browser auf Artix.
echo "export \$(dbus-launch)" >/etc/profile.d/dbus.sh

# Aktiviert Tippen zum Klicken auf Touchpads.
[ ! -f /etc/X11/xorg.conf.d/40-libinput.conf ] && printf 'Section "InputClass"
        Identifier "libinput touchpad catchall"
        MatchIsTouchpad "on"
        MatchDevicePath "/dev/input/event*"
        Driver "libinput"
    # Linke Maustaste durch Tippen aktivieren
    Option "Tapping" "on"
EndSection' >/etc/X11/xorg.conf.d/40-libinput.conf

# Konfiguriert den Browser mit Privacy-Einstellungen und installiert Add-ons.
whiptail --infobox "Einstellungen für die Browser-Privatsphäre und Add-ons werden gesetzt..." 7 60

browserdir="/home/$name/.librewolf"
profilesini="$browserdir/profiles.ini"

# Startet Librewolf im Headless-Modus, um ein Profil zu erstellen.
sudo -u "$name" librewolf --headless >/dev/null 2>&1 &
sleep 1
profile="$(sed -n "/Default=.*.default-default/ s/.*=//p" "$profilesini")"
pdir="$browserdir/$profile"

# Erstellt die user.js und installiert Add-ons, wenn das Profilverzeichnis existiert.
[ -d "$pdir" ] && makeuserjs
[ -d "$pdir" ] && installffaddons

# Beendet die Librewolf-Instanz.
pkill -u "$name" librewolf

# Konfiguriert sudo-Einstellungen für den Benutzer.
echo "%wheel ALL=(ALL:ALL) ALL" >/etc/sudoers.d/00-larbs-wheel-can-sudo
echo "%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/shutdown,/usr/bin/reboot,/usr/bin/systemctl suspend,/usr/bin/wifi-menu,/usr/bin/mount,/usr/bin/umount,/usr/bin/pacman -Syu,/usr/bin/pacman -Syyu,/usr/bin/pacman -Syyu --noconfirm,/usr/bin/loadkeys,/usr/bin/pacman -Syyuw --noconfirm,/usr/bin/pacman -S -y --config /etc/pacman.conf --,/usr/bin/pacman -S -y -u --config /etc/pacman.conf --" >/etc/sudoers.d/01-larbs-cmds-without-password
echo "Defaults editor=/usr/bin/nvim" >/etc/sudoers.d/02-larbs-visudo-editor
mkdir -p /etc/sysctl.d
echo "kernel.dmesg_restrict = 0" > /etc/sysctl.d/dmesg.conf

# Entfernt temporäre sudoers-Datei.
rm -f /etc/sudoers.d/larbs-temp

# Zeigt die Abschlussmeldung an.
finalize
