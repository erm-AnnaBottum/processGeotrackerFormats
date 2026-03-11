# This script takes the output from combine_datasets.R, a df of combined base
# & auxiliary analytical results data, and formats it into the EDFFlat table of
# the GeoTracker EDD format. This script differs from edf_to_edfflat-EXPLORATORY.R
# in that it includes remapping and updating of default values.
#
# This script should be used AFTER exploratory review has been completed, and best
# remapping and default settings have been determined.
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

# update blank values with predefined default values in mapping definitions file                      
for (col in names(df_edd_prep)){
  if(
    (!is.na(mp_def$default_value[mp_def$`Field Name` == col]) #& # check that this field should be defaulted
       #sum(is.na(df_edd_prep[[col]])) == 0 # check that entire field is null
     )
  ) {
    df_edd_prep[[col]] <-mp_def$default_value[mp_def$`Field Name` == col]
  }
}

# final edd prep before exporting ####
# format dates into yyyyMMdd format
# default dates to analysis date when blank
df_edff_edd <- df_edd_prep %>%
  mutate(
    LOGCODE = "UNK",
    LABCODE = "UNK",
    EXTDATE = case_when(
      is.na(EXTDATE) ~ ANADATE,
      TRUE ~ EXTDATE
    ),
    RECDATE = case_when(
      is.na(RECDATE) ~ ANADATE,
      TRUE ~ RECDATE
    ),
    PROJNAME = get_global_id,
    LAB_REPNO = case_when(
      is.na(LAB_REPNO) ~ LABWO,
      TRUE ~ LAB_REPNO
    ),
    LABLOTCTL = case_when(
      is.na(LABLOTCTL) ~ ANMCODE,
      TRUE ~ LABLOTCTL
    ),
    BASIS = case_when(
      is.na(BASIS) ~ "N",
      TRUE ~ BASIS
    ),
    LABSAMPID = case_when(
      is.na(LABSAMPID) ~ substr(SAMPID, 1, 12), # truncate to 12 characters to fit in to EDD reqs
      TRUE ~ substr(LABSAMPID, 1, 12)
    ),
    MODPARLIST = case_when(
      MODPARLIST == "NA" ~ "F",
      TRUE ~ MODPARLIST
    ),
    LABWO = "GEOTRK",
    RUN_NUMBER = case_when(
      is.na(RUN_NUMBER) ~ "1",
      TRUE ~ RUN_NUMBER
    ),
    EXMCODE = case_when(
      EXMCODE == "Unknown" ~ "METHOD",
      TRUE ~ EXMCODE
    ),
    REPDLVQ = "IRL",
    DILFAC = case_when(
      is.na(DILFAC) ~ "1",
      TRUE ~ DILFAC
    )
  )
  

# write edd ####
# lst_out <- list("EDFFlat" = df_edff_edd)
# 
# write.xlsx(lst_out, file.path(fol_out, paste0(
#   file_name,
#   ".EXXON-MOBIL.GeoTracker.",
#   format(Sys.Date(), "%Y%m%d"),
#   ".xlsx"
# )))

# handle remapping ####

remap_file <- file.path(fol_ref, "mapping_definitions_20260217.xlsx")

# analyte
df_analyte_mapping <- read_excel(
  remap_file,
  sheet = "remap_guide-analyte"
)

analyte_maps <- list(df_analyte_mapping$EM_equis_cas_rn) %>%
  unlist() %>%
  setNames(df_analyte_mapping$PARLABEL)

# analytic method
df_anl_meth_mapping <- read_excel(
  remap_file,
  sheet = "remap_guide-anl_method"
)

anl_meth_maps <- list(df_anl_meth_mapping$EM_analytic_method) %>%
  unlist() %>%
  setNames(df_anl_meth_mapping$ANMCODE)

# matrix code
df_matrix_mapping <- read_excel(
  remap_file,
  sheet = "remap_guide-matrix"
)

matrix_maps <- list(df_matrix_mapping$EM_matrix_code) %>%
  unlist() %>%
  setNames(df_matrix_mapping$MATRIX)

# units
df_units_mapping <- read_excel(
  remap_file,
  sheet = "remap_guide-units"
)

unit_maps <- list(df_units_mapping$EM_units) %>%
  unlist() %>%
  setNames(df_units_mapping$UNITS)


df_edff_edd$PARLABEL <- analyte_maps[df_edff_edd$PARLABEL]
df_edff_edd$ANMCODE <- anl_meth_maps[df_edff_edd$ANMCODE]
df_edff_edd$MATRIX <- matrix_maps[df_edff_edd$MATRIX]
df_edff_edd$UNITS <- unit_maps[df_edff_edd$UNITS]


# do some final filtering on analytical data, per discussions with Tina & pertaining
# in particular only to reviewed ExxonMobil/18LBT dataset
#
# split into two EDDs: one to load to EM and another to document all records
# that are omitted from load

if(TRUE){
  df_edff_edd <- df_edff_edd %>%
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
  
  if(nrow(df_edff_edd) == (nrow(df_edff_edd_load) + nrow(df_edff_edd_omit))){
    print("ALL GOOD")
  } else{
    print("We have a problem")
    print(paste0("Full dataset: ", nrow(df_edff_edd), " | load: ", nrow(df_edff_edd_load), " | omit: ", nrow(df_edff_edd_omit)))
  }
}






