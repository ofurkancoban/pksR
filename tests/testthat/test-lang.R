po <- pksR:::read_po(system.file("i18n", "de.po", package = "pksR"))

test_that("every message in the code has a German translation", {
  files <- list.files(test_path("..", "..", "R"), pattern = "[.]R$", full.names = TRUE)
  skip_if(length(files) == 0, "package sources not available")
  texts <- unlist(lapply(files, function(f) {
    p <- utils::getParseData(parse(f, keep.source = TRUE))
    calls <- which(p$token == "SYMBOL_FUNCTION_CALL" & p$text %in% c("tr", "N_"))
    vapply(calls, function(i) {
      call <- p$parent[p$id == p$parent[i]]
      kids <- p[p$parent == call, ]
      str <- p$text[p$parent %in% kids$id[kids$token == "expr"][-1] & p$token == "STR_CONST"][1]
      eval(parse(text = str))
    }, "")
  }))
  missing <- setdiff(unique(texts), names(po)[nzchar(po)])
  expect_identical(missing, character(0))
})

test_that("translations keep every placeholder of the English text", {
  # Interpolated expressions and cli classes must be identical; plural
  # markers ({?s}) differ between the languages and are left out.
  placeholders <- function(x) {
    inner <- unlist(regmatches(x, gregexpr("\\{[^{}]*\\}", x)))
    inner <- inner[!startsWith(inner, "{?")]
    classes <- unlist(regmatches(x, gregexpr("\\{\\.[a-z]+", x)))
    formats <- unlist(regmatches(x, gregexpr("%[ds]", x)))
    sort(c(inner, classes, formats))
  }
  for (en in names(po)) {
    expect_identical(placeholders(po[[en]]), placeholders(en), label = en)
  }
})

test_that("the language follows the option, then the session", {
  withr::local_options(pksR.lang = NULL)
  withr::local_envvar(LANGUAGE = "de_DE")
  expect_identical(pksR:::pks_lang(), "de")
  withr::local_envvar(LANGUAGE = "en")
  expect_identical(pksR:::pks_lang(), "en")
  withr::local_options(pksR.lang = "de")
  expect_identical(pksR:::pks_lang(), "de")
  withr::local_options(pksR.lang = "fr")
  expect_error(pksR:::pks_lang(), "must be")
})

test_that("messages come in German when the language is German", {
  withr::local_options(pksR.lang = "de")
  expect_error(pks_rates(pks_example(), per = -1), "positive Zahl")
  expect_message(pks_validate(pks_example()), "Pr\u00fcfung")
  withr::local_options(pksR.lang = "en")
  expect_error(pks_rates(pks_example(), per = -1), "positive number")
})

test_that("the lang argument of pks_get() sets labels and messages", {
  local_fake_release()
  de <- pks_get(years = 2021, offence = "total", lang = "de")
  en <- pks_get(years = 2021, offence = "total", lang = "en")
  expect_true(all(de$offence_label == "Straftaten insgesamt"))
  expect_true(all(en$offence_label == "Total offences"))
  expect_error(pks_get(years = 2021, offence = "nichts", lang = "de"), "Keine Straftat")
  expect_error(pks_get(lang = "fr"), "must be")
  # The option of the session is restored after the call
  expect_identical(getOption("pksR.lang"), "en")
})

test_that("data as published keep the BKA label in German and get the English one", {
  local_fake_release()
  de <- pks_get(years = 2021, harmonize_to = NULL, offence = "burglary", lang = "de")
  en <- pks_get(years = 2021, harmonize_to = NULL, offence = "burglary", lang = "en")
  expect_identical(unique(de$offence_key), "435*00")
  expect_match(unique(de$offence_label), "^Wohnungseinbruchdiebstahl")
  expect_identical(unique(en$offence_label), "Residential burglary")
})
