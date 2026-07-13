/* Bundle derived from PROGETTO - pulizia dataset.sas (SOFA-Project)
   Phase 1, steps 3-4: implausible-value handling. Sentinel codes
   (-1 = missing, -2 = not evaluable) and biologically impossible
   entries (weight < 30 kg, height < 100 cm) are recoded to SAS
   missing. The author's ARRAY loop also rescales a calcium value of
   880 (a likely unit error) by dividing values in [100,999] by 100.
   Seeded with a small mock frame that triggers each rule. */

DATA SOFA_DATE;
INFILE DATALINES DLM='|' DSD;
INPUT PAZIENTE PESO ALTEZ TEMPRIC CADUTE MMSE_N CALC_N ALB_N VITD_N;
DATALINES;
1|72|168|5|0|28.5|9.2|3.8|22
2|-1|175|-1|-1|30|880|4.1|18.5
3|25|95|10|1|-1|10.1|-2|30.2
4|80|-1|-2|0|27|9.0|4.0|25
;
RUN;

*3) PROBLEMA PESO E ALTEZZA;
*Indentifico mancante con ".", trasformo -1 e numeri sospetti in mancante;
DATA SOFA_MANCANTI;
SET SOFA_DATE;

IF PESO=-1 THEN PESO=.;
IF PESO<30 THEN PESO=.;

IF ALTEZ=-1 THEN ALTEZ=.;
IF ALTEZ<100 THEN ALTEZ=.;

IF TEMPRIC=-1 THEN TEMPRIC=.;

IF CADUTE=-1 THEN CADUTE=.;

IF TEMPRIC=-2 THEN TEMPRIC=.;
RUN;

*4) PROBLEMA DATI MANCANTI;
*mmse, calc, alb, vitd hanno -1 se mancante e -2 se non valutabile;
*in CALC c'e un 880, probabile errore di unita, correggiamo dividendo per 100;
DATA SOFA_MANCANTI1;
SET SOFA_MANCANTI;

ARRAY VARS (*) MMSE_N CALC_N ALB_N VITD_N;
DO I=1 TO DIM(VARS);
IF VARS(I)=-1 OR VARS(I)=-2 THEN VARS(I)=.;
IF 100 <= VARS(I) <= 999 THEN VARS(I)=VARS(I)/100;
END;

DROP I;
RUN;

PROC PRINT DATA=SOFA_MANCANTI1;
TITLE "Valori implausibili ricodificati e calcio riscalato";
RUN;
