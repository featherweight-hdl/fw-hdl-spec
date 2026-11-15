# fw-hdl-spec

The implementation-independent specification of fw-hdl. `bindings/sv` holds
the layer-1 SystemVerilog API, `fw_hdl_pkg`: declarations only, which each
tool compiles with its own method bodies. The design is in the root repo's
`docs/design/core-layer1.md`.

- `semantics/`: the normative semantics (`*.md`) and the elaborated-netlist
  format (`netlist.schema.json`).
- `conformance/`: the conformance scenarios, each a `top.sv` with its
  expected netlist or diagnostics (see `conformance/README.md`).
- `tools/fw_api_check.py`: the API check a tool runs on its `fw_hdl_pkg`
  (its declarations must equal the spec's), and the spec lint (`--lint`).
  Needs pyslang.
- Compile-check the API, lint it, compile every scenario against the
  default bodies, and run the smoke test: `dfm run tests`.
- Build the API reference, extracted from the doc comments in `bindings/sv`
  by sphinx-systemverilog (toolchain: `pip install -r docs/requirements.txt`):

      python -m sphinx -W -b html docs docs/_build/html

  It is published at <https://dvkit.org/featherweight-hdl/fw-hdl-spec/> by
  `.forgejo/workflows/docs.yml` on every push to `main`.

  The build generates the API's default method bodies with sv-weave, as the
  `sv-api-compile` task does, so the sources parse without errors.

Doc comments use sphinx-systemverilog's `native` style: the comment directly
above a declaration is reStructuredText, with `:param:` and `:returns:`
fields and `::` code samples.
