file_paths = fs::dir_ls("data/raw/climate/")
datasets = purrr::map(
  file_paths, \(x) readr::read_csv(x, col_select = 1:3, col_types = "cDd")
)
names(datasets) = fs::path_file(fs::path_ext_remove(names(datasets)))

library(dplyr)

weekly = function(data) {
  data_weekly = data |>
    mutate(
      week_start = lubridate::floor_date(date, unit = "week", week_start = 7),
      week = lubridate::epiweek(date),
      year = lubridate::epiyear(date)
    ) |>
    group_by(ubigeo, year, week_start, week) |>
    summarise(value = mean(value), .groups = "drop")
  data_weekly
}

weekly_datasets = purrr::map(datasets, weekly)
weekly_dataset = purrr::reduce(
  weekly_datasets, inner_join, by = c("ubigeo", "year", "week_start", "week")
)
names(weekly_dataset)[-1:-(length(datasets) + 1)] = names(datasets)

output_path = "data/interim/climate.csv"
readr::write_csv(weekly_dataset, output_path, na = "")
