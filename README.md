
# ShiftMate Business

Mobilna aplikacija za načrtovanje delovnih izmen, upravljanje razpoložljivosti zaposlenih in evidentiranje opravljenih delovnih ur.

**Predmet:** Razvoj vseprisotnih informacijskih rešitev (RVIR)  
**Študijsko leto:** 2026/2027  
**Fakulteta:** FERI, Univerza v Mariboru  
**Razvijalec:** Omar Zdralovic  
**Status:** Načrtovanje in prototipna faza

## 1. O projektu

ShiftMate Business je mobilna aplikacija za mala podjetja, ki potrebujejo preprost način organizacije dela in upravljanja zaposlenih.

Aplikacija omogoča načrtovanje delovnih izmen, spremljanje razpoložljivosti, avtomatsko pripravo predlogov urnikov in potrjevanje dejansko opravljenih ur.

Sistem podpira dve uporabniški vlogi: **delodajalec** in **delavec**.

## 2. Glavne funkcionalnosti

### Delodajalec
- Upravljanje podjetja in zaposlenih
- Ustvarjanje, urejanje in dodeljevanje izmen
- Pregled razpoložljivosti zaposlenih
- Avtomatska priprava urnika (Auto-Scheduling)
- Pregled in potrjevanje opravljenih ur
- Statistika in izvoz podatkov

### Delavec
- Pregled osebnega urnika
- Vnos in urejanje razpoložljivosti
- Pregled dodeljenih izmen
- Vnos in oddaja opravljenih ur
- Pregled statusov potrditve
- Obvestila o spremembah urnika

## 3. Auto-Scheduling Engine

Aplikacija bo vključevala hevristični algoritem za samodejno razporejanje zaposlenih.

Algoritem bo upošteval:
- razpoložljivost zaposlenih,
- časovna prekrivanja izmen,
- največje dovoljeno število delovnih ur,
- zahtevane delovne vloge,
- potreben počitek,
- čim bolj enakomerno porazdelitev ur.

Algoritem bo pripravil predlog urnika, ki ga mora delodajalec pred objavo potrditi.

## 4. Tehnologije

| Področje | Tehnologija |
|---|---|
| Mobilna aplikacija | Flutter |
| Programski jezik | Dart |
| Upravljanje stanja | Provider / ChangeNotifier |
| Backend storitev | Supabase |
| Podatkovna baza | PostgreSQL |
| Avtentikacija | Supabase Auth |
| Dostop do podatkov | Row Level Security |
| Lokalno shranjevanje | Hive CE |
| Testiranje | flutter_test |
| CI | GitHub Actions |

## 5. Arhitektura

Projekt uporablja večplastno arhitekturo:

1. Presentation layer – zasloni in gradniki Flutter.
2. State management – Provider in ChangeNotifier.
3. Repository layer – dostop do podatkov.
4. Data layer – Supabase in Hive CE.
5. Domain logic – poslovna pravila in Auto-Scheduling Engine.

## 6. Zagon projekta

### Predpogoji

- Flutter SDK
- Dart SDK
- Android Studio ali VS Code
- Android emulator ali fizična naprava

### Namestitev

```bash
git clone https://github.com/omarzdra/shiftMate.git
cd shiftMate
flutter pub get
```

### Zagon aplikacije

```bash
flutter run
```

**Opomba:** Če je repozitorij ustvarjen pod drugim imenom ali računom, ustrezno spremeni povezavo za kloniranje.

Trenutno projekt vsebuje začetno Flutter aplikacijo. Povezava s Supabase in poslovne funkcionalnosti bodo implementirane v naslednjih razvojnih fazah.

## 7. Testiranje

Zagon vseh testov:

```bash
flutter test
```

Statična analiza:

```bash
flutter analyze
```

Preverjanje formatiranja:

```bash
dart format --output=none --set-exit-if-changed .
```

## 8. CI – GitHub Actions

Projekt uporablja GitHub Actions za avtomatsko preverjanje kode ob spremembah v repozitoriju.

Workflow izvaja:
- namestitev odvisnosti,
- preverjanje formatiranja,
- statično analizo,
- avtomatske teste.

Konfiguracija je v `.github/workflows/flutter-ci.yml`.

## 9. Dokumentacija

Podrobnejša projektna dokumentacija se nahaja v mapi `dokumentacija/`.

- [Prototipna dokumentacija](dokumentacija/prototipna_dokumentacija.md)
- [Mockupi](dokumentacija/mockupi/)
- [Diagrami](dokumentacija/prototipna-dokumentacija.md)

Dokumentacija vsebuje opis projekta, primere uporabe, načrt arhitekture, podatkovni model, zaslone in razvojni načrt.

## 10. Načrt razvoja

| Faza | Vsebina |
|---|---|
| 1 | Projektna zasnova, mockupi in GitHub |
| 2 | Supabase Auth in uporabniške vloge |
| 3 | Upravljanje zaposlenih in izmen |
| 4 | Razpoložljivost zaposlenih |
| 5 | Auto-Scheduling Engine |
| 6 | Evidenca in potrjevanje ur |
| 7 | Obvestila, statistika in offline podpora |
| 8 | Testiranje in končna dokumentacija |

## 11. Trenutno stanje

Projekt je v prototipni fazi.

Vzpostavljajo se osnovna struktura aplikacije, dokumentacija, prototipi uporabniškega vmesnika, razvojne naloge in avtomatsko preverjanje kode.

## 12. Licenca

Projekt je razvit za študijske namene v okviru predmeta RVIR na Univerzi v Mariboru.
