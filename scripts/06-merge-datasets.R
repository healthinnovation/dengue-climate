dengue_path = "data/interim/dengue.csv"
dengue = readr::read_csv(dengue_path, col_types = "ciiiii")

climate_path = "data/interim/climate.csv"
climate = readr::read_csv(climate_path, col_types = "ciDidddddddddd")

population_path = "data/interim/population.csv"
population = readr::read_csv(population_path, col_types = "cid")

socio_path = "data/interim/sociodemographic.csv"
socio = readr::read_csv(socio_path, col_types = "cdddddddd")

library(dplyr)

dataset = dengue |>
  left_join(population, by = c("ubigeo", "year")) |>
  left_join(climate, by = c("ubigeo", "year", "week")) |>
  left_join(socio, by = c("ubigeo")) |>
  arrange(ubigeo, year, week) |>
  mutate(district_id = as.numeric(factor(ubigeo, labels = 1:1874))) |>
  relocate(district_id, .before = everything()) |>
  tidyr::replace_na(list(probable_cases = 0, confirmed_cases = 0))

library(sf)
data("Peru", package = "innovar")

dataset_sf = Peru |>
  mutate(district_id = as.numeric(factor(ubigeo, labels = 1:1874))) |>
  relocate(district_id, .before = everything()) |>
  select(-c(ends_with(".code"), capital)) |>
  rename(department = dep, province = prov, district = distr)

saveRDS(dataset_sf, "data/processed/dengue-climate-sf.rds")
readr::write_csv(dataset, "data/processed/dengue-climate.csv", na = "")

# dictionary = tibble(name = colnames(dataset), description = NA)
# readr::write_csv(dictionary, "data/processed/dictionary_v1.csv", na = "")
