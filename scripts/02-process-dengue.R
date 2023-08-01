input_path = "data/raw/DEN_Datos completos_data.csv"

dengue_raw = read.csv(
  input_path, sep = "\t", skipNul = TRUE, fileEncoding = "latin1",
)

library(dplyr)

dengue_select = select(dengue_raw, c(1, 2, 4, 21, 22))
col_names = c("year", "week", "ubigeo", "confirmed_cases", "probable_cases")
names(dengue_select) = col_names

dengue = dengue_select |>
  mutate(ubigeo = stringr::str_pad(ubigeo, 6, pad = "0"))

data("Peru", package = "innovar")

grid = expand.grid(
  ubigeo = Peru$ubigeo, year = unique(dengue$year), week = unique(dengue$week)
)

dengue_full = grid |>
  left_join(dengue, by = c("ubigeo", "year", "week")) |>
  arrange(ubigeo, year, week)

output_path = "data/interim/dengue.csv"
write.csv(dengue_full, output_path, row.names = FALSE, fileEncoding = "UTF-8")
