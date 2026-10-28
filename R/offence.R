# Offence selection by key, alias or label, in German or English
# (notes/decisions.md). The offence map of the data release decides; a
# release without alias columns gets the aliases of the snapshot that ships
# with the package, matched by key.

# Lowercase ASCII with underscores, the form of the aliases: a name written
# with umlauts, with ae/oe/ue, with spaces or in capitals is the same name.
normalize_name <- function(x) {
  x <- tolower(enc2utf8(x))
  for (p in list(c("\u00e4", "ae"), c("\u00f6", "oe"), c("\u00fc", "ue"), c("\u00df", "ss"))) {
    x <- gsub(p[1], p[2], x, fixed = TRUE)
  }
  x <- gsub("[^a-z0-9]+", "_", x)
  gsub("^_+|_+$", "", x)
}

with_aliases <- function(map) {
  if (all(c("alias_en", "alias_de") %in% names(map))) return(map)
  snap <- offence_map_snapshot
  i <- match(map$offence_key_harmonized, snap$offence_key_harmonized)
  map$alias_en <- snap$alias_en[i]
  map$alias_de <- snap$alias_de[i]
  map
}

# Harmonized keys for `offence`. Each element is, in this order: a key, an
# alias, a full label, or a part of a label; a part may match several keys,
# which are reported.
resolve_offences <- function(offence, map) {
  if (!is.character(offence) || anyNA(offence) || !length(offence)) {
    cli::cli_abort(tr("{.arg offence} must be a character vector, such as {.code \"residential_burglary\"} or {.code \"435*00\"}."))
  }
  map <- with_aliases(map)
  keys <- map$offence_key_harmonized
  labels <- cbind(normalize_name(map$label_de), normalize_name(map$label_en))
  aliases <- cbind(map$alias_de, map$alias_en)
  out <- lapply(offence, function(x) {
    if (x %in% keys) return(x)
    n <- normalize_name(x)
    hit <- keys[rowSums(aliases == n, na.rm = TRUE) > 0 | rowSums(labels == n, na.rm = TRUE) > 0]
    if (length(hit)) return(hit)
    part <- nzchar(n) & (grepl(n, labels[, 1], fixed = TRUE) | grepl(n, labels[, 2], fixed = TRUE) |
                           grepl(n, aliases[, 1], fixed = TRUE) | grepl(n, aliases[, 2], fixed = TRUE))
    if (!any(part)) {
      cli::cli_abort(c(
        tr("No offence matches {.val {x}}."),
        "i" = tr("See {.fn pks_offences} for keys, names and labels.")
      ))
    }
    found <- keys[part]
    shown <- paste0(found, " (", map[[paste0("alias_", pks_lang())]][part], ")")
    cli::cli_inform(tr("{.val {x}} matches {length(found)} offence{?s}: {shown}."))
    found
  })
  unique(unlist(out))
}

# Label of each harmonized key in `lang`.
offence_labels <- function(keys, map, lang) {
  map[[paste0("label_", lang)]][match(keys, map$offence_key_harmonized)]
}

# Published rows that feed the harmonized keys `keys`, year by year (the
# published key of a harmonized key can differ between years).
published_rows <- function(data, keys, map) {
  spec <- offence_spec(map)
  direct <- spec[is.na(spec$minus_key) & spec$offence_key_harmonized %in% keys, ]
  computed <- spec[!is.na(spec$minus_key) & spec$offence_key_harmonized %in% keys & spec$year %in% data$year, ]
  if (nrow(computed)) {
    cli::cli_inform(tr("Not published as such, only computed when harmonizing: {.val {unique(paste0(computed$offence_key_harmonized, ' (', computed$year, ')'))}}."))
  }
  paste(data$year, data$offence_key) %in% paste(direct$year, direct$plus_key)
}

# English labels for data as published: through the harmonized key of each
# published key and year.
published_labels_en <- function(data, map) {
  spec <- offence_spec(map)
  direct <- spec[is.na(spec$minus_key), ]
  i <- match(paste(data$year, data$offence_key), paste(direct$year, direct$plus_key))
  offence_labels(direct$offence_key_harmonized[i], map, "en")
}
