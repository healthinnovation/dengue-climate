census_colnames = c(
  "ubigeo", "district", "population", "non_precarious_household",
  "public_water_supply", "street_lighting", "internet_access", "have_fridge",
  "urban", "rural", "men", "women", "have_insurance", "literate"
)

census_raw = readr::read_csv(
  "data/raw/sociodemographic.csv", col_names = census_colnames,
  col_types = "cccddddddddddd", skip = 1
)

census = census_raw |>
  mutate(
    ubigeo = stringr::str_pad(ubigeo, width = 6, side = "left", pad = "0")
  )

library(dplyr)

households = census |>
  select(ubigeo, non_precarious_household:literate, -c(urban, rural, men, women))

poverty_raw = readr::read_csv(
  "data/raw/socioeconomic.csv", col_types = "cddddddddddddd",
  col_select = c(ubigeo, monetary_poverty, hh_1_nbi_or_more, number_hh, idh)
)

poverty = poverty_raw |>
  mutate(ubn = hh_1_nbi_or_more / number_hh, .keep = "unused")

sociodemographics = inner_join(households, poverty, by = "ubigeo")

library(parameters)

pca_sociodemo = sociodemographics |>
  select(-ubigeo) |>
  principal_components(n = 4)

pca_sociodemo_scores = pca_sociodemo |>
  predict(names = c("comp1", "comp2", "comp3", "comp4")) |>
  as_tibble()

sociodemo = census |>
  select(ubigeo, urban, rural, men, women) |>
  bind_cols(pca_sociodemo_scores) |>
  rename_with(
    \(x) paste0("socio_", stringr::str_replace_all(x, "_", "")), .cols = -ubigeo
  )

readr::write_csv(sociodemo, "data/interim/sociodemographic.csv")
