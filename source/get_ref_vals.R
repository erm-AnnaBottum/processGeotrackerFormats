# This script grabs reference values from each of the GeoTracker EDD tables. It
# references dataframes created in the compile_geotracker_suite.R script, so that
# script must be run first.
#
# Anna Bottum / Spring 2026

# rt_location_type ####
df_loc_types <- bind_rows(
  list(
    df_geoxy_edd,
    df_geoz_edd,
    df_geowell_edd,
    df_well_const_edd
  )
) %>%
  select(FIELD_PT_CLASS) %>%
  distinct()

# rt_horz_collection_method_code ####
df_horz_method <- df_geoxy_edd %>%
  select(XY_METHOD) %>%
  distinct()

# rt_horz_datum_code ####
df_horz_datum <- df_geoxy_edd %>%
  select(XY_DATUM) %>%
  distinct()

# rt_company ####
df_company <- df_geoxy_edd %>%
  select(XY_SURVEY_ORG) %>%
  distinct()

# rt_elev_collect_method_code ####
df_elev_method <- df_geoz_edd %>%
  select(ELEV_METHOD) %>%
  distinct()

# rt_elev_datum ####
df_elev_datum <- df_geoz_edd %>%
  select(ELEV_DATUM) %>%
  distinct()

# dt_location ####
df_loc_ids <- bind_rows(
  list(
    df_geoxy_edd,
    df_geoz_edd,
    df_geowell_edd,
    df_well_const_edd
  )
) %>%
  select(FIELD_PT_NAME) %>%
  distinct()

lst_rv_out <- list(
  "location_type" = df_loc_types,
  "horz_collection_method" = df_horz_method,
  "horz_datum" = df_horz_datum,
  "company" = df_company,
  "elev_collection_method" = df_elev_method,
  "elev_datum" = df_elev_datum,
  "loc_ids" = df_loc_ids
)

write.xlsx(lst_rv_out, file.path(fol_out, paste0("Geotracker_RefVals_Summary_", format(Sys.Date(), "%Y%m%d"), ".xlsx")))

# get ref vals from EDF Flat table
df_anl_meth <- df_edff_edd %>%
  select(ANMCODE) %>%
  distinct()

df_units <- df_edff_edd %>%
  select(UNITS) %>%
  distinct()

df_matrix <- df_edff_edd %>%
  select(MATRIX) %>%
  distinct()

lst_edf_rv_out <- list(
  "anl_method" = df_anl_meth,
  "units" = df_units,
  "matrix" = df_matrix
)

write.xlsx(lst_edf_rv_out, file.path(fol_out, paste0("Geotracker_RefVals_Summary_", format(Sys.Date(), "%Y%m%d"), ".xlsx")))

