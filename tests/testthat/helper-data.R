example_bathy <- function() {
  read_bathy(blueterra_example("bathy"))
}

example_zones <- function() {
  terra::vect(blueterra_example("zones"))
}
