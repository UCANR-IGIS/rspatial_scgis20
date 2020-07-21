## Make a map from a Google Sheet

## Load required packages
library(googlesheets4)
library(dplyr)
library(leaflet)
library(httr)
library(rjson)

## In case Google Sheets authorization is enabled, turn it off (we don't need it)
googlesheets4::gs4_deauth()

## Get the ID for the Google Sheet (permission is 'anyone with the link')
scgis_cities_id <- "1wmvQDTr2wTIIsafptWfkh2WO6dUQDwuVcDUSJbMjm20"

## Download the 'Form Responses' sheet
cities_tbl <- googlesheets4::range_read(ss = scgis_cities_id, sheet = "Form Responses 1", range = NULL) %>% 
  select("fname" = "First name", "city" = "City", "state" = "State / Province", "zip" = "Zip / Postal Code",
         "country" = "Country", "invertebrate" = "What is your favorite invertebrate?")

## Add an ID column that uniquely identifies each row
cities_tbl$ID <- 1:nrow(cities_tbl)

## See what it looks like
## View(cities_tbl)

## Grab a temporary token for the ESRI World Geocoding Service
workshop_token_url <- "https://raw.githubusercontent.com/UCANR-IGIS/rspatial_scgis20/master/docs/token1.txt"

## Create a (file) connection object
f <- file(workshop_token_url, open = "r")

## Read in the first line of the file
my_esri_token <- readLines(f, n = 1)

## Close the connection
close(f)

## Load the script that has the custom functions
source("./scripts/geocode_esri.R")
#source("./outputs/rspatial_scgis20/docs/scripts/geocode_esri.R")

## Run the geocode
cities_tbl_gc <- geocode_many(cities_tbl$ID, "", cities_tbl$city, cities_tbl$state, cities_tbl$zip, cities_tbl$country, my_esri_token)

## View the results
## cities_tbl_gc

## Merge the geocode results with the survey data
cities_loc_df <- merge(cities_tbl, cities_tbl_gc, by = "ID", all.x = T)
## cities_loc_df

## Create a character vector of HTML code for the pop-up windows
my_popups <- paste0("<b>", cities_loc_df$fname, "</b><br/>City: ", 
                    cities_loc_df$city, "<br/>Feels most like a:<br/><b>",
                    cities_loc_df$invertebrate, "</b>")

## Create the leaflet map
cities_lflt <- leaflet(cities_loc_df) %>% 
  addTiles() %>% 
  addCircleMarkers(~lon, ~lat, popup = my_popups)

## Display the leaflet map
print(cities_lflt)

