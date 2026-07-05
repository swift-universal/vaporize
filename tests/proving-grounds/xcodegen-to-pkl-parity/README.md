# XcodeGen-To-Pkl Parity Proving Grounds

Each child directory contains a legacy XcodeGen-shaped `project.yml` and a
checked-in AppleProjectSpec `project.pkl` parity specimen.

The CUJ-10 and CUJ-13 tests use these fixtures in two ways:

- compare checked-in YAML and checked-in Pkl signatures directly;
- regenerate Pkl from YAML through Vaporize and compare the generated result
  back to the source YAML.

This proves importer parity for multiple project shapes before Pkl is treated
as forward truth.
