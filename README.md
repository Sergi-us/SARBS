# Suckless Auto-Rice Bootstrapping Scripts

SARBS ist ein effizientes Shell-Skript, das ein voll funktionsfähiges, auf einem Auto-tilling Fenstermanager basierendes System auf Arch-Linux (oder Derivaten) installiert, ohne die Routine manueller (Nach)installationsprozesse und Konfigurationen.

TODO Vim bezug ergänzen... Die Efficiens der nutzung über die Tastatur ansprechen und die Deutsche tastatur abfucken

- [dotfiles](https://codeberg.org/Sergius/dotfiles.git)


Das Installation-Skript zieht zusätzliche Repositories:
- [dwm](https://github.com/Sergi-us/dwm.git) (window manager)
- [dmenu](https://github.com/Sergi-us/dmenu.git)
- [dwmblocks](https://github.com/Sergi-us/dwmblocks.git) (statusbar)
- [st](https://codeberg.org/Sergius/st.git) (terminal emulator)
- [surf](https://github.com/Sergi-us/surf.git)

Es werden Programme aus der [progs.csv](https://codeberg.org/Sergius/SARBS/src/branch/main/progs.csv) installiert. Die Konfiguration ist in den [dotfiles](https://codeberg.org/Sergius/dotfiles.git) ...

## Suckless [Philosophie und Grundprinzipien](https://suckless.org/philosophy/)

## Nutzung

Diese Konfigurationsdateien funktionieren unabhängig mit verschiedenen Suckless Tools die in SARBS integriert sind, dennoch empfehle ich SARBS als Ganzes zu nutzen, und GitHub als reine Kollaboration- und Entwicklungs-platform zu betrachten.

## Installation von SARBS

Benutze [SARBS](https://sarbs.xyz/sarbs/) um alles automatisch zu installieren:

auf eine frische Arch-Linux Installation, als root angemeldet:



```bash
curl -LO https://sarbs.xyz/sarbs.sh
sh sarbs.sh
```

SARBS führt dich durch den installationsprozess und legt einen neuen Benutzer an oder überschreibt die Konfiguration von einen Bestehenden Nutzer (nützlich um SARBS wiederherzustellen)

Wenn der Installationsprozess abgeschlossen ist, kannst du dein System neu starten und dich im TTY-1 mit dem zuvor erstellten Nutzernamen und Passwort einloggen.
Mit `MOD`+`F1` kannst ein Hilfe-Dokument aufrufen. Viel Spaß

## Entwicklungsfortschritt
- UFW Konfiguration und Standard-Regeln hinzugefügt(deny incoming und allow outgoing). nftabels wird als Backend gesetzt.
- es wird eine Logdatei im Home-Verzeichnis des root Nutzers abgelegt.
- die Installationsroutine für Programme die aus Git Repositories installiert werden wurde auf unterschiedliche Branches angepasst. Es wird der aktuelle Branch vor dem klonen abgefragt. (Master und Main Thematik)
