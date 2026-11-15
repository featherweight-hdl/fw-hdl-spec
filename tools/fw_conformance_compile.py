"""Compile-checks every conformance scenario against an fw_hdl_pkg.

The M1 exit criterion (core-layer1.md 9): every scenario's top.sv compiles
against the spec's fw_hdl_pkg with its generated default bodies. Each
scenario is compiled on its own (they all declare package ``scenario``) with
``verilator --lint-only``, together with the filesets given as dfm task
inputs (a JSON list of std.FileSet items: the API and the woven bodies).

Usage::

    python fw_conformance_compile.py --conformance <dir> --inputs <inputs.json>
        [--verilator verilator] [--log-dir DIR]
"""
import argparse
import concurrent.futures
import json
import os
import subprocess
import sys

# References the scenario's top class, so every class it reaches is
# specialized and checked; never runs. The handle is an fw_component: a
# module-level variable of type scenario::top trips a Verilator 5.055
# internal error (V3Param) on scenario ctor_choice.
WRAPPER = """module fw_compile_top;
    initial begin
        fw_hdl_pkg::fw_component t;
        if ($test$plusargs("fw_never")) begin
            t = scenario::top::create("top", null);
            t.build();
            t.connect();
        end
    end
endmodule
"""


def fileset_args(items):
    args, files = [], []
    for fs in items:
        if fs.get("type") != "std.FileSet":
            continue
        base = fs.get("basedir", "")
        for d in fs.get("incdirs", []):
            args.append("+incdir+" + os.path.normpath(os.path.join(base, d)))
        for d in fs.get("defines", []):
            args.append("+define+" + d)
        if fs.get("filetype") == "systemVerilogSource":
            files.extend(os.path.join(base, f) for f in fs.get("files", []))
    return args, files


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--conformance", required=True)
    ap.add_argument("--inputs", required=True, help="JSON file: the task's input filesets")
    ap.add_argument("--verilator", default="verilator")
    ap.add_argument("--log-dir", default=".")
    args = ap.parse_args(argv)
    with open(args.inputs) as fp:
        items = json.load(fp)
    fargs, files = fileset_args(items)
    names = sorted(n for n in os.listdir(args.conformance)
                   if os.path.isfile(os.path.join(args.conformance, n, "top.sv")))
    os.makedirs(args.log_dir, exist_ok=True)
    wrapper = os.path.abspath(os.path.join(args.log_dir, "fw_compile_top.sv"))
    with open(wrapper, "w") as fp:
        fp.write(WRAPPER)

    def one(n):
        cmd = [args.verilator, "--lint-only", "-Wno-fatal", "-Wno-lint", "-Wno-style"] + fargs \
            + ["-I" + os.path.join(args.conformance, n)] \
            + files + [os.path.join(args.conformance, n, "top.sv"), wrapper] \
            + ["--top-module", "fw_compile_top"]
        log = os.path.join(args.log_dir, n + ".log")
        with open(log, "w") as fp:
            r = subprocess.run(cmd, stdout=fp, stderr=subprocess.STDOUT)
        return n, r.returncode, log

    nfail = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=os.cpu_count() or 4) as ex:
        for n, rc, log in sorted(ex.map(one, names)):
            print("%-4s %s%s" % ("PASS" if rc == 0 else "FAIL", n, "" if rc == 0 else "  (" + log + ")"))
            nfail += rc != 0
    print("conformance compile: %d of %d scenarios compile" % (len(names) - nfail, len(names)))
    return 1 if nfail else 0


if __name__ == "__main__":
    sys.exit(main())
