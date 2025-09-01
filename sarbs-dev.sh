#!/bin/sh
## 2025-08-22 SARBS
# Lazy.nvim ersetzt vim-plug
# dunst deaktiviert
# TODO qutebrowser als librewolf alternative einbauen (wahrscheinlich über die progs.csv und dotfiles möglich)
# TODO BlackArch Quellen hinzufügen

# Sergi's automatisches Einrichtungsskript (SARBS)
# im Original von Luke Smith <luke@lukesmith.xyz> "ewige Props an dich bra"
# Lizenz: MIT

# Sudoers Einstellungen ab Zeile 521 geändert.

### OPTIONEN UND VARIABLEN ###
dotfilesrepo="https://github.com/Sergi-us/dotfiles.git"
progsfile="https://raw.githubusercontent.com/Sergi-us/SARBS/main/progs.csv"
aurhelper="yay"
branch_option=""                # Für DEV-Branch oder leer lassen
fallback_option="-b main"       # Der Fallback-Branch
# export TERM=ansi
enable_firewall="true"          # Firewall-Setup aktivieren (true/false)

# TODO rssurls sollen über die dotfiles geladen werden und aus der Installationsroutine entfernt werden...
# rssurls="https://github.com/Sergi-US/voidrice/commits/master.atom \"~SARBS dotfiles\""

### FUNKTIONEN ###

# Diese Funktion füge bei den anderen Funktionen ein:
setupfirewall() {
    whiptail --infobox "UFW Firewall wird eingerichtet..." 7 50


    # Backend auf nftables setzen (besser für Wireguard)
    # Prüfe ob die Backend-Zeile existiert
    if grep -q "^#*IPT_BACKEND=" /etc/default/ufw; then
        # Zeile existiert (auskommentiert oder nicht), ersetze sie
        sed -i 's/^#*IPT_BACKEND=.*/IPT_BACKEND="nftables"/' /etc/default/ufw
    else
        # Zeile existiert nicht, füge sie hinzu
        echo 'IPT_BACKEND="nftables"' >> /etc/default/ufw
    fi

    # UFW zurücksetzen um sicherzustellen dass keine alten Regeln existieren
    echo "y" | ufw --force reset >/dev/null 2>&1

    # Standardregeln setzen
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1

    # HINWEIS: UFW-Regeln werden in /etc/ufw/ gespeichert:
    # - /etc/ufw/user.rules (IPv4 Regeln)
    # - /etc/ufw/user6.rules (IPv6 Regeln)
    # - /etc/ufw/before.rules & before6.rules (System-Regeln)
    # Backup dieser Dateien vor dem Skript-Lauf wird empfohlen!

    # UFW aktivieren (--force um die Bestätigungsfrage zu überspringen)
    echo "y" | ufw --force enable >/dev/null 2>&1

    # UFW-Dienst beim Systemstart aktivieren
    case "$(readlink -f /sbin/init)" in
        *systemd*)
            systemctl enable ufw >/dev/null 2>&1
            ;;
        *)
            # Für Artix/OpenRC
            rc-update add ufw default >/dev/null 2>&1
            ;;
    esac

    whiptail --infobox "Firewall wurde erfolgreich konfiguriert!" 7 50
    sleep 3
}

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
            --yesno "Der Benutzer \`$name\` existiert bereits auf diesem System. SARBS kann für einen bereits existierenden Benutzer installieren werden, aber es wirden alle Einstellungen/Dotfiles des Benutzerkontos ÜBERSCHREIBEN.\\n\\nSARBS wird deine Benutzerdaten, Dokumente, Videos usw. NICHT überschreiben und auch NICHT Löschen, also mach dir darum keine Sorgen. Klicke nur auf <FORTFAHREN>, wenn du damit einverstanden bist, dass deine Einstellungen überschrieben werden.\\n\\nBeachte auch, dass SARBS das Passwort von $name auf das von dir eingegebene ändern wird." 14 80
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
##    # Neue Backup-Konfiguration
##    # Gruppe erstellen, falls sie nicht existiert
##    if ! getent group backup_users >/dev/null; then
##        whiptail --infobox "Backup-Gruppe wird erstellt..." 7 50
##        groupadd backup_users
##    fi
##    # USB-Mount-Verzeichnis erstellen und konfigurieren, falls es nicht existiert
##    if [ ! -d "/mnt/usb" ]; then
##        whiptail --infobox "USB-Mount-Verzeichnis wird eingerichtet..." 7 50
##        mkdir -p "/mnt/usb"
##        chown root:backup_users "/mnt/usb"
##        chmod 2775 "/mnt/usb"
##    fi
##
##    # Nutzer zur Backup-Gruppe hinzufügen
##    usermod -aG backup_users "$name"
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
            # sudo -u "$name" git pull --force origin master
            sudo -u "$name" git pull --force
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
gitmakeinstall() {
    progname="${1##*/}"
    progname="${progname%.git}"
    dir="$repodir/$progname"
    whiptail --title "SARBS Installation" \
        --infobox "\`$progname\` wird installiert ($n von $total) via \`git\` und \`make\`. $(basename "$1") $2" 8 80

    # Stelle sicher, dass das repodir dem User gehört
    [ ! -d "$repodir" ] && sudo -u "$name" mkdir -p "$repodir"

    # Git-Operationen als User
    if ! sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
        --no-tags -q $branch_option "$1" "$dir" && \
       ! sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
        --no-tags -q $fallback_option "$1" "$dir" && \
       ! sudo -u "$name" git -C "$repodir" clone --depth 1 --single-branch \
        --no-tags -q "$1" "$dir"; then
        # Clone fehlgeschlagen, versuche pull
        cd "$dir" || return 1
        sudo -u "$name" git pull --force
    fi

    cd "$dir" || exit 1
    # Make als User ausführen, nur install als root
    sudo -u "$name" make >/dev/null 2>&1
    make install >/dev/null 2>&1
    # Aufräumen: Stelle sicher, dass alles dem User gehört
    chown -R "$name:wheel" "$dir"
    cd /tmp || return 1
}

# Installiert Pakete aus dem AUR mit dem AUR-Helper.
aurinstall() {
    whiptail --title "SARBS Installation" \
        --infobox "\`$1\` wird aus dem AUR installiert ($n von $total). $1 $2" 9 80
    echo "$aurinstalled" | grep -q "^$1$" && return 1
    sudo -u "$name" $aurhelper -S --noconfirm "$1" >/dev/null 2>&1
    clear || tput reset
}

# Installiert Python-Pakete mit pip.
pipinstall() {
    whiptail --title "SARBS Installation" \
        --infobox "Das Python-Paket \`$1\` wird installiert ($n von $total). $1 $2" 9 80
    [ -x "$(command -v "pip")" ] || installpkg python-pip >/dev/null 2>&1
    yes | pip install "$1"
    clear || tput reset
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

# Firewall einrichten wenn aktiviert
[ "$enable_firewall" = "true" ] && setupfirewall

# Klont ein Git-Repository und kopiert die Dateien in ein Zielverzeichnis.
putgitrepo() {
    whiptail --infobox "Konfigurationsdateien werden heruntergeladen und installiert..." 7 80
    dir=$(mktemp -d)
    [ ! -d "$2" ] && mkdir -p "$2"
    chown "$name":wheel "$dir" "$2"
    sudo -u "$name" git -C "$repodir" clone --depth 1 \
        --single-branch --no-tags -q --recursive $branch_option \
        --recurse-submodules "$1" "$dir" || \
    sudo -u "$name" git -C "$repodir" clone --depth 1 \
        --single-branch --no-tags -q --recursive $fallback_option \
        --recurse-submodules "$1" "$dir" || \
    sudo -u "$name" git -C "$repodir" clone --depth 1 \
        --single-branch --no-tags -q --recursive \
        --recurse-submodules "$1" "$dir"
    sudo -u "$name" cp -rfT "$dir" "$2"

    # Erstelle benutzerspezifische symbolische Links
    whiptail --infobox "Benutzerspezifische symbolische Links werden erstellt..." 7 60
    # Dunst-Link für pywal (überschreibt alte Links/Dateien)
    sudo -u "$name" mkdir -p "/home/$name/.config/dunst"
    sudo -u "$name" rm -f "/home/$name/.config/dunst/dunstrc"  # Alte Datei/Link entfernen
    sudo -u "$name" ln -sf "/home/$name/.cache/wal/dunstrc" "/home/$name/.config/dunst/dunstrc"
}

# Instaliert lazy.nvim
lazyinstall() {
    whiptail --infobox "Lazy.nvim wird installiert..." 7 80
    mkdir -p "/home/$name/.config/nvim/lua"
    chown -R "$name:wheel" "/home/$name/.config/nvim"
    sudo -u "$name" nvim --headless -c "lua require('lazy').sync()" -c "qa"
}

# Installiert vim-plug und die Plugins aus der Neovim-Konfiguration.
##vimplugininstall() {
##    whiptail --infobox "Neovim-Plugins werden installiert..." 7 80
##    mkdir -p "/home/$name/.config/nvim/autoload"
##    curl -Ls "https://raw.githubusercontent.com/Sergi-US/vim-plug/master/plug.vim" > "/home/$name/.config/nvim/autoload/plug.vim"
##    chown -R "$name:wheel" "/home/$name/.config/nvim"
##    sudo -u "$name" nvim -c "PlugInstall|q|q"
##}

# Erstellt die user.js für Firefox/Librewolf basierend auf Arkenfox ===
##makeuserjs(){
##    arkenfox="$pdir/arkenfox.js"
##    overrides="$pdir/user-overrides.js"
##    userjs="$pdir/user.js"
##    ln -fs "/home/$name/.config/firefox/larbs.js" "$overrides"
##    [ ! -f "$arkenfox" ] && curl -sL "https://raw.githubusercontent.com/Sergi-us/user.js/master/user.js" > "$arkenfox"
##    cat "$arkenfox" "$overrides" > "$userjs"
##    chown "$name:wheel" "$arkenfox" "$userjs"
##    # Installieren des Aktualisierungsskripts.
##    mkdir -p /usr/local/lib /etc/pacman.d/hooks
##    cp "/home/$name/.local/bin/arkenfox-auto-update" /usr/local/lib/
##    chown root:root /usr/local/lib/arkenfox-auto-update
##    chmod 755 /usr/local/lib/arkenfox-auto-update
##    # Konfiguration des pacman-Hooks zum automatischen Aktualisieren.
##    echo "[Trigger]
##Operation = Upgrade
##Type = Package
##Target = firefox
##Target = librewolf
##Target = librewolf-bin
##[Action]
##Description=Arkenfox user.js aktualisieren
##When=PostTransaction
##Depends=arkenfox-user.js
##Exec=/usr/local/lib/arkenfox-auto-update" > /etc/pacman.d/hooks/arkenfox.hook
##}

# === Installiert Librewolf-Add-ons manuell durch Herunterladen der XPI-Dateien TESTVERSION ===
##installffaddons(){
##    # Liste der zu installierenden Add-ons
##    addonlist="ublock-origin decentraleyes istilldontcareaboutcookies vimmatic darkreader keepassxc-browser styl-us nighttab"
##    addontmp="$(mktemp -d)"
##    trap "rm -fr $addontmp" HUP INT QUIT TERM PWR EXIT
##    IFS=' '
##    sudo -u "$name" mkdir -p "$pdir/extensions/"
##
##    # WICHTIG: In das temporäre Verzeichnis wechseln
##    cd "$addontmp" || return 1
##
##    for addon in $addonlist; do
##        if [ "$addon" = "ublock-origin" ]; then
##            addonurl="$(curl -sL https://api.github.com/repos/gorhill/uBlock/releases/latest | grep -E 'browser_download_url.*\.firefox\.xpi' | cut -d '"' -f 4)"
##        else
##            addonurl="$(curl --silent "https://addons.mozilla.org/en-US/firefox/addon/${addon}/" | grep -o 'https://addons.mozilla.org/firefox/downloads/file/[^"]*')"
##        fi
##        file="${addonurl##*/}"
##
##        # KORREKTUR: Entweder -O ohne Umleitung ODER -o mit Dateiname
##        sudo -u "$name" curl -LOs "$addonurl"
##
##        # Prüfen ob die Datei existiert
##        if [ -f "$file" ]; then
##            id="$(unzip -p "$file" manifest.json | grep "\"id\"" | head -1)"
##            id="${id%\"*}"
##            id="${id##*\"}"
##            mv "$file" "$pdir/extensions/$id.xpi"
##        else
##            echo "Warnung: Download von $addon fehlgeschlagen"
##        fi
##    done
##
##    chown -R "$name:wheel" "$pdir/extensions"
##    cd - >/dev/null
##}

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
trap 'rm -f /etc/sudoers.d/sarbs-temp' HUP INT QUIT TERM PWR EXIT
echo "%wheel ALL=(ALL) NOPASSWD: ALL
Defaults:%wheel,root runcwd=*" >/etc/sudoers.d/sarbs-temp

# Konfiguriert pacman mit zusätzlichen Optionen.
grep -q "ILoveCandy" /etc/pacman.conf || sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
sed -Ei "s/^#(ParallelDownloads).*/\1 = 10/;/^#Color$/s/#//" /etc/pacman.conf

# Setzt die Anzahl der Kompilierungskerne auf die Anzahl der verfügbaren CPUs.
sed -i "s/-j2/-j$(nproc)/;/^#MAKEFLAGS/s/^#//" /etc/makepkg.conf

# Installiert den AUR-Helper manuell.
manualinstall $aurhelper || error "Fehler beim Installieren des AUR-Helfers."

# AUR-Helper konfigurieren (Stellt sicher, dass Git-Pakete aus dem AUR automatisch aktualisiert werden)
sudo -u "$name" $aurhelper -Y --save --devel

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

# Dunst systemd-Service maskieren (wird über xinitrc gestartet)
## 2025-06-16 TODO Testen. dunst soll erst nach x11 starten.
whiptail --infobox "Dunst-Service wird deaktiviert (läuft über xinitrc)..." 7 60
sudo -u "$name" XDG_RUNTIME_DIR="/run/user/$(id -u "$name")" \
    systemctl --user mask dunst.service >/dev/null 2>&1

# Installiert Neovim-Plugins, falls sie noch nicht installiert sind.
# wurde durch Lazy.nvim ersetzt
# [ ! -f "/home/$name/.config/nvim/autoload/plug.vim" ] && vimplugininstall

# Instaliert Lazy.nvim
[ ! -d "/home/$name/.local/share/nvim/lazy" ] && lazyinstall

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

# Kernel-Einstellung: Erlaubt normalen Benutzern dmesg zu lesen (für System-Debugging)
mkdir -p /etc/sysctl.d
echo "kernel.dmesg_restrict = 0" > /etc/sysctl.d/dmesg.conf

# Entfernt alte sudoers-Regeln von vorherigen Installationen für sauberes Setup
rm -f /etc/sudoers.d/00-sarbs-wheel-can-sudo \
      /etc/sudoers.d/01-sarbs-cmds-without-password \
      /etc/sudoers.d/02-sarbs-visudo-editor \
      /etc/sudoers.d/00-larbs-* \
      /etc/sudoers.d/01-larbs-* \
      /etc/sudoers.d/02-larbs-*

# Konfiguriert sudo-Einstellungen für den Benutzer.
echo "%wheel ALL=(ALL:ALL) ALL" >/etc/sudoers.d/00-sarbs-wheel-can-sudo

# NOPASSWD-Befehle übersichtlich aufgelistet
cat >/etc/sudoers.d/01-sarbs-cmds-without-password <<'EOF'
%wheel ALL=(ALL:ALL) NOPASSWD: \
    /usr/bin/shutdown, \
    /usr/bin/reboot, \
    /usr/bin/systemctl suspend, \
    /usr/bin/systemctl hibernate, \
    /usr/bin/systemctl poweroff, \
    /usr/bin/wifi-menu, \
    /usr/bin/mount, \
    /usr/bin/umount, \
    /usr/bin/pacman -Syu, \
    /usr/bin/pacman -Syyu, \
    /usr/bin/pacman -Syyu --noconfirm, \
    /usr/bin/pacman -Syyuw --noconfirm, \
    /usr/bin/cryptsetup open *, \
    /usr/bin/cryptsetup close *, \
    /usr/bin/loadkeys *, \
    /usr/local/bin/tomb
EOF

# Setzt nvim als Standard-Editor für visudo (sicheres Editieren von sudoers)
echo "Defaults editor=/usr/bin/nvim" >/etc/sudoers.d/02-sarbs-visudo-editor

# Entfernt temporäre sudoers-Datei.
rm -f /etc/sudoers.d/sarbs-temp

if systemd-detect-virt -q; then
  cfg="/home/$name/.config/picom/picom.conf"
  [ -f "$cfg" ] && sed -i \
    -e 's/^backend.*/backend = "xrender";/' \
    -e 's/^vsync.*/vsync = false;/' \
    -e 's/^use-damage.*/use-damage = false;/' \
    -e 's/^unredir-if-possible.*/unredir-if-possible = false;/' \
    -e 's/^dithered-present.*/dithered-present = false;/' "$cfg"
fi

fc-cache -rv

# Zeigt die Abschlussmeldung an.
finalize
