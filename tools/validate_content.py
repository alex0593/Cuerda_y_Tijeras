#!/usr/bin/env python3
"""Valida content/items.json y content/enemies.json contra reglas doc 05/07."""
import json, sys, pathlib
root = pathlib.Path(__file__).parent.parent
errors = []
try:
    items = json.loads((root/"content"/"items.json").read_text())
    enemies = json.loads((root/"content"/"enemies.json").read_text())
except Exception as e:
    print(f"FATAL: {e}"); sys.exit(2)
for iid, d in items["items"].items():
    for k in ("name", "description", "slot", "rarity", "tags", "restriction", "effect", "max_charges"):
        if k not in d: errors.append(f"item {iid} sin {k}")
    if d.get("slot") not in ("weapon","mechanism","amulet","consumable"):
        errors.append(f"item {iid} slot inválido")
    if d.get("rarity") not in ("común", "especial", "rara"):
        errors.append(f"item {iid} rareza inválida")
    if d.get("max_charges", 0) <= 0:
        errors.append(f"item {iid} max_charges inválido")
for sid, s in items["synergies"].items():
    if "name" not in s or "effect" not in s:
        errors.append(f"sinergia {sid} incompleta")
    for n in s.get("needs",[]):
        if n!="shadow" and n not in items["items"]:
            errors.append(f"sinergia {sid} pide {n} desconocido")
# max 2 relaciones por objeto (doc 05)
from collections import Counter
c = Counter()
for s in items["synergies"].values():
    for n in s["needs"]:
        if n in items["items"]: c[n]+=1
for iid, n in c.items():
    if n>2: errors.append(f"item {iid} tiene {n} relaciones (>2)")
for eid, e in enemies["enemies"].items():
    if "hp" not in e or "cost" not in e: errors.append(f"enemigo {eid} sin hp/cost")
if errors:
    print("ERRORES:"); [print(" -",x) for x in errors]; sys.exit(1)
print(f"OK: {len(items['items'])} objetos, {len(items['synergies'])} sinergias, {len(enemies['enemies'])} enemigos")
