img_get_value <- function(img, dirpath){
  download.img <- img |>
    ee_as_stars(
      region = peru_ee,
      scale = 5*1000
    )
  extract.value <- download.img |>
    st_extract(Peru,fun = mean) |>
    st_as_sf() |>
    mutate(ubigeo = Peru$ubigeo) |>
    st_drop_geometry()

  tidy.db <- extract.value |>
    pivot_longer(
      cols = -one_of("ubigeo"),
      names_to = "date",
      values_to = "value"
    ) |>
    mutate(
      variable = sapply(str_extract_all(date, "[A-Za-z]+"), paste, collapse = ""),
      date = ymd(str_extract(pattern = "[0-9]+",date))
    )
  if(dir.exists(dirpath)!=1){dir.create(dirpath)}
  write_csv(
    tidy.db,
    paste0(dirpath, sprintf("%s.csv", unique(tidy.db[["variable"]])))
  )
}
