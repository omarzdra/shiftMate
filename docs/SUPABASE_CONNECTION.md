# Povezava z razvojnim Supabase projektom

Projekt **shiftMate** (`vmayutnfvhqveztgtudu`, regija `eu-west-1`) je povezan z aplikacijo.

- API: `https://vmayutnfvhqveztgtudu.supabase.co`
- [Nadzorna plošča projekta](https://supabase.com/dashboard/project/vmayutnfvhqveztgtudu)
- Lokalni URL in aktivni javni publishable ključ sta v `config.local.json`, ki je izključen iz Git.
- Aplikacija ne vsebuje service_role ali drugega skrivnega ključa.

## Zagon

V VS Code izberi konfiguracijo **ShiftMate · Supabase** in zaženi aplikacijo. Iz terminala:

```bash
flutter run --dart-define-from-file=config.local.json
```

Povezan Android APK:

```bash
flutter build apk --debug --dart-define-from-file=config.local.json
```

Datoteka je v `build/app/outputs/flutter-apk/app-debug.apk`. Navadni `flutter run` brez konfiguracije še vedno prikaže navodila za pripravo povezave.

Na drugi napravi oziroma svežem klonu kopiraj `config.example.json` v `config.local.json` in javne vrednosti pridobi v nastavitvah tega projekta.

## Uporabljeni migraciji

1. `20261127213651_prototype.sql` — sedem tabel, RLS, pravice, validacija in RPC.
2. `20261127213859_complete_hosted_setup.sql` — indeksi za sestavljene tuje ključe in omejitev neposrednega API klica privzete funkcije `rls_auto_enable`.

Migraciji sta že uporabljeni; ne izvajaj ju znova. Imeni datotek ustrezata različicama, ki ju je ob uporabi določil Supabase. Oddaljena zgodovina migracij ni bila ročno prepisana. Drugih projektov v računu nismo spreminjali.

## Preverjeno na dejanskem projektu

- Vseh sedem aplikacijskih tabel ima omogočen RLS.
- Celoten SQL test `supabase/tests/rls.sql` je prestal na gostovani bazi. Preverja izolacijo podjetij, pravice, varnost vabil in potrjevanja ur ter atomarnost in zastarelost predloga urnika. Uporablja transakcijo z `ROLLBACK`; testni računi in poslovni podatki niso ostali v bazi.
- Auth health endpoint vrne HTTP 200; e-poštna prijava in registracija sta omogočeni, samodejna potrditev e-pošte je izključena.
- Anonimna REST zahtevka za `shifts` in `business_members` vrneta HTTP 401.
- Supabase security advisor po migracijah ne poroča o varnostnih opozorilih. Performance advisor opozarja le na indekse, ki v novi prazni bazi še niso bili uporabljeni.

SQL test uporablja vloge in `auth.uid()` dejanskega Supabase, vendar ne opravi prijave prek Auth strežnika. Celotna pot registracija–potrditev e-pošte–prijava–vabilo–izmena–evidenca še potrebuje preizkus z uporabnikovimi testnimi predali. Pripravljenost API-ja in SQL testi niso predstavljeni kot preverjena dostava e-pošte ali popoln uporabniški proces.

## Prva uporaba

1. V aplikaciji registriraj račun z e-pošto, do katere imaš dostop.
2. Potrdi naslov prek prejete povezave in se vrni v aplikacijo na prijavo.
3. Ustvari podjetje ali sprejmi kodo vabila.

Potrjevanje e-pošte ostaja omogočeno. Obstoječe varnostne nastavitve Auth niso bile oslabljene; demonstracijski računi in gesla niso bili ustvarjeni.

## GitHub Actions

Lokalna konfiguracija se namenoma ne objavlja. Za povezane APK iz GitHub Actions je treba v repository Variables nastaviti `SUPABASE_URL` in `SUPABASE_PUBLISHABLE_KEY` za ta projekt. Brez njiju workflow še vedno izdela tehnični APK, kot je opisano v README. Lokalni APK, zgrajen z zgornjim ukazom, vsebuje povezavo na shiftMate.
