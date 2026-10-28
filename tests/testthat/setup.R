# Tests expect English messages, whatever the locale of the tester
withr::local_options(pksR.lang = "en", .local_envir = teardown_env())
