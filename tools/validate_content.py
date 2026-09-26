#!/usr/bin/env python3
"""Valida content/items.json, content/enemies.json y content/economy.json (doc 05/07)."""
import json, sys, pathlib
root = pathlib.Path(__file__).parent.parent
errors = []
try:
    items = json.loads((root/"content"/"items.json").read_text())
    enemies = json.loads((root/"content"/"enemies.json").read_text())
    economy = json.loads((root/"content"/"economy.json").read_text())
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
# economía: precios por rareza, reparación y botín por tipo de sala (doc 07 §12/13)
for rarity in ("común", "especial", "rara"):
    if economy.get("prices", {}).get(rarity, 0) <= 0:
        errors.append(f"economy.json sin precio positivo para {rarity}")
shop = economy.get("shop", {})
if shop.get("repair_cost", 0) <= 0: errors.append("economy.json repair_cost inválido")
if shop.get("repair_amount", 0) <= 0: errors.append("economy.json repair_amount inválido")
if shop.get("entry_cost", 0) <= 0: errors.append("economy.json entry_cost inválido")
offers = shop.get("offers", 0)
if not isinstance(offers, int) or offers <= 0:
    errors.append("economy.json offers inválido")
# pool exclusiva del taller: solo se vende allí (doc 07 §13)
pool = economy.get("shop_pool")
if not isinstance(pool, list) or not pool:
    errors.append("economy.json shop_pool debe ser una lista no vacía")
elif isinstance(offers, int) and offers > 0:
    if len(pool) < offers:
        errors.append(f"economy.json shop_pool necesita al menos {offers} objetos")
    if len(set(pool)) != len(pool):
        errors.append("economy.json shop_pool repite objetos")
    for pid in pool:
        if pid not in items["items"]:
            errors.append(f"economy.json shop_pool pide {pid} desconocido")
        if pid == "scissors_basic":
            errors.append("economy.json no puede vender el arma inicial")
ROOM_KINDS = ("start", "combat", "treasure", "risk", "workshop", "boss")
loot = economy.get("loot", {})
for kind in ROOM_KINDS:
    value = loot.get(kind)
    if not isinstance(value, list) or len(value) != 2 or not all(isinstance(v, int) and v >= 0 for v in value) or value[0] > value[1]:
        errors.append(f"economy.json loot.{kind} debe ser [mín, máx] con mín <= máx")
for kind, value in loot.items():
    if kind not in ROOM_KINDS: errors.append(f"economy.json loot.{kind} tipo de sala desconocido")
if errors:
    print("ERRORES:"); [print(" -",x) for x in errors]; sys.exit(1)
print(f"OK: {len(items['items'])} objetos, {len(items['synergies'])} sinergias, {len(enemies['enemies'])} enemigos, economía válida")
