PROC IMPORT FILE="/home/u64212496/LAB R e SAS/SOFA.xlsx"
OUT=SOFA_IMP DBMS=XLSX REPLACE;
RUN;

PROC IMPORT FILE="/home/u64212496/LAB R e SAS/SOFA_modificato.xlsx"
OUT=SOFA_IMP DBMS=XLSX REPLACE;
RUN;
*ID 29 e 111 DA MODIFICALE MANUALMENTE SU EXCEL;

DATA SOFA;
SET SOFA_IMP;
IF PAZIENTE=. THEN DELETE;

RENAME "DATA DECESSO"n=DATA_DECESSO;

INFORMAT DATDIM DATINT  YYMMDD10.;
FORMAT DATDIM DATINT  DDMMYY10.;
RUN;

PROC SORT DATA=SOFA; BY PAZIENTE; RUN;



*0.1) FORMATO DELLE VARIABILI:

alcuni variabili nel datset excel contengono la , come delimitatore decimale, 
questo comporta che in SAS queste variabili vengano lette come CARATTERE;

*in mmse + presente un "/" per errore;
DATA CORREZIONI_MANUALI;
SET SOFA;

*trova se c'è "/";
IF INDEXC(MMSE, '/') > 0 THEN MMSE=""; *valore mancante di tipo carattere;

RUN;

* le variabili da trsformare in numeriche sono MMSE CALC ALB VITD;
*si procede con sostituire la virgola con il punto;

DATA SOFA_PUNTI;
SET CORREZIONI_MANUALI;

ARRAY VARS(*) $ MMSE CALC ALB VITD HBING; 

*nuovo array che conterrà variabili con punto;
ARRAY VARS_NEW(*) $ 20 MMSE CALC ALB VITD HBING;

DO I = 1 TO DIM(VARS); 
*sostituisce virgola con punto;   
VARS_NEW(I) = TRANWRD(VARS(I), ',', '.');
END;

   
DROP I;
RUN;


*ora si procede con la conversione da carattere a numeriche;

DATA SOFA_;
SET SOFA_PUNTI;

ARRAY VARS(*) $ MMSE CALC ALB VITD HBING; 

ARRAY VARS_NUM(*) MMSE_N CALC_N ALB_N VITD_N HBING_N; *nuove variabili;

DO I = 1 TO DIM(VARS);
VARS_NUM(I) = INPUT(VARS(I), 32.);
END;
    
DROP I;
DROP MMSE CALC ALB VITD HBING;
RUN;

*---------------------------------------------------;


*1) PROBLEMA ID RIPETUTI;

*ci sono degli identificativi dei pazienti che si ripetono su pazienti diversi,
per identificarli utilizziamo la funzione first. che assegna 1 a ogni prima riga con 
stesso valore della varibile "PAZINTE";

*il nuovo identificativo sarà il vecchio +1;

*********************METODO 1*****************;
DATA SOFA1;
SET SOFA_; 
BY PAZIENTE;

IF FIRST.PAZIENTE=1 THEN FLAG=1;
IF FLAG=. THEN PAZIENTE=PAZIENTE+1;

DROP FLAG;

RUN;

PROC FREQ DATA=SOFA1;
TABLES PAZIENTE /NOCOL NOPERCENT;
RUN;

********************METODO 2******************;

*il procedimento di sopra ha un problema, ovvero se id+1 è occupato si ripresenta il problema,
per ovviare tramite PROC SQL prendo il valore dell'ultimo id (sono ordinati) e aggiungo +1,
in questo modo sicuramente il nuovo id sarà l'unico;

*Ovviemnte funziona se c'è un unico valore duplicato;

PROC SQL;
  CREATE TABLE TABELLA_ULTIMO_ID AS /* crea un nuovo dataset */
  SELECT PAZIENTE, /* prendi tutte le variabili originali */
  MAX(PAZIENTE) AS ULTIMO_ID /* aggiungi una nuova colonna 'ULTIMO_ID' */
  FROM SOFA; 
QUIT;

DATA SOFA_SQL;
MERGE SOFA TABELLA_ULTIMO_ID;
RUN;

DATA SOFA_SQL;
SET SOFA_SQL; 
BY PAZIENTE;

IF FIRST.PAZIENTE=1 THEN FLAG=1;
IF FLAG=. THEN PAZIENTE=ULTIMO_ID+1;

DROP FLAG;

RUN;



*---------------------------------------------------------------;

*2) PROBLEMA DATE;

*2.1 alcune date hanno 1829 al posto di 1929
queste date vengono lette da sas in formato CARATTERE quindi mantenfono il formato
GG/MM/YY;

* La differenza tra le due date di riferimento (01/01/1960 
per SAS e 01/01/1900 per Excel) è di 21916 giorni;

* La costante '30DEC1899'd è proprio quel valore di spostamento, che tiene anche
 conto del bug di Excel relativo all'anno 1900;

DATA SOFA_DATE;
SET SOFA1;

*trova se c'è "7";
IF INDEXC(NASCITA, '/') > 0 THEN DO;
temp_date = INPUT(NASCITA, DDMMYY10.);
        
*aggiunge 100 anni;        
NASCITA_SAS = INTNX('YEAR', temp_date, 100);
END;
ELSE DO;
       
*Aggiunge la costante per passare dal sistema di date Excel a quello SAS;
NASCITA_SAS = INPUT(NASCITA, BEST.) + '30DEC1899'd;
END;
    
DROP NASCITA temp_date;
RENAME NASCITA_SAS = NASCITA;

FORMAT NASCITA_SAS DDMMYY10.;
RUN;


*---------------------------------------------------------;

*3)PROBLEMA PESO E ALTEZZA;

*METODO 1: 
-1 = mancante

Indentifico mancante con ".", trasformo tutti i "-1" e 
numeri sospetti in mancante;

DATA SOFA_MANCANTI;
SET SOFA_DATE;

IF PESO=-1 THEN PESO=.;
IF PESO<30 THEN PESO=.;

IF ALTEZ=-1 THEN ALTEZ=.;
IF ALTEZ<100 THEN ALTEZ=.;

IF TEMPRIC=-1 THEN TEMPRIC=.;

IF CADUTE=-1 THEN CADUTE=.;

IF TEMPRIC=-2 THEN TEMPRIC=.;

IF DATA_DECESSO=-1 THEN DATA_DECESSO="";
IF DATA_DECESSO="SI è RIFIUTATA" THEN DATA_DECESSO="";
RUN;

*data_decesso è in formato carattere, trasformiamola in formato numerico;

DATA SOFA_MANCANTI;
SET SOFA_MANCANTI;

DATA_DECESSO_N=INPUT(DATA_DECESSO, 12.) + '30DEC1899'd;

FORMAT DATA_DECESSO_N DDMMYY10.;
DROP DATA_DECESSO;
RUN;

*---------------------------------------------------;

*4) PROBLEMA DATI MANCANTI;

*le variabili mmse, calc, alb, vitd hanno -1 se mancante e -2 se non valutabile;
*trasformiamo tutte in dati mancanti "." utilizzando un ARRAY;
*in CALC_C c'è un 880, probabile errore di unità di misura, correggiamo dividendo per 100;

DATA SOFA_MANCANTI1;
SET SOFA_MANCANTI;

ARRAY VARS (*) MMSE_N CALC_N ALB_N VITD_N;
DO I=1 TO DIM(VARS);
IF VARS(I)=-1 OR VARS(I)=-2 THEN VARS(I)=.;
IF 100 <= VARS(I) <= 999 THEN VARS(I)=VARS(I)/100;
END;

DROP I;
RUN;

*5) problema decesso prima di intervento
E intervento prima di dimissione;


DATA SOFA_MANCANTI2;
SET SOFA_MANCANTI1;

/* Questo loop si attiva solo se la data di decesso è precedente
a quella di intervento e non è mancante. */
DO WHILE (DATA_DECESSO_N < DATINT AND DATA_DECESSO_N NE .);
    
/* Aggiunge esattamente 1 anno alla data di decesso,
gestendo correttamente gli anni bisestili, con SAME mantiene stesso giorno e mese */
DATA_DECESSO_N = INTNX('YEAR', DATA_DECESSO_N, 1, 'SAME');
END;
RUN;


*nel paziente 145;

*CALCOLIAMO LA PERMANENZA MEDIA;

DATA SOFA_MANCANTI3;
SET SOFA_MANCANTI2;

IF DATDIM NE . THEN DO;
TEMPO_PERMANENZA=DATDIM-DATINT;
END;

IF TEMPO_PERMANENZA<0 THEN TEMPO_PERMANENZA=.;

RUN;

PROC MEANS DATA=SOFA_MAnCANTI3 MEAN;
VAR TEMPO_PERMANENZA;
ODS OUTPUT SUMMARY=MEDIA;
RUN;

PROC MEANS DATA=SOFA_MAnCANTI3 MEDIAN;
VAR TEMPO_PERMANENZA;
ODS OUTPUT SUMMARY=MEDIANA;
RUN;

DATA STAT;
SET MEDIANA;
CALL SYMPUTX("TEMPO_MEDIANO", TEMPO_PERMANENZA_median );
RUN;

%PUT &TEMPO_MEDIANO;

DATA _NULL_;
SET MEDIA;
CALL SYMPUTX("TEMPO_MEDIO", TEMPO_PERMANENZA_mean);
RUN;

%PUT &TEMPO_MEDIO;

DATA SOFA_MANCANTI4;
SET SOFA_MANCANTI3;

IF DATINT>DATDIM AND DATDIM NE . THEN DO;
DATDIM=DATINT+&TEMPO_MEDIO;
END;

DROP TEMPO_PERMANENZA;
RUN;

DATA SOFA_corretto;
SET SOFA_MANCANTI4;

RENAME MMSE_N=MMSE;
RENAME CALC_N=CALC;
RENAME ALB_N=ALB;
RENAME VITD_N=VITD;
RENAME HBING_N=HBING;
RENAME DATA_DECESSO_N=DATA_DECESSO;

RUN;

DATA SOFA_corretto_test;
set SOFA_corretto;

IF DATINT>DATDIM AND DATDIM NE . THEN DO;
flag=1;
end;


if data_decesso ne . and data_decesso<DATINT then bandiera=1;

if data_decesso ne . and data_decesso<DATdim then bandiera1=1;

if data_decesso=datint then ug=1;
run;

*SPECIFICHIAMO I FORMATI;

PROC FORMAT;
VALUE SEX
1="uomo"
2="donna";

VALUE STATCIV
1="non sposato/a senza partner"
2="coniugato/a"
3="convivente"
4="separato/divorziato"
5="vedovo";

VALUE ANEST
1="generale"
2="spinale"
3="pendurale"
4="plesica"
5="combinata"
6="sedazione"
7="locale assistita"
8="altro";

run;





***************************************************
**************ANALISI DELLA SOPRAVVIVENZA**********
***************************************************;

*"Qual è la probabilità che un paziente sopravviva al ricovero chirurgico?";

*La censura avviene quando: il paziente viene dimesso vivo. In quel momento, 
l'osservazione si interrompe. Non sappiamo cosa accadrà dopo, ma sappiamo che è sopravvissuto almeno per tutta la durata del ricovero.
;

PROC MEANS DATA=SOFA_CORRETTO;
VAR SOFAING;
RUN;

PROC FORMAT;
VALUE GRUPPO
1="SOFA=0"
2="SOFA>0";
RUN;

DATA SOPRAVVIVENZA;
SET SOFA_CORRETTO;

/* Definiamo la data di fine studio (ultima data nota nel dataset) */
DATA_FINE_STUDIO = '30DEC2012'd;

EVENT=(DATA_DECESSO NE .);

IF EVENT=1 THEN TEMPO_EVENTO=DATA_DECESSO-DATINT;
IF EVENT=0 THEN TEMPO_EVENTO=DATA_FINE_STUDIO-DATINT;

IF SOFAING = 0 THEN SOFA_gruppo = 1;
ELSE SOFA_gruppo = 2;

FORMAT SOFA_gruppo GRUPPO.;

RUN;

ODS pdf FILE="/home/u64212496/LAB R e SAS/tabella_log_rank1.pdf" STYLE=minimal;

/* Diciamo a SAS di "catturare" solo la tabella chiamata ParameterEstimates */
ODS SELECT HomTests;

ods trace on;
PROC LIFETEST DATA=SOPRAVVIVENZA PLOTS=SURVIVAL(ATRISK);
TIME TEMPO_EVENTO* EVENT(0);
STRATA SOFA_GRUPPO;
TITLE "Curve di Sopravvivenza";
RUN;
ods trace off;

ODS pdf CLOSE;
ODS SELECT ALL; 

*Questo significa che i pazienti con una disfunzione d'organo all'ingresso
 hanno una probabilità di sopravvivenza a lungo termine 
 significativamente inferiore.;
* L'ultimo paziente di quel gruppo esce dall'osservazione (per morte o censura) a circa 100 giorni, 
e quindi la curva non può proseguire oltre;




/* --- Calcolo dell'Hazard Ratio con PROC PHREG --- */


PROC PHREG DATA=SOPRAVVIVENZA;
MODEL TEMPO_EVENTO * EVENT(0) = SOFA_gruppo / RISKLIMITS;
    
TITLE "Modello di Cox per il Calcolo dell'Hazard Ratio";

RUN;



/* --- 2. Usa ODS per creare un file HTML e selezionare SOLO la tabella che vuoi --- */
/* Apriamo una destinazione HTML */
ODS pdf FILE="/home/u64212496/LAB R e SAS/tabella_hazard_ratio1.pdf" STYLE=minimal;

/* Diciamo a SAS di "catturare" solo la tabella chiamata ParameterEstimates */
ODS SELECT ParameterEstimates;


/* --- 3. Esegui la tua analisi PROC PHREG --- */
/* SAS eseguirà il codice ma manderà nel file HTML solo la tabella selezionata */
PROC PHREG DATA=SOPRAVVIVENZA;
    MODEL TEMPO_EVENTO * EVENT(0) = SOFA_gruppo / RISKLIMITS;
    TITLE "Modello di Cox per il Calcolo dell'Hazard Ratio";
RUN;


/* --- 4. Chiudi la destinazione HTML e ripristina l'output normale --- */
ODS pdf CLOSE;
ODS SELECT ALL; /* Importante: ripristina l'output per non influenzare i prossimi step */