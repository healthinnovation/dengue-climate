file_paths = fs::dir_ls("data/raw/climate/")
datasets = purrr::map(
  file_paths,
  \(x) readr::read_csv(
    x, col_select = c(ubigeo, date, value), col_types = "iccccDdc"
  )
)
names(datasets) = fs::path_file(fs::path_ext_remove(names(datasets)))

library(dplyr)

dataset = purrr::reduce(
  datasets, inner_join, by = c("ubigeo", "date")
)
n_col = ncol(dataset)
n_vars = length(datasets)
names(dataset)[(n_col - n_vars + 1):n_col] = names(datasets)

naniar::miss_var_summary(dataset)

dataset |>
  group_by(ubigeo) |>
  summarise(n = n_distinct(date))

weekly_dataset = dataset |>
  mutate(
    week_start = lubridate::floor_date(date, unit = "week", week_start = 7),
    week = lubridate::epiweek(date),
    year = lubridate::epiyear(date)
  ) |>
  group_by(ubigeo, year, week_start, week) |>
  summarise(across(max_evapo:min_temp, \(x) mean(x)), .groups = "drop") |>
  rename_with(
    \(x) paste0("climate_", stringr::str_replace_all(x, "_", "")),
    .cols = max_evapo:min_temp
  )

output_path = "data/interim/climate.csv"
readr::write_csv(weekly_dataset, output_path, na = "")
