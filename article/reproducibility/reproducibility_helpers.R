# Shared helpers for the clean-environment reproducibility workflow.
#
# This file deliberately relies only on base R plus utilities already required
# to execute the documented `blueterra` examples.

bt_repro_default <- function(value, fallback) {
  if (is.null(value) || !length(value) || identical(value, "")) fallback else value
}

bt_repro_parse_args <- function(args) {
  out <- list()
  i <- 1L
  while (i <= length(args)) {
    arg <- args[[i]]
    if (!startsWith(arg, "--")) {
      stop("Unexpected argument: ", arg, call. = FALSE)
    }
    key_value <- substring(arg, 3L)
    if (grepl("=", key_value, fixed = TRUE)) {
      pieces <- strsplit(key_value, "=", fixed = TRUE)[[1]]
      key <- pieces[[1]]
      value <- paste(pieces[-1L], collapse = "=")
    } else if (i < length(args) && !startsWith(args[[i + 1L]], "--")) {
      key <- key_value
      value <- args[[i + 1L]]
      i <- i + 1L
    } else {
      key <- key_value
      value <- TRUE
    }
    if (is.character(value)) {
      value <- gsub("~+~", " ", value, fixed = TRUE)
    }
    out[[key]] <- value
    i <- i + 1L
  }
  out
}

bt_repro_utc <- function(time = Sys.time()) {
  format(time, tz = "UTC", usetz = TRUE, format = "%Y-%m-%dT%H:%M:%SZ")
}

bt_repro_shell_quote <- function(value) {
  shQuote(as.character(value))
}

bt_repro_sha256_file <- function(path) {
  if (!file.exists(path)) {
    stop("Cannot hash a missing file: ", path, call. = FALSE)
  }

  shasum <- Sys.which("shasum")
  sha256sum <- Sys.which("sha256sum")
  if (nzchar(shasum)) {
    output <- system2(shasum, c("-a", "256", bt_repro_shell_quote(path)), stdout = TRUE, stderr = TRUE)
  } else if (nzchar(sha256sum)) {
    output <- system2(sha256sum, bt_repro_shell_quote(path), stdout = TRUE, stderr = TRUE)
  } else {
    stop("Neither `shasum` nor `sha256sum` is available for SHA-256 hashing.", call. = FALSE)
  }
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("SHA-256 command failed: ", paste(output, collapse = "\n"), call. = FALSE)
  }
  fields <- strsplit(trimws(output[[1]]), "[[:space:]]+")[[1]]
  if (!length(fields) || !grepl("^[[:xdigit:]]{64}$", fields[[1]])) {
    stop("Could not parse SHA-256 output for: ", path, call. = FALSE)
  }
  tolower(fields[[1]])
}

bt_repro_sha256_text <- function(text) {
  path <- tempfile("blueterra-repro-text-")
  on.exit(unlink(path), add = TRUE)
  con <- file(path, open = "wb")
  writeBin(charToRaw(enc2utf8(paste(text, collapse = "\n"))), con)
  close(con)
  bt_repro_sha256_file(path)
}

bt_repro_write_csv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.csv(x, path, row.names = FALSE, na = "")
  invisible(path)
}

bt_repro_json_escape <- function(value) {
  value <- enc2utf8(as.character(value))
  value <- gsub("\\\\", "\\\\\\\\", value, fixed = TRUE)
  value <- gsub("\"", "\\\\\"", value, fixed = TRUE)
  value <- gsub("\n", "\\\\n", value, fixed = TRUE)
  value <- gsub("\r", "\\\\r", value, fixed = TRUE)
  value <- gsub("\t", "\\\\t", value, fixed = TRUE)
  value
}

bt_repro_to_json <- function(x) {
  if (is.null(x)) {
    return("null")
  }
  if (is.factor(x)) {
    x <- as.character(x)
  }
  if (is.data.frame(x)) {
    rows <- lapply(seq_len(nrow(x)), function(i) as.list(x[i, , drop = FALSE]))
    return(bt_repro_to_json(rows))
  }
  if (is.list(x)) {
    nms <- names(x)
    if (!is.null(nms) && all(nzchar(nms))) {
      entries <- vapply(seq_along(x), function(i) {
        paste0(
          "\"", bt_repro_json_escape(nms[[i]]), "\":",
          bt_repro_to_json(x[[i]])
        )
      }, character(1))
      return(paste0("{", paste(entries, collapse = ","), "}"))
    }
    return(paste0("[", paste(vapply(x, bt_repro_to_json, character(1)), collapse = ","), "]"))
  }
  if (length(x) != 1L) {
    return(paste0("[", paste(vapply(as.list(x), bt_repro_to_json, character(1)), collapse = ","), "]"))
  }
  if (is.logical(x)) {
    return(if (is.na(x)) "null" else if (isTRUE(x)) "true" else "false")
  }
  if (is.numeric(x)) {
    if (!is.finite(x)) return("null")
    return(format(x, scientific = FALSE, trim = TRUE, digits = 17))
  }
  if (is.na(x)) {
    return("null")
  }
  paste0("\"", bt_repro_json_escape(x), "\"")
}

bt_repro_write_json <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(bt_repro_to_json(x), path, useBytes = TRUE)
  invisible(path)
}

bt_repro_scalar <- function(x) {
  if (!length(x) || is.null(x) || is.na(x[[1]])) "" else as.character(x[[1]])
}

bt_repro_format_numbers <- function(x) {
  x <- as.numeric(x)
  if (!length(x)) return("")
  paste(format(x, scientific = FALSE, trim = TRUE, digits = 16), collapse = ";")
}

bt_repro_crs_fields <- function(x) {
  crs_text <- try(terra::crs(x, proj = FALSE), silent = TRUE)
  if (inherits(crs_text, "try-error") || is.null(crs_text) || !length(crs_text) || is.na(crs_text)) {
    crs_text <- ""
  }
  crs_text <- gsub("[\r\n]+", " ", crs_text)
  list(text = crs_text, sha256 = bt_repro_sha256_text(crs_text))
}

bt_repro_empty_schema <- function(object, object_class) {
  data.frame(
    object = object,
    object_class = object_class,
    rows = NA_integer_,
    columns = NA_integer_,
    layers = NA_integer_,
    field_names = "",
    field_types = "",
    geometry_type = "",
    crs_text = "",
    crs_sha256 = "",
    extent = "",
    resolution = "",
    value_min = "",
    value_max = "",
    stringsAsFactors = FALSE
  )
}

bt_repro_object_schema <- function(object, x) {
  if (inherits(x, "SpatRaster")) {
    out <- bt_repro_empty_schema(object, paste(class(x), collapse = "/"))
    ext <- terra::ext(x)
    crs_fields <- bt_repro_crs_fields(x)
    extrema <- try(terra::global(x, c("min", "max"), na.rm = TRUE), silent = TRUE)
    out$rows <- terra::nrow(x)
    out$columns <- terra::ncol(x)
    out$layers <- terra::nlyr(x)
    out$field_names <- paste(names(x), collapse = ";")
    out$field_types <- paste(rep("numeric", terra::nlyr(x)), collapse = ";")
    out$crs_text <- crs_fields$text
    out$crs_sha256 <- crs_fields$sha256
    out$extent <- bt_repro_format_numbers(as.vector(ext))
    out$resolution <- bt_repro_format_numbers(terra::res(x))
    if (!inherits(extrema, "try-error")) {
      out$value_min <- bt_repro_format_numbers(extrema[, "min"])
      out$value_max <- bt_repro_format_numbers(extrema[, "max"])
    }
    return(out)
  }

  if (inherits(x, "SpatVector")) {
    out <- bt_repro_empty_schema(object, paste(class(x), collapse = "/"))
    attrs <- terra::as.data.frame(x)
    ext <- terra::ext(x)
    crs_fields <- bt_repro_crs_fields(x)
    out$rows <- nrow(x)
    out$columns <- ncol(attrs)
    out$field_names <- paste(names(attrs), collapse = ";")
    out$field_types <- paste(vapply(attrs, function(column) paste(class(column), collapse = "/"), character(1)), collapse = ";")
    out$geometry_type <- paste(unique(terra::geomtype(x)), collapse = ";")
    out$crs_text <- crs_fields$text
    out$crs_sha256 <- crs_fields$sha256
    out$extent <- bt_repro_format_numbers(as.vector(ext))
    return(out)
  }

  if (is.data.frame(x)) {
    out <- bt_repro_empty_schema(object, paste(class(x), collapse = "/"))
    out$rows <- nrow(x)
    out$columns <- ncol(x)
    out$field_names <- paste(names(x), collapse = ";")
    out$field_types <- paste(vapply(x, function(column) paste(class(column), collapse = "/"), character(1)), collapse = ";")
    return(out)
  }

  out <- bt_repro_empty_schema(object, paste(class(x), collapse = "/"))
  out$field_names <- paste(names(x), collapse = ";")
  out
}

bt_repro_file_hashes <- function(root, scope) {
  paths <- list.files(root, recursive = TRUE, full.names = TRUE, include.dirs = FALSE)
  if (!length(paths)) {
    return(data.frame(scope = character(), artifact = character(), bytes = numeric(), sha256 = character(), stringsAsFactors = FALSE))
  }
  info <- file.info(paths)
  paths <- paths[!is.na(info$isdir) & !info$isdir]
  info <- file.info(paths)
  root_prefix <- paste0(normalizePath(root, winslash = "/", mustWork = TRUE), "/")
  relative <- sub(root_prefix, "", normalizePath(paths, winslash = "/", mustWork = TRUE), fixed = TRUE)
  data.frame(
    scope = scope,
    artifact = relative,
    bytes = as.numeric(info$size),
    sha256 = vapply(paths, bt_repro_sha256_file, character(1)),
    stringsAsFactors = FALSE
  )
}
