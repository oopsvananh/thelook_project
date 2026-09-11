# TheLook eCommerce — Customer Analysis & Segmentation

An end-to-end customer analytics project using SQL, Python, and Power BI to identify revenue-growth opportunities for TheLook, a fictional fashion eCommerce business.

> **Business question:** How can TheLook grow revenue by better understanding its customer segments and product preferences?

The analysis covers customer profiles, purchase behaviour, value generation, cohort retention, conversion, product preferences, and rule-based RFM segmentation using TheLook data from 2019–2024.

## Key Findings

- **Customer conversion is the largest leak:** only 27.8% of 100K registered users complete a purchase.
- **Behaviour is more informative than demographics:** gender, age, country, and traffic source are broadly balanced, while RFM segments show much clearer differences in customer value.
- **One-time purchasing is a structural retention issue:** 88.09% of customers purchase only once, and the 2019 cohort retained just 5.49% of customers in year one.
- **Small segments create disproportionate value:** Loyal Customers represent 1.17% of the customer base and average 3.06 orders per customer, while High-Value New Customers represent 4.37% and have an AOV of $219.89.

## Deliverables

| Deliverable | Description |
|---|---|
| [Power BI dashboard](./main_report.pbix) | Interactive report containing the final dashboards and visual analysis |
| [Presentation slides](./Slide%20Project.pdf) | Executive summary of findings and recommendations |
| [SQL analysis](./sql/customer_analysis.sql) | Business metrics, customer analysis, RFM preparation, cohort retention, and product analysis |
| [Analysis notebooks](./notebooks) | Exploratory analysis, data cleaning, and RFM scoring |

## Analytical Workflow

```text
Raw data → EDA → Data cleaning → SQL analysis → RFM segmentation → Power BI dashboard
```

1. **Exploratory data analysis** — inspect nulls, duplicates, distributions, and data quality.
2. **Data processing** — clean source tables and prepare analysis-ready datasets.
3. **Descriptive analysis** — assess business performance, customer profiles, customer value, purchasing behaviour, conversion, and product preferences.
4. **RFM segmentation** — score Recency, Frequency, and Monetary value, then assign actionable customer segments.
5. **Retention validation** — use cohort analysis to test whether low repeat purchasing is caused only by limited observation time.
6. **Visualization** — present results and recommendations in Power BI and the slide deck.

### Why rule-based RFM?

Purchase frequency is highly skewed: 88% of customers have a frequency of one. Distance-based clustering therefore tends to produce one dominant cluster and several small, difficult-to-interpret groups. Rule-based RFM thresholds keep each segment transparent and actionable—for example, defining Loyal Customers using a frequency of at least three purchases.

## Tech Stack

- **SQL Server** — data storage, metric calculation, cohort analysis, and product analysis
- **Python** — data cleaning and RFM scoring with pandas and NumPy
- **Jupyter Notebook** — reproducible exploratory and transformation workflow
- **Power BI** — dashboard development and visualization

## Repository Structure

```text
thelook_project/
├── README.md
├── main_report.pbix
├── Slide Project.pdf
├── sql/
│   └── customer_analysis.sql
├── notebooks/
│   ├── 00_eda.ipynb
│   ├── 01_data_cleaning.ipynb
│   └── 02_rfm_segmentation.ipynb
├── scripts/
│   └── load_data_to_db.py
└── data/
    ├── raw/                  # Source CSV files
    ├── processed/            # Cleaned tables used by SQL Server
    └── output/               # Query results and RFM outputs
```

## Data

The project uses the public **TheLook eCommerce** dataset, originally available through Google BigQuery public datasets. The core customer analysis uses four tables:

| Table | Contents |
|---|---|
| `users` | Customer identity, demographics, location, and acquisition source |
| `orders` | Order status and order-level timestamps |
| `order_items` | Product-level transaction detail and sale price |
| `products` | Product category, department, retail price, and cost |

The repository includes the source, processed, and analysis-output CSV files needed to review the workflow. Web-event and inventory data are present for supporting analysis but are not part of the core customer segmentation model.

## Reproducing the Analysis

### Prerequisites

- Python 3 with `pandas`, `numpy`, `matplotlib`, `sqlalchemy`, and `pyodbc`
- Jupyter Notebook or JupyterLab
- SQL Server and Microsoft ODBC Driver 17 for SQL Server
- Power BI Desktop to open the `.pbix` report

### Steps

1. Run `notebooks/00_eda.ipynb` to review the source data.
2. Run `notebooks/01_data_cleaning.ipynb` to regenerate the files in `data/processed/`.
3. Create a SQL Server database named `thelook` and update `SERVER` in `scripts/load_data_to_db.py` if needed.
4. Uncomment the four base-table entries in `TABLES`, comment out `customer_segments`, and run `scripts/load_data_to_db.py`.
5. Run the relevant sections of `sql/customer_analysis.sql`. Export the RFM preparation result to `data/output/raw_rfm.csv`.
6. Run `notebooks/02_rfm_segmentation.ipynb` to generate `data/output/rfm_scored.csv`.
7. Enable only the `customer_segments` entry in `scripts/load_data_to_db.py` and run the script again.
8. Open `main_report.pbix` in Power BI Desktop and update the SQL Server connection if required.

## Limitations & Future Work

- RFM segmentation is rule-based rather than clustering-based. This is more interpretable for the highly skewed purchase-frequency distribution, but clustering on transformed features could be explored later.
- Cohort retention is measured for the overall customer base rather than separately for each RFM segment.
- The 2024 figures represent a partial year and should not be compared directly with complete prior years.

## Author

Nguyen Thi Van Anh — Capstone Project, Track 2
