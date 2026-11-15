# Sphinx configuration for the fw-hdl spec: the layer-1 SV API reference,
# extracted from the doc comments in bindings/sv by sphinx-systemverilog.
import os

from sv_weave.config import load_config
from sv_weave.filelist import SourceSpec
from sv_weave.run import run

project = "fw-hdl spec"
author = "Matthew Ballance"
copyright = "2026, Matthew Ballance"

extensions = ["sphinx_systemverilog"]

_here = os.path.dirname(os.path.abspath(__file__))
_root = os.path.dirname(_here)
_sv = os.path.join(_root, "bindings", "sv")

# The API has no method bodies, so pyslang reports every call to an extern
# method as an error. Generate the default bodies with sv-weave, as the
# sv-api-compile task does, and compile them in through fw_hdl_pkg's hook.
_bodies = os.path.join(_here, "_build", "sv-api-bodies")
_res = run(load_config(os.path.join(_root, "tools", "sv-weave.yaml")),
           spec=SourceSpec(files=[os.path.join(_sv, "fw_hdl_pkg.sv")], incdirs=[_sv]),
           out_dir=_bodies, verify="off")
_inc = _res.includes[0]

sv_build_units = [os.path.join(_sv, "fw_hdl_pkg.sv")]
sv_include_dirs = [_sv, _bodies]
sv_defines = {_inc.define: _inc.define_value}
sv_doc_style = "native"
# A macro's expansion is each tool's own, so it is not shown.
sv_macro_body = "none"

exclude_patterns = ["_build"]

html_theme = "furo"
html_title = "fw-hdl spec"
