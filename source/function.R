get_edd_column_names <- function(edd_format_path, edd_ws) {
  vec_fields <- read_excel(edd_format_path, edd_ws) %>%
    pull(`Field Name`)
  
  n_fields <- min(which(is.na(vec_fields)) - 1, length(vec_fields))
  
  vec_fields[1:n_fields]
}

add_edd_columns <- function(df, edd_format_path, edd_ws) {
  edd_column_names <- get_edd_column_names(edd_format_path, edd_ws)
  
  current_column_names <- names(df)
  
  missing_column_names <- base::setdiff(
    edd_column_names, current_column_names
  ) %>%
    setNames(nm = .)
  
  missing_column_names[] <- NA
  
  tibble::add_column(df, !!!missing_column_names) %>%
    select(all_of(edd_column_names))
}

get_zip_data <- function(data_type){
  # unzip folder whose name contains specified data type
  uz_data <- unzip(zip_list[str_detect(zip_list, data_type)], list = TRUE)
  
  # read the text file within that zipped folder
  df_data_in <- read.delim(file = unz(description = zip_list[str_detect(zip_list, data_type)], filename = uz_data$Name),
                           header = TRUE, sep = "\t", quote = "")
}