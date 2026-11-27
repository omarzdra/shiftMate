Aplikacija je doslej vsebovala začetni zaslon. Sprememba doda delovni poti delodajalca in zaposlenega: Supabase Auth in članstva, varna vabila, izmene, razpoložljivost, predlog razporejanja s potrditvijo, oddajo/pregled ur in informativno plačilo. Provider upravlja stanje, Hive CE omogoča izoliran predpomnilnik za branje brez povezave.

Migracija vzpostavi RLS in preverjene RPC postopke. Potrditev urnika v transakciji ponovno preveri omejitve ter zastarele podatke. CI preveri PostgreSQL politike, Flutter format, analizo, teste in APK artifact.

Preverjeno lokalno:

- 73 uspešnih unit/widget testov; `flutter analyze` brez težav.
- Debug APK se uspešno zgradi; brez Supabase konfiguracije prikaže pripravo povezave.
- Migracija, RLS, atomarnost in demo seed preverjeni v izoliranem PostgreSQL WASM s simuliranim Auth.
- Postavitve renderirane pri širinah 390/1200 in povečavi besedila 1x/2x.
- Workflow preverjen z actionlint; gostovani zagon 46018722397 je uspešen, vključno z APK artifactom.

PR naj ostane draft: ločeni ShiftMate Supabase projekt še ni konfiguriran, zato dejanska Auth/API integracija in celotna demonstracija nista potrjeni. Integracijski test prijava–urnik–odjava na Android emulatorju je uspešen s testnim repozitorijem (1/1). Podrobni rezultati so v `docs/PROTOTYPE_STATUS.md`.

Povezano: #3, #4, #5, #6, #7, #8, #9, #10, #12. Issues naj se ne zaprejo samodejno. Obvestila, PDF/CSV, deaktivacija zaposlenih, naprednejši pogledi urnika in zgodovina popravkov ur ostanejo za naslednji mejnik. Nobena oddaljena baza ni bila spremenjena; main se ne združuje.
