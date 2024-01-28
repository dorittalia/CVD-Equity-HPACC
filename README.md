# Hypertension care cascades and reducing inequities in cardiovascular disease in low- and middle-income countries

This repository contains replication code for Stein et al. paper "Hypertension care cascades and reducing inequities in cardiovascular disease in low- and middle-income countries". Nature Medicine. 2024.

### Prerequisites

This code is written in R. Relevant packages needed are listed at the top of each script.

## Contents

The following scripts can be found in the 'code' folder of this repository:

* `0_prep_data_final.R`: This script prepares the dataset for analysis.
* `1_pre_scenario_coding_final.Rmd`: This script selects countries and observations for analysis, identifies best performers and sets scenario targets, calculates hypertension prevalence by country, constructs composite relative risk reduction estimates for each individual, calculates baseline 10-year cardiovascular disease risk for each individual, and calculates area under the cascade values.
* `2_scenario_code_final.Rmd`: This script includes the functions for each scenario that are mapped onto nested data for each country and wealth quintile for every set of targets. This code uses cluster computing.
* `3_scenario_summary_calculations_final.Rmd`: This script cleans output from script #2 and merges all scenario outputs into one dataframe.
* `4_tables_figures_final.Rmd`: This script conducts further scenario output cleaning (i.e., setting values for country-quintiles that were the targets in each scenario) and codes the manuscript tables and figures, including intermediate calculations to produce figures (i.e., calculating absolute percentage point gap in CVD risk comparing Q1 and Q5).
* `5_appendix_final.Rmd`: This script codes the Supplementary Information file.

## Contact

I am **Dorit Talia Stein**, PhD Candidate at Harvard University. You can reach me at:
* doritstein@g.harvard.edu
* [@dorittalia](https://twitter.com/dorittalia)

## License

This project is licensed under the MIT License.
