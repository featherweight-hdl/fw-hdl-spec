"""Builds and runs the apb example of docs/protocol-packages/behaviour.rst.

    direnv exec . python packages/fw-hdl-spec/docs/examples/apb/check.py <outdir>

1. Back to back: build tb/apb_tb.sv in Verilator against rt-sv, run it,
   require PASS; run it with +mut (an initiator with no setup phase),
   require FAIL.
2. Static: elaborate the same top_c with fe-sv, require no errors.
3. Lower: elaborate tb/apb_emit.sv (the initiator and the target on the
   top's pins), emit it as SV, require no diagnostics, and lint the result
   with Verilator.

Needs the packages of an fw-hdl workspace (fw-hdl-fe-sv, fw-hdl-rt-sv) and
verilator on PATH. Exits non-zero on the first failure.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
SPEC = HERE.parents[2]
PKGS = SPEC.parent
BIND = SPEC / "bindings" / "sv"
RT = PKGS / "fw-hdl-rt-sv" / "sv"
VLT = ["verilator", "-Wno-fatal", "-Wno-lint", "-Wno-style", "--timescale", "1ns/1ns"]
KIT = str(HERE / "src" / "apb_pkg.sv")
TB = str(HERE / "tb" / "apb_tb.sv")


def run(cmd, log: Path):
    r = subprocess.run(cmd, capture_output=True, text=True)
    log.write_text(r.stdout + r.stderr)
    if r.returncode != 0:
        sys.exit(f"FAIL: {cmd[0]} (rc={r.returncode}), see {log}")
    return r.stdout


def main(out: Path):
    from fw.hdl.fe.sv import elaborate
    from fw.hdl.fe.sv.emit import emit_sv

    out.mkdir(parents=True, exist_ok=True)

    # 1. Back to back in rt-sv, and the mutant.
    obj = out / "obj"
    run(VLT + ["--binary", f"-I{RT}", f"-I{BIND}", "--top-module", "apb_tb",
               "-Mdir", str(obj), "-o", "Vapb_tb", str(RT / "fw_hdl_pkg.sv"),
               KIT, TB, str(HERE / "tb" / "apb_tb_top.sv")], out / "build.log")
    for arg, want in (("", "PASS"), ("+mut", "FAIL")):
        name = arg.lstrip("+") or "plain"
        text = run([str(obj / "Vapb_tb"), "+fw_edges=200"] + ([arg] if arg else []),
                   out / f"{name}.run.log")
        got = "PASS" if "PASS" in text.splitlines() else "FAIL"
        print(f"sim {name}: {got} (want {want})")
        if got != want:
            sys.exit(f"FAIL: sim {name}, see {out / (name + '.run.log')}")

    # 2. The same top through fe-sv's static elaboration.
    r = elaborate([KIT, TB], top="apb_tb_pkg::top_c")
    if not r.ok:
        sys.exit(f"FAIL: elaborate top_c: {[str(d) for d in r.diags]}")
    print("elaborate top_c: PASS")

    # 3. The transactors lowered to SV, and linted.
    r = elaborate([KIT, str(HERE / "tb" / "apb_emit.sv")], top="apb_emit_pkg::top",
                  lower=True)
    if not r.ok:
        sys.exit(f"FAIL: elaborate emit top: {[str(d) for d in r.diags]}")
    ctxt, top = r.to_ir()
    if r.ir_diags:
        sys.exit(f"FAIL: lower: {[str(d) for d in r.ir_diags]}")
    res = emit_sv(ctxt, top, out / "emit", top_module="apb_xtors")
    run(VLT + ["--lint-only", "--top-module", "apb_xtors"]
        + res.filelist.read_text().split(), out / "lint.log")
    print("emit + lint: PASS")


if __name__ == "__main__":
    main(Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "build")
