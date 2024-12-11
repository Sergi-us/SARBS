# Die deutschsprachigen Voidrice [SARBS](https://sarbs.sergius.xyz/) Dotfiles

## Serigius' Arch Rice Build System (SARBS)

Dieses SARBS-Repo ist ein Fork von [Luke Smith](https://github.com/LukeSmithxyz/voidrice). Es verschreibt sich
ausdrücklich
seiner Philosophie und ist als Community-Projekt für deutschsprachige Nutzer gedacht.

SARBS wird zwar auf GitHub entwickelt und hier findet die Kollaboration statt, aber bereitgestellt wird es auf meinen
Server unter https://sarbs.sergius.xyz.

Dieses Repo beinhaltet die Konfigurations- und Skriptdateien, die in [SARBS](https://sarbs.sergius.xyz) mitgeliefert
werden.

- Nützliche Skripte in `~/.local/bin/`
- Einstellungen für:
    - `vim/nvim` (Texteditor)
    - `zsh` (Shell)
    - `lf` (Dateimanager)
    - `mpd/ncmpcpp` (Musik)
    - `nsxiv` (Bildbetrachter)
    - `mpv` (Audio- / Video-Wiedergabe)
    - Weitere tools, wie z. B. `xdg`, `inputrc` ...
- Was möglich ist, wird im `~` (HOME-Verzeichnis) optimiert/konfiguriert:
    - Konfigurationsdateien befinden sich in: `~/.config/`.
    - Einige Umgebungsvariablen sind in `~/.zprofile` gesetzt, um sie nach `~/.config/` zu verschieben.
- Lesezeichen in Textdateien werden von verschiedenen Skripten genutzt (z. B: `~/.local/bin/shortcuts`).
    - Die Datei mit Lesezeichen befindet sich in `~/.config/shell/bm-files`.
    - Die Verzeichnisse mit den Lesezeichen befindet sich in `~/.config/shell/bm-dirs`.

## Nutzung

Diese Konfigurationsdateien funktionieren unabhängig voneinander mit verschiedenen suckless-Tools, die in SARBS integriert sind. Dennoch empfehle ich, SARBS als Ganzes zu nutzen und GitHub als reine Kollaborations- und Entwicklungsplattform zu betrachten.

- [dwm](https://github.com/Sergi-us/dwm) (Fenstermanager / WM (window manager))
- [dwmblocks](https://github.com/Sergi-us/dwmblocks) (Status-Anzeige)
- [st](https://github.com/Sergi-us/st) (Terminal Emulator)

Ausprobieren solltest ihr auch:

- [mutt-wizard](https://github.com/lukesmithxyz/mutt-wizard). Er wird auch in diesem Setup unterstützt. Es handelt sich
  beim Mutt-Wizard um ein einfach zu installierender E-Mail-Client für die Konsole, der unabhängig vom E-Mail-Provider
  funktioniert. Er ist ebenfalls in den Dotfiles enthalten

## Installation von SARBS

Benutze das [SARBS](https://sarbs.sergius.xyz)-Skript, um alles automatisch zu installieren.

Führe dazu auf einem frisch installierten Arch oder Artix folgende Befehle aus:

```sh
curl -LO https://sarbs.sergius.xyz/sarbs.sh
```

```sh
sh sarbs.sh
```

[SARBS](https://sarbs.sergius.xyz) führt dich durch den Installationsprozess und legt dabei einen neuen Benutzer an.

**Hinweis** Aktuell muss man das Skript 2x laufen lassen, um sich anmelden zu können.

Nachdem Abschluss der Installation solltest du dein System neu starten. Anschließend kannst du dich einloggen. Mit
`MOD`+`F1` kannst du ein Hilfe-Dokument aufrufen. Viel Spaß &#128516;.

Du kannst auch die Repo-Dateien direkt in dein HOME-Verzeichnis klonen und die Abhängigkeiten
installieren: [dependencies](https://github.com/LukeSmithxyz/LARBS/blob/master/static/progs.csv).

## Standard Desktop-Hintergrund

Thomas Thiemeyer's *The Road to Samarkand* ([fb](https://www.facebook.com/t.thiemeyer/), [insta](https://www.instagram.com/tthiemeyer/), [shop](https://www.redbubble.com/de/people/TThiemeyer/shop))

## TODO: scripy PGP-Erstellung klären

[Kommentar]: # (Meinst du hier scripy oder scrcpy? scrcpy ist ein Tool, um das Handy zu steuern. scripy ist mir unbekannt.)

Mit [scrcpy](https://github.com/Genymobile/scrcpy) kann man auf sein Android-Handy zugreifen. Es ist für SARBS zwar
nicht notwendig, jedoch nutze ich es, um mit meinem Handy zu interagieren. Bei der Installation von SARBS ist mir
aufgefallen, dass **identische** PGP-Schlüssel im `~/.android`-Verzeichnis erstellt werden. Solange das ungeklärt ist,
bleibt scripy draußen und muss manuell installiert werden.

*Mir ist weder bekannt, welches Tool die PGP-Schlüssel erstellt noch welche Abhängigkeiten bestehen. Das `~/.android`
-Verzeichnis und der darin enthaltene PGP-Schlüssel scheinen für die Funktionalität nicht relevant zu sein, da nach
einem Löschen des Verzeichnisses scrcpy weiterhin funktioniert.*
