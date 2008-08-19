Die makefile ermöglicht das kompilieren unter Linux für Linux und auch Windows.


Zum kompilieren werden benötigt:
flex
gcc
i486-mingw32-gcc

Zum packen:
tar
zip

Für den upload:
ftp
(und die Zugangsdaten für den Server)


Anleitung:
Zum kompilieren: "make"
Zum packen: "make packages"
Zum hochladen: "make upload"


Anmerkungen:
Bei jeder neuen Version sollte der Versionsstring in der Quelldatei, die VERSION in der makefile und die Dateinamen in der Datei upload geändert werden.
