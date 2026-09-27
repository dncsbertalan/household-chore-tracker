# Az alkalmazás funkciói

## Fiókkezelés és hitelesítés

- Új felhasználói fiók regisztrálása.
- Bejelentkezés és kijelentkezés.
- Alapvető felhasználói profiladatok kezelése.

Nem biztos:

- Alternatív bejelentkezési lehetőség Apple- vagy Google-fiókkal.

## Háztartások kezelése

- Új háztartás létrehozása.
- Háztartás adatainak megtekintése/módosítása.
- Háztartás törlése.
- Felhasználók meghívása a háztartásba.
- Meghívások elfogadása vagy elutasítása.
- Tagok eltávolítása a háztartásból.
- Kilépés egy háztartásból.
- A háztartás összes tagjának megtekintése.
- Adminisztratív jogosultságok megosztása több felhasználó között.
- Háztartásszintű beállítások kezelése.

## Szerepkörök és jogosultságok

- Egyedi szerepkörök létrehozása/módosítása/törlése.
- Szerepkörök hozzárendelése a háztartás tagjaihoz.
- Előre definiált szerepkörök támogatása (pl. szülő, gyerek, lakótárs)
- Szerepkörönként konfigurálható jogosultságok.

(A jogosultságok szerveroldali ellenőrzése minden releváns művelet előtt.)

## Feladatok kezelése

- Új feladat létrehozása/módosítása/törlése.
- Feladat részleteinek megtekintése.
- Feladat hozzárendelése egy vagy több háztartástaghoz.
- Opcionális pontos időpont/határidő megadása.
- Feladat státuszának módosítása.
- Aktív feladatok megtekintése.
- Teljesített feladatok megtekintése.
- Korábbi feladatok megtekintése.
- Egy adott háztartáshoz tartozó feladatok megtekintése.

### Ismétlődő feladatok

- Ismétlődő feladat létrehozása/módosítása.
- Az ismétlődési szabály külön kezelése az egyes konkrét feladatelőfordulásoktól.
- Különböző ismétlődési minták támogatása (fix időpontban ismételt, teljesítést követően fix időintervallum elteltével ismételt, on demand).
- Egy konkrét előfordulás módosítása a teljes sorozat megváltoztatása nélkül. (Korábbi teljesített előfordulások megőrzése akkor is, ha az ismétlődési szabály később megváltozik.)

### Szükség szerinti feladatok

Olyan feladatok támogatása, amelyeknek nincs fix ismétlődési időpontjuk (pl. a szemét kivitele).

### Feladatok jóváhagyása és ellenőrzése

- Annak beállítása, hogy egy feladat teljesítése igényel-e jóváhagyást.
- A szükséges jóváhagyások számának konfigurálása.
- Feladatteljesítés jóváhagyása/elutasítása.

Nem biztos:

- Annak meghatározása, hogy mely szerepkörök vagy felhasználók jogosultak jóváhagyni.

## Feladatkiosztás és felelősség

- Feladat közvetlen hozzárendelése háztartástagokhoz.
- Feladat újbóli kiosztása más felhasználóhoz.
- A korábbi feladatelőfordulásokhoz tartozó felelősségi adatok megőrzése.

## Offline működés

- Helyben tárolt adatok megjelenítése internetkapcsolat nélkül.
- Más engedélyezett helyi műveletek végrehajtása internetkapcsolat nélkül.
- A helyi módosítások azonnali megjelenítése a felhasználói felületen, tárolásuk későbbi szinkronizációhoz.
- Függőben lévő módosítások elküldése az internetkapcsolat helyreállása után.

## Valós idejű frissítések

- Szerveroldali broadcast üzenetek fogadása, ha egy másik háztartástag módosítást hajt végre.

## Konfliktuskezelés

- Verzió alapú optimista konfliktus kezelés.

## Háztartás létrehozása AI segítségével

- A háztartás manuális vagy AI által támogatott létrehozási módjának kiválasztása.
- A háztartás jellemzőinek és a felhasználó preferenciáinak felmérése egy kérdőív segítségével.
- A megadott válaszok alapján AI segítségével kezdeti háztartás-konfiguráció generálása.
- A generált háztartás-konfiguráció megtekintése és manuális módosítása a létrehozás előtt.
- A generált javaslat egyes elemeinek elfogadása vagy elutasítása.

## Kép, illetve leírás alapján feladat generálása

- Új feladat generálása természetes nyelven megadott leírás alapján.
- Új feladat generálása a felhasználó által készített vagy feltöltött kép alapján.

## Főbb képernyők és felhasználói felületi funkciók

- Bejelentkezési és regisztrációs képernyő.
- Háztartásválasztó képernyő.
- Háztartás dashboard.
- Feladatlista.
- Feladat létrehozása és szerkesztése.
- Ismétlődő feladat konfigurálása.
- Feladatelőzmények.
- Háztartástagok kezelése.
- Meghívások kezelése.
- Szerepkörök kezelése.
- Jogosultságok szerkesztése.
- Háztartási beállítások.
- Felhasználói profil és beállítások.
- Jóváhagyásra váró feladatok.
- Offline és szinkronizációs állapot megjelenítése.
