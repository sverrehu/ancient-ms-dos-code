##pl66##tm4##lm10##rm2












##ceS H H   E D  -  T e k s t e d i t o r





##ceSkrevet i Turbo Assembler av

##ceSverre H. Huseby
##ceBj›lsengt. 17
##ceN-0468 Oslo
##ceNorge

##ceTlf: +47 2 230539

##ttSHH ED - Brukermanual                                     SIDE ##pn##nl##nl##nl##nl
##np
##ceINTRODUKSJON
##ce============



"SHH ED" (heretter kalt ED) er en enkel teksteditor som er inspirert av
editorene i Borlands programmeringsverkt›y. Disse er igjen WordStar-inspirerte.

Problemet med Borlandeditorene, er at de "sitter fast" i et kjempemessig
integrert arbeidsmilj›. nsker man † bruke editoren til noe annet enn
† skrive programmer i nettopp Borlands programmeringsspr†k, kan man ikke
velge † utelate alt som ikke har med teksteditering † gj›re. Dette
medf›rer at det kan ta flere sekunder † loade editoren. S‘rlig etter at
VROOMM-teknikken ble innf›rt, har alt begynt † ta lang tid.

Dette er spesielt irriterende n†r man programmerer, for da ›nsker man
ofte † forlate editoren for † kompilere programmet, for deretter †
g† inn i editoren for † rette evt. feil.

Med dette som bakgrunn har jeg fors›kt † lage en editor som er ganske lik
den til Borland (siden jeg er sv‘rt godt forn›yd med den!), men som ikke
er mer enn nettopp en editor.

Merk: Filen ED.DVI inneholder denne teksten skrevet i LaTeX. Har du mulighet
for † skrive ut DVI-filer, blir resultatet mye penere enn det du leser
n†! :-)

##np
##ceREGLER
##ce======



ED er et s†kalt "Freewareprogram". Dette inneb‘rer at du gratis kan bruke og
kopiere det s† mye du vil, bare du holder deg til f›lgende regler:

##lm15
* ##lm17Opphavsretten til programmet ligger fortsatt hos meg. Det er (if›lge
en av definisjonene) det som skiller Freeware fra Public Domain.

##lm15
* ##lm17Det er ikke tillatt † selge programmet, dvs. ta penger for det
utover distribusjonskostnader (lagringsmedium, porto, annonseutgifter ol).

##lm15
* ##lm17Firma som driver salg av PD- og SW- programmer, skal kontakte meg f›r
programmet tilbys. Dette er for at jeg skal ha mulighet for † sende
oppgraderinger og evt. feilrettinger. Det er b†de i min og brukernes interesse
at programmet spres i nyeste mulige versjon.

##lm15
* ##lm17Legger du som SYSOP programmet inn i en BBS, b›r du kontakte meg av
samme grunn.

##lm15
* ##lm17N†r programmet kopieres videre, skal det kopieres i sin opprinnelige
form, dvs at alle Copyright-meldinger skal v‘re intakte osv. Alle filer
skal v‘re med, dette gjelder b†de program, dokumentasjon og evt. tekstfiler.

Det skal ikke kopieres i samme directory som andre programmer, men det kan
godt ligge p† samme diskett.

Merk at dette gjelder kopiering. Du kan godt legge programmet hvor du vil
p† harddisken din, med eller uten dokumentasjon, men hvis en annen person
›nsker en kopi, skal vedkommende f† hele pakken.

##lm15
* ##lm17Jeg er p† ingen m†te ansvarlig for tap eller skade som m†tte oppst†
i forbindelse med bruk. Det finnes ingen garanti for at programmet virker som
angitt.

##lm10
Det er ogs† fint om du kan v‘re behjelpelig med † rapportere evt. feil du
m†tte finne, b†de store og sm†!

##np
##ceOPPSTART AV ED
##ce==============



MERK: Hvis du ikke har f†tt programmet direkte fra meg, b›r du kj›re EDSETUP
(se forklaring lenger nede) og velge standardoppsett f›r du begynner †
bruke ED. Dette er for † "rydde opp" etter evt. endringer gjort av tidligere
brukere.


ED startes opp med kommandoen ED. nsker man † g† direkte inn i en fil,
angis dette p† kommandolinjen:

    ED <filnavn>

Hvis ikke filnavn er angitt, vil ED sjekke om det er en plukkfil (se BRUK
AV PLUKKMENY OG PLUKKFILER lenger nede) i n†v‘rende directory. Hvis det
finnes, hentes den f›rste filen i denne inn i editoren.

Finnes ingen plukkfil, vil brukeren bli bedt om et filnavn.


Filnavn kan enten v‘re navn p† eksisterende filer, navn p† ikke eksisterende
filer, eller en s›kemaske (feks: *.ASM).

Blir en eksisterende fil angitt, leses denne inn i editoren. Eksisterer ikke
filen, t›mmes editoren, og klargj›res for ny fil med angitt navn.
Er det en s›kemaske som er angitt, vises passende filnavn, og man kan velge
›nsket fil.


nsker man † avbryte en handling, kan man i de fleste tilfeller trykke Esc for
† komme tilbake i teksten igjen.



##ceAVSLUTNING AV ED
##ce================



Etter endt editering, avlsuttes ED med Alt-X. (Dette er ogs† angitt nederst
p† skjermen.)

Hvis n†v‘rende fil ikke er lagret, f†r man sp›rsm†l om dette skal gj›res
f›r det returneres til DOS.


##np
##ceSTANDARD FILETTERNAVN
##ce=====================



N†r man programmerer, jobber man oftest med filer med samme etternavn.
Dette tar ED hensyn til ved at den, hver gang en ny fil leses, sparer
dennes etternavn.

N†r filnavn senere skal angis, slipper man † angi noe etternavn hvis
dette er det samme som p† n†v‘rende fil.

nsker man † editere en fil uten etternavn, angir man filnavnet med et
punktum etter. Da vil ikke ED legge til noe.


ED vil alltid utvide med standard etternavn n†r det sp›rres etter
fil. Ogs† n†r det gjelder lesing/skriving av blokker.





##ceBRUK AV PLUKKMENY OG PLUKKFILER
##ce===============================



N†r nye filer hentes inn i editoren, vil tidligere filer legges
i en s†kalt plukkliste. I denne listen ligger, i tillegg til filens
navn, opplysninger om hvor mark›ren var plassert i teksten, og plassering av
evt. blokk- og posisjonsmark›rer.

nsker man † hente tilbake en av de tidligere filene, trykkes F4 (eller
Alt-F3 for de som ›nsker full Borlandkompatibilitet!). Da f†r man en
liste over n†v‘rende og opp til 13 tidligere filnavn. Ved † flytte mark›ren
til ›nsket fil, og s† trykke Return, erstattes n†v‘rende fil med den
tidligre, og mark›ren plasseres p† den posisjonen den var p† da filen
sist ble forlatt.

Det er ogs† mulig † lagre denne plukklisten i en plukkfil. Det gj›res ved
† trykke Alt-F4. Dette gj›res kun en gang, for senere vil ED selv holde
filen oppdatert.

Plukkfilen legges i n†v‘rende directory, under navnet ED.PCK. Denne kan
fjernes n†r det m†tte v‘re ›nskelig.

N†r ED startes opp, vil den sjekke om det er en plukkfil i n†v‘rende
directory. Hvis det er tilfelle, leses den inn, og dersom ingen filnavn
er angitt p† kommandolinjen, hentes den f›rste filen i listen (den som
sist ble redigert) inn i editoren.

Dette forenkler igjen programmering, siden man etter en kompilering
bare starter ED og havner direkte inn i den siste filen.

##np
##ceSTATUSLINJEN
##ce============



verste skjermlinje inneholder informasjon om hvordan ED jobber i ›yeblikket.
F›lgende kan leses ut:

##lm15
N†v‘rende linje- og kolonnenummmer.

Hvorvidt Innsett, AutoInnrykk og Parentesparring er av eller p†.

Om filen er endret siden forrige lagring. Dette markeres med en stjerne (*)
til venstre for filnavnet.

Navn p† n†v‘rende fil. Dette er en kortform som kun inneholder disk- og
filnavn. Evt. directories vises ikke.

##lm10
P† nederste linje vises de viktigste tastene, slik at man slipper †
g† inn i hjelpevinduet for † lete etter disse.





##ceMUSSTYRING
##ce==========



I tillegg til † bruke piltastene, kan man flytte mark›ren ved hjelp
av en Microsoft-kompatibel mus. Dette skjer ved † peke p† ›nsket posisjon,
og s† trykke venstre mustast. Det er imidlertid ikke mulig † flytte forbi
siste linje av teksten.

Musen kan ogs† brukes til scrolling: Plasser musmark›ren p† ›verste eller
nederste statuslinje, og trykk venstre mustast for † scrolle opp (mot
begynnelsen av teksten), eller h›yre mustast for † scrolle ned.

Merk: Brukes skjermformater som ikke er standard, dvs med annet enn 80
kolonner, kan det tenkes at musstyringen ikke virker riktig.

(Se OPPSETT AV ED MED EDSETUP.COM hvis ikke musen fungerer riktig.)

##np
##ceSPESIELT
##ce========



ED'S BEHANDLING AV TAB

For ED er ASCII-koden for Tab bare et hvilket som helst tegn. Leser man inn
en fil som fra f›r inneholder tabulatortegn, vil ED vise disse som sm†
sirkler, som er slik Tab-tegnet ser ut i IBM's verden.

Trykker man Tab-tasten under editering, vil dette gi et innrykk, dvs. at
mark›ren flyttes til kolonnen hvor f›rste ikke-blanke tegn finnes i
linjen over. Mellomrommet fylles med blanke, ikke med Tab-tegn.

Har du fra f›r filer som inneholder Tab-tegn, kan disse konverteres med
programmet EXPTAB.COM i programpakken "SHH Utilities" (Se filen OTHERPRG.TXT).
Dette programmet bytter ut Tab'er i en fil med riktig antall mellomrom.





##ceED I TALL
##ce=========



Maks linjelengde: 255          ##nl
Maks antall linjer: 10000      ##nl
Maks lengde p† s›kestreng: 32  ##nl
Maks lengde p† filnavn: 80     ##nl

Det er ingen fast grense p† hvor store filer som kan editeres (bortsett fra
antall linjer og linjelengde). Dette avgj›res av tilgjengelig minne i
maskinen. ED leser hele filen inn i minnet, og bruker ikke disken til
mellomlagringer.

##np
##ceKORT KOMMANDOOVERSIKT
##ce=====================



Dette kan man ogs† f† fram ved † trykke F1 mens ED er ibruk. Man blar
fram og tilbake i hjelpeteksten med PgDn og PgUp.



##lm15
GRUNNLEGGENDE MARKRFLYTTING

##lm20
Tegn venstre               Ctrl-S el Venstrepil     ##nl
Tegn h›yre                 Ctrl-D el H›yrepil       ##nl
Ord venstre                Ctrl-A el Ctrl-Venstrepil##nl
Ord h›yre                  Ctrl-F el Ctrl-H›yrepil  ##nl
Linje opp                  Ctrl-E el Pil opp        ##nl
Linje ned                  Ctrl-X el Pil ned        ##nl
Scroll en linje opp        Ctrl-W                   ##nl
Scroll en linje ned        Ctrl-Z                   ##nl
Side opp                   Ctrl-R el PgUp           ##nl
Side ned                   Ctrl-C el PgDn           ##nl
##lm15



ANNEN MARKRFLYTTING

##lm20
Linjestart                 Home                     ##nl
Linjeslutt                 End                      ##nl
Skjermstart                Ctrl-Home                ##nl
Skjermslutt                Ctrl-End                 ##nl
Tekststart                 Ctrl-PgUp                ##nl
Tekstslutt                 Ctrl-PgDn                ##nl
Blokkstart                 Ctrl-Q B                 ##nl
Blokkslutt                 Ctrl-Q K                 ##nl
G† til linje               Ctrl-Q G                 ##nl
##lm15



INNSETTING OG SLETTING

##lm20
Innsett av/p†              Ctrl-V el Ins            ##nl
Sett inn linje             Ctrl-N                   ##nl
Slett linje                Ctrl-Y                   ##nl
Slett til linjeslutt       Ctrl-Q Y                 ##nl
Slett tegn til venstre     Ctrl-H el BackSpace      ##nl
Slett tegn                 Ctrl-G el Del            ##nl
Slett ord til h›yre        Ctrl-T                   ##nl
##lm15

##np
BLOKKHNDTERING

##lm20
Marker blokkstart          Ctrl-K B                 ##nl
Marker blokkslutt          Ctrl-K K                 ##nl
Kopier blokk               Ctrl-K C                 ##nl
Flytt blokk                Ctrl-K V                 ##nl
Slett blokk                Ctrl-K Y                 ##nl
Les blokk fra disk         Ctrl-K R                 ##nl
Skriv blokk til disk       Ctrl-K W                 ##nl
Skjul/vis blokk            Ctrl-K H                 ##nl
Rykk blokk inn             Ctrl-K I                 ##nl
Rykk blokk ut              Ctrl-K U                 ##nl
##lm15



DIVERSE

##lm20
Innrykk                    Ctrl-I el Tab            ##nl
Auto innrykk av/p†         Ctrl-O I                 ##nl
Parentesparring av/p†      Ctrl-O P                 ##nl
Sett posisjonsmark›r       Ctrl-K 1,2               ##nl
Finn posisjonsmark›r       Ctrl-Q 1,2               ##nl
Kontrolltegn prefix        Ctrl-P c                 ##nl
S›k etter tekst            Ctrl-Q F                 ##nl
S›k og erstatt tekst       Ctrl-Q A                 ##nl
Gjenta siste s›k           Ctrl-L                   ##nl
Vis brukerskjerm           F5                       ##nl
##lm15



FILHNDTERING

##lm20
Lagre fil                  F2                       ##nl
Hent fil                   F3                       ##nl
Plukk frem tidligere fil   F4                       ##nl
Opprett plukkfil           Alt-F4                   ##nl
##lm10


##np
##ceFORKLARING TIL SPESIELLE KOMMANDOER
##ce===================================



GRUNNLEGGENDE MARKRFLYTTING

Dette er helt rett fram. Gir ingen videre forklaringer.



ANNEN MARKRFLYTTING

"Blokkstart" flytter til starten p† markert blokk. Se BLOKKOMANDOER lenger
nede.

"Blokkslutt" flytter til slutten p† markert blokk.

"G† til linje" vil be om et linjenummer, og deretter flytte mark›ren
til oppgitt linje.



INNSETTING OG SLETTING

"Innsett av/p†" vil velge om innskrevet tekst skal settes inn i
eksisterende tekst, eller overskrive det som finnes fra f›r. Status for
dette vises ›verst p† skjermen, og er enten "Innsett" eller "Erstatt".

"Slett linje" fjerner linjen mark›ren st†r p†. Det er ingen m†te † f†
denne tilbake p†, uten † lese inn filen en gang til.

"Slett til linjeslutt" sletter tekst fra mark›rens posisjon og ut linjen.
Denne teksten kan ikke hentes tilbake uten † lese inn filen p† nytt.

"Slett ord til h›yre" fjerner f›rst ikke-skilletegn, deretter evt. blanke
fram til linjeslutt eller et nytt ikke-blankt tegn. Skilletegn er et av
f›lgende: space < > , ; . : ( ) [ ] { } ^ ' = * + - / \ $ #


##np
BLOKKOMANDOER

En blokk er en del av teksten, alt fra et tegn til hundrevis av linjer,
som er omgitt av to blokkmark›rer. Det kan til en hver tid bare v‘re markert
‚n blokk, og denne vises i en annen farge enn resten av teksten.

For † markere en blokk, plasseres mark›ren p† det f›rste tegnet som skal
v‘re med. Der trykkes "marker blokkstart". Deretter plasseres mark›ren
ETTER siste tegn i blokken, og "marker blokkslutt" velges.

N†r blokken f›rst er markert, kan den flyttes, kopieres, slettes, eller
skrives til disk.

"Kopier blokk" / "Flytt blokk" vil kopiere eller flytte en blokk til n†v‘rende
mark›rposisjon. Merk at det ikke er mulig † kopiere en blokk inn i seg selv.
Mark›ren m† alts† v‘re utenfor blokken.

"Slett blokk" fjerner blokken fra teksten, og det er ingen mulighet
for † f† denne tilbake igjen (uten † lese inn filen fra disk).

"Skriv blokk til disk" vil lagre markert blokk i en egen fil. Det vil
f›rst sp›rres etter filnavn, og hvis angitt fil eksisterer, vil det bli
spurt om denne skal overskrives.

"Les blokk fra disk" vil f† ED til † be om et filnavn, og deretter lese
angitt fil inn i teksten p† mark›rens posisjon. Teksten vil automatisk
bli markert som en blokk.

"Skjul/vis blokk" vil sl† av/p† utheving av blokken. N†r blokken ikke
er uthevet, er det ikke mulig † utf›re blokkoperasjoner p† den. Blokkmark›rene
vil imidlertid fremdeles v‘re p† samme posisjon.

"Rykk blokk inn" vil legge inn en blank i begynnelsen av hver blokklinje,
og dermed flytte blokken til h›yre.

"Rykk blokk ut" fjerner en evt. blank i begynnelsen av hver blokklinje. Blokken
blir dermed flyttet et hakk til venstre.


##np
DIVERSE

"Innrykk" vil flytte mark›ren (evt. sette inn blanke hvis Innsett er p†)
til neste posisjon som svarer til starten p† et ord p† linjen over. Hvis
linjen over er kortere enn n†v‘rende mark›rkolonne, tas det utgangspunkt i
linjen over den igjen osv.

"Auto innrykk av/p†" velger om Innrykk automatisk skal utf›res n†r
Return trykkes. N†r denne er p†, vil alle nye linjer starte i samme kolonne
som linjen over. Status vises p† ›verste linje.

"Parentesparring av/p†" er litt spesiell. N†r man angir en venstreparentes,
venstreklamme ol, er det sv‘rt sannsynlig at man senere kommer til † angi
tilsvarende h›yreparentes, h›yreklamme osv. Det er ofte lett † glemme dette,
s‘rlig hvis man skriver lange uttrykk med mange parenteser i hverandre.
Med parentesparring p†, vil ED automatisk sette inn h›yreutgaven av angitt
parentestype, og plassere mark›ren mellom disse. De tegnene som p†virkes av
dette, er (), [], {}, og "". Status vises p† ›verste linje. Merk: Dette
virker bare hvis Innsett er p†.

"Sett posisjonsmark›r" gir mulighet for † sette inn en av to plassmark›rer,
slik at man senere raskt kan komme tilbake til et punkt i teksten.

"Finn posisjonsmark›r" hopper til en av to tidligere markerte posisjoner
i teksten. Hvis ingen posisjoner tidligere er markert, flyttes til starten
av teksten.

"Kontrolltegn prefix". Det er ofte ›nskelig † legge inn kontrollkoder
(ASCII-koder med verdi < 32) i teksten, feks. for † legge inn sideskiftkode
til printer. For † gj›re dette, trykkes Ctrl-P og bokstaven hvis plass i
alfabetet svarer til ›nsket kode. Eksempel: Skal legge inn sideskift. Dette
har ASCII-verdi 12, og siden L er den 12. bokstaven i alfabetet, trykkes
Ctrl-P L.

"S›k etter tekst" ber om en s›ketekst og evt. opsjoner (se under) som styrer
s›kingen. Hvis ingen opsjoner angis, letes det fram til f›rste forekomst av
teksten etter n†v‘rende mark›rposisjon. Det skilles p† store og sm† bokstaver.
Hvis ikke teksten blir funnet, gis en pipetone.

"S›k og erstatt tekst" ber om s›ketekst, samt en streng som skal erstatte
forekomster av denne. Deretter sp›rres det etter evt. opsjoner (se under).
Hvis ingen opsjoner angis, byttes neste forekomst etter n†v‘rende posisjon,
etter † ha spurt om dette skal gj›res. Hvis ikke det er flere forekomster,
gis en pipetone.

Opsjoner til "S›k etter tekst" og "S›k og erstatt tekst" kan v‘re ingenting,
eller ‚n eller flere av f›lgende:

##lm15
G ##lm17s›k Globalt, dvs. fra starten av dokumentet, og helt til siste
forekomst.

##lm15
N ##lm17erstatt teksten uten † be bruker om bekreftelse.

##lm10
"Gjenta siste s›k" s›ker en gang til etter forrige angitte tekst, og erstatter
den med evt. angitt erstatning.

"Vis brukerskjerm" henter fram skjermen som var aktiv f›r ED ble startet.
Denne er spesielt god † ha n†r en kompilator har gitt flere feilmeldinger,
og man skal rette opp disse. Trykk en tast for † komme tilbake i editoren.



FILHNDTERING

I alle tilfeller hvor det bes om et filnavn, er det mulig † angi wildcards
(jokertegn, ? og *) i filnavnet. Man f†r is†fall opp en liste over filer som
passer, samt alle subdirectories. Man kan da flytte en mark›r rundt med
piltastene, og velge ›nsket fil ved † trykke Return. Hvis det som velges
er et directory, gis oversikt over tilsvarende filer i dette.

Hvis man, under sp›rring etter navn p† fil som skal skrives til disk, oppgir
navn p† en eksisterende fil, f†r man sp›rsm†l om denne skal erstattes. N†r en
fil skrives til disk, vil en evt. tidligere fil med samme navn f† etternavnet
.BAK, slik at det er mulig † hente tilbake denne siden.

N†r n†v‘rende fil erstattes, eller n†r man g†r ut av editoren, vil ED
sjekke om teksten er endret, og is†fall sp›rre om den skal lagres.

Se ogs† STANDARD FILETTERNAVN lenger oppe.

"Lagre fil" vil skrive n†v‘rende fil til disk. Hvis filnavn av en eller annen
grunn ikke er oppgitt (det skjer hvis et ulovlig filnavn angis), vil
det bli spurt om et nytt navn.

"Hent fil" ber om navn p† fil som skal hentes inn i editoren, og henter
inn denne.

"Plukk frem tidligere fil" og "Opprett plukkfil" er forklart under BRUK
AV PLUKKMENY OG PLUKKFILER.

##np
##ceOPPSETT AV ED MED EDSETUP.COM
##ce=============================



Det er mulig † gj›re permanente endringer i ED's oppsett ved hjelp av
programmet EDSETUP.COM.

Dette kan feks. v‘re nyttig hvis man ikke klarer † venne seg til
parentesparring, og ikke ›nsker † m†tte sl† denne av for hver gang ED
startes opp.

Det f›rste valget i EDSETUP er "Resett av mus ved start". Hvis musen
ikke fungerer med ED, kan det l›nne seg † sette denne p†. Dette kan
f›re til at ED bruker et par sekunder lenger ved oppstart, siden
en del musdrivere bruker litt tid p† † resette musen (Det er derfor
dette vanligvis er av). Hvis resett er av, vil ED bruke en annen (mindre
sikker) metode for † finne ut om en mus er tilkoplet.

Det er ogs† mulig † endre de fleste av fargene som ED bruker.


For at EDSETUP skal kunne brukes, m† ED.COM finnes i n†v‘rende directory,
og filen m† ikke v‘re skrivebeskyttet. EDSETUP skriver nemlig det nye
oppsettet rett inn i ED.COM, siden det gir raskere oppstart enn en evt.
oppstartfil som leses hver gang programmet startes. Etter min mening er
dette ogs† en ryddigere m†te † gj›re det p†, siden antall filer begrenses.

Det er imidlertid et (lite) problem: Antivirusprogrammer av sjekksumtypen
vil klage over at ED.COM er endret f›rste gang det kj›res etter forandring
av oppsettet. Dette er helt greit, for ED _er_ jo endret, men det skyldes
alts† ikke virus denne gangen!



F›r du begynner † bruke ED, b›r du kj›re EDSETUP og velge standard oppsett
for † rydde opp etter evt. endringer gjort av tidligere brukere (med mindre
du f†r programmet direkte fra meg).

##np