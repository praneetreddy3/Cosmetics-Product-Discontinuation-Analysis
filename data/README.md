# Data

This project uses an open-source cosmetics chemical-composition dataset (the "Chemicals in Cosmetics" data published via data.gov, sourced from the California Safe Cosmetics Program).

**Not committed to this repo** due to file size — download it yourself:

1. Visit the dataset page: https://catalog.data.gov/dataset/chemicals-in-cosmetics-d55bf
2. Download the CSV export.
3. Save it in this folder as `cosmeticdata.csv` (i.e. `data/cosmeticdata.csv`), which is the path `src/cosmetics_discontinuation_analysis.R` expects.

## Key Fields Used

| Field | Description |
|---|---|
| CDPHId | Unique product identifier |
| ProductName / CompanyName / BrandName | Product identification |
| PrimaryCategory / SubCategory | Product classification |
| ChemicalName / ChemicalCount | Chemical composition |
| InitialDateReported / MostRecentDateReported | Reporting timeline |
| DiscontinuedDate | Used to derive the binary `Discontinued` label |
