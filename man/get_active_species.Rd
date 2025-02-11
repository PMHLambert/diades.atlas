% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/fct_species.R
\name{get_active_species}
\alias{get_active_species}
\title{Get Active species}
\usage{
get_active_species(session = shiny::getDefaultReactiveDomain())
}
\arguments{
\item{session}{The Shiny Session object}
}
\value{
a tbl with active species
}
\description{
Get Active species
}
\examples{
if (interactive()) {
  get_active_species()
}
}
