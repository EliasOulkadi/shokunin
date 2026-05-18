#!/usr/bin/env python3
import os
import re
import sys
from datetime import datetime

MAX_PREVIEW = 200
MAX_CMD = 100

def strip_ansi(text):
    text = re.sub(r'\x1b\[[0-9;]*[a-zA-Z]', '', text)
    text = re.sub(r'\x1b\][0-9;]*[a-zA-Z]', '', text)
    return text.replace('\r\n', '\n')

def extract_sections(lines):
    buffer = []
    sections = []
    for line in lines:
        trimmed = line.strip()
        if trimmed:
            buffer.append(trimmed)
    if buffer:
        sections.append(' '.join(buffer))
    return sections

def parse_transcript(raw_text, session_id):
    clean = strip_ansi(raw_text)
    lines = [line for line in clean.split('\n') if line.strip()]
    sections = extract_sections(lines)
    decisions = []
    commands = []
    keywords = ['decid', 'usar', 'cre', 'implement']
    cmd_pattern = re.compile(r'(npm|pip|git|docker|python|node) ')

    for s in sections:
        if len(s) <= 20:
            continue
        if any(kw in s.lower() for kw in keywords):
            decisions.append(s[:MAX_PREVIEW])
        m = cmd_pattern.search(s)
        if m:
            commands.append(s[:MAX_CMD])

    decisions = list(dict.fromkeys(decisions))[:5]
    commands = list(dict.fromkeys(commands))[:10]
    today = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    output = f"# Session: {session_id}\n- Date: {today}\n\n"
    if decisions:
        output += "## Decisions\n"
        for d in decisions:
            output += f"- {d}\n"
        output += "\n"
    if commands:
        output += "## Commands\n"
        for c in commands:
            output += f"- {c}\n"
        output += "\n"
    output += "## Conversation Log\n"
    for s in sections:
        output += f"> {s}\n"

    log_dir = os.path.join(os.path.expanduser("~"), ".shokunin", "memory", "sessions")
    os.makedirs(log_dir, exist_ok=True)
    path = os.path.join(log_dir, f"{session_id}-parsed.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write(output)
    return output

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: read-transcript.py <raw_text_file> [session_id]", file=sys.stderr)
        sys.exit(1)
    with open(sys.argv[1], encoding="utf-8", errors="replace") as f:
        raw = f.read()
    sid = sys.argv[2] if len(sys.argv) > 2 else f"manual-{datetime.now().strftime('%Y%m%d-%H%M%S')}"
    print(parse_transcript(raw, sid))
