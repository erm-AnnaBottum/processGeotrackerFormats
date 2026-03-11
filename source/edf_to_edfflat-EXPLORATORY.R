# This script takes the output from combine_datasets.R, a df of combined base
# & auxiliary analytical results data, and formats it into the EDFFlat table of
# the GeoTracker EDD format. This script differs from edf_to_edfflat-EDD.R
# in that it does NOT remap
#
# This script should be used for exploratory data review.
# read in geotracker data (which table?)
#
# Anna Bottum / Spring 2026

source("source/combine_datasets.R")

# read in mapping guides/definitions
mp_def <- read_excel(file.path(fol_ref, mapping_guide),
                     sheet = "mapping_def")

# create a map of the column names
colnames_map <- list(mp_def$`Field Name`) %>%
  unlist() %>%
  setNames(mp_def$data_field)

# prep data for edd ####
df_get_colnames <- df_join
names(df_get_colnames) <- colnames_map[names(df_get_colnames)] # rename existing columns
df_get_colnames <- df_get_colnames[, !is.na(names(df_get_colnames))] # get rid of column names that are NA - these aren't needed in EDD

df_edd_prep <- df_get_colnames %>%
  add_edd_columns(file.path(fol_ref, mapping_guide), "mapping_def")

# Prep dfs for EDD ####
# do some final filtering on analytical data, per discussions with Tina & pertaining
# in particular only to reviewed ExxonMobil/18LBT dataset. This will likely need
# to be modified for future migration efforts.
#
# split into two EDDs: one to load to EQuIS and another to document all records
# that are omitted from migration

if(TRUE){
  df_edff_edd <- df_edd_prep %>%
    mutate(
      filter_status = case_when(
        (`#FIELD_PT_NAME` == "" | PARVQ == "SU" | UNITS == "ppmv" |
           as.Date(LOGDATE, "%Y%m%d") < as.Date("2021-01-01", "%Y-%m-%d"))  ~ "omit",
        TRUE ~ "load"
      )
    )
  # edd to load
  df_edff_edd_load <- df_edff_edd %>%
    filter(
      filter_status == "load"
      # as.Date(LOGDATE, "%Y%m%d") > "2020-12-31"
    )
  
  # edd of omitted records
  df_edff_edd_omit <- df_edff_edd %>%
    filter(
      filter_status == "omit"
    )
  
  # ensure the split didn't drop any records
  if(nrow(df_edff_edd) == (nrow(df_edff_edd_load) + nrow(df_edff_edd_omit))){
    print("ALL GOOD")
  } else{
    print("We have a problem")
    print(paste0("Full dataset: ", nrow(df_edff_edd), " | load: ", nrow(df_edff_edd_load), " | omit: ", nrow(df_edff_edd_omit)))
  }
}






