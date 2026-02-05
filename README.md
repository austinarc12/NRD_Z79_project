Here you can find the R code used in project titled "Trends in Long-Term Medication use Coding in the NRD from 2016-2020"

Our aim in this project was to explore trends in long-term current medication use through Z79 coding in the NRD from 2016 to 2020.
We also attempted to identify medication cessation events (MCE) upon hospital readmissions.
We hoped to elucidate the feasibility of using the NRD for future pharmacoepidemiology and deprescribing research.

Each yearly NRD dataset is very large, so code runs slowly and we recommend dropping data elements you don't plan to use.
You can vist https://hcup-us.ahrq.gov/tech_assist/centdist.jsp to purchase NRD datasets by the year.

The code adds data elements to the NRD dataset that isolate the Z79 codes for each patient admission 
and then identifies medication cessation event, which we define as Z79 codes present on index admission but
not subsequently coded for in any associated readmissions or in the last associated readmission.

Thank you!
