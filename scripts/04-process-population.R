input_path = "data/raw/grvProyeccionPoblacion.xlsx"

col_names = c(
  "department", "province", "district", "population_2018", "population_2019",
  "population_2020", "population_2021", "population_2022"
)

population_raw = readxl::read_excel(input_path, col_names = col_names, skip = 1)

library(dplyr)

population = population_raw |>
  tidyr::drop_na(province, district, population_2018) |>
  mutate(across(starts_with("population"), \(x) as.numeric(gsub(",", "", x)))) |>
  arrange(department, province, district)

data("Peru", package = "innovar")

population_innova = Peru |>
  sf::st_drop_geometry() |>
  select(ubigeo, department = dep, province = prov, district = distr) |>
  arrange(department, province, district)

population_check = population |>
  mutate(row_id = row_number()) |>
  relocate(row_id, .before = everything()) |>
  left_join(population_innova, by = c("department", "province", "district")) |>
  filter(is.na(ubigeo))

readr::write_csv(population_check, "data/raw/population-check.csv", na = "")

population_fixed = readr::read_csv(
  "data/raw/population-fixed.csv", show_col_types = FALSE, trim_ws = TRUE
)

population_input = population_fixed |>
  select(
    department_fixed, province_fixed, district_fixed, population_2018:population_2022
  )

rows_replace = population_fixed$row_id
population_clean = population
population_clean[rows_replace, ] = population_input

population_ubigeo = population_innova |>
  mutate(
    district_id = stringr::str_squish(district),
    province_id = stringr::str_squish(province),
    department_id = stringr::str_squish(department)
  ) |>
  select(department_id, province_id, district_id, ubigeo)

population_final = population_clean |>
  mutate(
    district_id = stringr::str_squish(district),
    province_id = stringr::str_squish(province),
    department_id = stringr::str_squish(department)
  ) |>
  left_join(
    population_ubigeo, by = c("department_id", "province_id", "district_id")
  ) |>
  select(ubigeo, starts_with("population")) |>
  arrange(ubigeo)

population_final_long = population_final |>
  tidyr::pivot_longer(
    starts_with("population"),
    names_prefix = "population_",
    names_to = "year",
    values_to = "population"
  ) |>
  group_by(ubigeo) |>
  tidyr::complete(year = as.character(2018:2023)) |>
  ungroup()

district_population = population_final_long |>
  group_by(ubigeo) |>
  mutate(pop = c(na.omit(population), zoo::na.spline(population, xout = 6))) |>
  ungroup() |>
  select(ubigeo, year, population = pop)

output_path = "data/interim/population.csv"
readr::write_csv(district_population, output_path, na = "")
