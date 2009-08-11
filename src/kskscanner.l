/* kskscanner von JonnyJD - version siehe gleichnamige Variable */

%option noyywrap
%option nounput
/*%option nodefault*/
/*%option yylineno*/

%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>

const char *priceFile = "preise";
const char *cgiName = "/usr/lib/cgi-bin/kskscanner";
int maxIOBuffer = 100000;
const char *tmpFileName = "_kskscanner_tmpFile";
time_t now;
extern FILE* yyin;
float itemVal, sum;
int allyNum, num;
int aVal[100], aNum[100];

/* fuer die Erstellung der allg. Preistabelle */
int isAlly;
char * item;
FILE * prices;
void genValue(float textVal);
void loadPrices();

/* Hilfsfunktionen */
void putName(char * name);

/* fuer die Allianzstatistik */
char * ally(int id);
int id(char * tag);
%}

TAG    (<[^>]*>)
TAGN    {TAG}\n?
TAGS    {TAG}[^<]*
VAR    ([^=]*=\")
PF    ([^/]*\/)


 /* Seitentypen */
 /* Handelsbude - rbfhandel1.* */
%s HB
%x HNAME
%x GUT GNUM GKM GVAL
%x ST SNUM SVAL

 /* Reichsressourcen - rbrinfo0.*, rbrinfo.* */
%s RR
%x RNAME
%x RGUT RGUT2 RGUTB RGUT3 RNUM

 /* Top Ten - rbtop10.* */
%s TT
%x PLR ALLY TAL AVAL


%%

 /* ----------------- Seitenerkennung  ---------------------------- */

("<font size="\"?6\"?" face=\"Diploma\">Dorf "|"<font face=\"Diploma\" size="\"?6\"?">Dorf ")    {
                        BEGIN(HNAME);
                    }
<HNAME>[^<]*        {
        if(strcmp(yytext,"Vogia, Handelsbude") == 0) {
          isAlly = 1;
          prices = fopen(priceFile,"w");
          fprintf(prices,"Zeitstempel\t%ld\n", now);
        } else {
          loadPrices();
        }
        printf("\n%s\n", yytext);
        if(isAlly) {
            printf(" - Allianzbude - \n");
        }
        printf("- - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n");
    }
<HNAME>"<"          {   BEGIN(HB); /* Handelsbude */ }

("<font size="\"?6\"?" face=\"Diploma\">Ressourcen im "|"<font face=\"Diploma\" size="\"?6\"?">Ressourcen im ")    {
                        BEGIN(RNAME);
                    }
<RNAME>[^<]*        {
        loadPrices();
        printf("\nRessourcen im %s\n", yytext);
        printf("- - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n");
    }
<RNAME>"<"          {   BEGIN(RR); /* Reichsressourcen */ }

("<font size="\"?6\"?" face=\"Diploma\">TOP 10"|"<font face=\"Diploma\" size="\"?6\"?">TOP 10")    {
                        printf("\nAllianzpunkte");
                        printf("\t\t\t\t\t\tSchnitt\n");
                        printf("- - - - - - -%50c\n", ' ');
                        BEGIN(TT);
                    }


 /* -------------------- HB Gueter -------------------------------- */

<HB>"<img src=\""{PF}{6}"gut"[0-9]*".gif\">&nbsp;"    {
                                            BEGIN(GUT);
                                        }
<GUT>[^<]*                              {   putName(yytext); }
<GUT>{TAGN}{5}                          {   BEGIN(GNUM); }
<GUT>{TAGN}{4}                          {   BEGIN(GKM); }

<GKM>[0-9]*                             {
                                            itemVal = atoi(yytext);
                                            printf("%6.0f\t", itemVal);
                                            genValue(1.0);
                                        }
<GKM>.|\n                               {   BEGIN(HB); }

<GNUM>[0-9]*                            {
                                            itemVal = atoi(yytext);
                                            printf("%6.0f\t", itemVal);
                                        }
<GNUM>{TAGS}{27,30}[^>]*"value=\""      {   BEGIN(GVAL); }
<GNUM>.|\n                              {   ECHO; }

<GVAL>[0-9.]*                           {   genValue(atof(yytext)); }
<GVAL>"\""                              {   BEGIN(HB); }
<GVAL>.|\n                              {   /* nothing */ }


 /* -------------- HB Gegenstaende -------------------- */

<HB>"<img src=\""{PF}{6}"st"[0-9]*".gif\" border="\"?0\"?>      {
                                            BEGIN(ST);
                                        }
<ST>[^<]*                               {   putName(yytext); }
<ST>{TAGN}{5}([0-9]*"/")*               {   BEGIN(SNUM); }

<SNUM>[0-9]*                            {
                                            itemVal = atoi(yytext);
                                            printf("%6.0f\t", itemVal);
                                        }
<SNUM>{TAGS}{27,33}[^>]*"value=\""      {   BEGIN(SVAL); }
<SNUM>.|\n                              {   ECHO; }

<SVAL>[0-9.]*                           {   genValue(atof(yytext)); }
<SVAL>"\""                              {   BEGIN(HB); }
<SVAL>.|\n                              {   ECHO; }

 /* -------------------- RR Gueter und Gegenstaende ---------------------- */

<RR>"<"(IMG|img)" "(SRC|src)"=\""{PF}{6}"gut"[0-9]*".gif\" border="\"?0\"?">&nbsp;"    {
                                            BEGIN(RGUTB); /* Gut */
                                        }
<RR>"<"(IMG|img)" "(SRC|src)"=\""{PF}{6}"st"[0-9]*".gif\" border="\"?0\"?">" {
                                            BEGIN(RGUT);
                                            /* Gegenstand rbrinfo.* */
                                        }
<RR>"<a href=\"javascript:fensterSache("[0-9]*")\">"    {
                                            BEGIN(RGUT);
                                            /* Gegenstand rbrinfo.* */
                                        }

<RGUT,RGUTB>"<"                         {
                                            BEGIN(RR);
                                            /* anders bei rbrinfo Gegenst. */
                                        }
<RGUT>[^<]*                             {
                                            putName(yytext);
                                            BEGIN(RGUT2);
                }
<RGUTB>[^<]*                            {
                                            putName(yytext);
                                            BEGIN(RGUT3);
                                        }
<RGUT2,RGUT3>"<b>"                      {   BEGIN(RNUM); /* rbrinfo0.* */ }
<RGUT3>"</td><td>"                      {   BEGIN(RNUM); }

<RGUT3>"<td>"                           {   BEGIN(RNUM); /*Umlautschluckung */ }
<RGUT2>"</td><td></td><td>"             {   BEGIN(RNUM); }
<RGUT2>"<td></td>\n<td>"                {   BEGIN(RNUM); }
<RGUT2>"<td>&nbsp;"[0-9]+"</td><td>"    {   BEGIN(RNUM); /* rbrinfo.* */ }
<RGUT2>("</tr>"|"</TR>")                {
                                            /* kein Wert gefunden = 0 */
                                            itemVal = 0;
                                            printf("%6.0f\t", 0.0);
                                            genValue(-1.0);
                                            BEGIN(RR);
                                        }
<RGUT2,RGUT3>.|\n                       {   /* ueberlesen */ }
<RNUM>[0-9]*                            {
                                            itemVal = atoi(yytext);
                                            printf("%6.0f\t", itemVal);
                                            genValue(itemVal);
                                            BEGIN(RR);
                                        }
<RNUM>[<&]                              {   BEGIN(RGUT2); }
<RNUM>.|\n                              {   ECHO;         }


 /* ------------- Top 10 ---------------------------- */

<TT>"<b>"[0-9]*".</b></td><td valign="\"?bottom\"?"><b>"[^<]*"</b></td><td valign="\"?bottom\"?">"      {   BEGIN(PLR);   }
<PLR>[0-9]*             {
                            sum += atoi(yytext);
                            num++;
                            BEGIN(TT);
                        }

<TT>"allym"             {   BEGIN(ALLY);  }
<TT>"["                 {   BEGIN(TAL);   }

<ALLY>[0-9]*            {   allyNum = atoi(yytext); }
<ALLY>".gif\" border="\"?0\"?"></td><td valign="\"?bottom\"?">" {
                            BEGIN(AVAL); }

<TAL>[^\]]*             {   allyNum = id(yytext);   }
<TAL>"]</b></td><td valign="\"?bottom\"?">"     {
                            BEGIN(AVAL); }

<AVAL>[0-9]*            {
                            aVal[allyNum] += atoi(yytext);
                            aNum[allyNum]++;
                            BEGIN(TT);
                        }


 /* ------------- Allgemein ------------------------- */

<HB,RR><<EOF>>  {
                    printf("\t\t\t\t\t\t----------\n");
                    printf("Summe:\t\t\t\t\t\t%10.2f\n\n", sum);
                    fclose(prices);
                    return 0;
                }
<TT><<EOF>>     {
                    int i, higherPos, max, pos;
                    printf(" 0. Allianzlose\t\t\t\t%8.0f", sum);
                    printf("%5d%10.0f\n", num, sum/num);
                    higherPos = 999999999;
                    pos = 1;
                    do {
                        max = 0;
                        for (i=0; i<100; i++) {
                            if ((aVal[i] < higherPos) && (aVal[i] > max)) {
                                max = aVal[i];
                            }
                        }
                        higherPos = max;
                        for (i=0; i<100; i++) {
                            if ((aVal[i] > 0) && (aVal[i] == max)) {
                                printf("%2d. ", pos);
                                printf("%s\t%8d", ally(i), aVal[i]);
                                printf("%5d", aNum[i]);
                                printf("%10d\n", aVal[i]/aNum[i]);
                                sum += aVal[i];
                                num += aNum[i];
                            }
                        }
                        pos++;
                    } while (max > 0);
                    printf("\t\t\t\t\t--------%15c\n", ' ');
                    printf("Gesamt\t\t\t\t\t%8.0f", sum);
                    printf("%5d%10.0f\n\n", num, sum/num);
                    return 0;
                }

.|\n            { /*printf("%s",yytext);*/ /* uninteresting */ }
<INITIAL><<EOF>>        { return 0; }

%%


char * ally(int id)
{
    switch (id) {
        case 16: return("Magistraten der Caldea\t[MAG]");      break;
        case 17: return("Koenigliche Allianz\t\t[SL]");        break;
        case 18: return("Zirkel der Erklaerten\t[ZdE]");       break;
        case 22: return("Nations of Senoi\t\t[NoS]");          break;
        case 23: return("SzasKhar\t\t[SK]");                   break;
        case 25: return("Bewahrer der Heiligen Allianz\t[HA]");break;
        case 31: return("Drachenritter\t\t[DR]");              break;
        case 32: return("Raeubergilde\t\t[RG]");               break;
        case 38: return("Piraten\t\t\t[P]");                   break;
        case 43: return("Die 13. Krieger\t\t[d13K]");          break;
        case 45: return("Schwerttaenzer\t\t[St]");             break;
        case 48: return("Landsgemeinde Felsenau\t[LF]");       break;
        case 51: return("Knights of Honor\t\t[KoH]");          break;
        case 52: return("Die Bruderschaft\t\t[DB]");           break;
        case 55: return("Konklave der Schatten\t[KdS]");       break;
        case 56: return("Equilibrium\t\t\t[EQ]");              break;
        case 59: return("Tempelwaechter\t\t[TW]");             break;
        case 60: return("Karims Schwarze Kraehen\t[KSK]");     break;
        case 61: return("Union freier Ritter\t\t[UfR]");       break;
        case 62: return("Consortes Caelestes\t\t[CC]");        break;
        case 63: return("Bund der Sitschan\t\t[BdS]");         break;
        case 64: return("Die letzten Ritter Alirions\t[LRA]"); break;
        case 65: return("Die Verrueckten\t\t[dV]");            break;
        case 66: return("Dvergr altvorderer Waechter\t[DAW]"); break;
        case 67: return("Raziels Klingen\t\t[RK]");            break;
        case 68: return("Die Nebel von Avalon\t[NA]");         break;
        case 69: return("Wiederstand\t\t\t[\"W\"]");           break;
        case 70: return("Nordwind\t\t\t[NW]");                 break;
        case 99: return("Test Spielleitung\t\t[G]");           break;
        default: return("?\t\t\t\t");                          break;
    }
}

int id(char * tag)
{
    if      (strcmp(tag,"EOR") == 0) return 16;
    else if (strcmp(tag,"SL")  == 0) return 17;
    else if (strcmp(tag,"ZdE") == 0) return 18;
    else if (strcmp(tag,"NoS") == 0) return 22;
    else if (strcmp(tag,"SK")  == 0) return 23;
    else if (strcmp(tag,"HA")  == 0) return 25;
    else if (strcmp(tag,"DR")  == 0) return 31;
    else if (strcmp(tag,"RG")  == 0) return 32;
    else if (strcmp(tag,"P")   == 0) return 38;
    else if (strcmp(tag,"d13K")== 0) return 43;
    else if (strcmp(tag,"St")  == 0) return 45;
    else if (strcmp(tag,"LF")  == 0) return 48;
    else if (strcmp(tag,"KoH") == 0) return 51;
    else if (strcmp(tag,"DB")  == 0) return 52;
    else if (strcmp(tag,"KdS") == 0) return 55;
    else if (strcmp(tag,"EQ")  == 0) return 56;
    else if (strcmp(tag,"TW")  == 0) return 59;
    else if (strcmp(tag,"KSK") == 0) return 60;
    else if (strcmp(tag,"UfR") == 0) return 61;
    else if (strcmp(tag,"CC")  == 0) return 62;
    else if (strcmp(tag,"BdS") == 0) return 63;
    else if (strcmp(tag,"LRA") == 0) return 64;
    else if (strcmp(tag,"dV")  == 0) return 65;
    else if (strcmp(tag,"DAW") == 0) return 66;
    else if (strcmp(tag,"RK")  == 0) return 67;
    else if (strcmp(tag,"NA")  == 0) return 68;
    else if (strcmp(tag,"&quot;W&quot;")  == 0) return 69;
    else if (strcmp(tag,"\"W\"")  == 0) return 69;
    else if (strcmp(tag,"NW")  == 0) return 70;
    else if (strcmp(tag,"G")   == 0) return 99;
    else return 0;
}

void putName(char * name)
{
    int i;
    char * newName;

    /* Standardisierung der Umlaute */
    newName = malloc(strlen(name)*2);
    newName[0] = 0;
    i = 0;
    while (i < strlen(name)) {
        switch (name[i]) {
            /* latin-1, 1 byte */
            case '\xC4': strcat(newName, "Ae"); i++; break;
            case '\xD6': strcat(newName, "Oe"); i++; break;
            case '\xDC': strcat(newName, "Ue"); i++; break;
            case '\xDF': strcat(newName, "ss"); i++; break;
            case '\xE4': strcat(newName, "ae"); i++; break;
            case '\xF6': strcat(newName, "oe"); i++; break;
            case '\xFC': strcat(newName, "ue"); i++; break;
            /* UTF-8, 2 bytes */
            case '\xC3':
                switch(name[++i]) {
                    case '\x84': strcat(newName, "Ae"); i++; break;
                    case '\x96': strcat(newName, "Oe"); i++; break;
                    case '\x9C': strcat(newName, "Ue"); i++; break;
                    case '\x9F': strcat(newName, "ss"); i++; break;
                    case '\xA4': strcat(newName, "ae"); i++; break;
                    case '\xB6': strcat(newName, "oe"); i++; break;
                    case '\xBC': strcat(newName, "ue"); i++; break;
                } break;
            /* HTML entities */
            case '&':
                i++;
                if (name[i] == 's') {
                    strcat(newName, "ss");
                    i += 6;
                } else {
                    strncat(newName, &name[i], 1);
                    strncat(newName, "e", 1);
                    i += 5;
                }
                break;
            /* ASCII Buchstabe */
            default: strncat(newName, &name[i++], 1); break;
        }
    }

    /* Ausgabeformatierung */
    strncpy(item, newName, 100);
    printf("%s", newName);
    if (strlen(newName) <  8) printf("\t");
    if (strlen(newName) < 16) printf("\t");
    if (strlen(newName) < 24) printf("\t");
}

void genValue(float textVal)
{
    char * name;
    float val;
    name = malloc(100);
    if(isAlly) {
        printf("%8.2f\t", textVal);
        itemVal *= textVal;
        /* preisliste schreiben */
        fprintf(prices,"%s\t", item);
        if (strlen(item) <  8) fprintf(prices, "\t");
        if (strlen(item) < 16) fprintf(prices, "\t");
        if (strlen(name) < 24) fprintf(prices, "\t");
        fprintf(prices,"%8.2f\n", textVal);
    }
    if(!isAlly) {
        while ((fscanf(prices,"%100[^\t]%*[\t]%f\n",name,&val) == 2)
            && (strcmp(name,item) != 0)) {
            /* preisliste bis zum richtigen item lesen */
        }
        if(strcmp(name,item) == 0) {
            printf("%8.2f\t", val);
            itemVal *= val;
        } else {
            printf("     n/a\t");
            itemVal = 0;
        }
        rewind(prices);
    }
    printf("%10.2f\n", itemVal);
    sum += itemVal;
}

void loadPrices()
{
    time_t fileTime;
    if( (prices = fopen(priceFile,"r")) == 0 ) {
        printf("FEHLER: Datei \"%s\" nicht vorhanden.\n", priceFile);
        exit(-1);
    } else {
        if(fscanf(prices, "Zeitstempel\t%ld\n", &fileTime) == 1) {
            printf("Preisdatei vom %s", ctime(&fileTime));
        } else {
            printf("Unbekannte Preisdatei: %s", priceFile);
        }
    }
}



int main(int argc, char* argv[])
{
    int contentLength;
    FILE* tmpFile;

    now = time(NULL);
    if (strcmp(argv[0], cgiName) == 0) {
        printf("Content-type: text/plain\n\n");
        contentLength = atoi(getenv("CONTENT_LENGTH"));
    } else {
        /* ausserhalb cgi unbeschraenkt */
        contentLength = 0;
    }
    printf("%s\n", VERSIONSTRING);
    printf("Aufgerufen am: %s", ctime(&now));

    item = malloc(100);

    if (argc < 2 && contentLength < maxIOBuffer) {
        yyin = stdin;
        yylex();
    } else if (argc < 2) {
        /* von stdin, aber passt nicht in buffer
           schreibe in tmpFile um deadlock zu verhindern
           siehe bug #14
         */
        tmpFile = fopen(tmpFileName, "w");
        while (!feof(stdin)) {
            fprintf(tmpFile, "%c", getchar());
        }
        fclose(tmpFile);
        yyin = fopen(tmpFileName, "r");
        yylex();
    } else {
        int i, j;
        for (i=1; i<argc; i++) {
            isAlly = 0;
            sum = 0;
            num = 0;
            for (j=0; j<100; j++) {
                aVal[j] = 0;
                aNum[j] = 0;
            }
            yyin = fopen(argv[i], "r");
            if (yyin == 0) {
                fprintf(stderr,
                    "Fehler: Konnte Datei %s nicht oeffnen.\n", argv[i]);
                exit(-1);
            } else {
                yylex();
            }
        }
    }


    return 0;
}

/* vim:set shiftwidth=4 expandtab smarttab: */
