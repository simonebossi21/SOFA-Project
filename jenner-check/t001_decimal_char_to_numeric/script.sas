/* Bundle derived from PROGETTO - pulizia dataset.sas (SOFA-Project)
   Phase 1, step 0.1: fix comma decimal separators, then convert
   character variables (read that way because Excel used commas)
   to numeric. Same ARRAY / TRANWRD / INPUT logic as the pipeline,
   seeded with a small mock frame matching the documented schema. */

/* mock: variables arrive as CHARACTER with comma decimals, as they
   would after PROC IMPORT of the original Excel sheet */
DATA SOFA;
INFILE DATALINES DLM='|' DSD;
INPUT PAZIENTE MMSE :$8. CALC :$8. ALB :$8. VITD :$8. HBING :$8.;
DATALINES;
1|28,5|9,2|3,8|22,0|13,4
2|30|8,8|4,1|18,5|12,9
3|24,0|10,1|3,5|30,2|11,0
4|/|9,0|4,0|25,0|14,1
5|27,5|880|3,9|20,0|13,0
;
RUN;

*in mmse c'è un "/" per errore;
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

PROC PRINT DATA=SOFA_;
VAR PAZIENTE MMSE_N CALC_N ALB_N VITD_N HBING_N;
TITLE "Variabili convertite in numeriche (virgola -> punto)";
RUN;
