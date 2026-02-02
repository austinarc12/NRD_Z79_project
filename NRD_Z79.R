library(data.table)
library(dplyr)
library(stringr)
library(purrr)
library(tidyr)
library(haven)

nrd <- fread('/filepath',
             # consider dropping data elements you don't need
             drop = c(""))

# execute your exlcusion criteria
nrd <- nrd %>%                   
  filter(AGE >= 18,               # exclude children
         DIED == 0,               # exclude those who died during hospitalization
         DMONTH <= 11,            # exclude December discharges
         !is.na(LOS),             # exclude those w/ invlaid length of stay
         !is.na(NRD_VisitLink))   # exclude those w/ invalid linkage number

# order, arrange and group dataset
# order by linkage number and then chronlogically by admissions
# then group by linkage number 
# and lastly exclude all isolated admissions that don't have subsequant readmissions
nrd <- nrd %>%
  setorder(NRD_VisitLink, NRD_DaysToEvent) %>%
  group_by(NRD_VisitLink)  %>%
  filter(n()>1) %>%
  # create a data element for the time between discharge and readmission
  mutate(Time_between = lag((lead(NRD_DaysToEvent) - NRD_DaysToEvent - LOS), n = 1))
     
# create new dataframe that isolates Z79 codes 
# for each row, across all ICD data elements, identify all Z79 codes and add them
# to their a new column called "Z79_codes"
nrd_Z79 <- nrd %>% select(matches("I10"), NRD_VisitLink) %>%
  mutate(Z79_codes = pmap(across(everything()), function(...) {
    values <- c(...)   
    Z79 <- values[str_detect(values, "Z79")]
    ifelse(length(Z79) > 0, paste(Z79, collapse = ","), NA)
  }))

# create a function to identify medication cessation events
findMCE <- function(x) {
  indexAd <- unlist(str_split(x[1], ","))   # isolate the index admission from the grouped linkage number
  reAds <- unlist(str_split(x[-1], ","))    # isolate the readmissions
  lastAd <- unlist(str_split(x[length(x)], ","))  # isolate the last admission
  anyMCE <- setdiff(indexAd, reAds)    # identify Z79 codes that are present on index admission but not on any readmissions
  lastMCE <- setdiff(indexAd,lastAd)   # identify Z79 codes that are present on index admission but not on last readmission
  paste(unique(c(anyMCE,lastMCE)), collapse = ",")
}

# apply the "findMCE" function
nrd_Z79 <- nrd_Z79 %>% 
  mutate(MCE = if_else(row_number() == 1, findMCE(Z79_codes), NA))

# add MCE and Z79_codes columns to initial NRD dataframe
nrd$MCE <- nrd_Z79$MCE  %>%
  nrd_Z79$Z79_codes %>%
  # shift "Time_between" data element up one row to coincide w/ index admission
  mutate(Time_between_shift = lead(Time_between))

# explore patient characteristics based on different the different medication groups
# below are some examples
  # nrd_med <- nrd %>% filter(grepl("Z79...", MCE))  
  # sum(nrd_med$FEMALE)
  # mean(nrd_med$AGE)
  # mean(nrd_med$Time_between_shift)
  # sort(table(nrd_med$I10_DX1), decreasing = TRUE)
  # sort(table(nrd_med$DRG), decreasing = TRUE)
  # use 'nrd %>% slice_head(n=1)' to isolate index admissions

