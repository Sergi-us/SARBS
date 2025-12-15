# 🚀 SARBS - Suckless Auto-Rice Bootstrapping Scripts

**Automatisierte Installation eines kompletten Suckless-basierten Linux-Desktops**

> **🔄 Umzug zu Codeberg**: Die aktive Entwicklung und Kollaboration findet jetzt auf [Codeberg](https://codeberg.org/Sergius/SARBS) statt. GitHub dient nur als Mirror.
> 
> **🌐 Homepage**: [sarbs.xyz](https://sarbs.xyz/sarbs/) - Dokumentation, Anleitungen und Support

Ein effizientes Shell-Skript, das ein voll funktionsfähiges, auf einem Auto-Tiling Fenstermanager basierendes System auf Arch Linux (oder Derivaten) installiert - ohne die Routine manueller Installationsprozesse und Konfigurationen.

## 🎯 Was ist SARBS?

<p align="center">
    <img
      src="https://codeberg.org/Sergius/SARBS/raw/branch/main/SARBS-Screenshot-1.png"
      alt="Vorschau von SARBS"
      width="800"
    >
</p>

SARBS installiert und konfiguriert automatisch:
- ✅ **dwm** - Dynamic Window Manager mit nützlichen Patches
- ✅ **st** - Simple Terminal mit Features
- ✅ **dmenu** - Application Launcher
- ✅ **dwmblocks** - Modulare Statusbar
- ✅ **surf + tabbed** - Minimalistischer Browser
- ✅ **dotfiles** - Komplette Konfiguration
- ✅ **Alle nötigen Programme** - Aus einer zentralen [progs.csv](https://codeberg.org/Sergius/SARBS/src/branch/main/progs.csv)

### Philosophie

Folgt der [Suckless-Philosophie](https://suckless.org/philosophy/):
- **Einfachheit** - Code ist die Dokumentation
- **Minimalismus** - Nur was nötig ist
- **Tastaturzentriert** - Effiziente Navigation
- **Anpassbarkeit** - Volle Kontrolle durch Quellcode

## ⚡ Installation

### Schnellstart

Auf eine frische Arch Linux Installation, als **root** angemeldet:

```bash
curl -LO https://sarbs.xyz/sarbs.sh
sh sarbs.sh
```

### Was passiert?

1. **Benutzer-Setup** - Legt neuen Benutzer an oder nutzt bestehenden
2. **System-Update** - Aktualisiert Arch Linux
3. **AUR-Helper** - Installiert `yay` für AUR-Pakete
4. **Programme** - Installiert alle Programme aus [progs.csv](https://codeberg.org/Sergius/SARBS/src/branch/main/progs.csv)
5. **Suckless-Tools** - Klont und baut alle Repositories
6. **dotfiles** - Richtet Konfiguration ein
7. **Fertig!** - System bereit zum Neustart

### Nach der Installation

1. **Neustart**: `reboot`
2. **TTY-Login**: Mit dem erstellten Benutzernamen und Passwort
3. **dwm starten**: Automatisch oder mit `startx`
4. **Hilfe aufrufen**: <kbd>Super+F1</kbd> - Zeigt die Dokumentation (benötigt zathura)

## 📦 Installierte Repositories

SARBS klont und installiert automatisch:

- **[dotfiles](https://codeberg.org/Sergius/dotfiles)** - Konfigurationsdateien
- **[dwm](https://codeberg.org/Sergius/dwm)** - Window Manager
- **[dmenu](https://codeberg.org/Sergius/dmenu)** - Application Launcher
- **[dwmblocks-async](https://codeberg.org/Sergius/dwmblocks-async)** - Statusbar
- **[st](https://codeberg.org/Sergius/st)** - Terminal Emulator
- **[surf](https://codeberg.org/Sergius/surf)** - Web Browser
- **[tabbed](https://codeberg.org/Sergius/tabbed)** - Tab Interface

## 🛠️ Features & Details

### Sicherheit

- **UFW Firewall** - Automatisch konfiguriert (deny incoming, allow outgoing)
- **nftables Backend** - Modernes Firewall-Backend
- **Sichere Defaults** - Minimale Angriffsfläche

### Logging

- **Installationslog** - Wird im Home-Verzeichnis des root-Nutzers abgelegt
- **Fehlerbehandlung** - Detaillierte Fehlermeldungen bei Problemen

### Branch-Support

- **Flexible Git-Branches** - Automatische Erkennung von `main` und `master`
- **Aktueller Branch** - Wird vor dem Klonen abgefragt

## 🔧 Anpassung

### Eigene Programme hinzufügen

Bearbeite [progs.csv](https://codeberg.org/Sergius/SARBS/src/branch/main/progs.csv):

```csv
#TAG,NAME IN REPO (or git url),PURPOSE (should be a verb phrase to sound right while installing)
,neovim,"ist der beste Editor"
A,yay-bin,"ist ein AUR helper"
G,https://github.com/user/repo,"wird aus Git installiert"
```

**Tags:**
- *(leer)* - Pacman-Paket
- `A` - AUR-Paket (über yay)
- `G` - Git-Repository

### SARBS forken

```bash
# Fork auf Codeberg erstellen, dann:
git clone https://codeberg.org/Dein-Username/SARBS.git
cd SARBS
# Anpassungen vornehmen...
```

### SARBS wiederherstellen

SARBS kann auch verwendet werden, um eine bestehende Installation wiederherzustellen:

```bash
sh sarbs.sh
# Wähle bestehenden Benutzer
# Konfiguration wird überschrieben
```

## 🎓 Nutzung & Workflow

### Tastaturzentriert

Das gesamte System ist für Tastaturnutzung optimiert:
- **dwm** - Tiling Window Manager ohne Maus
- **Vim-Bindings** - Überall wo möglich
- **dmenu** - Schneller Programm-Launcher
- **Deutsche Tastatur** - Optimiert für QWERTZ

### Dokumentation

Die komplette Systemdokumentation ist in `sarbs.mom` verfügbar:
- <kbd>Super+F1</kbd> in dwm öffnet die Hilfe
- Alle Keybindings dokumentiert
- Workflow-Tipps und Tricks

### Lernkurve

- **Tag 1**: Navigation lernen, Keybindings verinnerlichen
- **Tag 7**: Effizientes Arbeiten ohne Maus
- **Tag 30**: Produktivitäts-Boost durch Tastatur-Workflows

## 🚧 Entwicklungsfortschritt

### ✅ Fertig
- UFW Konfiguration mit Standard-Regeln (deny incoming, allow outgoing)
- nftables als Backend
- Logdatei im Home-Verzeichnis des root-Nutzers
- Branch-Erkennung für Git-Repositories (master/main)

### 🔜 Geplant
- Bessere Fehlerbehandlung bei Netzwerkproblemen
- Optionale Desktop-Umgebungen zur Auswahl
- Post-Install Hook-System für eigene Skripte

## 📚 Komponenten-Dokumentation

Jede Komponente hat eine eigene README:

- **[dwm README](README-dwm.md)** - Window Manager Details
- **[st README](README-st.md)** - Terminal Features
- **[dmenu README](README-dmenu.md)** - Launcher Konfiguration
- **[dwmblocks README](README-dwmblocks-async.md)** - Statusbar Setup
- **[surf README](README-surf.md)** - Browser Nutzung
- **[tabbed README](README-tabbed.md)** - Tab Interface
- **[dotfiles README](README-dotfiles.md)** - Konfiguration Details

## 🤝 Credits & Inspiration

- **[Luke Smith](https://github.com/LukeSmithxyz/LARBS)** - Original LARBS-Inspiration
- **[suckless.org](https://suckless.org/)** - Software und Philosophie
- **Arch Linux Community** - Beste Linux-Distribution

## 💬 Support & Community

### Hilfe bekommen

- **[Codeberg Issues](https://codeberg.org/Sergius/SARBS/issues)** - Bug Reports & Feature Requests
- **[Homepage](https://sarbs.xyz/kontakt/)** - Kontaktformular
- **[Dokumentation](https://sarbs.xyz/sarbs/)** - Ausführliche Anleitungen

### Beitragen

Pull Requests sind willkommen! Bitte:
1. Fork auf Codeberg erstellen
2. Feature-Branch erstellen
3. Änderungen committen
4. Pull Request öffnen

## 📄 Lizenz

Siehe [LICENSE](LICENSE) Datei.

---

**📧 Kontakt**:
- [YouTube Kanal](https://www.youtube.com/@5ergius)
- [Codeberg Issues](https://codeberg.org/Sergius/SARBS/issues)
- [GitHub Issues](https://github.com/Sergi-us/SARBS/issues) (Mirror)
- [Homepage & Kontakt](https://sarbs.xyz/kontakt/)

 ---

**🌟 Gefällt dir SARBS?** - Star das Projekt auf [Codeberg](https://codeberg.org/Sergius/SARBS)!
