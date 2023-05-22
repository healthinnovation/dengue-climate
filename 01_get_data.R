library(tidyrgee)
library(tidyverse)
library(rgee)
library(sf)
library(stars)
library(innovar)
library(lubridate)
library(exactextractr)
source("utils.R")
ee_Initialize(drive = T)


# 1. Reading the Peru districts -------------------------------------------

data("Peru")
peru_ee <- Peru |> 
  st_bbox() |> 
  st_as_sfc() |>  
  sf_as_ee()

# 2. Meteorological and enviromental data pre-processing in Earth  --------

start_year <- 2018
end_year <- 2022
start_month <- 01
end_month <- 03

pp <- ee$ImageCollection$Dataset$`UCSB-CHG_CHIRPS_DAILY` |>  
  as_tidyee() |> 
  select("precipitation") |> 
  filter(year %in% start_year:end_year & month %in% start_month:end_month) |> 
  as_ee() |> 
  ee$ImageCollection$toBands()

tmin <- ee$ImageCollection$Dataset$ECMWF_ERA5_DAILY |>
  as_tidyee() |> 
  select("temperature_2m_min") |> 
  filter(year %in% start_year:end_year & month %in% start_month:end_month) |> 
  as_ee() |> 
  ee$ImageCollection$toBands() |> 
  ee$Image$subtract(273.15)

tmax <- ee$ImageCollection$Dataset$ECMWF_ERA5_DAILY |>
  as_tidyee() |> 
  select("temperature_2m_max") |> 
  filter(year %in% start_year:end_year & month %in% start_month:end_month) |> 
  as_ee() |> 
  ee$ImageCollection$toBands() |> 
  ee$Image$subtract(273.15)

etp.max <- ee$ImageCollection$Dataset$ECMWF_ERA5_DAILY |>
  as_tidyee() |> 
  select("potential_evaporation_max") |> 
  filter(year %in% start_year:end_year & month %in% start_month:end_month) |> 
  as_ee() |> 
  ee$ImageCollection$toBands()

etp.min <- ee$ImageCollection$Dataset$ECMWF_ERA5_DAILY |>
  as_tidyee() |> 
  select("potential_evaporation_min") |> 
  filter(year %in% start_year:end_year & month %in% start_month:end_month) |> 
  as_ee() |> 
  ee$ImageCollection$toBands() 

runoff.max <-  ee$ImageCollection$Dataset$ECMWF_ERA5_DAILY |>
  as_tidyee() |> 
  select("runoff_max") |> 
  filter(year %in% start_year:end_year & month %in% start_month:end_month) |> 
  as_ee() |> 
  ee$ImageCollection$toBands() 

runoff.min <- ee$ImageCollection$Dataset$ECMWF_ERA5_DAILY |>
  as_tidyee() |> 
  select("runoff_min") |> 
  filter(year %in% start_year:end_year & month %in% start_month:end_month) |> 
  as_ee() |> 
  ee$ImageCollection$toBands() 

# Working with GLDAS 3H to Daily
iniDate <- paste0(start_year,'-',start_month) |> ym() |> rdate_to_eedate()
endDate <- paste0(end_year,'-',end_month) |> ym() |> rdate_to_eedate()
difdate <- endDate$advance(-1, 'day')$difference(iniDate, 'day')
createList <- ee$List$sequence(0, difdate)
listdates <- createList$map(ee_utils_pyfunc(function(x){iniDate$advance(x, 'day')}))

humidity.3hours <- ee$ImageCollection$Dataset$NASA_GLDAS_V021_NOAH_G025_T3H |> 
  ee$ImageCollection$filter(ee$Filter$date(iniDate,endDate)) |> 
  ee$ImageCollection$select("Qair_f_inst") 

humidity.daily <- humidity.3hours$
  fromImages(
    listdates$map(
      ee_utils_pyfunc(
        function(summarize_day){
          filterCol <- humidity.3hours$filterDate(
            ee$Date(summarize_day),
            ee$Date(summarize_day)$
              advance(1, 'day')
          )
          
          filterCol.sum <- filterCol$sum()$select('Qair_f_inst')$
            copyProperties(filterCol$first())$
            setMulti(
              list(
                Date = ee$Date(summarize_day),
                'system:time_start' = ee$Date(summarize_day)$millis()
              )
            )
          return(filterCol.sum)
        }
      )
    )
  ) |> 
  ee$ImageCollection$toBands()

# Downloading variables 

img_get_value(img = pp)
img_get_value(img = tmax)
img_get_value(img = tmin)
img_get_value(img = runoff.max)
img_get_value(img = runoff.min)
img_get_value(img = etp.max)
img_get_value(img = etp.min)
img_get_value(img = humidity.daily)
