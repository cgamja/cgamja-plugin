#!/usr/bin/env python3
"""템플릿에만 있는 최상위 선언 슬롯을 프로젝트 선언에 `null` 로 추가한다.

값을 정하지 않는 것이 요점이다 — 값은 develop-setup 이 프로젝트를 읽고 정한다.
여기서는 **새 강제 수단이 읽을 자리**만 만든다. 기존 키는 절대 건드리지 않는다
(`protected` 목록·`lint_file.command` 는 프로젝트마다 정당하게 다르다).

  merge-slots.py <template.json> <project.json>   → 추가한 키를 공백으로 출력
"""
import collections
import json
import sys

tpl, prj = sys.argv[1], sys.argv[2]
t = json.load(open(tpl))
i = json.load(open(prj), object_pairs_hook=collections.OrderedDict)

added = [k for k in t if not k.startswith("$") and k not in i]
for k in added:
    i[k] = None
if added:
    with open(prj, "w") as f:
        f.write(json.dumps(i, ensure_ascii=False, indent=2) + "\n")
print(" ".join(added))
