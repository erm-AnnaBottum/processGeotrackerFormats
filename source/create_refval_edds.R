# grab reference values from mapping guide excel file
# scripts originally written for Exxon Mobil Geotracker Migration
# 
# February 2026 - Anna Bottum



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
source("function.R")

# user input ####
mapping_guide <- "mapping_definitions_20260217.xlsx"

# read in data ####
# set up directories - in case running this script w/o others
fol_main <- here::here()
fol_data <- file.path(fol_main, "data")
fol_ref <- file.path(fol_main, "reference")
fol_out <- file.path(fol_main, "output")

remap_file <- file.path(fol_ref, mapping_guide)
path_rv_edd <- file.path(fol_ref, "Blank_RefVals.xlsx")

# cas rn/analyte ####
df_cas_rv <- read_excel(
  remap_file,
  sheet = "remap_guide-analyte"
) %>%
  filter(EM_equis_cas_rn != "#N/A") %>%
  rename(
    `#cas_rn` = EM_equis_cas_rn,
    chemical_name = EM_equis_chemical_name
  ) %>%
  mutate(
    remark = "Added for Geotracker testing February 2026 AMB",
    status_flag = "A"
  ) %>%
  add_edd_columns(path_rv_edd, "rt_analyte")

# analytic method ####
df_anl_meth_rv <- read_excel(
  remap_file,
  sheet = "remap_guide-anl_method"
) %>%
  rename(
    `#analytic_method` = EM_analytic_method
  ) %>%
  mutate(
    remark = "Added for Geotracker testing February 2026 AMB",
    status_flag = "A"
  ) %>%
  add_edd_columns(path_rv_edd, "rt_analytic_method")

# matrix code ####
df_matrix_rv <- read_excel(
  remap_file,
  sheet = "remap_guide-matrix"
) %>%
  rename(
    `#matrix_code` = EM_matrix_code
  ) %>%
  mutate(
    remark = "Added for Geotracker testing February 2026 AMB",
    status_flag = "A"
  ) %>%
  add_edd_columns(path_rv_edd, "rt_matrix")

# units ####
df_units_rv <- read_excel(
  remap_file,
  sheet = "remap_guide-units"
) %>%
  rename(
    `#unit_code` = EM_units
  ) %>%
  mutate(
    remark = "Added for Geotracker testing February 2026 AMB",
    status_flag = "A"
  ) %>%
  add_edd_columns(path_rv_edd, "rt_unit")

# write to EDD ####
lst_rv_out <- list("rt_analyte" = df_cas_rv,
                   "rt_analytic_method" = df_anl_meth_rv,
                   "rt_matrix" = df_matrix_rv,
                   "rt_unit" = df_units_rv)

write.xlsx(lst_rv_out, file.path(fol_out, paste0("GeoTrackerRefVals_", format(Sys.Date(), "%Y%m%d"), ".RefVals.xlsx")))


















