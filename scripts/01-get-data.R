library(tidyrgee)
library(tidyverse)
library(rgee)
library(sf)
library(stars)
library(innovar)
library(lubridate)
library(exactextractr)
source("source/utils.R")
ee_Initialize(user = "antony.barja@upch.pe", drive = T)

# 1. Reading the Peru districts -------------------------------------------
data("Peru")
peru_ee <- Peru |>
  st_bbox() |>
  st_as_sfc() |>
  sf_as_ee()

# 2. Meteorological and environmental data pre-processing in Earth  --------

start_date <- '2018-01-01'
end_date <- '2023-12-31'

pp <- ee$ImageCollection$Dataset$`UCSB-CHG_CHIRPS_DAILY` |>
  as_tidyee() |>
  select("precipitation") |>
  filter(year %in% year(start_date):year(end_date) & month %in% month(start_date):month(end_date)) |>
  as_ee() |>
  ee$ImageCollection$toBands()

tmin <- ee$ImageCollection("ECMWF/ERA5_LAND/DAILY_AGGR")$
  select("temperature_2m_min")$
  filterDate(start_date,end_date)$
  toBands()$
  subtract(273.15)

tmax <- ee$ImageCollection("ECMWF/ERA5_LAND/DAILY_AGGR")$
  select("temperature_2m_max")$
  filterDate(start_date,end_date)$
  toBands()$
  subtract(273.15)

etp.max <-  ee$ImageCollection("ECMWF/ERA5_LAND/DAILY_AGGR")$
  select("potential_evaporation_max")$
  filterDate(start_date,end_date)$
  toBands()

etp.min <-  ee$ImageCollection("ECMWF/ERA5_LAND/DAILY_AGGR")$
  select("potential_evaporation_min")$
  filterDate(start_date,end_date)$
  toBands()

runoff.max <-   ee$ImageCollection("ECMWF/ERA5_LAND/DAILY_AGGR")$
  select("runoff_max")$
  filterDate(start_date,end_date)$
  toBands()

runoff.min <- ee$ImageCollection("ECMWF/ERA5_LAND/DAILY_AGGR")$
  select("runoff_min")$
  filterDate(start_date,end_date)$
  toBands()

humidity <- ee$Image("users/ambarja/GLDAS_2018-01_2023-06-30")
humidity <- humidity |>
  mutate(
    date = rep(
      seq(
        as.Date('2018-01-01'),
        as.Date('2023-05-09'),
        '1 days'),
      nrow(Peru)
      )
    )

precipitacion.era5 <- ee$ImageCollection("ECMWF/ERA5_LAND/DAILY_AGGR")$
  select("total_precipitation_sum")$
  filterDate(start_date,end_date)$
  toBands()

# Downloading variables
dirpath = "./data/raw/"

img_get_value(img = pp, dirpath)
img_get_value(img = tmax, dirpath)
img_get_value(img = tmin, dirpath)
img_get_value(img = etp.max, dirpath)
img_get_value(img = etp.min, dirpath)
img_get_value(img = runoff.max, dirpath)
img_get_value(img = runoff.min, dirpath)
img_get_value(img = humidity, dirpath)
img_get_value(img = precipitacion.era5, dirpath)
