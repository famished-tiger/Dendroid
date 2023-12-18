# Changelog

## [Unreleased]

## [0.2.02] - 2023-12-18
Code re-styling to fix most Rubocop offenses.

### Added
- Directory 'modeling' for PlantUML text files.

### Changed
- File `dendroid.rb`: added `relative_require` to load key dependencies. 

## [0.2.01] - 2023-12-17
Code re-styling to fix most Rubocop offenses.

## [0.2.00] - 2023-12-16
Version bump: Very crude parser implementation (generate shared parse forests in case of ambiguity).

### Added
- Directory `parsing`: module implementing a parser
- Directory `formatters`: module with classes for rendering parse tree/forest 

## [0.1.00] - 2023-11-03
Version bump: the Earley recognizer is functional.

## [0.0.12] - 2023-11-02
Added more tests.

### Added
- Added more tests to spec file of `Grammar` class.
- Added more tests to spec file of `Recognizer` class.

## [0.0.11] - 2023-11-02
Added Earley recognizer and its ancillary classes.

### Added
- Class `Chart` and its spec file
- Class `EItem` and its spec file
- Class `ItemSet` and its spec file
- Class `Recognizer` and its spec file

### Changed
- RSpec tests: moved module `SampleGrammars` to separate file in folder `support`

## [0.0.10] - 2023-11-01
Added missing class and method documentation, fixed some `Rubocop` offenses.


## [0.0.9] - 2023-11-01
Added classes for tokenization and grammar analysis.

### Added
- Class `AlternativeItem` and its spec file
- Class `BaseTokenizer` and its spec file
- Module `ChoiceItems` and its spec file- 
- Class `GrmAnalyzer` and its spec file
- Class `Literal` and its spec file
- Module `ProductionItems` and its spec file
- Class `Token` and its spec file
- Class `TokenPosition` and its spec file

## [0.0.8] - 2023-10-30
### Added
- Class `DottedItem` and its spec file

## [0.0.7] - 2023-10-30
### Added
- Class `BaseGrmBuilder` and its spec file

## [0.0.6] - 2023-10-30
### Added
- Class `Grammar` and its spec file

## [0.0.5] - 2023-10-28
### Added
- Class `Choice` and its spec file

### Fixed
- File `dendroid.gemspec`: added missing `CHANGELOG.md` in the package

## [0.0.4] - 2023-10-28
### Added
- Class `Production` and its spec file

## [0.0.3] - 2023-10-28
### Added
- Class `Rule` and its spec file

## [0.0.2] - 2023-10-28
### Added
- Class `SymbolSeq` and its spec file
- File `CHANGELOG.md`; the file file you're reading now.

### Changed
- Line separator set to lf (line feed)
- Code re-styling to please Rubocop 1.57.1

## [0.0.1] - 2023-10-27
### Added
- Class `NonTerminal` and its spec file

## [0.0.0] - 2023-10-27
- Initial commit

### Added
- Class `GrmSymbol` and its spec file
- Class `Terminal` and its spec file