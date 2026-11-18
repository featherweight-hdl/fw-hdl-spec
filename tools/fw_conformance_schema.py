"""Validates every conformance scenario's expectations against the netlist
schema (semantics/netlist.schema.json): a full netlist whole, a
diagnostics-only expectation by its diagnostics; a process scenario's
``trace`` (TRACE_SCHEMA); and each meta.json's keys.

Usage::

    python fw_conformance_schema.py --spec <fw-hdl-spec>
"""
import argparse
import json
import os
import sys

import jsonschema

META_KEYS = {"description", "static-only", "rtl", "features", "processes"}

# A per-edge trace of a process scenario (README.md, "Process scenarios").
TRACE_SCHEMA = {
    "type": "object", "required": ["clock", "edges"], "additionalProperties": False,
    "properties": {
        "clock": {"type": "string"},
        "edges": {"type": "integer", "minimum": 1},
        "signals": {"type": "array", "items": {"type": "string"}, "minItems": 1},
        "rows": {"type": "array",
                 "items": {"type": "array", "items": {"type": "integer", "minimum": 0}}},
    },
    "dependentRequired": {"signals": ["rows"], "rows": ["signals"]},
}


def check_trace(trace, meta):
    """Errors of a scenario's trace against its meta: a process scenario
    (feature ``processes``) has a trace and a ``processes`` mode; a row per
    edge and a value per signal."""
    errs = []
    proc = "processes" in meta.get("features", [])
    if proc != (trace is not None):
        errs.append("expect.json: trace present exactly when feature processes is")
    if proc != ("processes" in meta):
        errs.append("meta.json: processes present exactly when feature processes is")
    if meta.get("processes", "lowerable") not in ("lowerable", "sim-only"):
        errs.append("meta.json: processes is lowerable or sim-only")
    if trace is None:
        return errs
    errs += ["expect.json: trace: %s at %s" % (e.message[:200], "/".join(map(str, e.absolute_path)))
             for e in jsonschema.Draft202012Validator(TRACE_SCHEMA).iter_errors(trace)]
    rows = trace.get("rows")
    if rows is not None and isinstance(trace.get("edges"), int):
        if len(rows) != trace["edges"]:
            errs.append("expect.json: trace: %d rows for %d edges" % (len(rows), trace["edges"]))
        if any(len(r) != len(trace.get("signals", [])) for r in rows):
            errs.append("expect.json: trace: a row's length is not the number of signals")
    return errs


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--spec", required=True)
    args = ap.parse_args(argv)
    with open(os.path.join(args.spec, "semantics", "netlist.schema.json")) as fp:
        schema = json.load(fp)
    full = jsonschema.Draft202012Validator(schema)
    diag = jsonschema.Draft202012Validator(
        {"$defs": schema["$defs"], "type": "object", "required": ["diagnostics"],
         "additionalProperties": False,
         "properties": {"diagnostics": schema["properties"]["diagnostics"]}})
    conf = os.path.join(args.spec, "conformance")
    nbad = n = 0
    for name in sorted(os.listdir(conf)):
        d = os.path.join(conf, name)
        if not os.path.isfile(os.path.join(d, "top.sv")):
            continue
        n += 1
        errs = []
        with open(os.path.join(d, "expect.json")) as fp:
            exp = json.load(fp)
        trace = exp.pop("trace", None)
        v = full if "objects" in exp else diag
        errs += ["expect.json: %s at %s" % (e.message[:200], "/".join(map(str, e.absolute_path)))
                 for e in v.iter_errors(exp)]
        ds = [(x["path"], x["id"]) for x in exp.get("diagnostics", [])]
        if ds != sorted(set(ds)):
            errs.append("expect.json: diagnostics not unique and sorted by path, then id")
        if "objects" in exp:
            ps = [o["path"] for o in exp["objects"]]
            if ps != sorted(set(ps)):
                errs.append("expect.json: objects not unique and sorted by path")
        mp = os.path.join(d, "meta.json")
        meta = {}
        if os.path.isfile(mp):
            with open(mp) as fp:
                meta = json.load(fp)
            errs += ["meta.json: unknown key %s" % k for k in sorted(set(meta) - META_KEYS)]
        errs += check_trace(trace, meta)
        for e in errs:
            print("FAIL %s: %s" % (name, e))
        nbad += bool(errs)
    print("conformance schema: %d of %d scenarios valid" % (n - nbad, n))
    return 1 if nbad else 0


if __name__ == "__main__":
    sys.exit(main())
