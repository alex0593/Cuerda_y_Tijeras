#!/usr/bin/env python3
"""Barrido de candidatos de economía contra la arnés de medición.

No decide el balance: prueba un puñado de combinaciones y enseña los números
de cada una, para que la elección se haga con los datos delante. Los valores
viven siempre en content/economy.json; este script solo los mueve mientras
mide y deja el último candidato en el sitio.
"""
import json, pathlib, re, subprocess, sys

def _grab(text: str, prefix: str, kind: str):
    """Saca un número de una línea del informe. Los rangos "4-22 (media 11,8)"
    se leen por la media, que es lo comparable entre candidatos."""
    for line in text.splitlines():
        if not line.strip().startswith(prefix):
            continue
        if kind == "pct":
            found = re.search(r"([\d.]+)\s*%", line)
            return float(found.group(1)) if found else None
        found = re.search(r"media\s+([\d.]+)", line)
        return float(found.group(1)) if found else None
    return None

ROOT = pathlib.Path(__file__).parent.parent
ECON = ROOT / "content" / "economy.json"
GODOT = "godot"

# Candidatos absolutos: cada uno lleva los precios enteros. Si fueran
# relativos, el segundo mediría lo que dejara el primero y todos darían igual.
CANDIDATES = [
    ("A 5/8/12", {"común": 5, "especial": 8, "rara": 12}),
    ("B 4/8/12", {"común": 4, "especial": 8, "rara": 12}),
    ("C 4/7/12", {"común": 4, "especial": 7, "rara": 12}),
    ("D 4/6/10", {"común": 4, "especial": 6, "rara": 10}),
    ("E 3/6/10", {"común": 3, "especial": 6, "rara": 10}),
]

def measure(seeds: int) -> dict:
    out = subprocess.run(
        [GODOT, "--headless", "--script", "tools/measure_run.gd", "--path", ".",
         "--", "--seeds", str(seeds)],
        capture_output=True, text=True, timeout=900)
    text = out.stdout
    def grab(prefix, cast=float):
        for line in text.splitlines():
            if line.strip().startswith(prefix):
                value = line.split(":", 1)[1].strip().rstrip("%")
                try:
                    return cast(value.split("(")[0])
                except ValueError:
                    return None
        return None
    return {
        "hilos_en_taller": grab("hilos que llevas:", "mean"),
        "abrir": grab("puede abrirlo:"),
        "comprar_1": grab("puede comprar 1 objeto:"),
        "comprar_2": grab("puede comprar 2 objetos:"),
        "objetos": grab("objetos comprables por partida:", "mean"),
        "sinergias": None,
        "cobertura_min": None,
    }

def synergy_lines(text: str) -> list:
    return [l for l in text.splitlines() if l.strip().startswith("sinergia ") and "pendiente" not in l]

def main() -> int:
    seeds = int(sys.argv[1]) if len(sys.argv) > 1 else 150
    base = json.loads(ECON.read_text())
    rows = []
    for label, prices in CANDIDATES:
        data = json.loads(json.dumps(base))
        data["prices"] = dict(prices)
        ECON.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
        out = subprocess.run(
            [GODOT, "--headless", "--script", "tools/measure_run.gd", "--path", ".",
             "--", "--seeds", str(seeds)],
            capture_output=True, text=True, timeout=900)
        text = out.stdout
        def grab(prefix, kind="pct"):
            return _grab(text, prefix, kind)
        values = [grab("sinergias por partida:", "mean")]
        syn = []
        for line in synergy_lines(text):
            # "  sinergia impulse_scissors   2% de las partidas"
            for token in line.split():
                if token.endswith("%"):
                    syn.append(float(token.rstrip("%")))
                    break
        rows.append((
            label,
            grab("hilos que llevas:", "mean"),
            grab("puede abrirlo:"),
            grab("puede comprar 1 objeto:"),
            grab("puede comprar 2 objetos:"),
            grab("objetos comprables por partida:", "mean"),
            values[0] if values else None,
            min(syn) if syn else None,
            max(syn) if syn else None,
        ))
    # Se deja el último candidato en el archivo: el barrido no decide.
    print("precios        taller abrir 1obj 2obj  objs  sinerg  peq  max")
    for row in rows:
        name, hilos, abrir, c1, c2, objs, sin, peq, mx = row
        def fmt(v, w=6, dec=0):
            if not isinstance(v, (int, float)):
                return " " * w
            return f"{v:>{w}.{dec}f}"
        print(f"{name:<14}{fmt(hilos, dec=1)}{fmt(abrir)}{fmt(c1)}{fmt(c2)}"
              f"{fmt(objs, dec=1)}{fmt(sin, dec=2)}{fmt(peq)}{fmt(mx)}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
