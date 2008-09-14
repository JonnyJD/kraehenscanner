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

const char *version = "kskscanner - Version 1.4.1 vom 14.9.2008";

const char *preisdatei = "preise";
const char *cgi_name = "kskscanner.cgi";
time_t jetzt;
extern FILE* yyin;
float itemval, sum;
int allynum, num;
int aval[100], anum[100];

/* fuer die Erstellung der allg. Preistabelle */
int isAlly;
char * item;
FILE * preise;
void genValue(float textval);
void loadPrices();

/* Hilfsfunktionen */
void putName(char * name);

/* fuer die Allianzstatistik */
char * ally(int id);
int id(char * tag);
%}

TAG	(<[^>]*>)
TAGN	{TAG}\n?
TAGS	{TAG}[^<]*
VAR	([^=]*=\")
PF	([^/]*\/)


 /* Seitentypen */
 /* Handelsbude - rbfhandel1.* */
%s HB
%x HNAME
%x GUT GNUM GKM GVAL
%x ST SNUM SVAL

 /* Reichsressourcen - rbrinfo0.*, rbrinfo.* */
%s RR
%x RNAME
%x RGUT RGUT2 RNUM

 /* Top Ten - rbtop10.* */
%s TT
%x PLR ALLY TAL AVAL


%%

 /* ----------------- Seitenerkennung  ---------------------------- */

"<font size=6 face=\"Diploma\">Dorf "	{ BEGIN(HNAME); }
<HNAME>[^<]*	{
		  if(strcmp(yytext,"Leipia, Handelsbude") == 0) {
			isAlly = 1;
			preise = fopen(preisdatei,"w");
			fprintf(preise,"Zeitstempel\t%ld\n", jetzt);
		  } else loadPrices();
		  printf("\n%s\n", yytext);
		  if(isAlly) printf(" - Allianzbude - \n");
		  printf("- - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n");
		}
<HNAME>"<"				{ BEGIN(HB); /* Handelsbude */ }

"<font size=6 face=\"Diploma\">Ressourcen im "	{ BEGIN(RNAME); }
<RNAME>[^<]*	{
		  loadPrices();
		  printf("\nRessourcen im %s\n", yytext);
		  printf("- - - - - - - - - - - - - - - - - - - - - - - - - - - - -\n");
		}
<RNAME>"<"	{ BEGIN(RR); /* Reichsressourcen */ }

"<font size=6 face=\"Diploma\">TOP 10"	{
					  printf("\nAllianzpunkte");
					  printf("\t\t\t\t\t\tSchnitt\n");
					  printf("- - - - - - -\n");
					  BEGIN(TT);
					}


 /* -------------------- HB Gueter -------------------------------- */

<HB>"<img src=\""{PF}{6}"gut"[0-9]*".gif\">&nbsp;"	{ BEGIN(GUT); }
<GUT>[^<]*			{ putName(yytext); }
<GUT>{TAGN}{5}			{ BEGIN(GNUM); }
<GUT>{TAGN}{4}			{ BEGIN(GKM); }

<GKM>[0-9]*			{
				  itemval = atoi(yytext);
				  printf("%6.0f\t", itemval);
				  genValue(1.0);
				}
<GKM>.|\n			{ BEGIN(HB); }

<GNUM>[0-9]*			{
				  itemval = atoi(yytext);
				  printf("%6.0f\t", itemval);
				}
<GNUM>{TAGS}{27,30}{VAR}{6}	{ BEGIN(GVAL); }
<GNUM>.|\n			{ ECHO; }

<GVAL>[0-9.]*			{ genValue(atof(yytext)); }
<GVAL>"\""			{ BEGIN(HB); }
<GVAL>.|\n			{ /* nothing */ }


 /* -------------- HB Gegenstaende -------------------- */

<HB>"<img src=\""{PF}{6}"st"[0-9]*".gif\" border=0>"	{ BEGIN(ST); }
<ST>[^<]*			{ putName(yytext); }
<ST>{TAGN}{5}([0-9]*"/")*	{ BEGIN(SNUM); }

<SNUM>[0-9]*			{
				  itemval = atoi(yytext);
				  printf("%6.0f\t", itemval);
				}
<SNUM>{TAGS}{27,33}{VAR}{6}	{ BEGIN(SVAL); }
<SNUM>.|\n			{ ECHO; }

<SVAL>[0-9.]*			{ genValue(atof(yytext)); }
<SVAL>"\""			{ BEGIN(HB); }
<SVAL>.|\n			{ ECHO; }

 /* -------------------- RR Gueter und Gegenstaende ---------------------- */

<RR>"<IMG SRC=\""{PF}{6}"gut"[0-9]*".gif\" border=0>&nbsp;"	{ BEGIN(RGUT); /* Gut */}
<RR>"<img src=\""{PF}{6}"gut"[0-9]*".gif\" border=0>&nbsp;"	{ BEGIN(RGUT); /* Gut */}
<RR>"<IMG SRC=\""{PF}{6}"st"[0-9]*".gif\" border=0>"	{
				  BEGIN(RGUT); /* Gegenstand rbrinfo.* */ }
<RR>"<a href=\"javascript:fensterSache("[0-9]*")\">"	{
				  BEGIN(RGUT); /* Gegenstand rbrinfo.* */ }

<RGUT>"<"			{ BEGIN(RR); /* anders bei rbrinfo Gegenst. */ }
<RGUT>[^<]*			{
				  putName(yytext);
				  BEGIN(RGUT2);
				}
<RGUT2>"<b>"				{ BEGIN(RNUM); /* rbrinfo0.* */ }
<RGUT2>"</td><td>"			{ BEGIN(RNUM); }
<RGUT2>"<td>"				{ BEGIN(RNUM); /*Umlautschluckung */ }
<RGUT2>"</td><td></td><td>"		{ BEGIN(RNUM); }
<RGUT2>"<td></td>\n<td>"		{ BEGIN(RNUM); }
<RGUT2>"<td>&nbsp;"[0-9]+"</td><td>"	{ BEGIN(RNUM); /* rbrinfo.* */ }
<RGUT2>("</tr>"|"</TR>")		{
				  /* kein Wert gefunden = 0 */
				  itemval = 0;
				  printf("%6.0f\t", 0.0);
				  genValue(-1.0);
				  BEGIN(RR);
				}
<RGUT2>.|\n			{ /* ueberlesen */ }

<RNUM>[0-9]*			{
				  itemval = atoi(yytext);
				  printf("%6.0f\t", itemval);
				  genValue(itemval);
				  BEGIN(RR);
				}
<RNUM>[<&]			{ BEGIN(RGUT2); }
<RNUM>.|\n			{ ECHO; }


 /* ------------- Top 10 ---------------------------- */

<TT>"<b>"[0-9]*".</b></td><td valign=bottom><b>"[^<]*"</b></td><td valign=bottom>"				{ BEGIN(PLR); }
<PLR>[0-9]*			{
				  sum += atoi(yytext);
				  num++;
				  BEGIN(TT);
				}

<TT>"allym"			{ BEGIN(ALLY); }
<TT>"["				{ BEGIN(TAL);  }

<ALLY>[0-9]*				{ allynum = atoi(yytext); }
<ALLY>".gif\" border=0></td><td valign=bottom>"	{ BEGIN(AVAL); }

<TAL>[^\]]*				{ allynum = id(yytext); }
<TAL>"]</b></td><td valign=bottom>"	{ BEGIN(AVAL); }

<AVAL>[0-9]*			{
				  aval[allynum] += atoi(yytext);
				  anum[allynum]++;
				  BEGIN(TT);
				}


 /* ------------- Allgemein ------------------------- */

<HB,RR><<EOF>>		{
			  printf("\t\t\t\t\t\t----------\n");
			  printf("Summe:\t\t\t\t\t\t%10.2f\n\n", sum);
			  fclose(preise);
			  return 0;
			}
<TT><<EOF>>	{
		  int i, higherpos, max, pos;
		  printf(" 0. Allianzlose\t\t\t\t%8.0f", sum);
		  printf("%5d%10.0f\n", num, sum/num);
		  higherpos = 999999999;
		  pos = 1;
	          do {
			max = 0;
			for (i=0; i<100; i++) {
				if (aval[i]<higherpos && aval[i]>max) {
					max = aval[i];
				}
			}
			higherpos = max;
			for (i=0; i<100; i++) {
				if (aval[i]>0 && aval[i] == max) {
					printf("%2d. ", pos);
					printf("%s\t%8d", ally(i), aval[i]);
					printf("%5d", anum[i]);
					printf("%10d\n", aval[i]/anum[i]);
					sum += aval[i];
					num += anum[i];
				}
			}
			pos++;
		  } while (max > 0);
		  printf("\t\t\t\t\t--------\n");
		  printf("Gesamt\t\t\t\t\t%8.0f", sum);
		  printf("%5d%10.0f\n\n", num, sum/num);
		  return 0;
		}

.|\n			{ /* uninteresting */ }
<INITIAL><<EOF>>	{ return 0; }

%%


char * ally(int id) {
	switch (id) {
		case 16: return("Magistraten der Caldea\t[MAG]"); break;
		case 17: return("Koenigliche Allianz\t[SL]"); break;
		case 18: return("Zirkel der Erklaerten\t[ZdE]"); break;
		case 22: return("Nations of Senoi\t\t[NoS]"); break;
		case 23: return("SzasKhar\t\t[SK]"); break;
		case 25: return("Bewahrer der Heiligen Allianz\t[HA]"); break;
		case 31: return("Drachenritter\t\t[DR]"); break;
		case 32: return("Raeubergilde\t\t[RG]"); break;
		case 38: return("Piraten\t\t\t[P]"); break;
		case 43: return("Die 13. Krieger\t\t[d13K]"); break;
		case 45: return("Schwerttaenzer\t\t[St]"); break;
		case 48: return("Landsgemeinde Felsenau\t[LF]"); break;
		case 51: return("Knights of Honor\t\t[KoH]"); break;
		case 52: return("Die Bruderschaft\t\t[DB]"); break;
		case 55: return("Konklave der Schatten\t[KdS]"); break;
		case 56: return("Equilibrium\t\t\t[EQ]"); break;
		case 59: return("Tempelwaechter\t\t[TW]"); break;
		case 60: return("Karims Schwarze Kraehen\t[KSK]"); break;
		case 61: return("Union freier Ritter\t\t[UfR]"); break;
		case 62: return("Consortes Caelestes\t\t[CC]"); break;
		case 63: return("Bund der Sitschan\t\t[BdS]"); break;
		case 64: return("Die letzten Ritter Alirions\t[LRA]"); break;
		case 65: return("Die Verrueckten\t\t[dV]"); break;
		case 66: return("Dvergr altvorderer Waechter\t[DAW]"); break;
		case 67: return("Raziels Klingen\t\t[RK]"); break;
		case 99: return("Test Spielleitung\t\t[G]"); break;
		default: return "?";
	}
}

int id(char * tag) {
	if (strcmp(tag,"MAG") == 0) return 16;
	else if (strcmp(tag,"SL") == 0) return 17;
	else if (strcmp(tag,"ZdE") == 0) return 18;
	else if (strcmp(tag,"NoS") == 0) return 22;
	else if (strcmp(tag,"SK") == 0) return 23;
	else if (strcmp(tag,"HA") == 0) return 25;
	else if (strcmp(tag,"DR") == 0) return 31;
	else if (strcmp(tag,"RG") == 0) return 32;
	else if (strcmp(tag,"P") == 0) return 38;
	else if (strcmp(tag,"d13K") == 0) return 43;
	else if (strcmp(tag,"St") == 0) return 45;
	else if (strcmp(tag,"LF") == 0) return 48;
	else if (strcmp(tag,"KoH") == 0) return 51;
	else if (strcmp(tag,"DB") == 0) return 52;
	else if (strcmp(tag,"KdS") == 0) return 55;
	else if (strcmp(tag,"EQ") == 0) return 56;
	else if (strcmp(tag,"TW") == 0) return 59;
	else if (strcmp(tag,"KSK") == 0) return 60;
	else if (strcmp(tag,"UfR") == 0) return 61;
	else if (strcmp(tag,"CC") == 0) return 62;
	else if (strcmp(tag,"BdS") == 0) return 63;
	else if (strcmp(tag,"LRA") == 0) return 64;
	else if (strcmp(tag,"dV") == 0) return 65;
	else if (strcmp(tag,"DAW") == 0) return 66;
	else if (strcmp(tag,"RK") == 0) return 67;
	else if (strcmp(tag,"G") == 0) return 99;
	else return 0;
}

void putName(char * name) {
	int i;
	char * newname;

	newname = malloc(strlen(name)*2);
	newname[0] = 0;
	i = 0;
	while (i < strlen(name)) {
		switch (name[i]) {
			case '\xC4': strcat(newname, "Ae"); i++; break;
			case '\xD6': strcat(newname, "Oe"); i++; break;
			case '\xDC': strcat(newname, "Ue"); i++; break;
			case '\xDF': strcat(newname, "ss"); i++; break;
			case '\xE4': strcat(newname, "ae"); i++; break;
			case '\xF6': strcat(newname, "oe"); i++; break;
			case '\xFC': strcat(newname, "ue"); i++; break;
			case '&':
				i++;
				if (name[i] == 's') {
					strcat(newname, "ss");
					i += 6;
				} else {
					strncat(newname, &name[i], 1);
					strncat(newname, "e", 1);
					i += 5;
				}
				break;
			default: strncat(newname, &name[i++], 1); break;
		}
	}

	strncpy(item, newname, 100);
	printf("%s", newname);
	if (strlen(newname) < 8)  printf("\t");
	if (strlen(newname) < 16) printf("\t");
	if (strlen(newname) < 24) printf("\t");
}

void genValue(float textval) {
	char * name;
	float val;
	name = malloc(100);
	if(isAlly) {
		printf("%8.2f\t", textval);
		itemval *= textval;
		/* preisliste schreiben */
		fprintf(preise,"%s\t", item);
		if (strlen(item) < 8)  fprintf(preise, "\t");
		if (strlen(item) < 16) fprintf(preise, "\t");
		if (strlen(name) < 24) fprintf(preise, "\t");
		fprintf(preise,"%8.2f\n", textval);
	}
	if(!isAlly) {
		while ((fscanf(preise,"%100[^\t]%*[\t]%f\n",name,&val) == 2)
			&& (strcmp(name,item) != 0))
		{ /* preisliste lesen */ }
		if(strcmp(name,item) == 0) {
			printf("%8.2f\t", val);
			itemval *= val;
		} else {
			printf("     n/a\t");
			itemval = 0;
		}
		rewind(preise);
	}
	printf("%10.2f\n", itemval);
	sum += itemval;
}

void loadPrices() {
	time_t dateizeit;
	if((preise = fopen(preisdatei,"r")) == 0) {
		printf("FEHLER: Datei \"%s\" nicht vorhanden.\n", preisdatei);
		exit(-1);
	} else {
		if(fscanf(preise, "Zeitstempel\t%ld\n", &dateizeit) == 1) 
			printf("Preisdatei vom %s", ctime(&dateizeit));
		else
			printf("Unbekannte Preisdatei: %s", preisdatei);
	}
}



int main(int argc, char* argv[]) {
	jetzt = time(NULL);
	if (strcmp(argv[0], cgi_name) == 0) {
		printf("Content-type: text/plain\n\n");
	}
	printf("%s\n", VERSIONSTRING);
	printf("Aufgerufen am: %s", ctime(&jetzt));

	item = malloc(100);

	if (argc < 2) yyin = stdin;
	else {
		int i, j;
		for (i=1; i<argc; i++) {
			isAlly = 0; sum = 0; num = 0;
			for (j=0; j<100; j++) {
				aval[j] = 0; anum[j] = 0;
			}
			yyin = fopen(argv[i], "r");
			if (yyin == 0) {
				fprintf(stderr,
			    "Fehler: Konnte Datei %s nicht oeffnen.\n",
			    argv[i]);
				exit(-1);
			} else yylex();
		}
	}


	return 0;
}
