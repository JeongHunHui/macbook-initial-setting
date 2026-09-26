#!/usr/bin/env python3
"""Merge the small managed template without changing personal settings or comments.

Requires Python 3.11+. Unsupported layouts fail before touching the destination.
"""
import copy
from datetime import datetime
import json
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile
import tomllib


def merge_text(original, template):
    before = tomllib.loads(original)
    managed = tomllib.loads(template)
    expected = copy.deepcopy(before)
    text = original

    def apply(table, values):
        nonlocal text
        current = expected
        for part in table:
            current = current.setdefault(part, {})
        for key, value in values.items():
            if isinstance(value, dict):
                apply(table + [key], value)
                continue
            if not table and key in ('model', 'model_reasoning_effort') and key in current:
                continue
            current[key] = value
            headers = list(re.finditer(r'^\s*\[([^\n]+)\][^\n]*$', text, re.M))
            if not table:
                start, end = 0, headers[0].start() if headers else len(text)
            else:
                name = '.'.join(table)
                index = next((i for i, h in enumerate(headers) if h.group(1).strip() == name), None)
                if index is None:
                    text = text.rstrip() + '\n\n[' + name + ']\n'
                    start = end = len(text)
                else:
                    start = headers[index].end()
                    end = headers[index + 1].start() if index + 1 < len(headers) else len(text)
            block = text[start:end]
            pattern = re.compile(r'^[ \t]*' + re.escape(key) + r'[ \t]*=[^\n]*', re.M)
            line = key + ' = ' + json.dumps(value, ensure_ascii=False)
            if pattern.search(block):
                block = pattern.sub(lambda _: line, block, count=1)
            else:
                block = block.rstrip() + '\n' + line + '\n'
            text = text[:start] + block + text[end:]

    apply([], managed)
    if tomllib.loads(text) != expected:
        raise ValueError('지원하지 않는 TOML 배치입니다. 기존 설정은 변경하지 않았습니다.')
    return text


def install(template, destination):
    destination = destination.resolve()
    original = destination.read_text() if destination.exists() else ''
    result = merge_text(original, template.read_text())
    if result == original:
        print('Codex 설정: 이미 적용됨')
        return
    destination.parent.mkdir(parents=True, exist_ok=True)
    if destination.exists():
        backup = destination.with_name(destination.name + '.bak-' + datetime.now().strftime('%Y%m%d%H%M%S%f'))
        shutil.copy2(destination, backup)
        print('백업:', backup)
    fd, name = tempfile.mkstemp(prefix='.mac-init-', dir=destination.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(result)
        os.replace(name, destination)
    finally:
        if os.path.exists(name):
            os.unlink(name)
    print('Codex 입력 설정 병합 완료 (모델·MCP·개인 설정 보존)')


if __name__ == '__main__':
    install(Path(sys.argv[1]), Path(sys.argv[2]))
