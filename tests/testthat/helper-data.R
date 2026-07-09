example_bathy <- function() {
  read_bathy(blueterra_example("synthetic_bathy"))
}

example_zones <- function() {
  terra::vect(blueterra_example("synthetic_zones"))
}
