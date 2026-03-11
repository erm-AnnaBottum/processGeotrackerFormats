# This script sources the edf_to_edfflat scripts and the combine_datasets.R script.
# This script should be run to generate either an exploratory review dataset
# (set explore_workflow=TRUE) or a final EDD output (explore_workflow=FALSE)
#
# Anna Bottum / Spring 2026

source("source/combine_datasets.R")

# import ####
if(!require(pacman)){ install.packages("pacman") } else { library(pacman) }
p_load(
  here, 
  dplyr, 
  readxl,
  stringr,
  tidyr,
  openxlsx,
  janitor,
  svDialogs
)

options(scipen = 999)
source("source/function.R")


# User Input ----------------
# if this is for exploratory data review, enter TRUE. if for final EDD formatting, enter FALSE
explore_workflow <- TRUE 
facility = "SantaBarbara" # auxiliary dataset source (county level in most cases)
dataset = "18LBT" # base dataset source (site level in most cases)
batch_size = 8000 # desired max record count in analytical results EDD
target_global_id <- "T0608300183"
include_geo <- FALSE # include geo/loc data in final output EDD?
# ----------------

# set up directories ####
fol_main <- here::here()
fol_data <- file.path(fol_main, "data")
fol_out <- file.path(fol_main, "output")
path_edd_desc <- file.path(fol_main, "reference", "EDDDescription_GeotrackerEDF.xlsx")

# Handle Locations/Geo suite data ----------------
# read in data
zip_list <- list.files(fol_data, pattern = "zip$", full.names = TRUE)

# get GeoXY data
df_geoxy_in <- get_zip_data("GeoXY")

# get GeoZ data
df_geoz_in <- get_zip_data("GeoZ")

# get GeoWell data
df_geowell_in <- get_zip_data("GeoWell")

# get field point data
df_fldpt_in <- get_zip_data("FieldPoints") %>%
  filter(!is.na(`LENGTH.OF.WELL.SCREEN..FT.`))
names(df_fldpt_in) <- str_replace_all(str_replace_all(names(df_fldpt_in), "\\.", "_"), "__", "_")

# prep locations data for EDD ----------------

if (explore_workflow){ # do only base format updates to put data into GeoTracker format (NO remapping or defaults)
  
  # get analytical data
  source("source/edf_to_edfflat-EXPLORATORY.R")
  
  # GeoXY Tab - Exploratory ####
  df_geoxy_edd <- df_geoxy_in %>%
    rename(`#GLOBAL_ID` = GLOBAL_ID) %>%
    mutate(
      XY_SURVEY_DATE = format(as.Date(XY_SURVEY_DATE, tryFormats = c("%Y-%m-%d")), "%Y%m%d")
    ) %>%
    # handle duplicates
    group_by(
      across(-c(XY_SURVEY_DATE, LATITUDE, LONGITUDE, XY_ACC_VAL, XY_SURVEY_DESC))
    ) %>%
    mutate(
      group_size = n(),
      keep_status = case_when(
        group_size > 1 & XY_SURVEY_DATE != max(XY_SURVEY_DATE) ~ "omit"
      )
    ) %>%
    ungroup() %>%
    filter(is.na(keep_status)) %>%
    add_edd_columns(path_edd_desc, "GEO_XY")
  
  # GeoZ Tab - Exploratory ####
  df_geoz_edd <- df_geoz_in %>%
    rename(
      `#GLOBAL_ID` = GLOBAL_ID,
      EFF_Date = EFFECTIVE_DATE) %>%
    mutate(
      ELEV_SURVEY_DATE = format(as.Date(ELEV_SURVEY_DATE, tryFormats = c("%Y-%m-%d")), "%Y%m%d")
    ) %>%
    group_by(
      `#GLOBAL_ID`,
      FIELD_PT_NAME
    ) %>%
    mutate(
      group_size = n(),
      keep_status = case_when(
        group_size > 1 & ELEV_SURVEY_DATE != max(ELEV_SURVEY_DATE) ~ "omit"
      )
    ) %>%
    ungroup() %>%
    filter(is.na(keep_status)) %>%
    add_edd_columns(path_edd_desc, "GEO_Z")
  
  # GeoWell Tab ####
  df_geowell_edd <- df_geowell_in %>%
    rename(
      `#GLOBAL_ID` = GLOBAL_ID,
      FIELD_PT_NAME = FIELD_POINT_NAME
    ) %>%
    mutate(
      GW_MEAS_DATE = format(as.Date(GW_MEAS_DATE, tryFormats = c("%Y-%m-%d")), "%Y%m%d")
    ) %>%
    add_edd_columns(path_edd_desc, "GEO_WELL")
  
  # Well Construction Tab - Exploratory ####
  df_well_const_edd <- df_geowell_in %>%
    left_join(
      df_fldpt_in,
      by = c("GLOBAL_ID" = "GLOBAL_ID", "FIELD_POINT_NAME" = "FIELD_PT_NAME")
    ) %>%
    rename(
      `#GLOBAL_ID` = GLOBAL_ID,
      FIELD_PT_NAME = FIELD_POINT_NAME,
      FIELD_PT_DESC = FIELD_POINT_DESCRIPTION,
      FIELD_PT_CLASS = FIELD_POINT_CLASS,
      SCRE_DEPTH = DEPTH__TOP_OF_CASING_TO_WELL_SCREEN_FT_,
      SCREEN_LENGTH = LENGTH_OF_WELL_SCREEN_FT_
    ) %>%
    add_edd_columns(path_edd_desc, "WELL_CONSTRUCTION") %>%
    distinct()
  
} else { # prep Geo suite tables for final EDD formatting (remapping & defaults)
  
  # get analytical data
  source("source/edf_to_edfflat.R")
  
  # GeoXY Tab - Final EDD ####
  df_geoxy_edd <- df_geoxy_in %>%
    rename(`#GLOBAL_ID` = GLOBAL_ID) %>%
    mutate(
      XY_SURVEY_DATE = format(as.Date(XY_SURVEY_DATE, tryFormats = c("%Y-%m-%d")), "%Y%m%d"),
      GPS_EQUIP_TYPE = case_when(
        is.na(GPS_EQUIP_TYPE) | GPS_EQUIP_TYPE == "" ~ "UNK",
        TRUE ~ GPS_EQUIP_TYPE
      ),
      XY_METHOD = case_when(
        is.na(XY_METHOD) | XY_METHOD == "" ~ "UNKNOWN",
        TRUE ~ XY_METHOD
      ),
      XY_ACC_VAL = case_when(
        is.na(XY_ACC_VAL) | XY_ACC_VAL == "" ~ 0,
        TRUE ~ XY_ACC_VAL
      ),
      XY_SURVEY_ORG = case_when(
        is.na(XY_SURVEY_ORG) | XY_SURVEY_ORG == "" ~ "UNKNOWN",
        !str_detect(XY_SURVEY_ORG, "(?i)Stantec|AECOM") ~ "UNKNOWN",
        TRUE ~ XY_SURVEY_ORG
      ),
      FIELD_PT_CLASS = case_when(
        str_detect(FIELD_PT_CLASS, "QC") ~ "FQC",
        is.na(FIELD_PT_CLASS) | FIELD_PT_CLASS == "" | FIELD_PT_CLASS == "PRIW" ~ "UNK",
        TRUE ~ FIELD_PT_CLASS
      ),
      XY_SURVEY_DATE = case_when(
        is.na(XY_SURVEY_DATE) | XY_SURVEY_DATE == "" ~ "19000101",
        TRUE ~ XY_SURVEY_DATE
      )
    ) %>%
    filter(`#GLOBAL_ID` == target_global_id) %>%
    # handle duplicates
    group_by(across(-c(XY_SURVEY_DATE, LATITUDE, LONGITUDE, XY_ACC_VAL, XY_SURVEY_DESC))) %>%
    mutate(
      group_size = n(),
      keep_status = case_when(
        group_size > 1 & XY_SURVEY_DATE != max(XY_SURVEY_DATE) ~ "omit"
      )
    ) %>%
    ungroup() %>%
    filter(is.na(keep_status)) %>%
    add_edd_columns(path_edd_desc, "GEO_XY")
  
  # GeoZ Tab - Final EDD ####
  df_geoz_edd <- df_geoz_in %>%
    rename(
      `#GLOBAL_ID` = GLOBAL_ID,
      EFF_Date = EFFECTIVE_DATE) %>%
    mutate(
      ELEV_SURVEY_DATE = format(as.Date(ELEV_SURVEY_DATE, tryFormats = c("%Y-%m-%d")), "%Y%m%d"),
      ELEV_ACC_VAL = case_when(
        is.na(ELEV_ACC_VAL) | ELEV_ACC_VAL == "" ~ 0,
        TRUE ~ ELEV_ACC_VAL
      ),
      ELEV_METHOD = case_when(
        is.na(ELEV_METHOD) | ELEV_METHOD == "" | str_detect(ELEV_METHOD, "UN") ~ "UN",
        TRUE ~ ELEV_METHOD
      ),
      ELEV_SURVEY_ORG = "UNKNOWN"
    ) %>%
    filter(`#GLOBAL_ID` == target_global_id) %>%
    group_by(
      `#GLOBAL_ID`,
      FIELD_PT_NAME
    ) %>%
    mutate(
      group_size = n(),
      keep_status = case_when(
        group_size > 1 & ELEV_SURVEY_DATE != max(ELEV_SURVEY_DATE) ~ "omit"
      )
    ) %>%
    ungroup() %>%
    filter(is.na(keep_status)) %>%
    add_edd_columns(path_edd_desc, "GEO_Z")
  
  # GeoWell Tab - Final EDD ####
  df_geowell_edd <- df_geowell_in %>%
    rename(
      `#GLOBAL_ID` = GLOBAL_ID,
      FIELD_PT_NAME = FIELD_POINT_NAME
    ) %>%
    mutate(
      GW_MEAS_DATE = format(as.Date(GW_MEAS_DATE, tryFormats = c("%Y-%m-%d")), "%Y%m%d"),
      # executive decision from Tina on Sheen: anything besides Y/N/U should get set to U
      # since this field is not actually needed/used in EQuIS
      SHEEN = case_when(
        SHEEN != "U" | SHEEN != "Y" | SHEEN != "N" ~ "U", 
        TRUE ~ SHEEN
      )
    ) %>%
    add_edd_columns(path_edd_desc, "GEO_WELL") %>%
    filter(`#GLOBAL_ID` != "") %>%
    filter(`#GLOBAL_ID` == target_global_id)
  
  # Well Construction Tab - Final EDD ####
  df_well_const_edd <- df_geowell_in %>%
    left_join(
      df_fldpt_in,
      by = c("GLOBAL_ID" = "GLOBAL_ID", "FIELD_POINT_NAME" = "FIELD_PT_NAME")
    ) %>%
    rename(
      `#GLOBAL_ID` = GLOBAL_ID,
      FIELD_PT_NAME = FIELD_POINT_NAME,
      FIELD_PT_DESC = FIELD_POINT_DESCRIPTION,
      FIELD_PT_CLASS = FIELD_POINT_CLASS,
      SCRE_DEPTH = DEPTH__TOP_OF_CASING_TO_WELL_SCREEN_FT_,
      SCREEN_LENGTH = LENGTH_OF_WELL_SCREEN_FT_
    ) %>%
    mutate(
      FIELD_PT_CLASS = case_when(
        FIELD_PT_CLASS == "Remediation/Groundwater Monitoring Well" ~ "MW",
        FIELD_PT_CLASS == "Vapor Extraction Well" ~ "SVE",
        FIELD_PT_CLASS == "SOIL VAPOR EXTRACTION WELL" ~ "SVE", # need to handle here since rt_remap_detail can't do duplicates
        is.na(FIELD_PT_CLASS) | FIELD_PT_CLASS == "" ~ "UNK",
        TRUE ~ FIELD_PT_CLASS
      )
    ) %>%
    add_edd_columns(path_edd_desc, "WELL_CONSTRUCTION") %>%
    filter(
      !is.na(SCRE_DEPTH),
      `#GLOBAL_ID` != ""
    ) %>%
    distinct() %>%
    filter(`#GLOBAL_ID` == target_global_id)
  
}

# Prep for EDD export ####
# create named list of dataframes
if(include_geo){
  df_lst <- list(GEO_XY = df_geoxy_edd,
                 GEO_Z = df_geoz_edd,
                 GEO_WELL = df_geowell_edd,
                 WELL_CONSTRUCTION = df_well_const_edd#,
                 # EDFFlat = df_edff_edd_load
  )
  
  # write to text file
  # create list of filenames
  txt_files <- paste0(names(df_lst), ".txt")
  
  # write each df to temporary txt file
  for (df in seq_along(df_lst)){
    write.table(
      df_lst[[df]],
      file = txt_files[df],
      sep = "\t",
      row.names = FALSE, # don't add row numbers
      quote = FALSE, # don't surround fields with quotes
      na = ""
    )
  }
  
  # zip everything together
  zip(
    zipfile = file.path(fol_out, paste0(dataset, "_LocationsData.GeoTrackerEDF_", format(Sys.Date(), "%Y%m%d"), ".zip")),
    files = txt_files
  )
  
  # clean up temporary txt files
  unlink(txt_files)
  
} else {
  # assign group numbers by batch size
  df_edff_edd_load_bch <- df_edff_edd_load %>%
    mutate(
      batch_group = ceiling(row_number()/batch_size)
    )
  
  # get list that's length of num batches
  batch_lst <- c(df_edff_edd_load_bch %>%
                   select(batch_group) %>%
                   distinct())[[1]]
  
  total_batches <- length(batch_lst)
  
  # iterate over each batch item, write to EDD
  lapply(batch_lst, function(batch){
    
    # subset edd
    edf_edd_write <- df_edff_edd_load_bch %>%
      filter(batch_group == batch) %>%
      select(-c(batch_group))
    
    df_lst <- list(EDFFlat = edf_edd_write)
    
    # write to text file
    # create list of filenames
    txt_files <- paste0(names(df_lst), ".txt")
    
    # write each df to temporary txt file
    for (df in seq_along(df_lst)){
      write.table(
        df_lst[[df]],
        file = txt_files[df],
        sep = "\t",
        row.names = FALSE, # don't add row numbers
        quote = FALSE, # don't surround fields with quotes
        na = ""
      )
    }
    
    # zip everything together
    zip(
      zipfile = file.path(fol_out, paste0(dataset, "_pt", batch, "-", length(batch_lst), ".GeoTrackerEDF_", format(Sys.Date(), "%Y%m%d"), ".zip")),
      files = txt_files
    )
    
    # clean up temporary txt files
    unlink(txt_files)
    
  })
}






  
