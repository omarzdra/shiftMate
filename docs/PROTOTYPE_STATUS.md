# Stanje delujočega prototipa ShiftMate Business

Datum: **27. 11. 2026**. Projekt: RVIR, UM FERI. Razvoj je samostojen; uporabljena je obstoječa Git identiteta, brez izmišljenih sodelavcev ali spreminjanja datumov preteklih commitov.

## Povzetek in meja preverjanja

Iz začetne aplikacije z enim zaslonom je nastala implementacija prototipa za delodajalca in zaposlenega. **73 unit/widget testov je uspešnih, statična analiza je čista, Android debug APK se zgradi.** Integracijski test prijava–urnik–odjava je uspel na Android emulatorju s testnim repozitorijem. Migracija in varnostna pravila so preverjena v izoliranem PostgreSQL in v gostovanem CI PostgreSQL jobu.

**To še ni potrjena celotna omrežna demonstracija s Supabase.** Med dostopnimi projekti ni bilo projekta ShiftMate. Nobena oddaljena baza ni bila spremenjena, noben plačljiv projekt ni bil ustvarjen in noben skrivni ključ ni bil dodan aplikaciji. Končni lokalni APK je tehnična gradnja brez konfiguracije in ob zagonu pokaže »Priprava povezave«.

## Zahteve mejnika

| Zahteva | Stanje in dokaz |
|---|---|
| Osnovna struktura in navigacija | Implementirano; widget testi in integracijski test na Android emulatorju |
| Pomemben del poslovnih funkcionalnosti | Implementirani obe vlogi, podjetje, vabila, izmene, razpoložljivost, urnik, ure in izračuni |
| Začetna baza in spletna komunikacija | Shema/RLS/RPC in pravi Supabase klient implementirani; dejanski Auth/API še nepreverjen |
| Začetni avtomatizirani testi | 73/73 unit/widget; dodatno 1/1 integracijski test na napravi |
| Statična analiza | `flutter analyze`: No issues found |
| Avtomatizirana gradnja | Lokalni in gostovani debug APK zgrajena; APK artifact naložen |
| GitHub Actions | Objavljen workflow; rezultat gostovanega zagona je naveden spodaj |
| Zgodovina razvoja | Feature veja in ločeni logični commiti, brez prepisovanja zgodovine |
| Issues in Pull Requests | Obstoječe naloge pregledane; posodobitve in PR blokirani z dovoljenji, pripravljena ročna predaja |
| Dokumentacija dejanskega stanja | README, ta pregled, diagrami in navodila za demonstracijo |

Mejnik zahteva še dejanski razvojni Supabase projekt in demonstracijo omrežnega procesa. Dokler to ni izvedeno, vseh kriterijev ni mogoče označiti kot izpolnjenih.

## Implementirano

- Supabase registracija, prijava, odjava in obnova seje z SDK; validacija obrazcev, prikaz napak in zaščitena navigacija.
- Vloga iz članstva v bazi. Ob izteku seje ali izgubi članstva se odstrani tudi sklad zaščitenih poti.
- Ustvarjanje podjetja, enkratna e-poštno vezana vabila z veljavnostjo 7 dni in sprejem samo s potrjenim naslovom.
- Pregled zaposlenih ter urejanje imena, pozicije, urne postavke in največjega števila tedenskih ur.
- Oba podatkovna pregleda z obdobnimi seštevki, naslednjimi izmenami, nedodeljenimi izmenami in čakajočimi urami.
- Časovno urejeni seznami izmen, ustvarjanje, urejanje, brisanje in ročne dodelitve. Nočna izmena ima izrecni naslednji datum konca.
- Ustvarjanje, urejanje, brisanje razpoložljivosti oziroma nerazpoložljivosti in pregled ekipe.
- Samostojen constraint-based greedy algoritem s konfigurabilnimi utežmi, determinističnim razreševanjem izenačenj in razlogi za nepokrite izmene.
- Izbor obdobja, predlog urnika, ročni popravki in izrecna potrditev. Osnutek ne piše v bazo. Strežnik ponovno preveri pravila in različice vrstic ter shrani celoten predlog v eni transakciji.
- Evidenca intervala dela, odmora in opombe; pending/approved/rejected; odobritev oziroma zavrnitev z razlogom; filtriranje po osebi, statusu in obdobju.
- Informativno plačilo iz potrjenih ur × postavke ob oddaji. Ne predstavlja uradnega obračuna plače.
- Hive CE za podatkovni posnetek in gostoto prikaza, izolacija po projektu/uporabniku in brisanje osebnih podatkov ob odjavi. Offline branje brez zapisovanja.
- Nalaganje, napake, prazna stanja, ročna osvežitev in ponovni poskus. Paginacija Supabase seznamov po 200 vrstic.
- Primarni in sestavljeni tuji ključi, časovni in denarni CHECK pogoji, indeksi, RLS, omejene pravice in preverjeni RPC postopki.

## Delno implementirano in naslednji mejnik

| Področje | Preostalo |
|---|---|
| Supabase Auth/API | Nastavitev razvojnega projekta in dejanski preizkus z vsaj dvema računoma |
| Avtentikacija | Mobilni deep link za e-poštno potrditev in obnovitev gesla |
| Upravljanje ekipe | Deaktivacija zaposlenih, več podjetij na račun |
| Urnik | Koledarska dnevna/tedenska mreža; trajni osnutki in ločeno množično objavljanje |
| Razporejanje | UI za preference in uteži; globalna optimizacija ni cilj greedy algoritma |
| Delovne ure | Ponovna oddaja zavrnjene evidence, urejanje/popravljanje in polna zgodovina sprememb |
| Lokalni podatki | Šifriranje občutljivega predpomnilnika in dvosmerna offline sinhronizacija |
| Osveževanje | Ni Realtime naročnin; podatki se osvežijo na zahtevo oziroma po spremembi |
| Obvestila in izvoz | Lokalna/oddaljena obvestila, PDF in CSV niso implementirani |
| Izdaja | Debug APK; podpisana izdaja za trgovino in iOS gradnja nista preverjeni |

Omejitev ur uporablja UTC tedne od ponedeljka 00:00; prikaz je v lokalnem času naprave. Izračun obdobja izbira evidence po času začetka, ne deli jih med obdobji. Ena razpoložljiva časovna celota mora pokriti celotno izmeno; nerazpoložljivost jo preglasi. Potrditev podpira do 500 dodelitev v eni transakciji. Naknadna sprememba razpoložljivosti ne prekliče obstoječe dodelitve.

## Izvedena preverjanja

| Preverjanje | Rezultat | Okolje / podatki |
|---|---|---|
| `flutter pub get --enforce-lockfile` | Uspešno | Lokalni SDK Flutter 3.47.7 / Dart 3.13.5 |
| Format izvorne kode | 26 datotek, 0 sprememb pri končnem preverjanju | `dart format --output=none --set-exit-if-changed lib test integration_test` |
| `flutter analyze` | No issues found | Celoten projekt |
| `flutter test --coverage` | **73/73 uspešnih** | Unit/widget testi, testni repozitorij, dejanski začasni Hive |
| Pokritost vrstic | 875/1527 = **57,3 %** | `coverage/lcov.info`; ne predstavlja omrežne pokritosti |
| Integracijski test | **1/1 uspešen** | Android 17/API 37, emulator KV, debug; testni repozitorij |
| Postavitve | 4/4 uspešne kombinacije | 390/1200 širine, 1x/2x besedilo; dejanske pisave SDK |
| PostgreSQL migracija in RLS | Uspešno | Lokalni PostgreSQL WASM s simuliranim `auth.uid()` |
| SQL v CI | Uspešno | PostgreSQL 17 service, Auth seam, dejanske vloge in RLS |
| Demo SQL | Uspešno | Izolirani PostgreSQL: 5 članov, 11 izmen, 32 razpoložljivosti |
| Workflow lint | Uspešno | actionlint 1.7.7 |
| `flutter build apk --debug` | Uspešno | Tehnični APK brez Supabase povezave |
| Dejanski Supabase Auth/Data API | **Ni izvedeno** | ShiftMate projekt ni konfiguriran |

`dart format .` je bil izveden pred gradnjo. Po Gradle gradnji naleti na Windows napako `PathNotFoundException` v generirani dolgi poti `build/integration_test/.transforms/...`; izvorna koda se zato lokalno preverja z zgornjim enakovrednim izrecnim seznamom map. CI izvaja zahtevani `dart format --output=none --set-exit-if-changed .` pred gradnjo in je ta korak uspešno opravil. Lint pravil ali testov zaradi tega ni bilo izključenih.

Prvi integracijski poskus je po namestitvi obtičal na emulatorju, zagnanem iz snapshot stanja. Po hladnem zagonu brez brisanja podatkov je isti test prestal. Ne gre za dokaz delovanja na fizični napravi ali povezave s Supabase.

Ponovljivi ukazi so v README. Lokalni dnevniki so v prezrti mapi `build/verification-*.log`, posnetki pa v `build/visual/`.

## APK in GitHub Actions

Lokalni APK: `build/app/outputs/flutter-apk/app-debug.apk` (202.161.392 bajtov). Podpis je preverjen z apksigner (v2, en podpisnik). Običajni APK je ponovno nameščen na emulator in njegova aktivnost se uspešno zažene. Za povezan APK vpiši javno konfiguracijo in uporabi `flutter build apk --debug --dart-define-from-file=config.local.json`.

[Gostovani zagon 46018722397](https://github.com/omarzdra/shiftMate/actions/runs/46018722397) je sprožen s push na commit `6a747fa82fde6c9d153039b8ad2f136dbf6f65d4`. Celotni zagon je uspešen: PostgreSQL job, formatiranje, analiza, 73 testov, gradnja APK in nalaganje artifactov. To potrjuje tudi gostovano gradnjo, ne potrjuje pa dejanske Supabase povezave. Dokumentacijski commit lahko sproži dodatni zagon z nespremenjeno kodo aplikacije.

Workflow uporablja obe repository Variables/Secrets `SUPABASE_URL` in `SUPABASE_PUBLISHABLE_KEY`. Brez obeh nastane tehnični APK z ustreznim `BUILD_STATUS.txt`; ena manjkajoča vrednost povzroči neuspešno gradnjo. Testi ne potrebujejo produkcijskih skrivnosti.

## Veja, commiti, Issues in PR

Veja: [feature/working-prototype](https://github.com/omarzdra/shiftMate/tree/feature/working-prototype), objavljena brez force push ali združevanja v main.

- `7e8e024` – podatkovna shema, RLS, RPC, SQL testi in demo podatki.
- `7e869ab` – modeli, podatkovni dostop, Provider, Hive CE in razporejevalnik z unit testi.
- `ecd8e48` – zasloni, obrazci, zaščitena navigacija, widget testi in integracijski test.
- `6a747fa` – PostgreSQL in Flutter CI, APK artifact in konfiguracija okolja.
- Dokumentacija se predaja v ločenem `docs:` commitu; točen seznam: `git log main..feature/working-prototype --oneline`.

Pregledani so obstoječi Issues #1–#12. Ni bilo odprtih PR. Ustvarjanje draft PR in posodobitev Issue #9 prek vtičnika sta bila zavrnjena z HTTP 403. CLI ni prijavljen. Samodejni varnostni pregled je zavrnil predlog prenosa obstoječih Git poverilnic v CLI; predlagani ukaz se ni izvedel. **PR ni bil ustvarjen in noben Issue ni bil spremenjen ali zaprt.**

[Primerjalna povezava za PR](https://github.com/omarzdra/shiftMate/compare/main...feature/working-prototype?expand=1), [pripravljen opis](PR_DESCRIPTION.md), [konkretni predlogi za Issues #3–#12](GITHUB_HANDOFF.md). Vse širše naloge ostanejo odprte do preverjanja njihovih preostalih kriterijev.

## Spremenjene in ustvarjene datoteke

- Konfiguracija: `pubspec.yaml`, `pubspec.lock`, `.gitignore`, `config.example.json`, `.github/workflows/flutter-ci.yml`, `android/app/src/main/AndroidManifest.xml`.
- Aplikacija: `lib/main.dart`, `lib/core/theme.dart`, `lib/models/domain.dart`, `lib/providers/app_state.dart`, `lib/providers/scheduling_state.dart`, `lib/repositories/workspace_repository.dart`, `lib/repositories/supabase_repository.dart`.
- Poslovne storitve: `lib/services/validation.dart`, `scheduling_service.dart`, `dashboard_summary.dart`, `local_cache.dart`.
- UI: `lib/screens/auth_screen.dart`, `editors.dart`, `workspace_screen.dart`, `scheduling_screen.dart`, `lib/widgets/common.dart`.
- Testi: `test/fixtures.dart`, `domain_test.dart`, `scheduling_test.dart`, `scheduling_state_test.dart`, `app_state_test.dart`, `dashboard_test.dart`, `hive_cache_test.dart`, `layout_test.dart`, `widget_test.dart`, `integration_test/session_test.dart`.
- Baza: `supabase/.gitignore`, `supabase/config.jsonc`, `supabase/migrations/20261127134209_prototype.sql`, `supabase/tests/auth_stub.sql`, `supabase/tests/rls.sql`, `supabase/demo.sql`.
- Dokumentacija: `README.md`, `docs/PROTOTYPE_STATUS.md`, `docs/GITHUB_HANDOFF.md`, `docs/PR_DESCRIPTION.md`.

Obstoječa uporabnikova sprememba `dokumentacija/prototipna_dokumentacija.md` (dodana povezava do repozitorija) je ostala nedotaknjena in ni vključena v nove commite.

## Ročna priprava in demonstracija

1. Ustvari ločen razvojni Supabase projekt, uporabi migracijo in nastavi e-pošto/geslo ter potrditev naslova. `private` ne izpostavljaj v Data API.
2. Nastavi `config.local.json` po `config.example.json` in zaženi povezano aplikacijo. Nikoli ne uporabljaj service_role ključa v Flutterju.
3. Za demonstracijo iz nič registriraj delodajalca, potrdi e-pošto, se prijavi in ustvari podjetje. Povabi štiri zaposlene z njihovimi naslovi, pozicijami in postavkami; vsak naj se registrira, potrdi naslov in sprejme lastno kodo vabila.
4. Vsak zaposleni naj doda razpoložljivost za naslednje dni. Delodajalec jo vidi pod Zaposleni → Razpoložljivost ekipe.
5. Delodajalec naj ustvari več nedodeljenih izmen, vključno z izmeno brez ustreznega kandidata, odpre Samodejni urnik in izbere obdobje.
6. Preveri predlagane dodelitve in razloge nepokritih izmen; ročno spremeni predlog in ga potrdi. Zaposleni naj osveži Moje izmene in preveri dodelitev.
7. Za preizkus oddaje uporabi že zaključeno izmeno in ustrezno razpoložljivost v preteklosti. Zaposleni odda dejanski interval, odmor in opombo pod Delovne ure. Prihodnjih ur ni mogoče oddati.
8. Delodajalec naj pod Delovne ure izbere osebo/status, odobri evidenco ali jo zavrne z razlogom.
9. Zaposleni naj osveži pregled in izbere ustrezno obdobje; vidi potrjene ure in informativno plačilo. Ponovni zagon povezane aplikacije mora obnoviti sejo in pridobiti ohranjene podatke.
10. Po uspešnem nalaganju izklopi povezavo, ročno osveži in preveri oznako predpomnilnika. Zapisovanje je blokirano. Po odjavi na isti napravi ni prikaza podatkov prejšnjega uporabnika.

Za hitrejši ponovljivi prikaz najprej v razvojnem Auth ustvari in potrdi račune `owner@shiftmate.example.test`, `ana@shiftmate.example.test`, `bor@shiftmate.example.test`, `cilka@shiftmate.example.test`, `denis@shiftmate.example.test`. Gesla izberi zunaj repozitorija. V SQL Editorju **tega razvojnega projekta** izvedi `SET shiftmate.allow_demo = 'yes';` in nato `supabase/demo.sql`. Seed zavrne obstoječa članstva in ne briše podatkov. Pripravi podjetje Kavarna Jutro · DEMO, 4 zaposlene, 10 prihodnjih nedodeljenih izmen in eno včerajšnjo dodeljeno izmeno za oddajo ur.

Ti naslovi so rezervirani primeri in praviloma ne prejemajo e-pošte; za seed jih ustvari kot že potrjene testne račune v Auth dashboardu. Za demonstracijo dejanske e-poštne registracije/vabila uporabi ločene testne predale, ki jih nadzoruješ. Seed ne dokazuje dostave e-pošte.

## Preostali pogoji za zaključek mejnika

- Dejanski preizkus migracije, Auth/API, pravic in celotne poti v izbranem razvojnem Supabase projektu.
- Prenos artifacta uspešnega gostovanega workflowa; pri povezani gradnji še vnos javne Supabase konfiguracije.
- Odprtje draft PR in posodobitev obstoječih Issues prek uporabnikovega dovoljenega GitHub dostopa.

Za odobritev uporabe GitHub CLI je potreben uporabnikov izrecni dostop oziroma samostojna prijava z `gh auth login`. To ni ovira za lokalno kodo, teste, APK ali objavljeno feature vejo.
