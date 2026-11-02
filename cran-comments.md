## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* local: macOS 26.6 (aarch64), R 4.6.0
* win-builder: R-release 4.6.2 (1 note: new submission, spelling)
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel,
  release, oldrel-1)

## Notes for the reviewers

* Not to be confused with the CRAN package 'pks' (probabilistic knowledge
  structures); the title says "German Police Crime Statistics".
* The package downloads data releases from GitHub
  (https://github.com/ofurkancoban/pksR-data). Examples that need the
  internet run only in interactive sessions (`@examplesIf interactive()`),
  because `\donttest{}` examples run during `R CMD check --as-cran` and
  would fail without a connection. Without internet the functions stop
  with an informative message or use the cache.
* Tests run offline with mocked responses (httr2::local_mocked_responses()).
* Files are written only to tools::R_user_dir("pksR", "cache"), and only
  when the user downloads data. The example of pks_cache_clear() points
  that directory to tempfile() first.
* The words flagged in DESCRIPTION are spelled correctly:
  'Bundeskriminalamt' (German Federal Criminal Police Office), 'Kreis'
  (district) and 'PKS' (abbreviation of 'Polizeiliche
  Kriminalstatistik') are German names of the data source; 'SHA' and
  'checksums' refer to SHA-256 file checksums.
