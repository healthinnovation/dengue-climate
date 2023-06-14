dengue_path = "data/interim/dengue.csv"
dengue = readr::read_csv(dengue_path, col_types = "ciiii")

climate_path = "data/interim/climate.csv"
climate = readr::read_csv(climate_path, col_types = "ciDiddd")

population_path = "data/interim/population.csv"
population = readr::read_csv(population_path, col_types = "cid")

sociodemographic_path = "data/interim/sociodemographic.csv"
sociodemographic = readr::read_csv(sociodemographic_path, col_types = "cd")

library(dplyr)

dataset = dengue |>
  left_join(population, by = c("ubigeo", "year")) |>
  left_join(climate, by = c("ubigeo", "year", "week")) |>
  left_join(sociodemographic, by = c("ubigeo")) |>
  arrange(ubigeo, year, week) |>
  mutate(district_id = as.numeric(factor(ubigeo, labels = 1:1874))) |>
  relocate(district_id, .before = everything()) |>
  tidyr::replace_na(list(cases = 0))

data("Peru", package = "innovar")

dataset_sf = Peru |>
  mutate(district_id = as.numeric(factor(ubigeo, labels = 1:1874))) |>
  relocate(district_id, .before = everything()) |>
  select(-c(ends_with(".code"), capital)) |>
  rename(department = dep, province = prov, district = distr)

saveRDS(dataset_geom, "data/processed/dengue-climate-sf.rds")
readr::write_csv(dataset, "data/processed/dengue-climate.csv", na = "")

# dictionary = tibble(name = colnames(dataset), description = NA)
# readr::write_csv(dictionary, "data/processed/dictionary.csv", na = "")
