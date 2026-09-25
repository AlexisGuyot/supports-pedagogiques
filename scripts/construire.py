#!/usr/bin/env python3
"""
Construit la vue grand public (GitHub Pages) et met à jour le README
à partir de l'arborescence du dossier de dépôt.

    supports/<Composante>/<Niveau>/<Module>/<Section>/<fichiers>
                                              └─ <2021-2023>/  anciennes versions
                                              └─ <Sous-dossier>/  groupe ou .zip

Usage :
    python scripts/construire.py            # génère _site/ et met à jour README.md
    python scripts/construire.py --servir   # idem, puis http://localhost:8000
    python scripts/construire.py --verifier # n'écrit rien, signale les anomalies

Dépendance : PyYAML (pip install pyyaml).
"""
from __future__ import annotations

import argparse
import fnmatch
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata
import zipfile
from datetime import date, datetime
from pathlib import Path
from urllib.parse import quote

import yaml

RACINE_DEPOT = Path(__file__).resolve().parent.parent
SORTIE = RACINE_DEPOT / "_site"
SOURCES_SITE = RACINE_DEPOT / "site"
DEBUT_README = "<!-- CATALOGUE:DEBUT (généré automatiquement, ne pas modifier à la main) -->"
FIN_README = "<!-- CATALOGUE:FIN -->"

GENRES = {
    "PDF": ["pdf"],
    "Diaporama": ["ppt", "pptx", "odp", "key"],
    "Texte": ["doc", "docx", "odt", "rtf", "md", "txt", "html"],
    "LaTeX": ["tex", "sty", "cls", "bib"],
    "Notebook": ["ipynb"],
    "Code": ["py", "java", "c", "h", "cpp", "hpp", "js", "ts", "sql", "r", "sh",
             "ml", "hs", "rs", "go", "php", "kt", "scala", "pl", "asm", "m"],
    "Données": ["csv", "tsv", "json", "xml", "xlsx", "xls", "ods", "sqlite", "db",
                "parquet", "dump", "backup"],
    "Archive": ["zip", "tar", "gz", "tgz", "7z", "rar", "bz2", "xz"],
    "Image": ["png", "jpg", "jpeg", "gif", "svg", "webp"],
    "Vidéo": ["mp4", "webm", "mov", "mkv"],
}
GENRE_PAR_EXT = {ext: g for g, exts in GENRES.items() for ext in exts}
GENRE_PAR_NOM = {"makefile": "Code", "dockerfile": "Code", "cmakelists.txt": "Code",
                 "readme": "Texte", "license": "Texte"}

avertissements: list[str] = []


# ───────────────────────── utilitaires ─────────────────────────

def nfc(s: str) -> str:
    return unicodedata.normalize("NFC", s)


def normaliser(s: str) -> str:
    """Forme de comparaison : minuscules, sans accents ni ponctuation."""
    s = unicodedata.normalize("NFKD", s.lower())
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


def slug(s: str) -> str:
    return normaliser(s).replace(" ", "-") or "x"


def taille_lisible(n: int) -> str:
    for unite in ("o", "Ko", "Mo", "Go"):
        if n < 1024 or unite == "Go":
            return f"{n:.0f} {unite}" if unite == "o" else f"{n:.1f} {unite}".replace(".", ",")
        n /= 1024
    return ""


def url_relative(chemin: Path) -> str:
    return "/".join(quote(nfc(p)) for p in chemin.parts)


def cle_tri(nom: str, ordre: list[str]):
    try:
        return (0, ordre.index(nom), "")
    except ValueError:
        return (1, 0, normaliser(nom))


def cle_tri_naturel(nom: str):
    """TP2 avant TP10."""
    return [int(t) if t.isdigit() else t for t in re.split(r"(\d+)", normaliser(nom))]


# ───────────────────────── dates Git ─────────────────────────

def dates_git(racine: Path) -> dict[str, str]:
    """Date du dernier commit de chaque fichier, en un seul appel à git."""
    try:
        sortie = subprocess.run(
            ["git", "-c", "core.quotePath=false", "log", "--format=@@%cs",
             "--name-only", "--", str(racine.relative_to(RACINE_DEPOT))],
            cwd=RACINE_DEPOT, capture_output=True, text=True, check=True,
        ).stdout
    except (subprocess.CalledProcessError, FileNotFoundError, ValueError):
        return {}
    dates, courante = {}, None
    for ligne in sortie.splitlines():
        if ligne.startswith("@@"):
            courante = ligne[2:]
        elif ligne.strip():
            dates.setdefault(nfc(ligne.strip()), courante)
    return dates


# ───────────────────────── analyse de l'arborescence ─────────────────────────

class Analyseur:
    def __init__(self, cfg: dict):
        self.cfg = cfg
        self.racine = RACINE_DEPOT / cfg["racine"]
        self.motif_archive = re.compile(cfg["motif_archive"])
        self.mots_ens = {normaliser(m) for m in cfg["motifs_enseignant"]}
        self.dates = dates_git(self.racine)
        self.titres: dict[str, str] = {}
        self.sections = []
        for i, s in enumerate(cfg["sections"]):
            self.sections.append({**s, "rang": i,
                                  "alias_n": {normaliser(a) for a in s["alias"]}})

    # -- fichiers --
    def ignore(self, p: Path) -> bool:
        return p.name.startswith(".") or any(
            fnmatch.fnmatch(p.name, m) for m in self.cfg["ignorer"])

    def enfants(self, dossier: Path):
        items = [p for p in dossier.iterdir() if not self.ignore(p)]
        fichiers = sorted((p for p in items if p.is_file()), key=lambda p: cle_tri_naturel(p.name))
        dossiers = sorted((p for p in items if p.is_dir()), key=lambda p: cle_tri_naturel(p.name))
        return fichiers, dossiers

    def date(self, p: Path) -> str:
        rel = nfc(str(p.relative_to(RACINE_DEPOT)))
        return self.dates.get(rel) or date.fromtimestamp(p.stat().st_mtime).isoformat()

    def fiche(self, p: Path, base: Path) -> dict:
        ext = p.suffix.lower().lstrip(".")
        mots = set(normaliser(p.stem).split())
        f = {
            "nom": nfc(str(p.relative_to(base))),
            "url": url_relative(p.relative_to(RACINE_DEPOT)),
            "ext": ext,
            "genre": GENRE_PAR_NOM.get(p.name.lower()) or GENRE_PAR_EXT.get(ext, ext.upper() or "Fichier"),
            "taille": p.stat().st_size,
            "maj": self.date(p),
            "enseignant": bool(mots & self.mots_ens),
            "_chemin": p,
        }
        titre = self.titres.get(nfc(p.name))
        if titre:
            f["titre"] = titre
        return f

    def tous_fichiers(self, dossier: Path) -> list[Path]:
        res = []
        for f in sorted(dossier.rglob("*"), key=lambda p: cle_tri_naturel(str(p))):
            if f.is_file() and not any(self.ignore(Path(x)) for x in f.relative_to(dossier).parts):
                res.append(f)
        return res

    def paquet(self, d: Path) -> dict:
        """Un dossier proposé en un seul .zip."""
        contenu = self.tous_fichiers(d)
        return {"nom": nfc(d.name), "zip": True, "_chemin": d, "nb": len(contenu),
                "taille": sum(f.stat().st_size for f in contenu),
                "maj": max((self.date(f) for f in contenu), default="")}

    def groupe(self, d: Path) -> dict:
        """Sous-dossier (TP1, TP6…) : ses fichiers sont listés, ses sous-dossiers zippés.
        Au-delà du seuil de fichiers, le dossier entier devient un .zip."""
        fichiers, sous = self.enfants(d)
        if len(fichiers) > self.cfg["seuil_dossier_zip"]:
            return self.paquet(d)
        return {"nom": nfc(d.name), "zip": False,
                "fichiers": [self.fiche(f, d) for f in fichiers],
                "dossiers": [self.paquet(x) for x in sous]}

    def periode(self, nom: str) -> str | None:
        m = self.motif_archive.search(nom)
        return re.sub(r"\s*[-–_/]+\s*", "-", m.group(0)) if m else None

    def analyser_dossier(self, dossier: Path, archives: bool = True) -> dict:
        fichiers, dossiers = self.enfants(dossier)
        res = {"fichiers": [self.fiche(f, dossier) for f in fichiers], "groupes": [], "archives": []}
        for d in dossiers:
            periode = self.periode(d.name) if archives else None
            if periode:
                contenu = self.analyser_dossier(d, archives=False)
                del contenu["archives"]
                res["archives"].append({"periode": periode, "dossier": nfc(d.name), **contenu})
            else:
                res["groupes"].append(self.groupe(d))
        res["archives"].sort(key=lambda a: a["periode"], reverse=True)
        # Section sans version à jour : la période la plus récente fait office de version courante
        if res["archives"] and not res["fichiers"] and not res["groupes"]:
            res["archives"][0]["recente"] = True
        return res

    # -- sections --
    def section_type(self, nom: str):
        n = normaliser(nom)
        for s in self.sections:
            if n in s["alias_n"]:
                return s
        return None

    # -- modules --
    def analyser_module(self, dossier: Path, composante: str, niveau: str) -> dict | None:
        meta = {}
        f_meta = dossier / "_infos.yml"
        if f_meta.exists():
            meta = yaml.safe_load(f_meta.read_text(encoding="utf-8")) or {}
            if meta.get("masquer"):
                return None
        self.titres = {nfc(k): v for k, v in (meta.get("titres") or {}).items()}

        nom_dossier = nfc(dossier.name)
        affiche = self.cfg["noms"].get(nom_dossier, nom_dossier)
        # « R3.07 - Titre », « R5.Real.05 - R5.Deploi.04 - Titre »…
        un_code = r"[A-Z]{1,4}\s?\d[\w.]*"
        m = re.match(rf"^({un_code}(?:\s*[-–/,]\s*{un_code})*)\s*[-–_:]\s*(.+)$", affiche)
        code, titre = (m.group(1), m.group(2)) if m else ("", affiche)
        code = " / ".join(re.split(r"\s*[-–/,]\s*", code)) if code else ""

        fichiers_racine, sous_dossiers = self.enfants(dossier)
        sections = []
        for d in sous_dossiers:
            type_s = self.section_type(d.name)
            s = self.analyser_dossier(d)
            if type_s:
                s.update(nom=type_s["nom"], court=type_s["court"], rang=type_s["rang"])
            else:
                s.update(nom=nfc(d.name), court=nfc(d.name), rang=100)
                avertissements.append(
                    f"Section non reconnue « {d.name} » dans {dossier.relative_to(self.racine)} "
                    f"(affichée telle quelle ; ajoutez un alias dans catalogue.yml si besoin)")
            s["dossier"] = nfc(d.name)
            sections.append(s)
        if fichiers_racine:
            sections.append({"nom": "Autres documents", "court": "Autres", "rang": 200,
                             "dossier": "", "groupes": [], "archives": [],
                             "fichiers": [self.fiche(f, dossier) for f in fichiers_racine]})
        sections.sort(key=lambda s: (s["rang"], normaliser(s["nom"])))

        identifiant = "-".join(slug(x) for x in (composante, niveau, nom_dossier))
        return {
            "id": identifiant,
            "dossier": nom_dossier,
            "code": meta.get("code", code),
            "titre": meta.get("titre", titre),
            "description": (meta.get("description") or "").strip(),
            "mots_cles": meta.get("mots_cles", []),
            "_chemin": dossier,
            "sections": sections,
        }

    def analyser(self) -> list[dict]:
        if not self.racine.is_dir():
            sys.exit(f"Dossier de dépôt introuvable : {self.racine}")
        ordre = self.cfg.get("ordre", [])
        composantes = []
        _, dossiers_c = self.enfants(self.racine)
        for dc in sorted(dossiers_c, key=lambda p: cle_tri(nfc(p.name), ordre)):
            fichiers_c, dossiers_n = self.enfants(dc)
            for f in fichiers_c:
                avertissements.append(f"Fichier ignoré (hors module) : {f.relative_to(self.racine)}")
            niveaux = []
            for dn in sorted(dossiers_n, key=lambda p: cle_tri(nfc(p.name), ordre)):
                fichiers_n, dossiers_m = self.enfants(dn)
                for f in fichiers_n:
                    avertissements.append(f"Fichier ignoré (hors module) : {f.relative_to(self.racine)}")
                modules = [m for dm in dossiers_m
                           if (m := self.analyser_module(dm, nfc(dc.name), nfc(dn.name)))]
                modules.sort(key=lambda m: cle_tri_naturel(m["code"] or m["titre"]))
                if modules:
                    niveaux.append({"nom": self.cfg["noms"].get(nfc(dn.name), nfc(dn.name)),
                                    "dossier": nfc(dn.name), "modules": modules})
            if niveaux:
                composantes.append({"nom": self.cfg["noms"].get(nfc(dc.name), nfc(dc.name)),
                                    "dossier": nfc(dc.name), "id": slug(dc.name),
                                    "niveaux": niveaux})
        return composantes


# ───────────────────────── production ─────────────────────────

def fichiers_de(bloc: dict):
    yield from bloc["fichiers"]
    for g in bloc["groupes"]:
        yield from g.get("fichiers", [])


def paquets_de(bloc: dict):
    for g in bloc["groupes"]:
        if g["zip"]:
            yield g
        else:
            yield from g["dossiers"]


def blocs_courants(module: dict):
    """Ce qui constitue la version à jour d'un module."""
    for s in module["sections"]:
        yield s
        for a in s["archives"]:
            if a.get("recente"):
                yield a


def tous_les_blocs(module: dict):
    for s in module["sections"]:
        yield s
        yield from s["archives"]


def parcourir_fichiers(module: dict, archives=True):
    for b in (tous_les_blocs(module) if archives else blocs_courants(module)):
        yield from fichiers_de(b)


def fabriquer_zips(composantes: list[dict], ecrire: bool):
    """Un .zip par module (version à jour) et un par dossier à télécharger d'un bloc."""
    base = SORTIE / "telechargements"
    for c in composantes:
        for n in c["niveaux"]:
            for m in n["modules"]:
                dossier_zip = base / m["id"]
                for b in tous_les_blocs(m):
                    for p in paquets_de(b):
                        rel = p["_chemin"].relative_to(m["_chemin"])
                        cible = dossier_zip / ("-".join(slug(x) for x in rel.parts) + ".zip")
                        if ecrire:
                            zipper(p["_chemin"], cible, p["_chemin"].parent, "")
                        p["url"] = url_relative(cible.relative_to(SORTIE))
                a_zipper = [f["_chemin"] for f in parcourir_fichiers(m, archives=False)]
                a_zipper += [p["_chemin"] for b in blocs_courants(m) for p in paquets_de(b)]
                cible = dossier_zip / f"{slug(m['code'] or m['titre'])}.zip"
                if ecrire and a_zipper:
                    zipper(a_zipper, cible, m["_chemin"], nfc(m["_chemin"].name))
                m["zip"] = {"url": url_relative(cible.relative_to(SORTIE)),
                            "taille": cible.stat().st_size if ecrire and cible.exists() else 0}


def zipper(chemins, cible: Path, base: Path, prefixe: str):
    if isinstance(chemins, Path):
        chemins = [chemins]
    cible.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(cible, "w", zipfile.ZIP_DEFLATED) as z:
        for c in chemins:
            fichiers = [c] if c.is_file() else sorted(f for f in c.rglob("*") if f.is_file())
            for f in fichiers:
                if f.name.startswith(".") or f.name == "_infos.yml":
                    continue
                z.write(f, nfc(str(Path(prefixe) / f.relative_to(base))))


def contexte_depot(cfg: dict) -> tuple[str, str]:
    depot = cfg.get("depot") or os.environ.get("GITHUB_REPOSITORY", "")
    url_site = cfg.get("url_site") or ""
    if not url_site and "/" in depot:
        proprio, nom = depot.split("/", 1)
        url_site = (f"https://{proprio}.github.io/" if nom.lower() == f"{proprio.lower()}.github.io"
                    else f"https://{proprio}.github.io/{nom}/")
    return depot, url_site


def nettoyer_pour_json(composantes: list[dict], cfg: dict, depot: str) -> list[dict]:
    racine_web = f"https://github.com/{depot}/tree/{cfg['branche']}/" if depot else ""
    for c in composantes:
        for n in c["niveaux"]:
            for m in n["modules"]:
                rel = m["_chemin"].relative_to(RACINE_DEPOT)
                m["depot"] = racine_web + url_relative(rel) if racine_web else ""
                m["maj"] = max((f["maj"] for f in parcourir_fichiers(m)), default="")
                m["nb"] = sum(1 for _ in parcourir_fichiers(m, archives=False)) + sum(
                    p["nb"] for b in blocs_courants(m) for p in paquets_de(b))
                for s in m["sections"]:
                    s.pop("rang", None)
                    for a in s["archives"]:
                        a["nb"] = sum(1 for _ in fichiers_de(a)) + sum(p["nb"] for p in paquets_de(a))
    return _sans_internes(composantes)


def _sans_internes(x):
    """Retire les clés internes (préfixe _) avant sérialisation."""
    if isinstance(x, dict):
        return {k: _sans_internes(v) for k, v in x.items() if not k.startswith("_")}
    if isinstance(x, list):
        return [_sans_internes(v) for v in x]
    return x


def generer_site(composantes, cfg, depot, url_site):
    catalogue = {
        "titre": cfg["titre"], "auteur": cfg["auteur"], "affiliation": cfg["affiliation"],
        "description": cfg["description"].strip(), "contact": cfg.get("contact", ""),
        "licence": cfg["licence"], "licence_code": cfg["licence_code"],
        "depot": f"https://github.com/{depot}" if depot else "",
        "branche": cfg["branche"],
        "genere": datetime.now().strftime("%Y-%m-%d"),
        "composantes": composantes,
    }
    for f in SOURCES_SITE.rglob("*"):
        if f.is_file():
            cible = SORTIE / f.relative_to(SOURCES_SITE)
            cible.parent.mkdir(parents=True, exist_ok=True)
            if f.suffix == ".html":
                html = f.read_text(encoding="utf-8")
                for cle in ("titre", "description", "auteur"):
                    html = html.replace("{{" + cle + "}}", _echapper(cfg[cle].strip()))
                html = html.replace("{{url_site}}", url_site)
                html = html.replace("{{depot}}", f"https://github.com/{depot}" if depot else "")
                cible.write_text(html, encoding="utf-8")
            else:
                shutil.copy2(f, cible)
    # les supports eux-mêmes, pour des téléchargements directs depuis le site
    shutil.copytree(RACINE_DEPOT / cfg["racine"], SORTIE / cfg["racine"],
                    ignore=shutil.ignore_patterns(*cfg["ignorer"], ".*"), dirs_exist_ok=True)
    for licence in ("LICENSE", "LICENSE-CODE"):
        if (RACINE_DEPOT / licence).exists():
            shutil.copy2(RACINE_DEPOT / licence, SORTIE / f"{licence}.txt")
    (SORTIE / "catalogue.json").write_text(
        json.dumps(catalogue, ensure_ascii=False, indent=1), encoding="utf-8")
    (SORTIE / ".nojekyll").touch()


def _echapper(s: str) -> str:
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")


def generer_readme(composantes, cfg, url_site):
    lignes = []
    nb_modules = sum(len(n["modules"]) for c in composantes for n in c["niveaux"])
    nb_docs = sum(m["nb"] for c in composantes for n in c["niveaux"] for m in n["modules"])
    maj = max((m["maj"] for c in composantes for n in c["niveaux"] for m in n["modules"]), default="")
    if url_site:
        lignes.append(f"**[Parcourir et télécharger les supports sur le site du catalogue]({url_site})** "
                      f"(recherche, archives .zip par module, anciennes versions).\n")
    lignes.append(f"{nb_modules} modules et {nb_docs} documents à jour"
                  + (f", dernière modification le {_date_fr(maj)}." if maj else "."))
    for c in composantes:
        lignes.append(f"\n### {c['nom']}\n")
        lignes.append("| Niveau | Module | Contenu | |")
        lignes.append("|---|---|---|---|")
        for n in c["niveaux"]:
            for m in n["modules"]:
                titre = f"{m['code']} {m['titre']}".strip()
                contenu = ", ".join(s["court"] for s in m["sections"])
                rel = f"{cfg['racine']}/{c['dossier']}/{n['dossier']}/{m['dossier']}"
                lien_site = f", [fiche]({url_site}#{m['id']})" if url_site else ""
                lignes.append(f"| {n['nom']} | {titre} | {contenu} | "
                              f"[dossier]({url_relative(Path(rel))}){lien_site} |")
    bloc = "\n".join(lignes)

    readme = RACINE_DEPOT / "README.md"
    texte = readme.read_text(encoding="utf-8")
    if DEBUT_README not in texte or FIN_README not in texte:
        avertissements.append("Marqueurs CATALOGUE absents du README : tableau non mis à jour.")
        return False
    avant, reste = texte.split(DEBUT_README, 1)
    _, apres = reste.split(FIN_README, 1)
    nouveau = f"{avant}{DEBUT_README}\n{bloc}\n{FIN_README}{apres}"
    if nouveau != texte:
        readme.write_text(nouveau, encoding="utf-8")
        return True
    return False


def _date_fr(iso: str) -> str:
    mois = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août",
            "septembre", "octobre", "novembre", "décembre"]
    a, m, j = iso.split("-")
    return f"{int(j)} {mois[int(m) - 1]} {a}"


# ───────────────────────── point d'entrée ─────────────────────────

def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--verifier", action="store_true", help="n'écrit rien, liste les anomalies")
    ap.add_argument("--servir", action="store_true", help="lance un serveur local après construction")
    ap.add_argument("--sans-readme", action="store_true", help="ne touche pas au README")
    args = ap.parse_args()

    cfg = yaml.safe_load((RACINE_DEPOT / "catalogue.yml").read_text(encoding="utf-8"))
    cfg.setdefault("noms", {})
    cfg["noms"] = cfg["noms"] or {}
    depot, url_site = contexte_depot(cfg)

    composantes = Analyseur(cfg).analyser()
    ecrire = not args.verifier
    if ecrire:
        shutil.rmtree(SORTIE, ignore_errors=True)
        SORTIE.mkdir()
    fabriquer_zips(composantes, ecrire)
    composantes = nettoyer_pour_json(composantes, cfg, depot)

    if ecrire:
        generer_site(composantes, cfg, depot, url_site)
        if not args.sans_readme and generer_readme(composantes, cfg, url_site):
            print("README.md mis à jour.")

    nb = sum(len(n["modules"]) for c in composantes for n in c["niveaux"])
    print(f"{nb} modules catalogués" + (f" → {SORTIE.relative_to(RACINE_DEPOT)}/" if ecrire else ""))
    for a in avertissements:
        print(f"  ! {a}")

    if args.servir and ecrire:
        import http.server, functools
        gestion = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(SORTIE))
        print("Aperçu : http://localhost:8000  (Ctrl+C pour arrêter)")
        http.server.ThreadingHTTPServer(("", 8000), gestion).serve_forever()


if __name__ == "__main__":
    main()
