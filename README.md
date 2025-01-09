# The Voidrice [SARBS](https://sarbs.sergius.xyz/)'s Dotfiles)
ist ein Fork von [Luke Smith](https://github.com/LukeSmithxyz/voidrice) unter einbehaltung der Philosophie und als Community projekt für Deutschsprachige Nutzer.


SARBS wird zwar auf GitHub entwickelt und hier findet die kolaboration stadt aber bereitgestellt wird es auf meinen Server unter https://sarbs.sergius.xyz

In diesem Repo sind die Konfigurations und Skriptdateien die in [SARBS](https://sarbs.sergius.xyz) mitgeliefert werden.

- Nützliche Skripte in `~/.local/bin/`
- Einstellungen für:
	- vim/nvim (text Editor)
	- zsh (shell)
	- lf (Datei Manager)
	- mpd/ncmpcpp (Musik)
	- nsxiv (image/gif Viewer)
	- mpv (Video Player)
	- anderes zeug wie `xdg` standard tools, inputrc und mehr...
- Was möglich ist wird im `~` (HOME Verzeichniss) optimiert/konfiguriert:
	- Konfigurationsdateien sind in: `~/.config/`
	- Einige Umgebungsvariablen sind in `~/.zprofile` gesetzt um diese nach `~/.config/` zu verschieben
- Bookmarks in Textfiles werden von verschiedenen Skripten benutzt (z.B: `~/.local/bin/shortcuts`)
	- Datein bookmarks in `~/.config/shell/bm-files`
	- Verzeichnisse bookmarks in `~/.config/shell/bm-dirs`

## Nutzung

Diese Konfigurationsdateien funktionieren unabhängig mit verschiedenen suckless Tools die in SARBS intergriert sind, dennoch empfehle ich SARBS als Ganzes zu nutzen, und GitHub als reine Kollaborations- und Entwicklungs-platform zu betrachten.

- [dwm](https://github.com/Sergi-us/dwm) (window manager)
- [dwmblocks](https://github.com/Sergi-us/dwmblocks) (statusbar)
- [st](https://github.com/Sergi-us/st) (terminal emulator)

_I also recommend trying out
[mutt-wizard](https://github.com/lukesmithxyz/mutt-wizard), which additionally
works with this setup. It gives you an easy-to-install terminal-based email
client regardless of your email provider. It is integrated into these dotfiles
as well._

## Installation von SARBS

Benutze [SARBS](https://sarbs.sergius.xyz) um alles automatisch zu instalieren:

auf eiene frisch instalierte Arch oder Artix folgende befehle ausführen:

```
curl -LO https://sarbs.sergius.xyz/sarbs.sh
```

```
sh sarbs.sh
```

SARBS fürht dich durch den installationsprozess und legt einen neuen benutzer dabei an.

**Hinweis** Aktuell muss man das skript 2x laufen lassen um sich anmelden zu können

wenn der Installationsprozell abgeschlossen ist, kannst du dein System neu starten und dich einloggen, mit `MOD`+`F1` kannst ein Hilfe-Dokument aufrufen. Enjoy ;-)

_or clone the repo files directly to your home directory and install the
[dependencies](https://github.com/LukeSmithxyz/LARBS/blob/master/static/progs.csv)._

## Standard Desktop Hintergrund

Thomas Thiemeyer's *The Road to Samarkand* ([fb](https://www.facebook.com/t.thiemeyer/), [insta](https://www.instagram.com/tthiemeyer/), [shop](https://www.redbubble.com/de/people/TThiemeyer/shop))

## Verlauf
Ich habe noch keine Versionierung aber notire hier den Entwicklungsfortschritt

- es wird eine Logdatei im Homeverzeichniss des root Nutzers abgelegt.
- die Installationsroutine für Programme die aus Git Repositories instaliert werden wurde auf unterschiedliche Branches angepasst. Es wird der aktuelle Branch vor dem clonen abgefragt. (Master und Main Thematik)
