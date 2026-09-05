# TheLook eCommerce — Customer Analysis & Segmentation

**Business question:** How can TheLook grow revenue by better understanding its customer segments and their product preferences?

TheLook is a (fictitious) fashion eCommerce dataset covering customers, orders, products, and web events from 2019–2024. This project focuses specifically on **Customer Analysis** — understanding who customers are, how much value they generate, how they buy, and which behavioural segments matter most — in order to identify concrete growth opportunities.

## Key Findings

- **Acquisition is strong, but conversion leaks badly.** Of 100K registered users, only 27.8% ever complete a purchase.
- **Demographics don't explain customer value — behaviour does.** Gender, age, country, and traffic source are all fairly balanced across the customer base; RFM segments show far sharper differences in value.
- **One-time buyers are the core problem, and it's structural.** 88.09% of customers purchase only once. Even the 2019 cohort — with 5 years to return — retained only ~5.5% of customers by year 1, confirming this isn't a data artifact.
- **A small group of segments drives disproportionate value.** Loyal Customers (1.17% of the base) generate value through frequency (3.06 orders/customer); High-Value New Customers (4.37%) generate value through order size (AOV $219.89).

Full analysis, charts, and recommendations are in [`report_project.pdf`](./report_project.pdf) / the accompanying slide deck.

## Approach

```
EDA → Data Processing → Descriptive Analysis → RFM Segmentation
```

1. **EDA** — explore raw data: nulls, duplicates, distributions
2. **Data Processing** — filter to completed orders, derive features (age groups, cohort labels)
3. **Descriptive Analysis** — Customer Profile, Customer Value, Purchasing Behaviour
4. **RFM Segmentation** — Recency/Frequency/Monetary scoring, rule-based segment assignment, validated with cohort retention analysis

**Why rule-based RFM instead of clustering?** Purchase frequency in this dataset is heavily skewed (88% of customers have Frequency = 1), which doesn't suit distance-based clustering well — it tends to produce one dominant cluster and several tiny, hard-to-interpret ones. Rule-based thresholds keep segments directly explainable and actionable (e.g. "Loyal = Frequency ≥ 3"). Clustering was considered as a possible extension but wasn't the right fit for this data shape — see the Limitations section below.

## Tech Stack

- **SQL Server** — data extraction, metric calculation, cohort & Pareto logic
- **Python (pandas)** — RFM scoring and segment assignment
- **Power BI** — dashboard and visualization

## Project Structure

```
thelook-project/
├── README.md
├── requirements.txt
├── sql/
│   └── customer_analysis.sql             # All SQL: profile, value, behaviour, RFM, cohort
├── notebooks/
│   ├── 00_eda.ipynb                      # Exploratory data analysis
│   ├── 01_data_cleaning.ipynb            # Clean raw CSVs
│   └── 02_rfm_segmentation.ipynb         # RFM scoring & segment assignment
├── scripts/
│   └── load_data_to_db.py                # Load cleaned CSVs into SQL Server
└── data/                                 # Not included in repo (see below)
    ├── raw/                              # Original CSVs from TheLook dataset
    ├── processed/                        # Cleaned CSVs (output of 01_data_cleaning)
    └── output/                           # Query results & RFM outputs
```

## Data

This project uses the public **TheLook eCommerce** dataset (originally available via BigQuery public datasets). Only 4 tables are used for this analysis:

| Table | Contents |
|---|---|
| `users` | Customer identity & demographics (age, gender, country, traffic source) |
| `orders` | Order-level info (status, timestamps) |
| `order_items` | Product-level detail within each order (sale price) |
| `products` | Product info (category, cost, department) |

Raw and cleaned CSVs are not included in this repo. To reproduce the analysis:
1. Download the TheLook dataset CSVs into `data/raw/`
2. Run `notebooks/00_eda.ipynb` to explore raw data
3. Run `notebooks/01_data_cleaning.ipynb` — outputs go to `data/processed/`
4. Run sections in `sql/customer_analysis.sql` in order (the RFM section requires exporting `raw_rfm.csv` first and running `notebooks/02_rfm_segmentation.ipynb`)
5. Load `data/output/rfm_scored.csv` into your database using `scripts/load_data_to_db.py`

## Limitations & Future Work

- Segmentation is rule-based (RFM thresholds) rather than algorithmic (e.g. clustering). Given the highly skewed frequency distribution, this was the more interpretable and immediately actionable choice — but a clustering-based approach could be explored as a future extension, potentially on log-transformed monetary/recency values.
- Cohort retention is analyzed at the overall customer level (by signup year/quarter), not broken down by RFM segment — it's used here as validation evidence for the purchase frequency finding, not as a segment-differentiating metric.
- The dataset's 2024 figures reflect partial-year data and are not directly comparable to prior full years.

## Author

Nguyen Thi Van Anh — Capstone Project, Track 2
