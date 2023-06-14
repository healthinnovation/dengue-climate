sociodemo_colnames = c(
  "ubigeo", "district", "population", "non_precarious_household",
  "public_water_supply", "street_lighting", "have_fridge", "urban", "rural",
  "men", "women", "have_insurance", "literate"
)

sociodemo_raw = readr::read_csv(
  "data/raw/sociodemographic.csv", col_names = sociodemo_colnames,
  col_types = "cccddddddddddd", skip = 1
)

library(dplyr)

sociodemo = sociodemo_raw |>
  select(ubigeo, non_precarious_household:literate) |>
  mutate(
    ubigeo = stringr::str_pad(ubigeo, width = 6, side = "left", pad = "0")
  ) |>
  rename_with(
    \(x) paste0("socio_", stringr::str_replace_all(x, "_", "")), .cols = -ubigeo
  )

socioeco_raw = readr::read_csv(
  "data/raw/socioeconomic.csv", col_types = "cddddddddddddd"
)

socioeco = socioeco_raw |>
  mutate(
    ubn = 100 * hh_1_nbi_or_more / number_hh,
    inadequate = 100 * hh_inadequate_char / number_hh,
    overcrowded = 100 * overcrowded_hh / number_hh,
    nosanitation = 100 * hh_wo_sanitation / number_hh,
    schoolabscence = 100 * hh_school_absence / number_hh,
    highecodependence = 100 * hh_high_economic_dependence / number_hh,
    monetarypoverty = 100 * monetary_poverty,
    completesecondaryedu = 100 * complete_secondary_edu,
    .keep = "unused"
  ) |>
  rename_with(
    \(x) paste0("socio_", stringr::str_replace_all(x, "_", "")), .cols = -ubigeo
  )

socio = sociodemo |>
  inner_join(socioeco, by = "ubigeo")

readr::write_csv(socio, "data/interim/sociodemographic.csv")
