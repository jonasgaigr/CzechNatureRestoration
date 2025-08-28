#----------------------------------------------------------#
# Nacteni knihoven -----
#----------------------------------------------------------#
packages <- c(
  "tidyverse", 
  "sf", 
  "sp", 
  "proj4", 
  "openxlsx",
  "fuzzyjoin", 
  "remotes"
)

# Standardni package
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, dependencies = TRUE)
    library(pkg, character.only = TRUE)
  }
}

# GitHub remotes
if (!require("rn2kcz", quietly = TRUE)) {
  remotes::install_github("jonasgaigr/rn2kcz", force = TRUE)
  library(rn2kcz)
}

#----------------------------------------------------------#
# Load remote data -----
#----------------------------------------------------------#


#--------------------------------------------------#
## N2K target features ---- 
#--------------------------------------------------#
sites_subjects <- openxlsx::read.xlsx(
  "Data/Input/seznam_predmetolokalit_Natura2000_2_2025.xlsx",
  sheet = 1
) %>%
  dplyr::rename(
    site_code = `Kód.lokality`,
    site_name = `Název.lokality`,
    site_type = `Typ.lokality`,
    feature_type = `Typ.předmětu.ochrany`,
    sdf_code = `Kód.SDF`,
    feature_code = `Kód.ISOP`,
    nazev_cz = `Název.česky`,
    nazev_lat = `Název.latinsky.(druh)`
  )

#--------------------------------------------------#
## Nature conservation authorities ---- 
#--------------------------------------------------#
n2k_oop <- readr::read_csv2(
  "Data/Input/n2k_oop_25.csv", 
  locale = readr::locale(encoding = "Windows-1250")
) %>%
  mutate(oop = gsub(";", ",", oop)) %>%
  dplyr::rename(SITECODE = sitecode) %>%
  dplyr::select(SITECODE, oop)

#--------------------------------------------------#
## NCA CR Regional brancher ---- 
#--------------------------------------------------#
rp_code <- readr::read_csv2(
  "Data/Input/n2k_rp_25.csv", 
  locale = readr::locale(encoding = "Windows-1250")
) %>%
  dplyr::rename(
    kod_chu = sitecode
  ) %>%
  dplyr::select(
    kod_chu, 
    pracoviste) %>%
  dplyr::mutate(
    pracoviste = gsub(",", 
                      "", 
                      pracoviste
    )
  )

#--------------------------------------------------#
## Stažení GIS vrstev AOPK ČR ---- 
#--------------------------------------------------#

endpoint <- "http://gis.nature.cz/arcgis/services/Aplikace/Opendata/MapServer/WFSServer?"
caps_url <- paste0(endpoint, "request=GetCapabilities&service=WFS")

layer_name_evl      <- "Opendata:Evropsky_vyznamne_lokality"
layer_name_po       <- "Opendata:Ptaci_oblasti"
layer_name_biotopzvld <- "Opendata:Biotop_zvlaste_chranenych_druhu_velkych_savcu"

getfeature_url_evl <- paste0(
  endpoint,
  "service=WFS&version=2.0.0&request=GetFeature&typeName=", layer_name_evl
)
getfeature_url_po <- paste0(
  endpoint,
  "service=WFS&version=2.0.0&request=GetFeature&typeName=", layer_name_po
)
getfeature_url_biotopzvld <- paste0(
  endpoint,
  "service=WFS&version=2.0.0&request=GetFeature&typeName=", layer_name_biotopzvld
)

#--------------------------------------------------#
## Funkce pro načtení vrstvy: nejprve lokálně, jinak z WFS ----
#--------------------------------------------------#

read_layer <- function(local_path, wfs_url, n2k = NULL) {
  if (file.exists(local_path)) {
    message("Reading local file: ", local_path)
    shp <- sf::st_read(local_path, options = "ENCODING=CP1250", quiet = TRUE)
  } else {
    message("Local file not found, downloading from WFS: ", wfs_url)
    shp <- sf::st_read(wfs_url, quiet = TRUE)
  }
  
  shp <- sf::st_transform(
    shp, 
    st_crs("+init=epsg:5514")
  )
  
  if (!is.null(n2k)) {
    shp <- dplyr::left_join(shp, n2k, by = "SITECODE")
  }
  
  return(shp)
}

#--------------------------------------------------#
## Načtení vrstev ----
#--------------------------------------------------#

evl <- read_layer("Data/Input/EvVyzLok.shp", getfeature_url_evl, n2k = n2k_oop)
po  <- read_layer("Data/Input/PtaciObl.shp", getfeature_url_po,  n2k = n2k_oop)
biotop_zvld <- read_layer("Data/Input/BiotopZvld.shp", getfeature_url_biotopzvld)

#--------------------------------------------------#
## Spojení EVL a PO ----
#--------------------------------------------------#

n2k_union <- sf::st_join(evl, po)

#----------------------------------------------------------#
# Nacteni lokalnich dat -----
#----------------------------------------------------------#

#--------------------------------------------------#
## Cesta k lokalnim datum ---- 
#--------------------------------------------------#

slozka_lokal <- "C:/Users/jonas.gaigr/Documents/host_data/"

#------------------------------------------------------#
## Soecies data ----
# export obsahuje data o vyskytu citlivych druhu: 
# kompletni pouze pro overene uzivatele,
# bez vyskytu citlivych druhu na vyzadani na jonas.gaigr@aopk.gov.cz
#------------------------------------------------------#

#------------------------------------------------------#
## Habitats data ----
# export obsahuje data o vyskytu citlivych druhu: 
# kompletni pouze pro overene uzivatele,
# bez vyskytu citlivych druhu na vyzadani na jonas.gaigr@aopk.gov.cz
#------------------------------------------------------#


#----------------------------------------------------------#
# KONEC ----
#----------------------------------------------------------#