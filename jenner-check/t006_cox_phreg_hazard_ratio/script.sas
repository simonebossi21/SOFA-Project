/* Bundle derived from PROGETTO - pulizia dataset.sas (SOFA-Project)
   Phase 2, step 2: Cox proportional-hazards model. The author fits a
   Cox regression with PROC PHREG on the same EVENT/TEMPO_EVENTO frame,
   using the SOFA group as the covariate and RISKLIMITS to report the
   Hazard Ratio (relative risk of death for organ dysfunction at
   admission). Seeded with the same mock survival frame as the
   Kaplan-Meier step, built the pipeline's way. */

DATA BASE;
INFILE DATALINES DLM='|' DSD;
INPUT PAZIENTE SOFAING DATINT :DATE9. DATA_DECESSO :DATE9.;
DATALINES;
1|0|02JAN2010|20MAR2011
2|0|10FEB2010|15AUG2012
3|0|05MAR2010|.
4|0|20APR2010|.
5|0|15MAY2010|10JAN2012
6|2|11MAY2010|30JUL2010
7|3|18JUN2010|02SEP2010
8|1|25JUL2010|.
9|4|30AUG2010|15OCT2010
10|2|09SEP2010|20DEC2011
11|1|12OCT2010|.
12|3|05NOV2010|18FEB2011
;
RUN;

DATA SOPRAVVIVENZA;
SET BASE;

DATA_FINE_STUDIO = '30DEC2012'd;

EVENT=(DATA_DECESSO NE .);

IF EVENT=1 THEN TEMPO_EVENTO=DATA_DECESSO-DATINT;
IF EVENT=0 THEN TEMPO_EVENTO=DATA_FINE_STUDIO-DATINT;

IF SOFAING = 0 THEN SOFA_gruppo = 1;
ELSE SOFA_gruppo = 2;

RUN;

/* --- Calcolo dell'Hazard Ratio con PROC PHREG --- */
PROC PHREG DATA=SOPRAVVIVENZA;
MODEL TEMPO_EVENTO * EVENT(0) = SOFA_gruppo / RISKLIMITS;

TITLE "Modello di Cox per il Calcolo dell'Hazard Ratio";

RUN;
