"""Shared helpers for plugin E2E tests.

OFX is header (line-based, SGML-ish) + body (XML-ish). Byte comparison is
useless because timestamps and file UIDs differ each run; we mask those
fields before structural comparison.
"""
from __future__ import annotations

import xml.etree.ElementTree as ET
from pathlib import Path

import pytest

_TESTBED_ROOT = Path(__file__).resolve().parents[2]
_WORKSPACE_ROOT = _TESTBED_ROOT.parent

# Fields whose value changes between runs; masked before tree comparison.
_VARIABLE_FIELDS = frozenset({
    "DTSERVER", "DTSTART", "DTEND", "DTPROFUP",
    "OLDFILEUID", "NEWFILEUID", "TRNUID",
})


def discover_samples(repo_name: str) -> list[tuple[Path, Path]]:
    """Return (input_path, expected_ofx_path) pairs for a plugin repo.

    Expects samples at ``<workspace>/<repo_name>/tests/samples/`` with pairs
    named ``<stem>.<ext>`` (input) and ``<stem>.expected.ofx`` (golden).
    """
    samples_dir = _WORKSPACE_ROOT / repo_name / "tests" / "samples"
    if not samples_dir.is_dir():
        return []

    pairs: list[tuple[Path, Path]] = []
    for expected in sorted(samples_dir.glob("*.expected.ofx")):
        stem = expected.name[: -len(".expected.ofx")]
        inputs = [
            p
            for p in samples_dir.iterdir()
            if p.is_file()
            and p.name.startswith(f"{stem}.")
            and p.name != expected.name
            and not p.name.endswith(".expected.ofx")
        ]
        if len(inputs) == 1:
            pairs.append((inputs[0], expected))
    return pairs


def sample_params(repo_name: str) -> list:
    """pytest.param objects for E2E parametrization.

    Returns a single sentinel ``pytest.param(None, None, id='no-samples-yet')``
    when no samples exist, so pytest always collects at least one test
    (test body must ``pytest.skip()`` when it sees None). This keeps pytest's
    exit code at 0 instead of 5 (no-tests-collected).
    """
    pairs = discover_samples(repo_name)
    if pairs:
        return [pytest.param(inp, exp, id=inp.stem) for inp, exp in pairs]
    return [pytest.param(None, None, id="no-samples-yet")]


def _split_ofx(text: str) -> tuple[dict[str, str], ET.Element]:
    body_start = text.index("<")
    header_block = text[:body_start]
    body = text[body_start:]

    header: dict[str, str] = {}
    for line in header_block.splitlines():
        line = line.strip()
        if not line:
            continue
        key, _, value = line.partition(":")
        header[key.strip()] = value.strip()

    return header, ET.fromstring(body)


def _mask_variable_fields(root: ET.Element) -> None:
    for elem in root.iter():
        if elem.tag in _VARIABLE_FIELDS:
            elem.text = "<MASKED>"


def _diff_trees(a: ET.Element, b: ET.Element, path: str = "") -> str | None:
    here = f"{path}/{a.tag}"
    if a.tag != b.tag:
        return f"tag mismatch at {path or '/'}: {a.tag!r} vs {b.tag!r}"
    if (a.text or "").strip() != (b.text or "").strip():
        return f"text mismatch at {here}: {(a.text or '').strip()!r} vs {(b.text or '').strip()!r}"
    if a.attrib != b.attrib:
        return f"attribute mismatch at {here}: {a.attrib} vs {b.attrib}"
    ac, bc = list(a), list(b)
    if len(ac) != len(bc):
        return (
            f"child count mismatch at {here}: {len(ac)} vs {len(bc)} "
            f"(actual tags: {[c.tag for c in ac]}, expected tags: {[c.tag for c in bc]})"
        )
    for child_a, child_b in zip(ac, bc):
        diff = _diff_trees(child_a, child_b, here)
        if diff:
            return diff
    return None


def assert_ofx_equal(actual: str, expected: str) -> None:
    """Assert two OFX documents are equal after masking variable fields."""
    actual_header, actual_root = _split_ofx(actual)
    expected_header, expected_root = _split_ofx(expected)

    assert actual_header == expected_header, (
        f"OFX header mismatch:\n  actual:   {actual_header}\n  expected: {expected_header}"
    )

    _mask_variable_fields(actual_root)
    _mask_variable_fields(expected_root)

    diff = _diff_trees(actual_root, expected_root)
    assert diff is None, f"OFX body mismatch: {diff}"
