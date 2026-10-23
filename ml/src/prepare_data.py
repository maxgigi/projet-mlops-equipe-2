"""Fige le jeu de données commun (California Housing) et vérifie son empreinte.

Usage (depuis la racine du dépôt) :
    python ml/src/prepare_data.py           # crée le CSV si absent, puis vérifie l'empreinte
    python ml/src/prepare_data.py --force   # recrée CSV et manifeste (change la référence !)
"""

import argparse
import hashlib
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

import pandas
import sklearn
from sklearn.datasets import fetch_california_housing

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
CSV_PATH = DATA_DIR / "california_housing.csv"
MANIFEST_PATH = DATA_DIR / "california_housing.manifest.json"

# Ordre des 8 variables = ordre attendu par l'API d'inférence (annexe B du sujet).
FEATURES = [
    "MedInc",
    "HouseAge",
    "AveRooms",
    "AveBedrms",
    "Population",
    "AveOccup",
    "Latitude",
    "Longitude",
]
# Cible : valeur médiane des maisons, en centaines de milliers de dollars.
TARGET = "MedHouseVal"


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def write_csv() -> int:
    """Télécharge le jeu via scikit-learn et l'écrit en CSV. Renvoie le nombre de lignes."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    df = fetch_california_housing(as_frame=True).frame[FEATURES + [TARGET]]
    df.to_csv(CSV_PATH, index=False)
    return int(df.shape[0])


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--force", action="store_true", help="recréer CSV et manifeste")
    args = parser.parse_args()

    if MANIFEST_PATH.exists() and not args.force:
        manifest = json.loads(MANIFEST_PATH.read_text())
        if not CSV_PATH.exists():
            print(f"{CSV_PATH.name} absent : régénération depuis la source officielle…")
            write_csv()
        actual = sha256(CSV_PATH)
        if actual != manifest["sha256"]:
            print(
                "ERREUR : empreinte différente du manifeste\n"
                f"  attendu {manifest['sha256']}\n  obtenu  {actual}\n"
                "  Vérifier les versions de pandas/scikit-learn (manifeste : "
                f"pandas {manifest.get('pandas_version')}, "
                f"scikit-learn {manifest.get('sklearn_version')})."
            )
            return 1
        print(f"OK : {CSV_PATH.name} conforme au manifeste (sha256 {actual[:12]}…)")
        return 0

    rows = write_csv()
    manifest = {
        "file": CSV_PATH.name,
        "sha256": sha256(CSV_PATH),
        "rows": rows,
        "features": FEATURES,
        "target": TARGET,
        "source": "sklearn.datasets.fetch_california_housing",
        "sklearn_version": sklearn.__version__,
        "pandas_version": pandas.__version__,
        "created_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    MANIFEST_PATH.write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Écrit {CSV_PATH} ({rows} lignes), sha256 {manifest['sha256'][:12]}…")
    print(f"À commiter : {MANIFEST_PATH.name} (le CSV reste hors de Git).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
