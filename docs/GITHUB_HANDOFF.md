# Posodobitve GitHub Issues in predaja PR

Stanje 27. 11. 2026. Po uporabnikovi izrecni odobritvi je bil ustvarjen draft PR #13 in posodobljeni so bili Issues #3–#12. Spodaj je vsebinski pregled dodanih posodobitev. Obstoječi opisi in kriteriji so ohranjeni; označene so samo preverjene naloge. Noben Issue ni bil zaprt ali ponovno odprt.

Veja: `feature/working-prototype`. [Draft PR #13](https://github.com/omarzdra/shiftMate/pull/13): **feat: delujoči prototip ShiftMate z varnim razporejanjem**. Opis: [PR_DESCRIPTION.md](PR_DESCRIPTION.md). PR naj ostane draft do dejanskega Supabase preizkusa; main ni bil spremenjen.

## #3 – CI

Workflow ima PostgreSQL preverjanje RLS, Flutter format, analizo, teste s pokritostjo, gradnjo APK in nalaganje artifactov. Statična validacija actionlint je uspešna; lokalno je 73 unit/widget testov uspešnih, analiza čista in APK se zgradi. [Gostovani zagon 46018722397](https://github.com/omarzdra/shiftMate/actions/runs/46018722397) je uspešen v obeh jobih, vključno z APK in artifacti. Ta rezultat velja za objavljeni commit 6a747fa; nove zagone preveri v Actions.

## #4 – Supabase in podatkovna baza

Verzionirana migracija, modeli in dejanski Supabase API/RPC dostop so implementirani. SQL shema, izolacija podjetij, pravice, vabila, potrjevanje ur in atomarnost urnika so preverjeni v izoliranem PostgreSQL WASM z Auth seamom. Oddaljeni ShiftMate projekt še ni konfiguriran; Auth/API v njem še nista preverjena. Obstoječi tuji projekti niso bili spreminjani. Naloga ostaja odprta.

## #5 – Avtentikacija in uporabniške vloge

Implementirani so registracija/prijava/odjava s Supabase SDK, ohranjanje seje, validacija in navigacija glede na članstvo. Widget testi preverjajo prijavo prek testnega repozitorija, napake, prehode in odstranitev zaščitenih poti ob izteku seje. Dejanska registracija, e-poštna potrditev in obnova seje prek Supabase zahtevajo razvojni projekt. Naloga ostaja odprta.

## #6 – Podjetje in zaposleni

Implementirani so ustvarjanje podjetja, e-poštno vezana vabila, sprejem po potrditvi e-pošte, seznam zaposlenih ter urejanje imena, pozicije, postavke in tedenske omejitve. Vabila potečejo po 7 dneh in so enkratna. SQL preverja identiteto in izolacijo podjetij. Deaktivacija zaposlenih še ni implementirana. Omrežna demonstracija ostaja odprta.

## #7 – Izmene

Implementirani so časovno urejen seznam izmen, CRUD, ročna dodelitev, nedodeljene izmene in strežniška validacija intervalov, prekrivanj, počitka, pozicije, razpoložljivosti in tedenskih ur. Lokalni predlog razporejevalnika se shrani samo ob potrditvi. Koledarska dnevna/tedenska mreža in trajno shranjeni osnutki še niso implementirani. Shranjevanje prek dejanskega Supabase API preveri po konfiguraciji.

## #8 – Razpoložljivost

Implementirani so datumski in časovni izbirniki, razpoložljivost/nerazpoložljivost, urejanje, brisanje in pregled ekipe. Razpoložljivost uporablja isti model v repozitoriju in razporejevalniku. Časovni intervali se preverjajo tudi v bazi. Omrežni CRUD in celotna pot na dveh računih še zahtevata razvojni projekt.

## #9 – Auto-Scheduling Engine

Samostojni Dart greedy algoritem in stanje predloga sta implementirana in unit testirana. Upoštevajo se celotna razpoložljivost, prekrivanje, tedenske ure, pozicija, počitek, porazdelitev, stroški, preference in stabilno izenačenje. Nepokrite izmene imajo razloge. Priprava predloga ne piše v bazo; ročne spremembe se preverijo; potrditev ponovno pridobi podatke, strežnik pa preveri zastarelost in omejitve v eni transakciji. SQL test potrjuje atomarno povrnitev konfliktnega predloga. Ostaja preverjanje na dejanskem Supabase projektu.

## #10 – Evidenca opravljenih ur

Implementirani so oddaja intervala/odmora/opombe, pending/approved/rejected, filtriranje po osebi/statusu/obdobju in informativno plačilo. SQL preprečuje lastno ali tuje potrjevanje, podvojene evidence, prihodnje konce in prekrivanje; postavko določi strežnik. Pregled hrani pregledovalca, čas in razlog zavrnitve. Popravljanje oziroma ponovna oddaja zavrnjene evidence ter polna zgodovina sprememb še nista implementirana. Omrežna pot oddaja–potrditev ostaja za preverjanje.

## #11 – Obvestila

Lokalna in oddaljena obvestila niso implementirana. Ohraniti odprto za naslednji mejnik.

## #12 – PDF/CSV in offline podpora

Hive CE hrani zadnje pridobljene podatke in nastavitev gostote. Predpomnilnik je izoliran po projektu/uporabniku, ob odjavi se izbriše. Unit test z dejansko datoteko Hive preveri ponovno odprtje in izolacijo; provider testi preverjajo offline branje ter blokado sprememb. Filtriranje ur je implementirano. PDF/CSV in dvosmerna offline sinhronizacija nista implementirana; naloga ostaja odprta.

## Preostali koraki

1. Preglej obstoječi draft PR #13; novega PR za isto vejo ne ustvarjaj.
2. Preglej že dodane posodobitve Issues #3–#12; nerešeni kriteriji ostajajo odprti.
3. V GitHub Actions preveri oba joba in prenesi APK artifact z datoteko BUILD_STATUS.txt.
4. Po dejanski demonstraciji z razvojnim Supabase dopolni rezultate in označi samo preverjene kriterije.

GitHub opravila so bila izvedena z uporabnikovo izrecno odobreno začasno uporabo obstoječe poverilnice. Poverilnica ni bila izpisana ali trajno shranjena; obstoječa prijava CLI ni bila spremenjena.
