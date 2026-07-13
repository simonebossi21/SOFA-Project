/* Bundle derived from PROGETTO - pulizia dataset.sas (SOFA-Project)
   Phase 1, step 1 (METODO 1): resolve duplicated patient IDs with the
   author's FIRST.-flag increment method, then verify uniqueness with
   PROC FREQ. Seeded with a small mock frame containing a duplicated
   PAZIENTE, matching the pipeline's handling. */

DATA SOFA_;
INFILE DATALINES DLM='|' DSD;
INPUT PAZIENTE SOFAING;
DATALINES;
10|0
11|2
11|1
12|0
13|3
;
RUN;

PROC SORT DATA=SOFA_; BY PAZIENTE; RUN;

*********************METODO 1*****************;
*first. assegna 1 a ogni prima riga con stesso valore di PAZIENTE;
*il nuovo identificativo sarà il vecchio +1;
DATA SOFA1;
SET SOFA_;
BY PAZIENTE;

IF FIRST.PAZIENTE=1 THEN FLAG=1;
IF FLAG=. THEN PAZIENTE=PAZIENTE+1;

DROP FLAG;

RUN;

PROC FREQ DATA=SOFA1;
TABLES PAZIENTE /NOCOL NOPERCENT;
TITLE "ID pazienti resi univoci (metodo FIRST. + 1)";
RUN;

PROC PRINT DATA=SOFA1;
TITLE "Dataset con identificativi corretti";
RUN;
