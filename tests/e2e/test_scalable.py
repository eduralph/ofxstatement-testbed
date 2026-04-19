"""E2E: ofxstatement-scalable samples."""
from __future__ import annotations

from pathlib import Path

import pytest
from ofxstatement.tool import run

from tests.e2e._framework import assert_ofx_equal, sample_params

_REPO = "ofxstatement-scalable"
_PLUGIN_TYPE = "scalable"


@pytest.mark.parametrize("input_path, expected_path", sample_params(_REPO))
def test_e2e(
    input_path: Path | None,
    expected_path: Path | None,
    tmp_path: Path,
) -> None:
    if input_path is None:
        pytest.skip(f"no E2E samples in {_REPO}/tests/samples/ yet")

    output_path = tmp_path / f"{input_path.stem}.ofx"
    try:
        exit_code = run(
            ["convert", "-t", _PLUGIN_TYPE, str(input_path), str(output_path)]
        )
    except SystemExit as e:
        exit_code = e.code
    assert exit_code == 0, f"ofxstatement exited with code {exit_code}"
    assert_ofx_equal(output_path.read_text(), expected_path.read_text())
