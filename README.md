# Cosmetics-Product-Discontinuation-Analysis

**Product Discontinuation Analysis in the Cosmetics Industry — Classification & Clustering in R**

## Overview

This project investigates whether cosmetic products can be flagged as likely-to-be-discontinued before it happens, and whether brands cluster into distinct formulation strategies based on chemical usage. It uses an open-source California cosmetics chemical-composition dataset covering thousands of products, brands, and categories.

**Key Technologies:** R, tidyverse, caret, randomForest, pROC, ggplot2, cluster (K-Means)

**Course:** GBUS 738, George Mason University — Spring 2025 (8-week session), graduate team project (4 members)

## Research Questions

1. **Classification:** Can products be classified by their likelihood of discontinuation? Logistic Regression and Random Forest models are used to forecast discontinuation and flag high-risk products.
2. **Clustering:** Do brands form distinct groups based on chemical-usage patterns? K-Means clustering is used to segment brands and surface formulation trends across the market.

## Data Pipeline

```
Raw cosmetics dataset (CSV)
    |
[Data Cleaning] — date parsing, missing-value imputation (median / "Unknown"),
                  binary Discontinued flag, categorical encoding
    |
[Aggregation] — one row per unique product/category/chemical combination
    |
        +--------------------------+--------------------------+
        |                                                      |
[Classification]                                       [Clustering]
Logistic Regression + Random Forest                    K-Means (5 clusters) on
on Discontinued ~ ChemicalCount +                       brand-level chemical usage
  PrimaryCategory + SubCategory
        |                                                      |
Confusion Matrix + ROC/AUC evaluation                  Brand segments (e.g. high-diversity
                                                         premium vs. simple-formulation brands)
```

## Dataset

**Source:** Open cosmetics chemical-composition dataset (California "Chemicals in Cosmetics" program data, via data.gov)

**Key fields:** Product Name, Company Name, Brand Name, Primary Category, Subcategory, Chemical Name, Chemical Count, Initial/Most Recent Date Reported, Discontinued Date

See `data/README.md` for how to obtain the CSV — it is not committed to this repo due to size.

## Methods

- **Data cleaning:** standardized date fields, imputed missing numeric values with the column median and missing categorical values as `"Unknown"`, converted `DiscontinuedDate` into a binary `Discontinued` label, and aggregated to one record per product formulation.
- **Logistic Regression:** `glm(Discontinued ~ ChemicalCount + PrimaryCategory + SubCategory, family = binomial)` for an interpretable baseline.
- **Random Forest:** 100-tree classifier (with one-hot encoding for high-cardinality categorical variables) to capture non-linear interactions and rank feature importance.
- **K-Means Clustering:** segmented brands into 5 clusters based on total chemical usage to reveal formulation strategy differences.
- **Evaluation:** confusion matrices and ROC/AUC curves for both classifiers.

## Key Findings

- Both models reached **~87% classification accuracy** (Random Forest 0.8721, Logistic Regression 0.8719) on the held-out test set.
- **Primary Category, Chemical Count, and Subcategory** were the strongest predictors of product longevity.
- **Personal Care, Baby, and Hair Care Products** showed the highest discontinuation rates; **Nail Products and Permanent Makeup** were the most stable categories.
- Products with a higher chemical count (6–10 chemicals) had a substantially higher discontinuation rate (43.7%) than simpler formulations (0–2 chemicals, 11.1%).
- Clustering separated **high-ingredient-diversity premium brands** (e.g., Charlotte Tilbury, NYX, SEPHORA, NARS) from **simpler, longer-lifecycle brands** (e.g., Palladio, No7, CoverGirl, The Body Shop).

## Repository Structure

```
Cosmetics-Product-Discontinuation-Analysis/
├── README.md
├── src/
│   └── cosmetics_discontinuation_analysis.R   # Full cleaning, modeling & clustering script
├── data/
│   └── README.md                              # Dataset source & download instructions
└── docs/
    ├── GBUS738_Cosmetics_FinalReport.pdf       # Full written report
    └── GBUS738_Cosmetics_GroupPresentation.pdf # Group presentation slides
```

## Getting Started

### Prerequisites
- **R 4.0+** with packages: `tidyverse`, `caret`, `rpart`, `rpart.plot`, `randomForest`, `pROC`, `MASS`, `ggplot2`, `cluster`

```r
install.packages(c("tidyverse", "caret", "rpart", "rpart.plot",
                    "randomForest", "pROC", "MASS", "ggplot2", "cluster"))
```

### Usage
1. Download the dataset per `data/README.md` and place it at `data/cosmeticdata.csv`.
2. Open `src/cosmetics_discontinuation_analysis.R` in RStudio and run top to bottom (or `Rscript src/cosmetics_discontinuation_analysis.R`).
3. Review console output for confusion matrices, AUC scores, and discontinuation-rate tables, and the generated plots for the clustering and ROC visualizations.

## Limitations & Future Work

- **Imbalanced dataset:** most products are still active, making discontinuations hard to predict — future work could apply SMOTE or collect more balanced data.
- **No market-trend data:** sales, pricing, and consumer-demand signals were unavailable; adding social-media sentiment or competitor trends could improve the model.
- **Dropped chemical names:** individual active ingredients were excluded from modeling; text-mining ingredient lists is a natural next step.
- Planned extensions: XGBoost/neural-network models, PCA-based feature selection, and a real-time early-risk-detection tool.

## Team

Graduate team project for GBUS 738, George Mason University — Sai Praneet Reddy Chinthala (this repository owner), Likith Reddy Challa, Medha Chada, and Sai Jayanth Kona.

## License

This project is for educational purposes. Underlying chemical-composition data is public domain (data.gov).
