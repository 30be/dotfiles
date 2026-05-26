"""Standalone test harness — mocks aqt so we can exercise the addon's logic."""
# pyright: reportAttributeAccessIssue=false, reportArgumentType=false
from __future__ import annotations

import sys
import types
from unittest.mock import MagicMock, patch


def install_aqt_mocks() -> dict[str, MagicMock]:
    mocks: dict[str, MagicMock] = {}

    aqt = types.ModuleType("aqt")
    aqt.mw = MagicMock(name="mw")
    aqt.gui_hooks = MagicMock(name="gui_hooks")
    aqt.gui_hooks.state_shortcuts_will_change = MagicMock()
    mocks["aqt"] = aqt

    aqt_qt = types.ModuleType("aqt.qt")
    for name in ("QDialog", "QDialogButtonBox", "QLabel", "QTextEdit", "QVBoxLayout"):
        setattr(aqt_qt, name, MagicMock(name=name))
    mocks["aqt.qt"] = aqt_qt

    aqt_utils = types.ModuleType("aqt.utils")
    aqt_utils.showWarning = MagicMock(name="showWarning")
    mocks["aqt.utils"] = aqt_utils

    sys.modules.update(mocks)
    return mocks


def make_fake_card() -> object:
    note = MagicMock()
    note.note_type.return_value = {
        "name": "Basic",
        "flds": [{"name": "Front"}, {"name": "Back"}, {"name": "Extra"}],
    }
    note.tags = ["music-theory", "chords"]
    note.__getitem__ = lambda self, key: {
        "Front": "What is the <b>V7</b> chord?",
        "Back": "<p>The V chord plus a minor 7th.</p><br>In C major: G-B-D-F.",
        "Extra": "",
    }[key]

    card = MagicMock()
    card.note.return_value = note
    card.current_deck_id.return_value = 999
    card.template.return_value = {"name": "Card 1"}
    return card


def test_strip_html(mod) -> None:
    assert mod._strip_html("<b>hi</b>") == "hi"
    assert mod._strip_html("a<br>b") == "a\nb"
    assert mod._strip_html("<p>x</p><p>y</p>") == "x\n\ny"
    assert mod._strip_html("&amp;&lt;") == "&<"
    assert mod._strip_html("  spaced  ") == "spaced"
    print("  _strip_html: ok")


def test_collect_and_format(mod) -> None:
    card = make_fake_card()
    fields = mod._collect_card_fields(card)
    assert list(fields.keys()) == ["Front", "Back", "Extra"]
    assert fields["Front"] == "What is the V7 chord?"
    assert "minor 7th" in fields["Back"]
    assert fields["Extra"] == ""
    print("  _collect_card_fields: ok")

    text = mod._format_context(fields, "Explain why the 7th is minor.")
    # No metadata block anymore
    assert "Note type" not in text
    assert "Card template" not in text
    assert "Deck:" not in text
    assert "Tags:" not in text
    assert "# Anki card context" not in text
    # Fields rendered as ### headings
    assert "### Front" in text
    assert "What is the V7 chord?" in text
    assert "### Extra" in text
    assert "(empty)" in text
    # System prompt section present
    assert "### System prompt" in text
    assert "Anki flashcard" in text
    assert "concise" in text
    # User prompt section
    assert "### Prompt" in text
    assert "Explain why the 7th is minor." in text
    # Ordering: fields → system prompt → user prompt
    sys_idx = text.index("### System prompt")
    prompt_idx = text.index("### Prompt")
    front_idx = text.index("### Front")
    assert front_idx < sys_idx < prompt_idx
    print("  _format_context with prompt: ok")

    text2 = mod._format_context(fields, "")
    assert "### Prompt" in text2
    # When no user prompt, literal "<none>" must appear under the Prompt section
    after_prompt = text2.split("### Prompt", 1)[1].strip()
    assert after_prompt == "<none>", f"expected '<none>', got {after_prompt!r}"
    print("  _format_context default prompt: ok")


def test_launch_command_shape(mod) -> None:
    with patch("subprocess.Popen") as popen:
        mod._launch_terminal("hello world")
        popen.assert_called_once()
        args, kwargs = popen.call_args
        cmd = args[0]
        assert cmd[0] == "kitty"
        assert "--single-instance" in cmd
        assert "--hold" in cmd
        assert "--directory" in cmd
        dir_idx = cmd.index("--directory")
        assert cmd[dir_idx + 1] == mod.WORKING_DIR
        assert cmd[-2] == "claude"
        assert cmd[-1] == "hello world"
        assert kwargs.get("start_new_session") is True
    print("  _launch_terminal command shape: ok")


def test_hook_registered(mod, aqt_mod) -> None:
    aqt_mod.gui_hooks.state_shortcuts_will_change.append.assert_called_once_with(
        mod._on_state_shortcuts
    )
    print("  state_shortcuts hook registered: ok")


def test_shortcut_added_in_review(mod) -> None:
    shortcuts: list = []
    mod._on_state_shortcuts("review", shortcuts)
    assert len(shortcuts) == 1
    key, callback = shortcuts[0]
    assert key == mod.SHORTCUT
    assert callback is mod._open_for_current_card
    print("  shortcut added in review state: ok")


def test_shortcut_not_added_elsewhere(mod) -> None:
    for state in ("deckBrowser", "overview", "edit", "profileManager"):
        shortcuts: list = []
        mod._on_state_shortcuts(state, shortcuts)
        assert shortcuts == [], f"unexpected shortcut added in state {state!r}"
    print("  shortcut skipped outside review state: ok")


def main() -> int:
    # Mocks must be installed BEFORE the package is imported, otherwise real
    # aqt (system-wide install) gets bound and mw is None.
    mocks = install_aqt_mocks()

    import importlib.util
    import os

    pkg_dir = os.path.dirname(os.path.abspath(__file__))
    spec = importlib.util.spec_from_file_location(
        "ankiclaude_under_test", os.path.join(pkg_dir, "__init__.py")
    )
    assert spec is not None and spec.loader is not None
    mod = importlib.util.module_from_spec(spec)
    sys.modules["ankiclaude_under_test"] = mod
    spec.loader.exec_module(mod)

    print("running tests:")
    test_strip_html(mod)
    test_collect_and_format(mod)
    test_launch_command_shape(mod)
    test_hook_registered(mod, mocks["aqt"])
    test_shortcut_added_in_review(mod)
    test_shortcut_not_added_elsewhere(mod)
    print("all good.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
