census_raw = readxl::read_excel(
  "data/raw/census-data.xlsx", range = "B6:AI1880", col_names = TRUE
)

library(dplyr)

census = census_raw |>
  mutate(ubigeo = stringr::str_pad(`Código`, 6, pad = "0")) |>
  rename(rural = `Rural encuesta`, urban = `Urbano encuesta`) |>
  mutate(rural_pct = rural / (rural + urban)) |>
  select(ubigeo, rural_pct)

socioeconomic_raw = readr::read_csv(
  "data/raw/socioeconomic-data.csv", col_types = "cddddddddddddd"
)

socioeconomic = socioeconomic_raw |>
  mutate(nbi = hh_1_nbi_or_more / number_hh) |>
  select(ubigeo, monetary_poverty, nbi)

sociodemographic = socioeconomic |>
  inner_join(census, by = "ubigeo")

readr::write_csv(sociodemographic, "data/interim/sociodemographic.csv")
