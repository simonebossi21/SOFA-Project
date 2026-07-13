/* Bundle derived from PROGETTO - pulizia dataset.sas (SOFA-Project)
   Phase 1, step 2: birth-date correction. Some dates carry 1829 in
   place of 1929 (read as CHARACTER, DD/MM/YY), while others arrive
   as Excel numeric serials. The author's INDEXC branch detects the
   format and applies INTNX 'YEAR' +100 to the character dates, and
   the '30DEC1899'd Excel->SAS epoch offset to the numeric ones.
   Seeded with a small mock frame carrying both representations. */

DATA SOFA1;
INFILE DATALINES DLM='|' DSD;
INPUT PAZIENTE NASCITA :$12.;
DATALINES;
1|03/07/1829
2|15/11/1829
3|10921
4|22/01/1830
;
RUN;

*2.1 alcune date hanno 1829 al posto di 1929;
* La differenza tra 01/01/1960 (SAS) e 01/01/1900 (Excel) e '30DEC1899'd;
DATA SOFA_DATE;
SET SOFA1;

*trova se c'e "/";
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

PROC PRINT DATA=SOFA_DATE;
TITLE "Date di nascita corrette (1829->1929 e conversione epoca Excel)";
RUN;
