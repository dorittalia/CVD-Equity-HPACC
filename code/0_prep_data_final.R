## This script prepares the dataset for analysis.

rm(list = ls())

library(ggplot2)
library(data.table)
library(countrycode)

options(scipen=999)

## end data
data <- read_csv("1 Raw Data/cleaned_final.csv") # August 31, 2022

## Read and clean data. These datasets have selected a reduced set of columns from the .dta files posted on the HPACC onedrive.
df <- fread("HTN Cascade- Marissa/Old/original_data/2020_data_short.csv")
temp <- fread("HTN Cascade- Marissa/Old/original_data/2019_data_short.csv")
#temp2 <- fread("HTN Cascade- Marissa/Old/original_data/older_data_short.csv")

df <- rbind(df, temp)
temp <- fread("HTN Cascade- Marissa/Old/original_data/older_data_short.csv")
temp <- temp[, hh_id:=as.character(hh_id)] ## Match class for now
df <- rbind(df, temp)
rm(temp)

df <- df[Country!="Zanzibar"] ## Exclude Zanzibar as not nationally representative
df <- df[Country=="South Africa DHS", Country:="South Africa"] ## Rename to match
df <- df[Country=="Kyrgyz Republic", Country:="Kyrgyzstan"] ## Rename to match

nrow(df) ## 1598304 observations
nrow(unique(df[,.(Country, year, svy)]))## 86 surveys (country-year)
df <- df[, country_year:=paste0(Country, " ", year)]
#df <- df[!is.na(age) & !is.na(sex)] ## 1596399 observations
df <- df[age>=40 & age<80] ## 531177 observations

## Country-specific cleaning
#'smoke' from Pascal's code: htncascades_2018-11-11.Rmd
df <- df[Country=="Indonesia" & csmoke == 999999999, csmoke:=0]
df <- df[Country=="Chile" & past_smk == 999999999, past_smk:=1]
df <- df[Country == "China" & past_smk == 0 & csmoke == 999999999, csmoke:=0] # China : values for which past_smk=0 and csmoke = 999999999 (i.e. skipped), is coded as 0
df <- df[Country=="Ecuador" & past_smk==0, csmoke:=0]
df <- df[!is.na(daily_smoke) & daily_smoke==1, csmoke:=1] # Fill current with daily if daily smoker

df <- df[csmoke%in%c(0,1)] ## 422506 observations
df <- df[, sbp:=as.numeric(sbp_avg)] ## The converted NA are all either "" or ".r"
df <- df[sbp%in%c(333333333, 444444444, 555555555, 666666666, 777777777, 888888888, 888888896, 999999999), sbp:=NA]
df <- df[!is.na(sbp) | clin_hypt==1] ## 409638 observations
df <- df[, dbp:=as.numeric(dbp_avg)] ## The converted NA are all either "" or ".r"
df <- df[dbp%in%c(333333333, 444444444, 555555555, 666666666, 777777777, 888888888, 888888896, 999999999), dbp:=NA]
df <- df[!is.na(dbp) | clin_hypt==1] ## 409536 observations

df <- df[hh_id == "666666666" | hh_id == "666666688", hh_id:=p_id] # these are the only two missing/weird codes in that var; missing hh_id is here set to individual participant id

## Identify diagnosed & controlled HTN (can use bpms_hypt and bpms_hypt_med instead)
df <- df[(hypt==1 | hypt12==1 | hypt_med == 1 | bp_med==1 | sbp>=140 | dbp>=90), hbp_start:=1] ## Either clinical HTN OR on BP lowering med OR previously diagnosed with HTN
df <- df[is.na(hbp_start) & sbp<140 & dbp<90, hbp_start:=0]
df <- df[(hypt==1 | hypt12==1 | hypt_med == 1 | bp_med==1), hbp_diag:=1] ## Previously diagnosed OR on BP lowering meds
df <- df[(sbp>=140 | dbp>=90) & is.na(hbp_diag), hbp_diag:=0]
df <- df[hbp_diag==1 & (sbp>=140 | dbp>=90), hbp_controlled:=0]
df <- df[hbp_diag==1 & (sbp<140 & dbp<90), hbp_controlled:=1] ## Uses 140/90 for control

## Clean missing edu strings
df <- df[educat=="" | educat==".c", educat:=NA]

library(tidyverse)
### missing data %
all <- readRDS("3 Output/all.rds")
countries <- unique(all$Country)

country <- all %>%
  distinct(Country)

# dataset with 44 countries, with incomplete cases included to summarize % missing by key variable and country
missing <- df %>%
  filter(Country %in% countries)

#country_miss <- unique(missing$Country)
country_miss <- missing %>%
  distinct(Country)

rename <- anti_join(country, country_miss)

# summarize missingness
# missing cascade variables?
data_missing <- missing %>%
  group_by(Country) %>%
  mutate(n = n()) %>%
  summarize(across(.cols = c(sbp, 
                             age, 
                             sex, 
                             bmi,
                             educat,
                             wealth_quintile, 
                             csmoke),
                   list(~sum(is.na(.)),
                        ~n()))) 


df2 <- df[!is.na(sbp) & !is.na(age) & !is.na(sex) & !is.na(bmi) & (!is.na(educat) | !is.na(wealth_quintile)) & !is.na(csmoke)] ## Final dataset = 396978 observations with either complete lab or non-lab indicators


## Keep complete observations (consider multiple imputation in the future)
df2 <- df[!is.na(sbp) & !is.na(age) & !is.na(sex) & !is.na(bmi) & (!is.na(educat) | !is.na(wealth_quintile)) & !is.na(csmoke)] ## Final dataset = 396978 observations with either complete lab or non-lab indicators



# test2 <- merge(test[Country=="Guyana" & !is.na(wealth_quintile) & age!=67 & age !=76 & clin_hypt==1 & !is.na(w_bp) & psu!=""],
#                test1[Country=="GUYANA"], by = c("sbp_round", "bmi_round", "age", "sex", "psu"), all=T)

## Sort out weights (just use w_bp for now, potentially update to include average weight for missing values)
# df <- df[wstep1==666666666 | wstep1 == 666666688, wstep1:=NA]
# df <- df[wstep2==666666666 | wstep2 == 666666688, wstep2:=NA]
# df <- df[wstep3==666666666 | wstep3 == 666666688, wstep3:=NA]
# df <- df[p_wt==666666666 | p_wt == 666666688, p_wt:=NA]
# 
# df <- df[, non_lab_wt:=wstep2]
# df <- df[is.na(non_lab_wt), non_lab_wt:=wpop_bp]
# df <- df[is.na(non_lab_wt), non_lab_wt:=p_wt]
# df <- df[!is.na(non_lab_wt)]

## Add country codes
df <- df[, ccodes:=countrycode(Country, origin = "country.name", destination = "iso3c")]

## Percent missing wealth/edu (used to identify surveys to keep (i.e., <35% missing))
# df <- df[is.na(educat), edu_miss:=.N, by = "country_year"]
# df <- df[, edu_miss:=mean(edu_miss, na.rm=T), by = "country_year"]
# df <- df[is.na(wealth_quintile), wealth_miss:=.N, by = "country_year"]
# df <- df[, wealth_miss:=mean(wealth_miss, na.rm=T), by = "country_year"]
# df <- df[, pct_edu_miss:=edu_miss/.N, by = "country_year"]
# df <- df[is.na(pct_edu_miss), pct_edu_miss:=0]
# df <- df[, pct_wealth_miss:=wealth_miss/.N, by = "country_year"]
# df <- df[is.na(pct_wealth_miss), pct_wealth_miss:=0]

## Restrict to just indicators used for analysis (might need to include additional indicators)
df <- df[,.(Country, ccodes, year, country_year, svy, p_id, rural, psu, stratum, w_bp, age, sex, educat, wealth_quintile,
            csmoke, bmi, sbp, dbp, mi, bp_ms, hypt, hypt_med, bp_med, aspirin, statin, clin_hypt,
            hbp_start, hbp_diag, hbp_controlled, countryGDPclass, und_hypt, bpms_hypt, bpms_hypt_med)]
df <- df[, Country:=toupper(Country)]

svy_keep <- fread("~/Documents/Stanford/Projects/CVD SES/hpacc_edu_wealth_survey_list.csv") ## Most recent year, preferring years with both edu+wealth available
df <- merge(df, svy_keep[,.(Country, year, svy, use_data)], by = c("Country", "year", "svy"))
df <- df[use_data==1]

write.csv(df, "~/Documents/Stanford/Projects/CVD SES/data/cleaned_final.csv", na = "", row.names=F)

# df <- df[!is.na(w_bp) & clin_hypt==1] ## Use to subset to just those with hypertension

