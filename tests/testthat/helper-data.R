example_bathy <- function() {
  read_bathy(blueterra_example("bathy"))
}

example_sites <- function() {
  sf::st_read(blueterra_example("sites"), quiet = TRUE)
}
