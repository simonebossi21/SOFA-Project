# SOFA Score & Surgical Survival Analysis

A SAS-based data cleaning and survival analysis pipeline for a clinical dataset of elderly patients undergoing surgery. The project investigates whether organ dysfunction at admission — measured by the **SOFA (Sequential Organ Failure Assessment)** score — is associated with in-hospital mortality.

## Research Question

> *"What is the probability that a patient survives surgical hospitalization, and does the SOFA score at admission significantly affect survival?"*

## Dataset

The raw data (`SOFA.xlsx`) contains clinical records for surgical patients with the following variables:

| Variable | Description |
|---|---|
| `PAZIENTE` | Patient ID |
| `NASCITA` | Date of birth |
| `SEX` | Sex (1 = Male, 2 = Female) |
| `STATCIV` | Marital status (1–5 scale) |
| `PESO` | Weight (kg) |
| `ALTEZ` | Height (cm) |
| `CADUTE` | Falls |
| `CCSCORE` | Charlson Comorbidity Score |
| `SOFAING` | SOFA score at admission |
| `MMSE` | Mini-Mental State Examination |
| `ALB` | Albumin |
| `CALC` | Calcium |
| `VITD` | Vitamin D |
| `HBING` | Hemoglobin at admission |
| `TEMPRIC` | Recovery time |
| `DATDIM` | Discharge date |
| `DATINT` | Surgery date |
| `INTDURAT` | Intervention duration |
| `ANEST` | Anesthesia type (1–8 scale) |
| `DATA DECESSO` | Date of death |

A manually corrected version (`SOFA_modificato.xlsx`) is also provided, with fixes applied to patient IDs 29 and 111.

## Pipeline Overview

The SAS program (`PROGETTO_-_pulizia_dataset.sas`) performs the full workflow in two phases:

### Phase 1 — Data Cleaning

1. **Decimal separator correction**: Several numeric variables (`MMSE`, `CALC`, `ALB`, `VITD`, `HBING`) use commas as decimal separators in Excel, causing SAS to import them as character strings. The pipeline replaces commas with dots and converts them to numeric type.

2. **Duplicate patient ID resolution**: Some patient IDs are duplicated across different individuals. Two methods are implemented — a simple increment approach and a robust `PROC SQL`-based method that assigns the next available ID after the current maximum.

3. **Date correction**: Some birth dates contain the year 1829 instead of 1929. The code detects the date format (character vs. Excel numeric) and applies the appropriate correction, including Excel-to-SAS epoch adjustment (`30DEC1899` offset).

4. **Implausible value handling**: Sentinel values (`-1` = missing, `-2` = not evaluable) and biologically implausible entries (weight < 30 kg, height < 100 cm) are recoded as SAS missing values (`.`). A calcium value of 880 (likely a unit error) is corrected by dividing by 100.

5. **Death date validation**: Cases where the recorded date of death precedes the surgery date are corrected by incrementing the year until chronological consistency is achieved.

6. **Length-of-stay imputation**: When the discharge date precedes the surgery date (a logical impossibility), the discharge date is replaced with the surgery date plus the dataset's mean length of stay.

### Phase 2 — Survival Analysis

1. **Kaplan-Meier estimation**: Patients are stratified into two groups based on their SOFA score at admission (`SOFA = 0` vs. `SOFA > 0`). Survival curves are estimated using `PROC LIFETEST`, and a **log-rank test** is performed to assess differences between groups.

2. **Cox proportional hazards model**: A Cox regression (`PROC PHREG`) is fitted to estimate the **Hazard Ratio** for the SOFA group variable, quantifying the relative risk of death associated with organ dysfunction at admission.

**Censoring rule**: patients discharged alive are right-censored at the study end date (30 December 2012).

## Results

The analysis shows that patients with organ dysfunction at admission (SOFA > 0) have a **significantly lower long-term survival probability** compared to those with no organ dysfunction (SOFA = 0).

## Requirements

- **SAS** (tested on SAS University Edition / SAS OnDemand for Academics)
- Input files placed in the SAS working directory

## Repository Structure

```
├── README.md
├── PROGETTO_-_pulizia_dataset.sas   # Main SAS program
├── SOFA.xlsx                        # Raw dataset
└── SOFA_modificato.xlsx             # Manually corrected dataset (IDs 29, 111)
```

## Usage

1. Upload `SOFA.xlsx` and `SOFA_modificato.xlsx` to your SAS environment.
2. Update the file paths in the `PROC IMPORT` and `ODS PDF` statements to match your directory.
3. Run `PROGETTO_-_pulizia_dataset.sas`.
4. Output PDF reports (Kaplan-Meier plot and Hazard Ratio table) are saved to the specified path.

## License

This project was developed for academic purposes.
