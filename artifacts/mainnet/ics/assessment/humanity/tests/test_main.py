import sys
from importlib import util
from pathlib import Path
import pytest


HERE = Path(__file__).resolve()
HUMANITY_DIR = HERE.parent.parent  # .../humanity
MODULE_PATH = HUMANITY_DIR / "main.py"


@pytest.fixture()
def mod(tmp_path):
    spec = util.spec_from_file_location("humanity_main", str(MODULE_PATH))
    mod = util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(mod)
    mod.current_dir = Path(tmp_path)
    return mod


class DummyResp:
    def __init__(self, status=200, data=None):
        self.status_code = status
        self._data = data if data is not None else {}

    def raise_for_status(self):
        if not (200 <= self.status_code < 400):
            import requests
            raise requests.HTTPError(f"HTTP {self.status_code}")

    def json(self):
        return self._data


def test_human_passport_api_picks_max(monkeypatch, mod):
    monkeypatch.setenv("HUMAN_PASSPORT_API_KEY", "key")

    def fake_get(url, headers=None):
        if url.endswith("0xabc"):
            return DummyResp(200, {"score": 2.5})
        if url.endswith("0xdef"):
            return DummyResp(200, {"score": 7.2})
        return DummyResp(200, {"score": 0})

    monkeypatch.setattr(mod.requests, "get", fake_get)
    assert mod.human_passport_score({"0xabc", "0xdef"}) == 7.2


def test_human_passport_api_min_and_cap(monkeypatch, mod):
    monkeypatch.setenv("HUMAN_PASSPORT_API_KEY", "key")

    def fake_get(url, headers=None):
        if url.endswith("0xlow"):
            return DummyResp(200, {"score": mod.scores["human-passport-min"] - 0.1})
        if url.endswith("0xhigh"):
            return DummyResp(200, {"score": mod.scores["human-passport-max"] + 5})
        return DummyResp(200, {"score": 0})

    monkeypatch.setattr(mod.requests, "get", fake_get)
    # below min -> 0
    assert mod.human_passport_score({"0xlow"}) == 0
    # above max -> cap
    assert mod.human_passport_score({"0xhigh"}) == mod.scores["human-passport-max"]


def test_human_passport_manual_input(monkeypatch, mod):
    monkeypatch.delenv("HUMAN_PASSPORT_API_KEY", raising=False)
    # valid within range
    monkeypatch.setattr("builtins.input", lambda _: "5")
    assert mod.human_passport_score({"0xabc"}) == 5.0
    # invalid -> 0
    monkeypatch.setattr("builtins.input", lambda _: "abc")
    assert mod.human_passport_score({"0xabc"}) == 0
    # below min -> 0
    monkeypatch.setattr("builtins.input", lambda _: str(mod.scores["human-passport-min"] - 0.01))
    assert mod.human_passport_score({"0xabc"}) == 0
    # above max -> cap
    monkeypatch.setattr("builtins.input", lambda _: str(mod.scores["human-passport-max"] + 10))
    assert mod.human_passport_score({"0xabc"}) == mod.scores["human-passport-max"]


def test_circles_verified_score(mod):
    (mod.current_dir / "circle_group_members.csv").write_text("0xabc\n")
    assert mod.circles_verified_score({"0xabc"}) == mod.scores["circles-verified"]
    # not present -> returns None (falsy)
    assert not mod.circles_verified_score({"0xdef"})


def test_discord_and_x_account_scores(monkeypatch, mod):
    # discord yes
    monkeypatch.setattr("builtins.input", lambda _: "yes")
    assert mod.discord_account_score() == mod.scores["discord-account"]
    # discord no
    monkeypatch.setattr("builtins.input", lambda _: "no")
    assert mod.discord_account_score() == 0
    # discord invalid then yes
    seq = iter(["maybe", "yes"])
    monkeypatch.setattr("builtins.input", lambda _: next(seq))
    assert mod.discord_account_score() == mod.scores["discord-account"]

    # x yes/no/invalid-then-yes
    monkeypatch.setattr("builtins.input", lambda _: "yes")
    assert mod.x_account_score() == mod.scores["x-account"]
    monkeypatch.setattr("builtins.input", lambda _: "no")
    assert mod.x_account_score() == 0
    seq = iter(["idk", "yes"])
    monkeypatch.setattr("builtins.input", lambda _: next(seq))
    assert mod.x_account_score() == mod.scores["x-account"]


def test_main_aggregator_threshold_and_capping(monkeypatch, mod):
    # below min -> 0
    monkeypatch.setattr(mod, "human_passport_score", lambda a: 0)
    monkeypatch.setattr(mod, "circles_verified_score", lambda a: 0)
    monkeypatch.setattr(mod, "discord_account_score", lambda: 2)
    monkeypatch.setattr(mod, "x_account_score", lambda: 1)
    sys.argv = [str(MODULE_PATH), "0xabc"]
    assert mod.main() == 0  # 3 < MIN_SCORE=4

    # cap above MAX_SCORE
    monkeypatch.setattr(mod, "human_passport_score", lambda a: 8)
    monkeypatch.setattr(mod, "circles_verified_score", lambda a: 4)
    monkeypatch.setattr(mod, "discord_account_score", lambda: 2)
    monkeypatch.setattr(mod, "x_account_score", lambda: 1)
    sys.argv = [str(MODULE_PATH), "0xabc"]
    assert mod.main() == mod.MAX_SCORE

    # normal within range
    monkeypatch.setattr(mod, "human_passport_score", lambda a: 4)
    monkeypatch.setattr(mod, "circles_verified_score", lambda a: 0)
    monkeypatch.setattr(mod, "discord_account_score", lambda: 0)
    monkeypatch.setattr(mod, "x_account_score", lambda: 0)
    sys.argv = [str(MODULE_PATH), "0xabc"]
    assert mod.main() == 4

