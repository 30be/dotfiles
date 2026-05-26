from __future__ import annotations

import html
import os
import re
import subprocess
from typing import Any

from aqt import gui_hooks, mw  # mw used by _open_for_current_card
from aqt.qt import (
    QDialog,
    QDialogButtonBox,
    QLabel,
    QTextEdit,
    QVBoxLayout,
)
from aqt.utils import showWarning

TERMINAL = "kitty"
SHORTCUT = "c"
# Launch Claude in this dir so it doesn't show the workspace-trust prompt for
# $HOME. Dedicated dir, created on demand — keeps Claude away from the addon's
# own source files.
WORKING_DIR = os.path.expanduser("~/.local/share/ankiclaude-sessions")


def _strip_html(s: str) -> str:
    s = re.sub(r"<br\s*/?>", "\n", s, flags=re.IGNORECASE)
    s = re.sub(r"</p\s*>", "\n\n", s, flags=re.IGNORECASE)
    s = re.sub(r"<[^>]+>", "", s)
    s = html.unescape(s)
    return re.sub(r"\n{3,}", "\n\n", s).strip()


SYSTEM_PROMPT = (
    "That was my Anki flashcard — I had it in my deck but seem to have forgotten "
    "some of the details. Keep your explanation concise (this is mid-review, not "
    "a deep dive): a few sentences of intuition, only the key point, no walls of "
    "text. If a specific prompt is provided below, prioritise answering that "
    "instead — still concisely."
)


def _collect_card_fields(card: Any) -> dict[str, str]:
    note = card.note()
    notetype = note.note_type()
    fields: dict[str, str] = {}
    for fld in notetype["flds"]:
        name = fld["name"]
        fields[name] = _strip_html(note[name])
    return fields


def _format_context(fields: dict[str, str], user_prompt: str) -> str:
    lines: list[str] = []
    for name, value in fields.items():
        lines.append(f"### {name}")
        lines.append(value if value else "(empty)")
        lines.append("")
    lines.append("### System prompt")
    lines.append(SYSTEM_PROMPT)
    lines.append("")
    lines.append("### Prompt")
    lines.append(user_prompt if user_prompt else "<none>")
    return "\n".join(lines)


class _PromptDialog(QDialog):
    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle("Ask Claude about this card")
        self.resize(560, 240)
        layout = QVBoxLayout(self)
        layout.addWidget(
            QLabel(
                "Optional question or instruction (leave empty for a general explanation):"
            )
        )
        self.editor = QTextEdit()
        self.editor.setAcceptRichText(False)
        self.editor.setPlaceholderText(
            "e.g. Explain why the 7th in V7 is minor and not major"
        )
        layout.addWidget(self.editor)
        buttons = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel
        )
        buttons.accepted.connect(self.accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

        ok_btn = buttons.button(QDialogButtonBox.StandardButton.Ok)
        if ok_btn is not None:
            ok_btn.setDefault(True)
            ok_btn.setShortcut("Ctrl+Return")

    def prompt(self) -> str:
        return self.editor.toPlainText().strip()


def _launch_terminal(context_text: str) -> None:
    os.makedirs(WORKING_DIR, exist_ok=True)
    cmd = [
        TERMINAL,
        "--single-instance",
        "--hold",
        "--directory",
        WORKING_DIR,
        "claude",
        context_text,
    ]
    try:
        subprocess.Popen(cmd, start_new_session=True)
    except FileNotFoundError as exc:
        showWarning(
            f"Could not launch {TERMINAL!r}: {exc}. "
            f"Make sure kitty and claude are installed and on PATH."
        )


def _open_for_current_card() -> None:
    if mw.reviewer is None or mw.reviewer.card is None:
        showWarning("No card is being reviewed.")
        return
    card = mw.reviewer.card
    dlg = _PromptDialog(parent=mw)
    if dlg.exec() != QDialog.DialogCode.Accepted:
        return
    fields = _collect_card_fields(card)
    text = _format_context(fields, dlg.prompt())
    _launch_terminal(text)


def _on_state_shortcuts(state: str, shortcuts: list) -> None:
    if state == "review":
        shortcuts.append((SHORTCUT, _open_for_current_card))


gui_hooks.state_shortcuts_will_change.append(_on_state_shortcuts)
