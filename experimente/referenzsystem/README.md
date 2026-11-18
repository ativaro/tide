# Historische TIDE-0.5-Referenz

Das [Quellenarchiv](quellen-0.5.tar.xz) enthält den früheren Python-Interpreter, seine Terminal- und Dokumenthosts, die vier Integrationstestdateien und die damaligen Paketmetadaten. Beim Archivieren wurden die Dateien nach dem Entpacken byteweise mit den Originalen verglichen, einschließlich der Ziele beider symbolischer Links. Generierte Bytecode-Caches wurden ausgelassen. Die SHA-256-Prüfsumme des Archivs ist `565957d974d5a2b5d146ac4ffbca823692b61699f391095e30588987078e6ae3`.

Zum Nachlesen eines alten Vergleichs lässt sich der damalige Stand aus dem Projektstamm in ein temporäres Verzeichnis entpacken. Der historische Link `apps` verweist dort wie zuvor auf die gewählten Anwendungsquellen.

```sh
stand=$(mktemp -d)
mkdir -p "$stand/experimente/referenzsystem"
ln -s "$PWD/apps" "$stand/apps"
tar -xJf experimente/referenzsystem/quellen-0.5.tar.xz -C "$stand/experimente/referenzsystem"
```

Der aktuelle Einstieg ist `./tide` im Projektstamm. `make test` baut die Tests aus TIDE-Quellen, `make check-no-python` prüft den vollständigen Neubau und das installierte Paket. [Build und Installation](../../README.md#installation-und-prüfung)
