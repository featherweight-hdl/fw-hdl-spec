# fw-hdl-spec

The implementation-independent specification of fw-hdl. `bindings/sv` holds
the layer-1 SystemVerilog API, `fw_hdl_pkg`: declarations only, which each
tool compiles with its own method bodies. The design is in the root repo's
`docs/design/core-layer1.md`.

- Compile-check the API and run the smoke test: `dfm run tests`.
- Build the API reference, extracted from the doc comments in `bindings/sv`
  by sphinx-systemverilog:

      python -m sphinx -W -b html docs docs/_build/html

  The build generates the API's default method bodies with sv-weave, as the
  `sv-api-compile` task does, so the sources parse without errors.

Doc comments use sphinx-systemverilog's `native` style: the comment directly
above a declaration is reStructuredText, with `:param:` and `:returns:`
fields and `::` code samples.
