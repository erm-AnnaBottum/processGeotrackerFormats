# This script combines a base analytical results data set with its auxiliary
# analytical dataset. Base dataset is a specific site while auxiliary is the county.
#
# Originally written to combine 18LBT and SantaBarbara datasets - get
# a few additional key fields from SantaBarbara by joining on sys_sample_code
# & a few other result level fields.
#
# input files should be converted to csv before reading in to avoid the loss of
# numeric accuracy in excel. This script requires csv
#
# Anna Bottum / Spring 2026

if(!require(pacman)){ install.packages("pacman") } else { library(pacman) }
# import ####
p_load(
  here, 
  dplyr, 
  readxl,
  stringr,
  tidyr,
  openxlsx,
  janitor
)

options(scipen = 999)
source("source/function.R")

# user input ####
file_name <- "18LBT_EDF" # name of input file containing data to be processed
aux_file_name <- "SantaBarbara_EDF" # name of input file containing auxiliary info
dest_fmt <- "EDFFlat" # destination format (select tab name on BlankEDD_GeotrackerEDF file)
rows_to_skip <- 1 # set to 0 as default
mapping_guide <- "mapping_definitions_20260217.xlsx"

# read in data ####
# set up directories
fol_main <- here::here()
fol_data <- file.path(fol_main, "data")
fol_ref <- file.path(fol_main, "reference")
fol_out <- file.path(fol_main, "output")

# get input data
# convert to .csv when possible as read.delim is cleaner with
# trailing zeroes than the read_excel functions
df_base_in <- read.delim(file.path(fol_data, paste0(file_name, ".csv")),
                    sep = ",",
                    colClasses = "character",
                    skip = rows_to_skip)

# format column names
names(df_base_in) <- str_replace_all(names(df_base_in), "\\.", "_")
get_global_id <- df_base_in$GLOBAL_ID[1]

df_base_prep <- df_base_in %>%
  mutate(
    SAMP_DATE = case_when(
      is.na(SAMP_DATE) | SAMP_DATE== "" ~ format(as.Date(ANALYSIS_DATE, "%m/%d/%Y"), "%Y%m%d"),
      TRUE ~ format(as.Date(SAMP_DATE, "%m/%d/%Y"), "%Y%m%d")
    ),
    SAMP_TIME = case_when(
      is.na(SAMP_TIME) | SAMP_TIME == "" ~ "0000",
      TRUE ~ SAMP_TIME
    ),
    ANALYSIS_DATE = format(as.Date(ANALYSIS_DATE, "%m/%d/%Y"), "%Y%m%d"),
    
    # handle cases where dates have already been added into sample ID
    base_samp_id = case_when(
      str_detect(SAMP_ID, format(as.Date(SAMP_DATE, "%Y%m%d"), "%m%d%y")) ~
        str_replace_all(
          SAMP_ID,
          format(as.Date(SAMP_DATE, "%Y%m%d"), "%m%d%y"),
          ""
          ),
      TRUE ~ SAMP_ID
    ),
    
    SAMP_ID = case_when(
      # 2 cases:
      # 1) no sampid OR field_pt_name: use qccode
      (is.na(SAMP_ID) | SAMP_ID == "") & is.na(FIELD_PT_NAME) | FIELD_PT_NAME == "" ~ paste0(
        QCCODE,
        "-",
        MATRIX,
        "-",
        SAMP_DATE
      ),
      # 2) sampid is populated: use sampid
      TRUE ~ paste0(
        base_samp_id,
        "-",
        MATRIX,
        "-",
        SAMP_DATE
      )
    ),
    SAMP_ID = str_replace_all(str_replace_all(SAMP_ID, " \\(\\)", ""), "--", "-"),
    QCCODE = case_when(
      QCCODE == "CS" & str_detect(FIELD_PT_NAME, "QCEB") ~ "EB", # few types of EBs so use str_detect here
      QCCODE == "CS" & FIELD_PT_NAME == "QCFD" ~ "FD",
      QCCODE == "CS" & FIELD_PT_NAME == "QCFB" ~ "FB",
      QCCODE == "CS" & FIELD_PT_NAME == "QCTB" ~ "TB",
      QCCODE == "CS" ~ "N",
      TRUE ~ QCCODE
    )
  )

# Auxiliary dataset ####
# read in auxiliary data, format col names
df_aux_in <- read.delim(file.path(fol_data, paste0(aux_file_name, ".csv")),
                        sep = ",",
                        colClasses = "character") %>%
  filter(
    GLOBAL_ID == get_global_id
  )

names(df_aux_in) <- str_replace_all(names(df_aux_in), "\\.", "_")

df_aux_prep <- df_aux_in %>%
  mutate(
    LOGDATE = format(as.Date(LOGDATE, "%m/%d/%Y"), "%Y%m%d"),
    SAMPID = paste0(
      SAMPID,
      "-",
      MATRIX,
      "-",
      LOGDATE
    )
  ) %>%
  select(
    SAMPID,
    LOGTIME,
    LOGCODE,
    LABWO,
    LABCODE,
    LABSAMPID,
    LABLOTCTL,
    BASIS,
    DILFAC,
    PARLABEL
  ) %>%
  rename(
    SAMP_ID = SAMPID
  )

# Join for full dataset ####
# join the two datasets, then add defaults if join came back empty
df_join <- df_base_prep %>%
  left_join(
    df_aux_prep,
    by = c("SAMP_ID" = "SAMP_ID", "PARAMETER" = "PARLABEL", "SAMP_TIME" = "LOGTIME")
  ) %>%
  mutate(
    LABWO = case_when(
      is.na(LABWO) ~ "GeoTracker Migration",
      TRUE ~ LABWO
    ),
    LOGCODE = case_when(
      is.na(LOGCODE) ~ "UNKNOWN",
      TRUE ~ LOGCODE
    ),
    LABCODE = case_when(
      is.na(LABCODE) ~ "UNKNOWNLAB",
      TRUE ~ LABCODE
    )
  )

# df_join will be called by edf_to_edfflat script, for final edd formatting


