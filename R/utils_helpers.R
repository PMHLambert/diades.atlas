translation <- function() {
  read.csv(
    app_sys("translation.csv")
  )
}
get_translation_entry <- function(entry, lg) {
  df <- read.csv(
    app_sys("translation.csv")
  )
  df[
    df$entry == entry,
    lg
  ]
}

translation_help <- function() {
  read.csv(
    app_sys("translation_help.csv")
  )
}

translation_iucn <- function() {
  read.csv(
    app_sys("translation_iucn.csv")
  )
}

translation_species <- function(session = shiny::getDefaultReactiveDomain()) {
  DBI::dbGetQuery(
    get_con(session),
    "SELECT local_name AS entry, english_name AS en, diadesatlas.translate(english_name, 'fr') AS fr from diadesatlas.species WHERE active=TRUE"
  )
}

#' @importFrom stats setNames
translation_abundance_level <- function(session = shiny::getDefaultReactiveDomain()) {
  # TODO ecrire depuis la base
  DBI::dbGetQuery(
    get_con(session),
    "select abundance_level_name AS entry, abundance_level_interpretation_short AS en from abundance_level"
    # "select abundance_level_name AS entry, abundance_level_interpretation_short AS en, diadesatlas.translate(abundance_level_interpretation_short, 'fr') AS fr from abundance_level"
  ) %>%
    # Cette traduction est temporaire, il FAUDRA utiliser la traduction depuis la base de données,
    # via le code SQL commenté
    mutate(
      fr = c(
        # Make R CMD Check happy because we're in 1987
        "Non enregistr\\u00e9 sur la p\\u00e9riode" %>% stringi::stri_unescape_unicode(),
        "Pr\\u00e9sence occasionnelle" %>% stringi::stri_unescape_unicode(),
        "Populations fonctionnelles",
        "Populations fonctionnelles abondante"
      )
    )
}

translation_v_ecosystemic_services <- function(session = shiny::getDefaultReactiveDomain()) {
  dplyr::bind_rows(
    DBI::dbGetQuery(
      get_con(session),
      "SELECT
        REPLACE(LOWER(casestudy_name), ' ', '-') as entry,
        casestudy_name as en,
        diadesatlas.translate(casestudy_name, 'fr') as fr
        from v_ecosystemic_services"
    ),
    DBI::dbGetQuery(
      get_con(session),
      "SELECT
        REPLACE(LOWER(category_name), ' ', '-') as entry,
        category_name as en,
        diadesatlas.translate(category_name, 'fr') as fr
        from v_ecosystemic_services"
    ),
    DBI::dbGetQuery(
      get_con(session),
      "SELECT
        REPLACE(LOWER(subcategory_name), ' ', '-') as entry,
        subcategory_name as en,
        diadesatlas.translate(subcategory_name, 'fr') as fr
        from v_ecosystemic_services"
    ),
    DBI::dbGetQuery(
      get_con(session),
      "SELECT
        REPLACE(LOWER(subcategory_name), ' ', '-') as entry,
        subcategory_name as en,
        diadesatlas.translate(subcategory_name, 'fr') as fr
        from v_ecosystemic_services"
    )
  )
}

#' @importFrom utils read.csv
build_language_json <- function(session = shiny::getDefaultReactiveDomain()) {
  lg <- dplyr::bind_rows(
    translation(),
    translation_species(session = session),
    translation_iucn(),
    translation_abundance_level(session = session),
    translation_v_ecosystemic_services(session = session),
    translation_help()
  )

  build_entry <- function(subset) {
    if (subset %not_in% names(lg)) {
      stop(
        "The entry '", subset, "' was not found in the translation data.frame."
      )
    }
    x <- list(
      translation = as.list(lg[[subset]])
    )
    names(x$translation) <- lg$entry
    x
  }
  available_langs <- get_available_lang(lg)

  lapply(
    available_langs,
    build_entry
  ) %>%
    setNames(available_langs) %>%
    jsonlite::toJSON(auto_unbox = TRUE)
}

get_available_lang <- function(df) {
  nms <- names(df)
  nms <- nms[which(nms != "entry")]
  nms
}

with_multilg <- function(fun, i18n, default) {
  purrr::partial(
    fun,
    label = with_i18(
      tags$span(
        default
      ),
      i18n
    )
  )
}

get_dt_lg <- function(lg) {
  list(
    url = switch(lg,
      en = "//cdn.datatables.net/plug-ins/1.10.11/i18n/English.json",
      fr = "//cdn.datatables.net/plug-ins/1.10.11/i18n/French.json"
    )
  )
}

#' Title
#'
#' @param con The DB connection object
#'
#' @return A list of data.frame
#' @export
#'
generate_datasets <- function(con) {
  cli::cat_rule("generate_datasets")
  dataCatchment <- DBI::dbReadTable(
    con,
    "v_abundance"
  ) %>%
    dplyr::inner_join(
      dplyr::tribble(
        ~abundance_level_id, ~abundance_interpretation,
        1, "Not recorded in the period",
        2, "Occasional vagrants",
        3, "Functional populations",
        4, "Abundant functional populations"
      ) %>%
        dplyr::mutate(abundance_interpretation = factor(abundance_interpretation,
          levels = .$abundance_interpretation
        )),
      by = "abundance_level_id"
    )

  catchment_geom <- sf::st_read(
    con,
    query =   "SELECT * FROM diadesatlas.v_basin vb"
  ) %>%
    rmapshaper::ms_simplify()

  dataALL <- DBI::dbGetQuery(
    con,
    "SELECT * from diadesatlas.v_species_ices_occurence vsio "
  ) %>%
    # tibble() %>%
    dplyr::mutate(nb_occurence = as.integer(nb_occurence))

  ices_geom <- sf::st_read(
    con,
    query = "SELECT * FROM diadesatlas.v_ices_geom;"
  ) %>%
    # sf::st_transform("+proj=eqearth +wktext") %>%
    sf::st_transform("+proj=wintri") %>%
    rmapshaper::ms_simplify()

  species_order <- c(
    "Alosa alosa",
    "Alosa fallax",
    "Petromyzon marinus",
    "Lampetra fluviatilis",
    "Salmo salar",
    "Salmo trutta",
    "Acipenser sturio",
    "Osmerus eperlanus",
    "Anguilla anguilla",
    "Chelon ramada",
    "Platichthys flesus"
  )

  species_list <- DBI::dbGetQuery(
    con,
    "SELECT *, diadesatlas.translate(english_name, 'fr') AS french_name from diadesatlas.species WHERE active=TRUE"
  )

  species_list <- species_list[
    match(
      species_order,
      species_list$latin_name
    ),
  ]
  return(
    list(
      dataCatchment = dataCatchment,
      catchment_geom = catchment_geom,
      dataALL = dataALL,
      ices_geom = ices_geom,
      species_list = species_list
    )
  )
}