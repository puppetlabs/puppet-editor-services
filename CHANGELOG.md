<!-- markdownlint-disable MD024 -->
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/) and this project adheres to [Semantic Versioning](http://semver.org).

## [v2.0.1](https://github.com/puppetlabs/puppet-editor-services/tree/v2.0.1) - 2024-02-14

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/v2.0.0...v2.0.1)

### Fixed

- (Dependencies) - Upgrade puppet-lint to v4.2.4 & puppet-strings to v4.1.2 [#370](https://github.com/puppetlabs/puppet-editor-services/pull/370) ([jordanbreen28](https://github.com/jordanbreen28))

## [v2.0.0](https://github.com/puppetlabs/puppet-editor-services/tree/v2.0.0) - 2023-11-27

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/v1.3.1...v2.0.0)

### Changed
- (CAT-1430) - Drop ruby 2.5 Support & Add Ruby 3.x Support [#348](https://github.com/puppetlabs/puppet-editor-services/pull/348) ([jordanbreen28](https://github.com/jordanbreen28))

### Fixed

- (maint) - Write file type definitions to tempfile [#359](https://github.com/puppetlabs/puppet-editor-services/pull/359) ([jordanbreen28](https://github.com/jordanbreen28))
- (CAT-1595) - Remove diagnostic on textDoucment onDidClose [#356](https://github.com/puppetlabs/puppet-editor-services/pull/356) ([jordanbreen28](https://github.com/jordanbreen28))
- (CAT-1493) - Fix missing file resource type parameters [#353](https://github.com/puppetlabs/puppet-editor-services/pull/353) ([jordanbreen28](https://github.com/jordanbreen28))

## [v1.3.1](https://github.com/puppetlabs/puppet-editor-services/tree/v1.3.1) - 2023-03-15

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/1.3.0...v1.3.1)

### Fixed

- GH-318 Used a realpath for load dependencies. [#326](https://github.com/puppetlabs/puppet-editor-services/pull/326) ([bit0rez](https://github.com/bit0rez))
- Fix `NoMethodError` in puppet_strings_helper.rb [#322](https://github.com/puppetlabs/puppet-editor-services/pull/322) ([scoiatael](https://github.com/scoiatael))
- (GH-320) Handle @param tags for non-existent params [#321](https://github.com/puppetlabs/puppet-editor-services/pull/321) ([h4l](https://github.com/h4l))

## [1.3.0](https://github.com/puppetlabs/puppet-editor-services/tree/1.3.0) - 2021-09-30

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/1.2.0...1.3.0)

### Fixed

- (GH-311) Explicitly require Facter [#312](https://github.com/puppetlabs/puppet-editor-services/pull/312) ([da-ar](https://github.com/da-ar))

### Other

- (GH-313) Prepare 1.3.0 Release [#314](https://github.com/puppetlabs/puppet-editor-services/pull/314) ([da-ar](https://github.com/da-ar))

## [1.2.0](https://github.com/puppetlabs/puppet-editor-services/tree/1.2.0) - 2021-05-28

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/1.1.0...1.2.0)

### Added

- (maint) Add port 9000 for dev. container [#307](https://github.com/puppetlabs/puppet-editor-services/pull/307) ([glennsarti](https://github.com/glennsarti))
- (GH-306) Add a syntax aware code folding provider [#302](https://github.com/puppetlabs/puppet-editor-services/pull/302) ([glennsarti](https://github.com/glennsarti))

### Fixed

- (GH-300) Return nil for bad hover requests [#301](https://github.com/puppetlabs/puppet-editor-services/pull/301) ([glennsarti](https://github.com/glennsarti))
- (GH-298) Fix tests for Facter 4.0.52 gem [#299](https://github.com/puppetlabs/puppet-editor-services/pull/299) ([glennsarti](https://github.com/glennsarti))

### Other

- (GH-309) Prepare 1.2.0 release [#308](https://github.com/puppetlabs/puppet-editor-services/pull/308) ([glennsarti](https://github.com/glennsarti))
- Fix small typo in README.md [#305](https://github.com/puppetlabs/puppet-editor-services/pull/305) ([vStone](https://github.com/vStone))

## [1.1.0](https://github.com/puppetlabs/puppet-editor-services/tree/1.1.0) - 2021-01-27

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/1.0.1...1.1.0)

### Other

- (GH-293) Prepare for 1.1.0 release [#294](https://github.com/puppetlabs/puppet-editor-services/pull/294) ([glennsarti](https://github.com/glennsarti))
- (GH-189) Fix module root for validation [#291](https://github.com/puppetlabs/puppet-editor-services/pull/291) ([glennsarti](https://github.com/glennsarti))
- (GH-289) Make Format On Type file size configurable [#290](https://github.com/puppetlabs/puppet-editor-services/pull/290) ([glennsarti](https://github.com/glennsarti))
- (maint) Use GitHub actions instead of Travis and Appveyor CI [#288](https://github.com/puppetlabs/puppet-editor-services/pull/288) ([glennsarti](https://github.com/glennsarti))
- (GH-189) Reset PuppetLint configuration for each call [#286](https://github.com/puppetlabs/puppet-editor-services/pull/286) ([glennsarti](https://github.com/glennsarti))
- (maint) Add codeowners file [#283](https://github.com/puppetlabs/puppet-editor-services/pull/283) ([jpogran](https://github.com/jpogran))
- (GH-282) Add Puppet 7 to CI testing  [#281](https://github.com/puppetlabs/puppet-editor-services/pull/281) ([glennsarti](https://github.com/glennsarti))

## [1.0.1](https://github.com/puppetlabs/puppet-editor-services/tree/1.0.1) - 2020-11-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/1.0.0...1.0.1)

### Other

- (GH-279) Prepare for 1.0.1 release [#280](https://github.com/puppetlabs/puppet-editor-services/pull/280) ([glennsarti](https://github.com/glennsarti))

## [1.0.0](https://github.com/puppetlabs/puppet-editor-services/tree/1.0.0) - 2020-07-25

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.26.1...1.0.0)

### Other

- (GH-274) Release 1.0.0 [#275](https://github.com/puppetlabs/puppet-editor-services/pull/275) ([glennsarti](https://github.com/glennsarti))
- (GH-272) Puppet Lint and document symbol sometimes not working [#273](https://github.com/puppetlabs/puppet-editor-services/pull/273) ([glennsarti](https://github.com/glennsarti))
- (GH-269) Fix Workspace Symbol Provider [#271](https://github.com/puppetlabs/puppet-editor-services/pull/271) ([glennsarti](https://github.com/glennsarti))
- (maint) Update Puppetfile Resolver to 0.3.0 [#268](https://github.com/puppetlabs/puppet-editor-services/pull/268) ([glennsarti](https://github.com/glennsarti))
- (maint) Document removal of Puppet 4 [#265](https://github.com/puppetlabs/puppet-editor-services/pull/265) ([glennsarti](https://github.com/glennsarti))
- (GH-262) Merge 1.0 into master [#264](https://github.com/puppetlabs/puppet-editor-services/pull/264) ([glennsarti](https://github.com/glennsarti))
- (GH-262) Prepare 1.0 to be merged into master [#263](https://github.com/puppetlabs/puppet-editor-services/pull/263) ([glennsarti](https://github.com/glennsarti))
- (GH-256) Add acceptance tests for puppetfile resolver request [#260](https://github.com/puppetlabs/puppet-editor-services/pull/260) ([glennsarti](https://github.com/glennsarti))

## [0.26.1](https://github.com/puppetlabs/puppet-editor-services/tree/0.26.1) - 2020-06-05

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.26.0...0.26.1)

### Added

- (GH-256) Puppetfile dependency endpoint [#255](https://github.com/puppetlabs/puppet-editor-services/pull/255) ([jpogran](https://github.com/jpogran))

### Fixed

- (maint) Pin Rubocop to < 0.84.0 [#253](https://github.com/puppetlabs/puppet-editor-services/pull/253) ([glennsarti](https://github.com/glennsarti))

### Other

- (maint) Remove vendored gems [#251](https://github.com/puppetlabs/puppet-editor-services/pull/251) ([glennsarti](https://github.com/glennsarti))
- (maint) Mergeup master into 1.0 [#250](https://github.com/puppetlabs/puppet-editor-services/pull/250) ([glennsarti](https://github.com/glennsarti))
- (GH-252) Remove puppetstrings featureflag and remove support for Puppet 4 [#247](https://github.com/puppetlabs/puppet-editor-services/pull/247) ([glennsarti](https://github.com/glennsarti))

## [0.26.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.26.0) - 2020-04-29

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.25.0...0.26.0)

### Added

- (GH-245) Use object cache for fact data [#246](https://github.com/puppetlabs/puppet-editor-services/pull/246) ([glennsarti](https://github.com/glennsarti))
- GH 242 facts endpoint [#243](https://github.com/puppetlabs/puppet-editor-services/pull/243) ([jpogran](https://github.com/jpogran))
- (GH-209) Refactor the session state to be a class and pass that instead of global modules [#210](https://github.com/puppetlabs/puppet-editor-services/pull/210) ([glennsarti](https://github.com/glennsarti))

### Fixed

- (GH-238) Monkey patch Facter for minimal resets [#239](https://github.com/puppetlabs/puppet-editor-services/pull/239) ([glennsarti](https://github.com/glennsarti))

### Other

- Revert "(GH-238) Monkey patch Facter for minimal resets" [#241](https://github.com/puppetlabs/puppet-editor-services/pull/241) ([jpogran](https://github.com/jpogran))
- (maint) Update rubocop to 0.80.x [#234](https://github.com/puppetlabs/puppet-editor-services/pull/234) ([glennsarti](https://github.com/glennsarti))
- (maint) Mergeback master into 1.0 [#233](https://github.com/puppetlabs/puppet-editor-services/pull/233) ([glennsarti](https://github.com/glennsarti))
- (maint) Update Bolt static data and Protocol definitions [#232](https://github.com/puppetlabs/puppet-editor-services/pull/232) ([glennsarti](https://github.com/glennsarti))
- (maint) Update README for new repo [#231](https://github.com/puppetlabs/puppet-editor-services/pull/231) ([glennsarti](https://github.com/glennsarti))
- (maint) Mergeback master into 1.0 [#230](https://github.com/puppetlabs/puppet-editor-services/pull/230) ([glennsarti](https://github.com/glennsarti))
- (GH-168) Add acceptance tests [#229](https://github.com/puppetlabs/puppet-editor-services/pull/229) ([glennsarti](https://github.com/glennsarti))
- (maint) mergeback master into 1.0 [#228](https://github.com/puppetlabs/puppet-editor-services/pull/228) ([glennsarti](https://github.com/glennsarti))

## [0.25.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.25.0) - 2020-03-26

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.24.0...0.25.0)

### Added

- (GH-221) Puppet Node Graph Response [#226](https://github.com/puppetlabs/puppet-editor-services/pull/226) ([jpogran](https://github.com/jpogran))

### Fixed

- (GH-207) Allow Qualified Resource Names in hover provider [#225](https://github.com/puppetlabs/puppet-editor-services/pull/225) ([glennsarti](https://github.com/glennsarti))

### Other

- (maint) Update puppetfile-resolver to 0.2.0 [#220](https://github.com/puppetlabs/puppet-editor-services/pull/220) ([glennsarti](https://github.com/glennsarti))
- (maint) Allow travis to build 1.0 branch [#219](https://github.com/puppetlabs/puppet-editor-services/pull/219) ([glennsarti](https://github.com/glennsarti))
- (maint) Mergeback master into 1.0 [#218](https://github.com/puppetlabs/puppet-editor-services/pull/218) ([glennsarti](https://github.com/glennsarti))

## [0.24.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.24.0) - 2020-01-28

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.23.0...0.24.0)

### Added

- (GH-213) Gather facts using the Sidecar [#214](https://github.com/puppetlabs/puppet-editor-services/pull/214) ([glennsarti](https://github.com/glennsarti))

### Other

- (maint) Prepare for 0.24.0 release [#217](https://github.com/puppetlabs/puppet-editor-services/pull/217) ([glennsarti](https://github.com/glennsarti))
- (GH-199) Update stack trace tests for Puppet 5.5.18 [#216](https://github.com/puppetlabs/puppet-editor-services/pull/216) ([glennsarti](https://github.com/glennsarti))
- (GH-213) Use Facts from the Sidecar [#215](https://github.com/puppetlabs/puppet-editor-services/pull/215) ([glennsarti](https://github.com/glennsarti))

## [0.23.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.23.0) - 2019-12-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.22.0...0.23.0)

### Added

- (GH-94) Extract Bolt module metadata and use within Plans [#190](https://github.com/puppetlabs/puppet-editor-services/pull/190) ([glennsarti](https://github.com/glennsarti))

### Other

- (maint) Prepare for 0.23.0 release [#206](https://github.com/puppetlabs/puppet-editor-services/pull/206) ([glennsarti](https://github.com/glennsarti))
- (maint) Update for Rubocop 0.77.0 [#205](https://github.com/puppetlabs/puppet-editor-services/pull/205) ([glennsarti](https://github.com/glennsarti))
- (GH-139) Provide completions for defined types [#204](https://github.com/puppetlabs/puppet-editor-services/pull/204) ([glennsarti](https://github.com/glennsarti))
- (GH-201) Fix hashrocket alignment in multi-resource declarations [#202](https://github.com/puppetlabs/puppet-editor-services/pull/202) ([glennsarti](https://github.com/glennsarti))
- (GH-199) Monkey Patch the Null Loader [#200](https://github.com/puppetlabs/puppet-editor-services/pull/200) ([glennsarti](https://github.com/glennsarti))
- (GH-198) Use the PuppetFile Resolver for validation [#197](https://github.com/puppetlabs/puppet-editor-services/pull/197) ([glennsarti](https://github.com/glennsarti))

## [0.22.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.22.0) - 2019-09-24

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.21.0...0.22.0)

### Added

- (GH-177) Add ability to fetch the client configuration [#179](https://github.com/puppetlabs/puppet-editor-services/pull/179) ([glennsarti](https://github.com/glennsarti))

### Fixed

- (maint) Send Language Server version in version request [#178](https://github.com/puppetlabs/puppet-editor-services/pull/178) ([glennsarti](https://github.com/glennsarti))

### Other

- (GH-187) Prepare for 0.22.0 release [#188](https://github.com/puppetlabs/puppet-editor-services/pull/188) ([glennsarti](https://github.com/glennsarti))
- (GH-177) Add auto-align hash rocket feature [#186](https://github.com/puppetlabs/puppet-editor-services/pull/186) ([glennsarti](https://github.com/glennsarti))
- (GH-177) Add registrations and settings for on type formatting [#185](https://github.com/puppetlabs/puppet-editor-services/pull/185) ([glennsarti](https://github.com/glennsarti))
- (GH-177) Dynamically unregister capabilities [#184](https://github.com/puppetlabs/puppet-editor-services/pull/184) ([glennsarti](https://github.com/glennsarti))
- Added completion for resource-like class [#180](https://github.com/puppetlabs/puppet-editor-services/pull/180) ([juliosueiras](https://github.com/juliosueiras))
- (GH-174) Understand Puppet Data Types [#175](https://github.com/puppetlabs/puppet-editor-services/pull/175) ([glennsarti](https://github.com/glennsarti))

## [0.21.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.21.0) - 2019-08-26

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.20.0...0.21.0)

### Added

- (GH-106) Update puppet-lint to 2.3.6 [#154](https://github.com/puppetlabs/puppet-editor-services/pull/154) ([glennsarti](https://github.com/glennsarti))
- (GH-144)  Add signature help provider feature [#145](https://github.com/puppetlabs/puppet-editor-services/pull/145) ([glennsarti](https://github.com/glennsarti))

### Other

- (GH-170) Prepare for 0.21.0 release [#171](https://github.com/puppetlabs/puppet-editor-services/pull/171) ([glennsarti](https://github.com/glennsarti))
- (GH-167) Refactor Language Server inmemory caching [#166](https://github.com/puppetlabs/puppet-editor-services/pull/166) ([glennsarti](https://github.com/glennsarti))
- (GH-163) Use aggregate metadata actions for puppetstrings feature flag [#165](https://github.com/puppetlabs/puppet-editor-services/pull/165) ([glennsarti](https://github.com/glennsarti))
- (GH-163) Add aggregate metadata sidecar object and tasks [#162](https://github.com/puppetlabs/puppet-editor-services/pull/162) ([glennsarti](https://github.com/glennsarti))
- (maint) Add tests for roundtripping hash serialisation [#161](https://github.com/puppetlabs/puppet-editor-services/pull/161) ([glennsarti](https://github.com/glennsarti))
- (maint) Fix integration test [#160](https://github.com/puppetlabs/puppet-editor-services/pull/160) ([glennsarti](https://github.com/glennsarti))
- Revert "(maint) Pin YARD to 0.9.19" [#159](https://github.com/puppetlabs/puppet-editor-services/pull/159) ([glennsarti](https://github.com/glennsarti))
- (GH-55) Allow Debug Server to work with Puppet 6 [#158](https://github.com/puppetlabs/puppet-editor-services/pull/158) ([glennsarti](https://github.com/glennsarti))
- (GH-55) Refactor Test Debug Client and add test for Next [#157](https://github.com/puppetlabs/puppet-editor-services/pull/157) ([glennsarti](https://github.com/glennsarti))
- (maint) A bunch of maintenance fixes [#156](https://github.com/puppetlabs/puppet-editor-services/pull/156) ([glennsarti](https://github.com/glennsarti))

## [0.20.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.20.0) - 2019-07-12

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.19.1...0.20.0)

### Added

- (GH-141) Modify the Puppet Function loading to use all of the new Puppet 4 API features [#142](https://github.com/puppetlabs/puppet-editor-services/pull/142) ([glennsarti](https://github.com/glennsarti))
- (GH-137) Load Puppet Custom Types, Defined Types and Classes via Puppet API v4 [#138](https://github.com/puppetlabs/puppet-editor-services/pull/138) ([glennsarti](https://github.com/glennsarti))
- (GH-121) Load Puppet Functions via Puppet API v4 and present as Puppet API v3 functions [#126](https://github.com/puppetlabs/puppet-editor-services/pull/126) ([glennsarti](https://github.com/glennsarti))

### Fixed

- (GH-147) Gracefully fail on LoadError when compiling manifests [#151](https://github.com/puppetlabs/puppet-editor-services/pull/151) ([glennsarti](https://github.com/glennsarti))
- (maint) Pin YARD to 0.9.19 [#150](https://github.com/puppetlabs/puppet-editor-services/pull/150) ([glennsarti](https://github.com/glennsarti))
-  (GH-128) Detect Puppet Plan files correctly [#149](https://github.com/puppetlabs/puppet-editor-services/pull/149) ([glennsarti](https://github.com/glennsarti))
- (maint) Fix typo in test descriptions [#143](https://github.com/puppetlabs/puppet-editor-services/pull/143) ([glennsarti](https://github.com/glennsarti))

### Other

- (GH-152) Release 0.20.0 [#153](https://github.com/puppetlabs/puppet-editor-services/pull/153) ([jpogran](https://github.com/jpogran))
- (maint) Refactor in-memory cache objects [#140](https://github.com/puppetlabs/puppet-editor-services/pull/140) ([glennsarti](https://github.com/glennsarti))

## [0.19.1](https://github.com/puppetlabs/puppet-editor-services/tree/0.19.1) - 2019-05-30

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.19.0...0.19.1)

### Added

- (GH-118) Fail gracefully when critical gems cannot load [#134](https://github.com/puppetlabs/puppet-editor-services/pull/134) ([glennsarti](https://github.com/glennsarti))

### Fixed

- (GH-132) Suppress $stdout usage for STDIO transport [#133](https://github.com/puppetlabs/puppet-editor-services/pull/133) ([glennsarti](https://github.com/glennsarti))

### Other

- (maint) Prepare for 0.19.1 release [#136](https://github.com/puppetlabs/puppet-editor-services/pull/136) ([glennsarti](https://github.com/glennsarti))
- (maint) Update for rubocop errors [#125](https://github.com/puppetlabs/puppet-editor-services/pull/125) ([glennsarti](https://github.com/glennsarti))
- (maint) Update for rubocop errors [#124](https://github.com/puppetlabs/puppet-editor-services/pull/124) ([glennsarti](https://github.com/glennsarti))
- (maint) Update for rubocop errors [#119](https://github.com/puppetlabs/puppet-editor-services/pull/119) ([glennsarti](https://github.com/glennsarti))

## [0.19.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.19.0) - 2019-03-24

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.18.0...0.19.0)

### Added

- (GH-111) Add --puppet-version command line argument [#112](https://github.com/puppetlabs/puppet-editor-services/pull/112) ([glennsarti](https://github.com/glennsarti))
- (GH-110) Used generate ruby types from LSP Typescript node modules [#57](https://github.com/puppetlabs/puppet-editor-services/pull/57) ([glennsarti](https://github.com/glennsarti))

### Fixed

- (GH-113) Rescue errors when running Facter 2.x [#114](https://github.com/puppetlabs/puppet-editor-services/pull/114) ([glennsarti](https://github.com/glennsarti))

### Other

- (GH-115) Prepare for 0.19.0 release [#116](https://github.com/puppetlabs/puppet-editor-services/pull/116) ([glennsarti](https://github.com/glennsarti))
- (maint) Fix typo for UTF8 file output [#108](https://github.com/puppetlabs/puppet-editor-services/pull/108) ([glennsarti](https://github.com/glennsarti))

## [0.18.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.18.0) - 2019-02-05

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.17.0...0.18.0)

### Added

- (GH-24) Allow parsing in tasks mode [#93](https://github.com/puppetlabs/puppet-editor-services/pull/93) ([glennsarti](https://github.com/glennsarti))

### Other

- (GH-99) Prepre for 0.18.0 release [#100](https://github.com/puppetlabs/puppet-editor-services/pull/100) ([glennsarti](https://github.com/glennsarti))
- (maint) Fix validation of puppetfiles [#92](https://github.com/puppetlabs/puppet-editor-services/pull/92) ([glennsarti](https://github.com/glennsarti))

## [0.17.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.17.0) - 2018-12-17

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.16.0...0.17.0)

### Added

- (GH-35) Update Language Server command arguments to be like Sidecar [#87](https://github.com/puppetlabs/puppet-editor-services/pull/87) ([glennsarti](https://github.com/glennsarti))
- (GH-88) Add workspace symbols provider [#86](https://github.com/puppetlabs/puppet-editor-services/pull/86) ([glennsarti](https://github.com/glennsarti))
- (GH-20) Add support for control repos in the Sidecar [#85](https://github.com/puppetlabs/puppet-editor-services/pull/85) ([glennsarti](https://github.com/glennsarti))

### Other

- (GH-90) Prepare for 0.17.0 release [#91](https://github.com/puppetlabs/puppet-editor-services/pull/91) ([glennsarti](https://github.com/glennsarti))

## [0.16.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.16.0) - 2018-11-30

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.15.1...0.16.0)

### Added

- (GH-34) Parse class and defined type parameters  [#79](https://github.com/puppetlabs/puppet-editor-services/pull/79) ([glennsarti](https://github.com/glennsarti))
- (GH-68) Load workspace information on initial start and on document saving [#77](https://github.com/puppetlabs/puppet-editor-services/pull/77) ([glennsarti](https://github.com/glennsarti))
- (GH-75) Add Node completion snippet [#76](https://github.com/puppetlabs/puppet-editor-services/pull/76) ([glennsarti](https://github.com/glennsarti))
- (GH-69) Fix rubocop violations from version 0.60.0 [#74](https://github.com/puppetlabs/puppet-editor-services/pull/74) ([glennsarti](https://github.com/glennsarti))
- (GH-67) Make resource completion smarter [#73](https://github.com/puppetlabs/puppet-editor-services/pull/73) ([glennsarti](https://github.com/glennsarti))

### Other

- (GH-80) Update changelog for Keep a Changelog format [#84](https://github.com/puppetlabs/puppet-editor-services/pull/84) ([glennsarti](https://github.com/glennsarti))
- (MAINT) Fix release version to 0.16.0 [#83](https://github.com/puppetlabs/puppet-editor-services/pull/83) ([michaeltlombardi](https://github.com/michaeltlombardi))
- (GH-80) Release 0.16.0 [#81](https://github.com/puppetlabs/puppet-editor-services/pull/81) ([jpogran](https://github.com/jpogran))
- (maint) Remove redundant code [#78](https://github.com/puppetlabs/puppet-editor-services/pull/78) ([glennsarti](https://github.com/glennsarti))

## [0.15.1](https://github.com/puppetlabs/puppet-editor-services/tree/0.15.1) - 2018-10-31

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.15.0...0.15.1)

### Added

- (GH-55) Disable the Debug Server on Puppet 6 [#63](https://github.com/puppetlabs/puppet-editor-services/pull/63) ([glennsarti](https://github.com/glennsarti))

### Fixed

- (GH-66) Fix go to definition [#65](https://github.com/puppetlabs/puppet-editor-services/pull/65) ([jpogran](https://github.com/jpogran))
- (maint) Update CI badges [#64](https://github.com/puppetlabs/puppet-editor-services/pull/64) ([glennsarti](https://github.com/glennsarti))

### Other

- (GH-71) Release 0.15.1 [#72](https://github.com/puppetlabs/puppet-editor-services/pull/72) ([jpogran](https://github.com/jpogran))
- (GH-69) Pin rubocop to < 0.60.0 [#70](https://github.com/puppetlabs/puppet-editor-services/pull/70) ([glennsarti](https://github.com/glennsarti))

## [0.15.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.15.0) - 2018-10-17

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.14.0...0.15.0)

### Added

- (GH-56) OutLineView [#59](https://github.com/puppetlabs/puppet-editor-services/pull/59) ([jpogran](https://github.com/jpogran))
- (GH-40) Create sidecar process to enumerate puppet types, classes, functions, node graph and puppet resource [#42](https://github.com/puppetlabs/puppet-editor-services/pull/42) ([glennsarti](https://github.com/glennsarti))

### Other

- (maint) Prepare for 0.15.0 release [#62](https://github.com/puppetlabs/puppet-editor-services/pull/62) ([glennsarti](https://github.com/glennsarti))
- (maint) Fix rubocop [#58](https://github.com/puppetlabs/puppet-editor-services/pull/58) ([glennsarti](https://github.com/glennsarti))
- (GH-54) Support Puppet 6 in the Language Server [#53](https://github.com/puppetlabs/puppet-editor-services/pull/53) ([glennsarti](https://github.com/glennsarti))
- (GH-40) Use sidecar process to enumerate puppet types, classes, functions, node graph and puppet resource [#45](https://github.com/puppetlabs/puppet-editor-services/pull/45) ([glennsarti](https://github.com/glennsarti))

## [0.14.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.14.0) - 2018-08-17

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.13.0...0.14.0)

### Fixed

- (GH-49) Exit STDIO loop if STDIN reaches EOF [#50](https://github.com/puppetlabs/puppet-editor-services/pull/50) ([glennsarti](https://github.com/glennsarti))

### Other

- (MAINT) Release prep for 0.14.0 [#52](https://github.com/puppetlabs/puppet-editor-services/pull/52) ([michaeltlombardi](https://github.com/michaeltlombardi))

## [0.13.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.13.0) - 2018-07-24

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.12.0...0.13.0)

### Fixed

- (GH-46) Detect Puppet Environment correctly [#47](https://github.com/puppetlabs/puppet-editor-services/pull/47) ([glennsarti](https://github.com/glennsarti))
- (maint) Force rubocop to only use project config [#44](https://github.com/puppetlabs/puppet-editor-services/pull/44) ([glennsarti](https://github.com/glennsarti))
- (GH-31) Use canonical names for line based breakpoints [#37](https://github.com/puppetlabs/puppet-editor-services/pull/37) ([glennsarti](https://github.com/glennsarti))

### Other

- (maint) Prepare for v0.13.0 release [#48](https://github.com/puppetlabs/puppet-editor-services/pull/48) ([glennsarti](https://github.com/glennsarti))
- (maint) Update for minor rubocop fixes [#39](https://github.com/puppetlabs/puppet-editor-services/pull/39) ([glennsarti](https://github.com/glennsarti))
- (GH-36) Use automatic port assignment as default [#38](https://github.com/puppetlabs/puppet-editor-services/pull/38) ([glennsarti](https://github.com/glennsarti))

## [0.12.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.12.0) - 2018-06-01

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.11.0...0.12.0)

### Added

- (maint) Minor rubocop fixes [#30](https://github.com/puppetlabs/puppet-editor-services/pull/30) ([glennsarti](https://github.com/glennsarti))
- (GH-28) Add basic puppetfile support [#25](https://github.com/puppetlabs/puppet-editor-services/pull/25) ([glennsarti](https://github.com/glennsarti))
- (GH-22) Refactor lang server [#23](https://github.com/puppetlabs/puppet-editor-services/pull/23) ([glennsarti](https://github.com/glennsarti))

### Fixed

- (GH-10)(GH-14) Fix unix loading for language server [#15](https://github.com/puppetlabs/puppet-editor-services/pull/15) ([glennsarti](https://github.com/glennsarti))

### Other

- (maint) Prepare for 0.12.0 release [#32](https://github.com/puppetlabs/puppet-editor-services/pull/32) ([glennsarti](https://github.com/glennsarti))
- (GH-26) Refactor workspace detection for control repos and modules [#29](https://github.com/puppetlabs/puppet-editor-services/pull/29) ([glennsarti](https://github.com/glennsarti))
- (maint) Add doc on how to do a release [#13](https://github.com/puppetlabs/puppet-editor-services/pull/13) ([glennsarti](https://github.com/glennsarti))

## [0.11.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.11.0) - 2018-04-26

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.10.0...0.11.0)

### Other

- (maint) Prepare for version 0.11.0 release [#12](https://github.com/puppetlabs/puppet-editor-services/pull/12) ([glennsarti](https://github.com/glennsarti))
- (GH-11) Refactor transport layer and fix STDIO server [#9](https://github.com/puppetlabs/puppet-editor-services/pull/9) ([glennsarti](https://github.com/glennsarti))
- (doc) Update README with Editor Services [#8](https://github.com/puppetlabs/puppet-editor-services/pull/8) ([glennsarti](https://github.com/glennsarti))
- (maint) Add a packaging process [#7](https://github.com/puppetlabs/puppet-editor-services/pull/7) ([glennsarti](https://github.com/glennsarti))

## [0.10.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.10.0) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.9.0...0.10.0)

## [0.9.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.9.0) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.8.0...0.9.0)

## [0.8.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.8.0) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.7.2...0.8.0)

## [0.7.2](https://github.com/puppetlabs/puppet-editor-services/tree/0.7.2) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.7.1...0.7.2)

## [0.7.1](https://github.com/puppetlabs/puppet-editor-services/tree/0.7.1) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.7.0...0.7.1)

## [0.7.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.7.0) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.6.0...0.7.0)

## [0.6.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.6.0) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.5.0...0.6.0)

## [0.5.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.5.0) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.4.6...0.5.0)

## [0.4.6](https://github.com/puppetlabs/puppet-editor-services/tree/0.4.6) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.4.5...0.4.6)

## [0.4.5](https://github.com/puppetlabs/puppet-editor-services/tree/0.4.5) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.4.2...0.4.5)

## [0.4.2](https://github.com/puppetlabs/puppet-editor-services/tree/0.4.2) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/0.4.0...0.4.2)

## [0.4.0](https://github.com/puppetlabs/puppet-editor-services/tree/0.4.0) - 2018-04-04

[Full Changelog](https://github.com/puppetlabs/puppet-editor-services/compare/804559931cdefe5364e463ee904f68c1a8d7ed39...0.4.0)
