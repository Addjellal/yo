/* Auto Emploi — interface web locale.
   Sécurité : tout contenu venant du web ou du LLM est injecté via textContent
   (jamais innerHTML) — une offre hostile ne peut pas exécuter de script ici. */
"use strict";

const TOKEN = document.querySelector('meta[name="auth-token"]').content;

// ─── Helpers ────────────────────────────────────────────────────────────────

function $(sel) { return document.querySelector(sel); }

function el(tag, attrs = {}, children = []) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") node.className = v;
    else if (k === "text") node.textContent = v;
    else if (k === "html") throw new Error("innerHTML interdit");
    else if (k.startsWith("on")) node.addEventListener(k.slice(2), v);
    else if (k === "dataset") Object.assign(node.dataset, v);
    else node.setAttribute(k, v);
  }
  for (const child of [].concat(children)) {
    if (child == null) continue;
    node.appendChild(typeof child === "string" ? document.createTextNode(child) : child);
  }
  return node;
}

async function api(path, options = {}) {
  const resp = await fetch(path, {
    ...options,
    headers: {
      "X-Auth-Token": TOKEN,
      ...(options.body ? { "Content-Type": "application/json" } : {}),
      ...(options.headers || {}),
    },
  });
  const data = await resp.json().catch(() => ({}));
  if (!resp.ok) throw new Error(data.error || `Erreur ${resp.status}`);
  return data;
}

// Téléchargement authentifié : un <a href> nu n'envoie pas X-Auth-Token et
// recevrait un 401 — on passe par fetch puis un blob temporaire.
async function downloadFile(file) {
  const resp = await fetch(`/api/download?file=${encodeURIComponent(file)}`, {
    headers: { "X-Auth-Token": TOKEN },
  });
  if (!resp.ok) {
    const data = await resp.json().catch(() => ({}));
    throw new Error(data.error || `Erreur ${resp.status}`);
  }
  const url = URL.createObjectURL(await resp.blob());
  const a = el("a", { href: url, download: file.split("/").pop() });
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

function toast(message, kind = "") {
  const box = el("div", { class: `toast ${kind}`, text: message });
  $("#toasts").appendChild(box);
  setTimeout(() => box.remove(), 5200);
}

function scoreColor(score) {
  if (score >= 8) return "var(--green)";
  if (score >= 6) return "var(--yellow)";
  return "var(--red)";
}

// Modale de confirmation (suppression de CV) — promesse résolue true/false
function confirmDialog(title, text, okLabel = "Supprimer définitivement") {
  return new Promise((resolve) => {
    $("#confirm-title").textContent = title;
    $("#confirm-text").textContent = text;
    $("#confirm-ok").textContent = okLabel;
    $("#confirm-overlay").hidden = false;
    const done = (result) => {
      $("#confirm-overlay").hidden = true;
      $("#confirm-ok").onclick = $("#confirm-cancel").onclick = $("#confirm-close").onclick = null;
      resolve(result);
    };
    $("#confirm-ok").onclick = () => done(true);
    $("#confirm-cancel").onclick = () => done(false);
    $("#confirm-close").onclick = () => done(false);
  });
}

// ─── État global ────────────────────────────────────────────────────────────

let APP = null;            // réponse de /api/state
let SCAN_JOB = null;       // id du scan courant
let OFFERS = [];           // offres retenues du dernier scan (≥ score min)
let SET_ASIDE = [];        // offres analysées mais sous le seuil (consultables)
let POLL_TIMER = null;
// Génération de polling : tout nouveau scan/vérif l'incrémente ; un poll plus
// ancien (scan ou check) s'arrête de lui-même et n'écrase plus le journal.
let POLL_GEN = 0;
let CVS = [];              // registre des CV (cartes /api/cvs ou résumé /api/state)
const SELECTED = { sectors: new Set(), sources: new Set(), cvs: new Set(), experience: "", contracts: new Set() };
let EXP_PILLS = {};        // key → élément pill
let SEC_CHIPS = {};        // key → élément chip
let SRC_CHIPS = {};        // key → élément chip
let CV_CHIPS = {};         // filename → élément chip
let SRC_USABLE = {};       // key → bool
let CON_CHIPS = {};        // key → élément chip (types de contrat)
// Types de contrat proposés (clés alignées avec CONTRACT_TYPES côté serveur)
const CONTRACT_OPTS = [
  ["cdi", "CDI"], ["cdd", "CDD"], ["alternance", "Alternance"], ["stage", "Stage"],
  ["vie", "VIE / VIA"], ["interim", "Intérim"], ["freelance", "Freelance"],
];

function toggleContract(key, force) {
  const chip = CON_CHIPS[key];
  if (!chip) return;
  const on = force !== undefined ? force : !SELECTED.contracts.has(key);
  if (on) { SELECTED.contracts.add(key); chip.classList.add("active"); }
  else { SELECTED.contracts.delete(key); chip.classList.remove("active"); }
}

function toggleSector(key, force) {
  const chip = SEC_CHIPS[key];
  if (!chip) return;
  const on = force !== undefined ? force : !SELECTED.sectors.has(key);
  if (on) { SELECTED.sectors.add(key); chip.classList.add("active"); }
  else { SELECTED.sectors.delete(key); chip.classList.remove("active"); }
}

function toggleSource(key, force) {
  const chip = SRC_CHIPS[key];
  if (!chip || !SRC_USABLE[key]) return;
  const on = force !== undefined ? force : !SELECTED.sources.has(key);
  if (on) { SELECTED.sources.add(key); chip.classList.add("active"); }
  else { SELECTED.sources.delete(key); chip.classList.remove("active"); }
}

function toggleCv(name, force) {
  const chip = CV_CHIPS[name];
  if (!chip) return;
  const on = force !== undefined ? force : !SELECTED.cvs.has(name);
  if (on) { SELECTED.cvs.add(name); chip.classList.add("active"); }
  else { SELECTED.cvs.delete(name); chip.classList.remove("active"); }
  localStorage.setItem("cvs", JSON.stringify([...SELECTED.cvs]));
}

function applyCriteria(c) {
  /* Pré-remplit le formulaire de recherche avec des critères (défauts .env
     ou critères d'une session passée à relancer). */
  if (!c) return;
  $("#f-global").checked = !!c.global;
  $("#f-global").dispatchEvent(new Event("change"));
  if (c.query !== undefined && c.query && !c.query.startsWith("(") && !c.global) $("#f-query").value = c.query;
  if (c.country && [...$("#f-country").options].some((o) => o.value === c.country)) {
    $("#f-country").value = c.country;
    $("#region-field").style.display = c.country === "fr" ? "" : "none";
  }
  if (c.location !== undefined) {
    if (APP.regions.includes(c.location) && $("#f-country").value === "fr") {
      $("#f-region").value = c.location;
      $("#f-city").value = "";
    } else {
      $("#f-region").value = "";
      $("#f-city").value = c.location || "";
    }
  }
  if (c.experience !== undefined && EXP_PILLS[c.experience || ""]) {
    EXP_PILLS[c.experience || ""].click();
  }
  if (Array.isArray(c.sectors)) {
    for (const key of Object.keys(SEC_CHIPS)) toggleSector(key, c.sectors.includes(key));
  }
  if (Array.isArray(c.sources) && c.sources.length) {
    for (const key of Object.keys(SRC_CHIPS)) toggleSource(key, c.sources.includes(key));
  }
  if (c.min_score !== undefined && Number.isInteger(c.min_score)) {
    $("#f-minscore").value = c.min_score;
    $("#minscore-val").textContent = c.min_score;
  }
  if (Array.isArray(c.exclude)) $("#f-exclude").value = c.exclude.join(", ");
  if (c.cv) {
    // Critère CV possiblement multiple : "a.pdf,b.pdf"
    const names = String(c.cv).split(",").map((n) => n.trim()).filter(Boolean);
    const known = names.filter((n) => CV_CHIPS[n]);
    if (known.length) {
      for (const name of Object.keys(CV_CHIPS)) toggleCv(name, known.includes(name));
    }
  }
}

// ─── Onglets ────────────────────────────────────────────────────────────────

document.querySelectorAll(".nav-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    document.querySelectorAll(".nav-btn").forEach((b) => b.classList.remove("active"));
    btn.classList.add("active");
    document.querySelectorAll(".tab").forEach((t) => (t.hidden = true));
    $(`#tab-${btn.dataset.tab}`).hidden = false;
    if (btn.dataset.tab === "track") loadTrack();
    if (btn.dataset.tab === "history") loadHistory();
    if (btn.dataset.tab === "cvs") loadCvs();
    if (btn.dataset.tab === "letters") loadLetters();
    if (btn.dataset.tab === "stats") loadStats();
  });
});

function switchTab(name) {
  document.querySelector(`.nav-btn[data-tab="${name}"]`).click();
}

// ─── Thème ──────────────────────────────────────────────────────────────────

const savedTheme = localStorage.getItem("theme");
if (savedTheme) document.documentElement.dataset.theme = savedTheme;
$("#theme-toggle").addEventListener("click", () => {
  const next = document.documentElement.dataset.theme === "dark" ? "light" : "dark";
  document.documentElement.dataset.theme = next;
  localStorage.setItem("theme", next);
});

// ─── Initialisation ─────────────────────────────────────────────────────────

async function init() {
  try {
    APP = await api("/api/state");
  } catch (e) {
    toast("Impossible de joindre le serveur : " + e.message, "err");
    return;
  }

  // Statut provider
  const dot = $("#provider-dot");
  dot.classList.add(APP.provider_ready ? "ok" : "ko");
  $("#provider-label").textContent = APP.provider_ready
    ? `${APP.provider} · ${APP.model}`
    : `${APP.provider} — clé manquante`;
  if (!APP.provider_ready) toast("Provider IA non configuré : voir l'onglet Réglages.", "err");

  // CV (cases à cocher multi)
  CVS = APP.cvs || [];
  rebuildCvChips();

  // Pays / régions
  const countrySel = $("#f-country");
  for (const c of APP.countries) countrySel.appendChild(el("option", { value: c.code, text: c.name }));
  countrySel.value = "fr";
  const regionSel = $("#f-region");
  regionSel.appendChild(el("option", { value: "", text: "Toutes les régions" }));
  for (const r of APP.regions) regionSel.appendChild(el("option", { value: r, text: r }));
  countrySel.addEventListener("change", () => {
    $("#region-field").style.display = countrySel.value === "fr" ? "" : "none";
  });

  // Expérience (pills radio)
  const expBox = $("#f-experience");
  EXP_PILLS = {};
  const allPill = el("span", { class: "pill active", text: "Tous niveaux", onclick: () => pickExperience("", allPill) });
  EXP_PILLS[""] = allPill;
  expBox.appendChild(allPill);
  for (const lvl of APP.experience_levels) {
    const pill = el("span", { class: "pill", text: lvl.label });
    pill.addEventListener("click", () => pickExperience(lvl.key, pill));
    EXP_PILLS[lvl.key] = pill;
    expBox.appendChild(pill);
  }
  function pickExperience(key, pill) {
    SELECTED.experience = key;
    expBox.querySelectorAll(".pill").forEach((p) => p.classList.remove("active"));
    pill.classList.add("active");
  }

  // Secteurs (chips multi)
  const secBox = $("#f-sectors");
  SEC_CHIPS = {};
  for (const s of APP.sectors) {
    const chip = el("span", { class: "chip", text: s.label.split(" / ")[0] + " " });
    chip.title = s.label;
    chip.addEventListener("click", () => toggleSector(s.key));
    SEC_CHIPS[s.key] = chip;
    secBox.appendChild(chip);
  }

  // Types de contrat (chips multi ; aucun = tous)
  const conBox = $("#f-contracts");
  if (conBox) {
    conBox.replaceChildren();
    CON_CHIPS = {};
    for (const [key, label] of CONTRACT_OPTS) {
      const chip = el("span", { class: "chip", text: label });
      chip.addEventListener("click", () => toggleContract(key));
      CON_CHIPS[key] = chip;
      conBox.appendChild(chip);
    }
  }

  // Sources (chips multi, présélection des sources sans auth + configurées)
  const srcBox = $("#f-sources");
  SRC_CHIPS = {};
  SRC_USABLE = {};
  for (const s of APP.sources) {
    const usable = !s.auth || s.configured;
    const chip = el("span", { class: "chip" + (usable ? "" : " locked") }, [
      s.label,
      el("span", { class: "chip-badge", text: s.auth ? (s.configured ? "✓" : "🔑 réglages") : "" }),
    ]);
    if (usable && s.key !== "linkedin") { SELECTED.sources.add(s.key); chip.classList.add("active"); }
    chip.addEventListener("click", () => {
      if (!usable) { toast(`${s.label} nécessite des clés API : onglet Réglages.`, "err"); return; }
      toggleSource(s.key);
    });
    SRC_CHIPS[s.key] = chip;
    SRC_USABLE[s.key] = usable;
    srcBox.appendChild(chip);
  }

  // Derniers critères persistés (.env DEFAULT_*) : pré-remplir le formulaire
  applyCriteria(APP.defaults);

  // Score min
  $("#f-minscore").value = APP.min_score;
  $("#minscore-val").textContent = APP.min_score;
  $("#f-minscore").addEventListener("input", (e) => ($("#minscore-val").textContent = e.target.value));
  $("#f-max").value = APP.max_per_source;

  // Réglages : indicateurs "configuré" + valeurs courantes des listes
  refreshSettingsHints(APP.settings);
  $("#s-provider").value = APP.provider;
  for (const sel of document.querySelectorAll("select[data-key]")) {
    const info = APP.settings[sel.dataset.key];
    if (info && info.set && [...sel.options].some((o) => o.value === info.display)) {
      sel.value = info.display;
    }
  }

  // Historique de recherches
  renderHistory();

  // Notion
  $("#btn-notion").hidden = !APP.notion;

  // « Recharger la dernière session » : offres servies depuis l'historique
  // local, sans scraping ni appel IA
  try {
    const data = await api("/api/sessions");
    if (data.sessions && data.sessions.length) {
      const last = data.sessions[0];
      const btn = $("#btn-reload-last");
      btn.hidden = false;
      btn.textContent = `↺ Recharger « ${last.criteria.query || "dernière session"} » (sans appel API)`;
      btn.addEventListener("click", () => loadSession(last.id));
    }
  } catch (e) { /* pas bloquant */ }

  // Modèles disponibles (scan local + modèles Claude connus) pour les menus
  // déroulants des réglages — non bloquant, en arrière-plan.
  loadModelLists();
}

// Peuple les <datalist> des champs « Modèle … » : modèles locaux détectés
// (Ollama/LM Studio/llama.cpp) + modèles Claude connus. Sans appel réseau
// externe ; échec silencieux (le champ reste libre).
async function loadModelLists() {
  let data;
  try {
    data = await api("/api/models");
  } catch (e) { return; }
  const fill = (id, names) => {
    const dl = $(id);
    if (!dl) return;
    dl.replaceChildren();
    for (const name of names) dl.appendChild(el("option", { value: name }));
  };
  const local = data.local || [];
  const anthropic = data.anthropic || [];
  fill("#dl-local-models", local);
  fill("#dl-anthropic-models", anthropic);
  fill("#dl-all-models", [...local, ...anthropic]);
}

// ─── Sélection des CV (cases à cocher) ──────────────────────────────────────

function rebuildCvChips() {
  const box = $("#f-cvs");
  box.replaceChildren();
  CV_CHIPS = {};
  if (!CVS.length) {
    box.appendChild(el("span", { class: "muted small", text: "Aucun CV — importez-en un (PDF, DOCX, TXT)." }));
    SELECTED.cvs.clear();
    return;
  }
  // Sélection mémorisée (migration depuis l'ancien stockage mono-CV)
  let saved = [];
  try { saved = JSON.parse(localStorage.getItem("cvs") || "[]"); } catch { saved = []; }
  const legacy = localStorage.getItem("cv");
  if (!saved.length && legacy) saved = [legacy];
  const names = CVS.map((c) => c.filename);
  saved = saved.filter((n) => names.includes(n));

  SELECTED.cvs.clear();
  for (const cv of CVS) {
    const chip = el("span", { class: "chip cv-chip", text: cv.label || cv.filename });
    chip.title = cv.filename + (cv.analyzed ? " — profil IA extrait" : "");
    chip.addEventListener("click", () => toggleCv(cv.filename));
    CV_CHIPS[cv.filename] = chip;
    box.appendChild(chip);
  }
  const initial = saved.length ? saved : [names[0]];
  for (const n of initial) toggleCv(n, true);
}

async function refreshCvData() {
  /* Recharge le registre des CV (après upload / suppression / analyse). */
  try {
    const out = await api("/api/cvs");
    CVS = out.cvs;
    rebuildCvChips();
    if (!$("#tab-cvs").hidden) renderCvList();
  } catch (e) {
    toast(e.message, "err");
  }
}

// ─── Upload CV (boutons + glisser-déposer) ──────────────────────────────────

function readAsBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result.split(",", 2)[1] || "");
    reader.onerror = () => reject(new Error("lecture impossible"));
    reader.readAsDataURL(file);
  });
}

// Suivi discret d'une analyse IA lancée à l'import (pas de spinner bloquant)
function watchCvAnalysis(jobId, name) {
  setTimeout(async () => {
    let job;
    try {
      job = await api(`/api/job?id=${encodeURIComponent(jobId)}`);
    } catch { return; }
    if (job.status === "running") { watchCvAnalysis(jobId, name); return; }
    if (job.status === "error") {
      toast(`Analyse IA de ${name} échouée : ${job.error || "erreur"} — bouton « Ré-analyser » dans Mes CV.`, "err");
      return;
    }
    await refreshCvData();
    if (CVD && job.result.cv && CVD.entry.id === job.result.cv.id) {
      openCvDetail(CVS.find((c) => c.id === CVD.entry.id) || job.result.cv);
    }
    toast(`Profil IA extrait : ${name} (visible dans Mes CV).`, "ok");
  }, 1500);
}

async function uploadCvFiles(fileList) {
  const files = [...(fileList || [])];
  if (!files.length) return;
  const imported = [];
  for (const file of files) {
    if (!/\.(pdf|docx|txt)$/i.test(file.name)) {
      toast(`${file.name} : format non supporté (PDF, DOCX ou TXT).`, "err");
      continue;
    }
    if (file.size > 25 * 1024 * 1024) {
      toast(`${file.name} : trop volumineux (max 25 Mo).`, "err");
      continue;
    }
    try {
      const b64 = await readAsBase64(file);
      const out = await api("/api/cv", { method: "POST", body: JSON.stringify({ filename: file.name, data: b64 }) });
      imported.push(out.name);
      if (out.analyze_job_id) watchCvAnalysis(out.analyze_job_id, out.name);
    } catch (err) {
      toast(`Import de ${file.name} échoué : ${err.message}`, "err");
    }
  }
  if (!imported.length) return;
  await refreshCvData();
  for (const name of imported) toggleCv(name, true);
  toast(
    imported.length === 1
      ? `CV importé : ${imported[0]} — analyse IA en cours…`
      : `${imported.length} CV importés (${imported.join(", ")}) — analyses IA en cours…`,
    "ok",
  );
}

$("#cv-upload-btn").addEventListener("click", () => $("#cv-file").click());
$("#cvs-upload-btn").addEventListener("click", () => $("#cv-file").click());
$("#cv-file").addEventListener("change", (e) => { uploadCvFiles(e.target.files); e.target.value = ""; });

// Glisser-déposer sur la carte de recherche
const searchCard = document.querySelector(".search-card");
["dragenter", "dragover"].forEach((evt) =>
  searchCard.addEventListener(evt, (e) => {
    e.preventDefault();
    searchCard.classList.add("dropzone-active");
  })
);
["dragleave", "drop"].forEach((evt) =>
  searchCard.addEventListener(evt, (e) => {
    e.preventDefault();
    searchCard.classList.remove("dropzone-active");
  })
);
searchCard.addEventListener("drop", (e) => {
  if (e.dataTransfer && e.dataTransfer.files) uploadCvFiles(e.dataTransfer.files);
});

// ─── Historique de recherches (localStorage) ────────────────────────────────

function renderHistory() {
  const box = $("#query-history");
  box.replaceChildren();
  const history = JSON.parse(localStorage.getItem("queries") || "[]");
  for (const q of history.slice(0, 6)) {
    const chip = el("span", { class: "chip", text: q });
    chip.addEventListener("click", () => ($("#f-query").value = q));
    box.appendChild(chip);
  }
}

function pushHistory(query) {
  let history = JSON.parse(localStorage.getItem("queries") || "[]");
  history = [query, ...history.filter((q) => q !== query)].slice(0, 10);
  localStorage.setItem("queries", JSON.stringify(history));
  renderHistory();
}

// ─── Lancement du scan ──────────────────────────────────────────────────────

$("#btn-scan").addEventListener("click", startScan);
$("#f-query").addEventListener("keydown", (e) => { if (e.key === "Enter") startScan(); });
// « Masquer le journal » replie seulement le texte : le spinner et la barre
// d'avancement restent visibles pour suivre le scan d'un coup d'œil.
$("#btn-progress-hide").addEventListener("click", () => {
  const card = $("#scan-progress");
  const minimized = card.classList.toggle("minimized");
  $("#btn-progress-hide").textContent = minimized ? "Afficher le journal" : "Masquer le journal";
});
$("#btn-show-log").addEventListener("click", () => {
  const card = $("#scan-progress");
  card.hidden = false;
  card.classList.remove("minimized");  // rouvrir doit montrer le texte
  $("#btn-progress-hide").textContent = "Masquer le journal";
  $("#btn-show-log").hidden = true;
});
$("#btn-scan-stop").addEventListener("click", async () => {
  if (!SCAN_JOB) return;
  $("#btn-scan-stop").disabled = true;
  try {
    await api("/api/stop", { method: "POST", body: JSON.stringify({ job_id: SCAN_JOB }) });
    toast("Arrêt demandé — les offres déjà scorées seront affichées.", "ok");
  } catch (e) {
    toast(e.message, "err");
  }
});

async function startScan() {
  const isGlobal = $("#f-global").checked;
  const noAi = $("#f-no-ai").checked;
  const query = $("#f-query").value.trim();
  if (noAi && isGlobal) { toast("Analyse locale sans IA : saisissez une requête (la recherche globale utilise l'IA).", "err"); return; }
  if (!query && !isGlobal) { toast("Indiquez un poste à rechercher (ou cochez la recherche globale).", "err"); return; }
  if (!SELECTED.cvs.size && !noAi) { toast("Cochez au moins un CV (bouton ＋ Importer si besoin).", "err"); return; }
  if (!SELECTED.sources.size) { toast("Sélectionnez au moins une source.", "err"); return; }

  const country = $("#f-country").value;
  const city = $("#f-city").value.trim();
  const region = country === "fr" ? $("#f-region").value : "";
  const maxRaw = $("#f-max").value.trim();

  const body = {
    query: isGlobal ? "" : query,
    global: isGlobal,
    cvs: [...SELECTED.cvs],
    country,
    location: city || region,
    sources: [...SELECTED.sources],
    sectors: [...SELECTED.sectors],
    experience: SELECTED.experience,
    contracts: [...SELECTED.contracts],
    min_score: parseInt($("#f-minscore").value, 10),
    max: maxRaw === "" ? 0 : parseInt(maxRaw, 10) || 0,  // 0 = sans plafond
    exclude: $("#f-exclude").value,
    include_seen: $("#f-include-seen").checked,
    no_ai: noAi,
  };

  let out;
  try {
    out = await api("/api/scan", { method: "POST", body: JSON.stringify(body) });
  } catch (e) {
    toast(e.message, "err");
    return;
  }
  if (!isGlobal) pushHistory(query);
  SCAN_JOB = out.job_id;
  $("#btn-scan").disabled = true;
  $("#search-empty").hidden = true;
  $("#results-zone").hidden = true;
  $("#setaside-zone").hidden = true;
  $("#scan-progress").hidden = false;
  $("#btn-show-log").hidden = true;
  $("#btn-scan-stop").disabled = false;
  { const sp = $("#scan-progress .spinner"); if (sp) sp.style.display = ""; }
  $("#progress-title").textContent = noAi
    ? `Analyse locale sans IA : « ${query} »`
    : isGlobal
      ? "Recherche globale d'après vos CV…"
      : `Recherche : « ${query} »`;
  $("#progress-log").replaceChildren();
  resetProgressBar();
  pollScan(++POLL_GEN);
}

// Recherche globale : le champ « poste » devient inutile
$("#f-global").addEventListener("change", () => {
  const on = $("#f-global").checked;
  $("#f-query").disabled = on;
  $("#f-query").placeholder = on
    ? "Requêtes générées automatiquement depuis vos CV cochés"
    : "Ex : ingénieur robotique, data engineer…";
});

// ─── Re-scoring de la base (sans scraper) ───────────────────────────────────

$("#btn-rescore").addEventListener("click", async () => {
  if (!SELECTED.cvs.size) { toast("Cochez au moins un CV (bouton ＋ Importer si besoin).", "err"); return; }
  const body = {
    cvs: [...SELECTED.cvs],
    sectors: [...SELECTED.sectors],
    experience: SELECTED.experience,
    min_score: parseInt($("#f-minscore").value, 10),
    exclude: $("#f-exclude").value,
    include_seen: $("#f-include-seen").checked,
  };
  let out;
  try {
    out = await api("/api/rescore", { method: "POST", body: JSON.stringify(body) });
  } catch (e) {
    toast(e.message, "err");
    return;
  }
  SCAN_JOB = out.job_id;
  $("#btn-scan").disabled = true;
  $("#search-empty").hidden = true;
  $("#results-zone").hidden = true;
  $("#setaside-zone").hidden = true;
  $("#scan-progress").hidden = false;
  $("#btn-show-log").hidden = true;
  $("#btn-scan-stop").disabled = false;
  { const sp = $("#scan-progress .spinner"); if (sp) sp.style.display = ""; }
  $("#progress-title").textContent = "Re-scoring de la base d'offres connues…";
  $("#progress-log").replaceChildren();
  resetProgressBar();
  pollScan(++POLL_GEN);
});

function pollScan(gen = POLL_GEN) {
  clearTimeout(POLL_TIMER);
  POLL_TIMER = setTimeout(async () => {
    if (gen !== POLL_GEN) return;  // un scan/vérif plus récent a pris la main
    let job;
    try {
      job = await api(`/api/job?id=${encodeURIComponent(SCAN_JOB)}`);
    } catch (e) {
      $("#btn-scan").disabled = false;
      toast("Suivi du scan perdu : " + e.message, "err");
      return;
    }
    if (gen !== POLL_GEN) return;
    renderLog(job.log);
    if (job.status === "running") { pollScan(gen); return; }
    // Terminé : on arrête le spinner et on fige le titre (sinon l'UI semble
    // « tourner encore » alors que le scan est fini, surtout si 0 offre).
    $("#btn-scan").disabled = false;
    $("#btn-scan-stop").disabled = true;
    const spinner = $("#scan-progress .spinner");
    if (spinner) spinner.style.display = "none";
    if (job.status === "error") {
      $("#progress-title").textContent = "Recherche échouée";
      toast("Scan échoué : " + (job.error || "erreur inconnue"), "err");
      return;
    }
    $("#progress-title").textContent = "Recherche terminée";
    setProgressBar(100);
    OFFERS = job.offers || [];
    SET_ASIDE = job.set_aside || [];
    // Offres trouvées (retenues OU mises de côté) → le journal s'efface mais
    // reste récupérable via « Revoir le journal ». Sinon il reste visible.
    const logHidden = OFFERS.length > 0 || SET_ASIDE.length > 0;
    $("#scan-progress").hidden = logHidden;
    $("#btn-show-log").hidden = !logHidden;
    renderResults();
    renderSetAside();
  }, 850);
}

function renderLog(lines) {
  const box = $("#progress-log");
  while (box.children.length < lines.length) {
    box.appendChild(el("div", { text: lines[box.children.length] }));
  }
  box.scrollTop = box.scrollHeight;
  updateProgressBar(lines);
}

// Déduit un pourcentage d'avancement des lignes du journal. Deux phases IA
// (pré-scoring puis analyse détaillée) progressent chacune sur sa plage pour
// que la barre n'aille jamais à reculons. Retourne null tant qu'on en est à la
// collecte (avancement indéterminé → barre masquée, le spinner suffit).
function computeProgressPercent(lines) {
  let pct = null, phase = 0;  // 0 collecte · 1 pré-scoring · 2 analyse
  for (const line of lines || []) {
    let m;
    if ((m = line.match(/(\d+)\s*\/\s*(\d+)\s*offre\(s\)\s*analys/i))) {
      const t = +m[2]; if (t > 0) { pct = 45 + 50 * (+m[1] / t); phase = 2; }
    } else if (/analyse détaillée/i.test(line)) {
      if (phase < 2) { pct = 45; phase = 2; }
    } else if ((m = line.match(/pré-scoring\s*:\s*lot\s*(\d+)\s*\/\s*(\d+)/i))) {
      if (phase < 2) { const t = +m[2]; if (t > 0) { pct = 5 + 40 * (+m[1] / t); phase = 1; } }
    } else if (/pré-scoring ia de/i.test(line)) {
      if (phase < 1) { pct = 5; phase = 1; }
    }
  }
  return pct;
}

function setProgressBar(pct) {
  const bar = $("#progress-bar"), fill = $("#progress-bar-fill"), label = $("#progress-percent");
  if (pct == null) { bar.hidden = true; label.hidden = true; return; }
  const v = Math.max(0, Math.min(100, Math.round(pct)));
  bar.hidden = false;
  fill.style.width = v + "%";
  label.hidden = false;
  label.textContent = v + "/100";
}

function updateProgressBar(lines) {
  setProgressBar(computeProgressPercent(lines));
}

function resetProgressBar() {
  $("#scan-progress").classList.remove("minimized");
  $("#btn-progress-hide").textContent = "Masquer le journal";
  setProgressBar(null);
}

// ─── Rendu des résultats ────────────────────────────────────────────────────

$("#sort-select").addEventListener("change", renderResults);
$("#date-filter").addEventListener("change", applyDateFilter);
$("#btn-export").addEventListener("click", exportResults);
$("#btn-notion").addEventListener("click", exportNotion);

// ─── Modal export format ─────────────────────────────────────────────────────

let _exportResolve = null;

function showExportPicker() {
  return new Promise(res => { _exportResolve = res; $("#export-overlay").hidden = false; });
}

function _closeExportPicker(fmt = null) {
  $("#export-overlay").hidden = true;
  if (_exportResolve) { _exportResolve(fmt); _exportResolve = null; }
}

$("#export-close").addEventListener("click", () => _closeExportPicker(null));
$("#export-csv").addEventListener("click",  () => _closeExportPicker("csv"));
$("#export-json").addEventListener("click", () => _closeExportPicker("json"));
$("#export-both").addEventListener("click", () => _closeExportPicker("both"));

// ─── Filtre date de publication ──────────────────────────────────────────────

function dateFilterCutoff() {
  const val = $("#date-filter").value;
  if (!val || val === "all") return null;
  const d = new Date();
  if (val === "1d")  d.setDate(d.getDate() - 1);
  else if (val === "3d")  d.setDate(d.getDate() - 3);
  else if (val === "7d")  d.setDate(d.getDate() - 7);
  else if (val === "14d") d.setDate(d.getDate() - 14);
  else if (val === "1m")  d.setMonth(d.getMonth() - 1);
  else if (val === "3m")  d.setMonth(d.getMonth() - 3);
  else if (val === "1y")  d.setFullYear(d.getFullYear() - 1);
  return d.toISOString().slice(0, 10);
}

function applyDateFilter() {
  const cutoff = dateFilterCutoff();
  const cards = Array.from(document.querySelectorAll("#results-grid .offer-card"));
  let count = 0;
  for (const card of cards) {
    const dp = card.dataset.datePosted;
    // Offres sans date connue : toujours affichées (on ne pénalise pas les
    // sources qui ne fournissent pas de date).
    const hide = !!(cutoff && dp && dp < cutoff);
    card.hidden = hide;
    if (!hide) count++;
  }
  const countEl = $("#results-count");
  if (countEl) countEl.textContent = `${count} offre${count !== 1 ? "s" : ""}`;
}

// Dernière offre dont on a cliqué « Ouvrir » : marquée jusqu'au choix d'un statut
let LAST_OPENED_CARD = null;

// Rendu générique d'une liste d'offres dans un conteneur, avec un contexte
// (job + liste + compteur). Partagé par les résultats de recherche ET la
// consultation d'une session d'historique.
function renderOfferCards(offers, ctx, mode = "score") {
  ctx.grid.replaceChildren();
  LAST_OPENED_CARD = null;
  const sorted = [...offers].sort((a, b) => {
    if (mode === "source") return a.source.localeCompare(b.source) || (b.score || 0) - (a.score || 0);
    if (mode === "company") return a.company.localeCompare(b.company);
    // Tri par meilleur CV correspondant : regroupe les offres par CV gagnant,
    // puis par score décroissant à l'intérieur de chaque groupe.
    if (mode === "cv") {
      return (a.best_cv || "").localeCompare(b.best_cv || "") || (b.score || 0) - (a.score || 0);
    }
    return (b.score || 0) - (a.score || 0);
  });
  sorted.forEach((offer, i) => {
    const card = offerCard(offer, ctx);
    card.style.setProperty("--i", Math.min(i, 12));
    ctx.grid.appendChild(card);
  });
  if (ctx.countEl) ctx.countEl.textContent = `${offers.length} offre${offers.length > 1 ? "s" : ""}`;
}

function renderResults() {
  const zone = $("#results-zone");
  if (!OFFERS.length) {
    zone.hidden = true;
    $("#results-grid").replaceChildren();
    // Rien au-dessus du seuil : on n'affiche le grand état vide que s'il n'y a
    // pas non plus d'offres mises de côté (sinon leur section porte le contenu).
    $("#search-empty").hidden = SET_ASIDE.length > 0;
    $("#search-empty").querySelector("p").textContent =
      "Aucune offre au-dessus du score minimum. Essayez d'autres mots-clés ou baissez le score.";
    return;
  }
  zone.hidden = false;
  $("#search-empty").hidden = true;
  renderOfferCards(OFFERS, {
    jobId: SCAN_JOB, offers: OFFERS, grid: $("#results-grid"),
    countEl: $("#results-count"), onEmpty: renderResults,
  }, $("#sort-select").value);
  applyDateFilter();
}

// Offres mises de côté (analysées mais sous le score minimum). Repliées par
// défaut : déjà évaluées, mais secondaires. Les cartes ne sont peintes qu'à
// l'ouverture. Elles partagent les indices du scan (job.offers), donc favori /
// lettre / rejet fonctionnent comme sur un résultat normal.
function renderSetAside() {
  const zone = $("#setaside-zone");
  const grid = $("#setaside-grid");
  const toggle = $("#btn-setaside-toggle");
  grid.replaceChildren();
  grid.hidden = true;
  toggle.textContent = "Afficher ▾";
  if (!SET_ASIDE.length) { zone.hidden = true; return; }
  zone.hidden = false;
  const n = SET_ASIDE.length;
  $("#setaside-count").textContent = `${n} offre${n > 1 ? "s" : ""} mise${n > 1 ? "s" : ""} de côté`;
}

$("#btn-setaside-toggle").addEventListener("click", () => {
  const grid = $("#setaside-grid");
  const show = grid.hidden;
  if (show && !grid.children.length) {
    renderOfferCards(SET_ASIDE, {
      jobId: SCAN_JOB, offers: SET_ASIDE, grid,
      countEl: null, onEmpty: renderSetAside,
    }, "score");
  }
  grid.hidden = !show;
  $("#btn-setaside-toggle").textContent = show ? "Masquer ▴" : "Afficher ▾";
});

function offerCard(offer, ctx) {
  // ctx = { jobId, offers, grid, countEl, onEmpty } — découple la carte du scan
  // courant : une session d'historique s'affiche avec son propre job.
  // score null = offre brute non analysée (sans IA, scraping seul)
  const rawMode = offer.score === null || offer.score === undefined;
  const score = offer.score || 0;
  const ring = el("div", { class: "score-ring", text: rawMode ? "—" : String(score) });
  ring.style.setProperty("--pct", rawMode ? 0 : score * 10);
  ring.style.setProperty("--ring", scoreColor(score));
  if (rawMode) ring.title = "Non analysée (scraping sans scoring)";

  const scoreBar = el("div", { class: "score-bar" }, [el("i")]);
  scoreBar.style.setProperty("--pct", rawMode ? 0 : score * 10);
  scoreBar.style.setProperty("--ring", scoreColor(score));

  const badges = el("div", { class: "offer-badges" }, [
    offer.best_cv ? el("span", { class: "badge cv", text: "🗎 " + offer.best_cv }) : null,
    offer.location ? el("span", { class: "badge", text: "📍 " + offer.location }) : null,
    offer.contract ? el("span", { class: "badge", text: offer.contract }) : null,
    offer.salary ? el("span", { class: "badge", text: "💰 " + offer.salary }) : null,
    el("span", { class: "badge src", text: offer.source }),
  ]);
  const statusBadge = el("span", { class: "badge status-badge", text: "" });
  badges.appendChild(statusBadge);

  // Détails repliables : atouts, lacunes, détail par CV, description
  let breakdown = null;
  if (Array.isArray(offer.cv_scores) && offer.cv_scores.length > 1) {
    breakdown = el("div", { class: "cv-breakdown" });
    for (const r of offer.cv_scores) {
      const row = el("div", { class: "cv-breakdown-row" }, [
        el("span", { class: "cb-score", text: `${r.score}/10` }),
        el("span", { class: "cb-label", text: r.cv }),
        r.cv === offer.best_cv ? el("span", { class: "cb-best", text: "◀ meilleur" }) : null,
        r.reasons ? el("span", { class: "cb-reasons", text: r.reasons }) : null,
      ]);
      row.querySelector(".cb-score").style.color = scoreColor(r.score);
      breakdown.appendChild(row);
    }
  }
  const details = el("div", { class: "offer-details" }, [
    offer.strengths ? el("div", { class: "strengths", text: "✔ Vos atouts : " + offer.strengths }) : null,
    offer.gaps ? el("div", { class: "gaps", text: "△ À combler : " + offer.gaps }) : null,
    breakdown,
    offer.description ? el("div", { class: "desc", text: offer.description }) : null,
  ]);
  details.hidden = true;
  const toggle = el("button", { class: "details-toggle", text: "Voir le détail ▾" });
  toggle.addEventListener("click", () => {
    details.hidden = !details.hidden;
    toggle.textContent = details.hidden ? "Voir le détail ▾" : "Réduire ▴";
  });

  // Actions
  const openLink = el("a", { class: "btn-ghost", text: "Ouvrir ↗", target: "_blank", rel: "noopener noreferrer" });
  if (offer.url && /^https?:\/\//i.test(offer.url)) openLink.href = offer.url;
  else openLink.style.display = "none";

  const btnFav = el("button", { class: "btn-ghost act-fav", text: "★", title: "Favori" });
  const btnApplied = el("button", { class: "btn-ghost act-applied", text: "✓", title: "Marquer postulée" });
  const btnReject = el("button", { class: "btn-ghost act-reject", text: "✗", title: "Rejeter (n'apparaîtra plus)" });
  const btnLetter = el("button", { class: "btn-ghost act-letter", text: "✉ Lettre" });

  const card = el("div", { class: "card offer-card" }, [
    el("div", { class: "offer-head" }, [
      ring,
      el("div", {}, [
        el("p", { class: "offer-title", text: offer.title }),
        el("div", { class: "offer-company", text: offer.company }),
      ]),
    ]),
    scoreBar,
    badges,
    offer.reasons ? el("p", { class: "offer-reasons", text: offer.reasons }) : null,
    toggle,
    details,
    el("div", { class: "offer-actions" }, [openLink, btnFav, btnApplied, btnReject, btnLetter]),
  ]);
  card.dataset.index = offer.index;       // pour le marquage de disponibilité (#check)
  card.dataset.datePosted = offer.date_posted || "";

  function applyStatus(status) {
    offer.status = status;
    btnFav.classList.toggle("on", status === "favorite");
    btnApplied.classList.toggle("on", status === "applied");
    card.classList.toggle("is-rejected", status === "rejected");
    const labels = { favorite: "★ favori", applied: "✓ postulée", rejected: "✗ rejetée" };
    statusBadge.textContent = labels[status] || "";
    statusBadge.className = "badge status-badge" + (labels[status] ? ` status-${status}` : "");
    statusBadge.style.display = labels[status] ? "" : "none";
  }
  applyStatus(offer.status);

  const TERMINAL = ["favorite", "applied", "rejected"];
  function removeFromResults() {
    const idx = ctx.offers.indexOf(offer);
    if (idx !== -1) ctx.offers.splice(idx, 1);
    if (LAST_OPENED_CARD === card) LAST_OPENED_CARD = null;
    card.remove();
    if (!ctx.offers.length) ctx.onEmpty();  // bascule sur l'état vide
    else if (ctx.countEl) ctx.countEl.textContent = `${ctx.offers.length} offre${ctx.offers.length > 1 ? "s" : ""}`;
  }

  async function mark(status) {
    try {
      await api("/api/track", {
        method: "POST",
        body: JSON.stringify({ job_id: ctx.jobId, indices: [offer.index], status }),
      });
      applyStatus(status);
      // Statut choisi → l'offre quitte les résultats (reste visible dans Suivi)
      if (TERMINAL.includes(status)) removeFromResults();
    } catch (e) {
      toast(e.message, "err");
    }
  }

  // « Ouvrir » : surligne la carte ; la dernière ouverte reste marquée jusqu'à
  // ce qu'un statut soit choisi (la carte quitte alors les résultats).
  openLink.addEventListener("click", () => {
    card.classList.add("is-opened");
    if (LAST_OPENED_CARD && LAST_OPENED_CARD !== card) {
      LAST_OPENED_CARD.classList.remove("is-last-opened");
    }
    card.classList.add("is-last-opened");
    LAST_OPENED_CARD = card;
  });
  btnFav.addEventListener("click", () => mark("favorite"));
  btnApplied.addEventListener("click", () => mark("applied"));
  btnReject.addEventListener("click", () => mark("rejected"));
  btnLetter.addEventListener("click", () => openLetterModal(offer, (st) => {
    applyStatus(st);
    if (TERMINAL.includes(st)) removeFromResults();
  }, ctx.jobId));

  return card;
}

async function exportResults() {
  const fmt = await showExportPicker();
  if (!fmt) return;
  try {
    const out = await api("/api/export", { method: "POST", body: JSON.stringify({ job_id: SCAN_JOB }) });
    if (fmt === "csv"  || fmt === "both") await downloadFile(out.csv_file);
    if (fmt === "json" || fmt === "both") await downloadFile(out.json_file);
    const label = fmt === "both" ? "CSV + JSON" : fmt.toUpperCase();
    toast(`Export ${label} téléchargé.`, "ok");
  } catch (e) {
    toast(e.message, "err");
  }
}

async function exportNotion() {
  try {
    const out = await api("/api/notion", { method: "POST", body: JSON.stringify({ job_id: SCAN_JOB }) });
    toast(`${out.count} offre(s) exportée(s) vers Notion.`, "ok");
  } catch (e) {
    toast(e.message, "err");
  }
}

// ─── Vérification de disponibilité (sans IA) ────────────────────────────────

$("#btn-check-avail").addEventListener("click", checkAvailability);

async function checkAvailability() {
  if (!OFFERS.length) { toast("Aucune offre à vérifier.", "err"); return; }
  let out;
  try {
    out = await api("/api/check-availability", { method: "POST", body: JSON.stringify({ job_id: SCAN_JOB }) });
  } catch (e) { toast(e.message, "err"); return; }
  $("#btn-check-avail").disabled = true;
  $("#scan-progress").hidden = false;
  $("#btn-show-log").hidden = true;
  { const sp = $("#scan-progress .spinner"); if (sp) sp.style.display = ""; }
  $("#progress-title").textContent = "Vérification de disponibilité (sans IA)…";
  $("#progress-log").replaceChildren();
  resetProgressBar();
  pollCheck(out.job_id, ++POLL_GEN);
}

function pollCheck(jobId, gen) {
  setTimeout(async () => {
    if (gen !== POLL_GEN) return;  // un scan/vérif plus récent a pris la main
    let job;
    try { job = await api(`/api/job?id=${encodeURIComponent(jobId)}`); }
    catch (e) { $("#btn-check-avail").disabled = false; toast("Suivi perdu : " + e.message, "err"); return; }
    if (gen !== POLL_GEN) return;
    renderLog(job.log);
    if (job.status === "running") { pollCheck(jobId, gen); return; }
    $("#btn-check-avail").disabled = false;
    const sp = $("#scan-progress .spinner"); if (sp) sp.style.display = "none";
    $("#progress-title").textContent = "Vérification terminée";
    if (job.status === "error") { toast("Vérification échouée : " + (job.error || ""), "err"); return; }
    applyAvailability((job.result && job.result.results) || []);
    $("#scan-progress").hidden = true;
    $("#btn-show-log").hidden = false;
  }, 850);
}

function applyAvailability(results) {
  const grid = $("#results-grid");
  let online = 0, gone = 0, unknown = 0;
  for (const r of results) {
    const card = grid.querySelector(`[data-index="${r.index}"]`);
    if (!card) continue;  // carte retirée (statut déjà choisi)
    card.classList.remove("avail-online", "avail-gone", "avail-unknown");
    let badge = card.querySelector(".avail-badge");
    if (!badge) {
      badge = el("span", { class: "badge avail-badge" });
      (card.querySelector(".offer-badges") || card).appendChild(badge);
    }
    if (r.available === true) { card.classList.add("avail-online"); badge.textContent = "🟢 en ligne"; online++; }
    else if (r.available === false) { card.classList.add("avail-gone"); badge.textContent = "🔴 retirée"; gone++; }
    else { card.classList.add("avail-unknown"); badge.textContent = "⚪ indéterminée"; unknown++; }
  }
  toast(`Disponibilité : ${online} en ligne · ${gone} retirée(s) · ${unknown} indéterminée(s).`, "ok");
}

// ─── Modale lettre ──────────────────────────────────────────────────────────

let LETTER_TONE = "standard";
let LETTER_DOCTYPE = "lettre";  // "lettre" (motivation) ou "message" (recruteur)
let LETTER_OFFER = null;
let LETTER_APPLY_STATUS = null;
let LETTER_JOB = null;     // job portant l'offre (scan courant ou session d'historique)
let LETTER_PREVIEW_FILE = null;  // nom du fichier txt en mode aperçu (depuis onglet Lettres)

function openLetterModal(offer, applyStatus, jobId) {
  LETTER_OFFER = offer;
  LETTER_APPLY_STATUS = applyStatus;
  LETTER_JOB = jobId || SCAN_JOB;
  LETTER_PREVIEW_FILE = null;
  $("#modal-title").textContent = `Candidature — ${offer.title} · ${offer.company}`;
  $("#btn-generate-letter").textContent = "Générer";
  $("#letter-config").hidden = false;
  $("#letter-loading").hidden = true;
  $("#letter-result").hidden = true;

  // Pills « type de document » (lettre de motivation / message recruteur)
  $("#letter-doctypes").querySelectorAll(".pill").forEach((p) => {
    p.classList.toggle("active", p.dataset.doctype === LETTER_DOCTYPE);
    p.onclick = () => {
      LETTER_DOCTYPE = p.dataset.doctype;
      $("#letter-doctypes").querySelectorAll(".pill").forEach((q) => q.classList.remove("active"));
      p.classList.add("active");
    };
  });

  const tonesBox = $("#letter-tones");
  tonesBox.replaceChildren();
  for (const t of APP.tones) {
    const pill = el("span", { class: "pill" + (t.key === LETTER_TONE ? " active" : ""), text: `${t.key} — ${t.label}` });
    pill.addEventListener("click", () => {
      LETTER_TONE = t.key;
      tonesBox.querySelectorAll(".pill").forEach((p) => p.classList.remove("active"));
      pill.classList.add("active");
    });
    tonesBox.appendChild(pill);
  }
  $("#modal-overlay").hidden = false;
}

// Ouvre la modale en mode aperçu (depuis l'onglet Lettres) — pas de génération,
// lecture du fichier txt existant.
async function openLetterPreview(letter) {
  LETTER_OFFER = null;
  LETTER_APPLY_STATUS = null;
  LETTER_JOB = null;
  LETTER_PREVIEW_FILE = letter.txt_file || null;

  $("#modal-title").textContent = `Aperçu — ${letter.title || "—"} · ${letter.company || "—"}`;
  $("#letter-config").hidden = true;
  $("#letter-loading").hidden = false;
  $("#letter-result").hidden = true;
  $("#letter-notes").hidden = true;
  $("#modal-overlay").hidden = false;

  let data;
  try {
    data = await api(`/api/letter-read?file=${encodeURIComponent(letter.txt_file)}`);
  } catch (e) {
    $("#letter-loading").hidden = true;
    $("#letter-config").hidden = false;
    toast("Impossible de lire la lettre : " + e.message, "err");
    return;
  }

  $("#letter-loading").hidden = true;
  $("#letter-subject").textContent = data.email_subject || "—";
  $("#letter-email").textContent = data.email_body || "—";
  $("#letter-body").value = data.letter || "";
  const txtFile = letter.txt_file || "";
  const pdfFile = letter.pdf_file || "";
  $("#letter-dl-txt").dataset.file = txtFile;
  if (pdfFile) {
    $("#letter-dl-pdf").hidden = false;
    $("#letter-dl-pdf").dataset.file = pdfFile;
  } else {
    $("#letter-dl-pdf").hidden = true;
  }
  $("#btn-letter-save").textContent = "💾 Enregistrer les modifications (txt + PDF)";
  $("#letter-result").hidden = false;
}

$("#modal-close").addEventListener("click", () => {
  $("#modal-overlay").hidden = true;
  LETTER_PREVIEW_FILE = null;
  $("#btn-letter-save").textContent = "💾 Enregistrer (txt + PDF)";
});
$("#modal-overlay").addEventListener("click", (e) => {
  if (e.target === $("#modal-overlay")) {
    $("#modal-overlay").hidden = true;
    LETTER_PREVIEW_FILE = null;
    $("#btn-letter-save").textContent = "💾 Enregistrer (txt + PDF)";
  }
});

// Curseur de longueur maximale
const maxWordsInput = $("#letter-maxwords");
if (maxWordsInput) {
  maxWordsInput.addEventListener("input", (e) => {
    $("#letter-maxwords-val").textContent = e.target.value;
  });
}

$("#btn-generate-letter").addEventListener("click", async () => {
  $("#letter-config").hidden = true;
  $("#letter-loading").hidden = false;
  const maxWords = parseInt($("#letter-maxwords").value, 10) || 350;
  let out;
  try {
    out = await api("/api/letter", {
      method: "POST",
      body: JSON.stringify({
        job_id: LETTER_JOB, index: LETTER_OFFER.index, tone: LETTER_TONE,
        doc_type: LETTER_DOCTYPE, max_words: maxWords,
      }),
    });
  } catch (e) {
    $("#letter-loading").hidden = true;
    $("#letter-config").hidden = false;
    toast(e.message, "err");
    return;
  }
  pollLetter(out.job_id);
});

function pollLetter(jobId) {
  setTimeout(async () => {
    let job;
    try {
      job = await api(`/api/job?id=${encodeURIComponent(jobId)}`);
    } catch (e) {
      $("#letter-loading").hidden = true;
      $("#letter-config").hidden = false;
      toast(e.message, "err");
      return;
    }
    if (job.status === "running") { pollLetter(jobId); return; }
    $("#letter-loading").hidden = true;
    if (job.status === "error") {
      $("#letter-config").hidden = false;
      toast("Génération échouée : " + (job.error || "erreur"), "err");
      return;
    }
    const r = job.result;
    const notes = Array.isArray(r.review_notes) ? r.review_notes : [];
    const notesBox = $("#letter-notes");
    const notesList = $("#letter-notes-list");
    notesList.textContent = "";
    if (notes.length) {
      notes.forEach((n) => {
        const li = document.createElement("li");
        li.textContent = String(n);
        notesList.appendChild(li);
      });
      notesBox.hidden = false;
    } else {
      notesBox.hidden = true;
    }
    $("#letter-subject").textContent = r.email_subject || "—";
    $("#letter-email").textContent = r.email_body || "—";
    $("#letter-body").value = r.letter;
    $("#letter-dl-txt").dataset.file = r.txt_file;
    if (r.pdf_file) {
      $("#letter-dl-pdf").hidden = false;
      $("#letter-dl-pdf").dataset.file = r.pdf_file;
    } else {
      $("#letter-dl-pdf").hidden = true;
    }
    $("#letter-result").hidden = false;
    const kind = r.doc_type === "message" ? "Message" : "Lettre";
    if (r.partial) {
      // Texte interrompu : affiché pour édition, l'offre reste dans les résultats.
      toast(`⚠ Génération interrompue — ${kind.toLowerCase()} partiel récupéré, complétez-le puis enregistrez.`, "err");
    } else {
      // Générer un texte ≠ postuler : on NE marque PAS l'offre « postulée ».
      // L'offre reste dans les résultats ; l'utilisateur choisit lui-même le
      // statut quand il a réellement candidaté. Le document est dans l'onglet Lettres.
      const lang = r.language === "en" ? " (offre en anglais → version EN)" : "";
      toast(`${kind} généré${lang} — éditez-la si besoin. L'offre n'est PAS marquée postulée : choisissez son statut quand vous aurez candidaté.`, "ok");
    }
  }, 900);
}

// Édition de la lettre : réécrit le .txt et le .pdf, sans appel IA.
// En mode aperçu (LETTER_PREVIEW_FILE) on utilise /api/letter-edit (sans job context).
$("#btn-letter-save").addEventListener("click", async () => {
  const letter = $("#letter-body").value;
  const emailSubject = $("#letter-subject").textContent === "—" ? "" : $("#letter-subject").textContent;
  const emailBody = $("#letter-email").textContent === "—" ? "" : $("#letter-email").textContent;
  try {
    let out;
    if (LETTER_PREVIEW_FILE) {
      out = await api("/api/letter-edit", {
        method: "POST",
        body: JSON.stringify({
          txt_file: LETTER_PREVIEW_FILE,
          letter,
          email_subject: emailSubject,
          email_body: emailBody,
        }),
      });
    } else {
      if (!LETTER_OFFER) return;
      out = await api("/api/letter-save", {
        method: "POST",
        body: JSON.stringify({
          job_id: LETTER_JOB,
          index: LETTER_OFFER.index,
          letter,
          email_subject: emailSubject,
          email_body: emailBody,
        }),
      });
    }
    $("#letter-dl-txt").dataset.file = out.txt_file;
    if (out.pdf_file) {
      $("#letter-dl-pdf").hidden = false;
      $("#letter-dl-pdf").dataset.file = out.pdf_file;
    }
    toast("Modifications enregistrées (txt + PDF régénérés).", "ok");
  } catch (e) {
    toast(e.message, "err");
  }
});

for (const id of ["#letter-dl-txt", "#letter-dl-pdf"]) {
  $(id).addEventListener("click", (ev) => {
    ev.preventDefault();
    const file = ev.currentTarget.dataset.file;
    if (file) downloadFile(file).catch((e) => toast(e.message, "err"));
  });
}

document.querySelectorAll("[data-copy]").forEach((btn) => {
  btn.addEventListener("click", () => {
    const text = btn.dataset.copy === "email"
      ? `Objet : ${$("#letter-subject").textContent}\n\n${$("#letter-email").textContent}`
      : $("#letter-body").value;
    navigator.clipboard.writeText(text).then(
      () => toast("Copié dans le presse-papier.", "ok"),
      () => toast("Copie impossible.", "err"),
    );
  });
});

// ─── Onglet Historique ──────────────────────────────────────────────────────

async function loadHistory() {
  let data;
  try {
    data = await api("/api/sessions");
  } catch (e) {
    toast(e.message, "err");
    return;
  }
  const list = $("#history-list");
  list.replaceChildren();
  $("#history-offers-panel").hidden = true;  // referme une éventuelle vue de session
  $("#history-empty").hidden = data.sessions.length > 0;

  const kindLabels = { web: "Web", scan: "CLI", watch: "Veille", rescore: "Re-scoring" };
  for (const s of data.sessions) {
    const btnView = el("button", { class: "btn-ghost small", text: "Voir les offres" });
    btnView.addEventListener("click", () => loadSession(s.id, "history"));
    const btnRerun = el("button", { class: "btn-ghost small", text: "↻ Relancer" });
    btnRerun.addEventListener("click", () => {
      applyCriteria(s.criteria);
      switchTab("search");
      toast("Critères repris — lancez la recherche quand vous êtes prêt.", "ok");
    });
    if (s.kind === "rescore") btnRerun.hidden = true;

    const metaBits = [
      `${s.date.replace("T", " ").slice(0, 16)} · ${s.summary} · ` +
      `${s.kept} offre(s) retenue(s) sur ${s.found}`,
    ];
    const meta = el("div", { class: "session-meta muted small", text: metaBits.join("") });
    if (s.cv_display) {
      meta.appendChild(el("span", { text: " · " }));
      meta.appendChild(el("span", {
        class: s.cv_display.includes("CV supprimé") ? "cv-deleted" : "",
        text: s.cv_display,
      }));
    }
    list.appendChild(el("div", { class: "card session-item" }, [
      el("div", { class: "session-main" }, [
        el("div", { class: "session-title" }, [
          el("strong", { text: s.criteria.query || "(re-scoring de la base)" }),
          el("span", { class: "badge src", text: kindLabels[s.kind] || s.kind }),
        ]),
        meta,
      ]),
      el("div", { class: "session-actions" }, [btnView, btnRerun]),
    ]));
  }
}

let HISTORY_OFFERS = [];

$("#btn-history-offers-close").addEventListener("click", () => {
  $("#history-offers-panel").hidden = true;
});

async function loadSession(id, target = "search") {
  let out;
  try {
    out = await api("/api/session-load", { method: "POST", body: JSON.stringify({ id }) });
  } catch (e) {
    toast(e.message, "err");
    return;
  }
  const when = out.date ? out.date.replace("T", " ").slice(0, 16) : "";
  const offers = out.offers || [];
  if (target === "history") {
    // Affiche les offres DANS l'onglet Historique, avec leur propre job — ne
    // touche ni au scan en cours (SCAN_JOB) ni à l'onglet courant.
    HISTORY_OFFERS = offers;
    const panel = $("#history-offers-panel");
    $("#history-offers-title").textContent = `Offres de la session du ${when}`;
    renderOfferCards(HISTORY_OFFERS, {
      jobId: out.job_id, offers: HISTORY_OFFERS, grid: $("#history-offers-grid"),
      countEl: $("#history-offers-count"), onEmpty: () => { panel.hidden = true; },
    });
    panel.hidden = false;
    panel.scrollIntoView({ behavior: "smooth", block: "nearest" });
  } else {
    SCAN_JOB = out.job_id;
    OFFERS = offers;
    switchTab("search");
    $("#scan-progress").hidden = true;
    $("#btn-show-log").hidden = true;
    renderResults();
  }
  toast(`Session du ${when} rechargée (${offers.length} offre(s), scores de l'époque).`
    + (out.letters_available ? "" : " CV introuvable : lettres indisponibles."), "ok");
}

// ─── Onglet Lettres ─────────────────────────────────────────────────────────

async function loadLetters() {
  let data;
  try {
    data = await api("/api/sessions");
  } catch (e) {
    toast(e.message, "err");
    return;
  }
  const grid = $("#letters-grid");
  grid.replaceChildren();
  $("#letters-empty").hidden = data.letters.length > 0;

  data.letters.forEach((letter, i) => {
    const actions = el("div", { class: "lt-actions" });
    const btnPreview = el("button", { class: "btn-ghost small", text: "👁 Aperçu" });
    btnPreview.addEventListener("click", (ev) => {
      ev.stopPropagation();
      openLetterPreview(letter).catch((e) => toast(e.message, "err"));
    });
    actions.appendChild(btnPreview);
    for (const [file, label] of [[letter.txt_file, "⬇ .txt"], [letter.pdf_file, "⬇ .pdf"]]) {
      if (!file) continue;
      const a = el("a", { class: "btn-ghost small", text: label, href: "#" });
      a.addEventListener("click", (ev) => {
        ev.preventDefault();
        ev.stopPropagation();
        downloadFile(file).catch((e) => toast(e.message, "err"));
      });
      actions.appendChild(a);
    }
    const card = el("div", { class: "card letter-card clickable", title: "Cliquer pour prévisualiser la lettre" }, [
      el("div", { class: "lt-title", text: letter.title || "—" }),
      el("div", { class: "lt-meta" }, [
        el("span", { text: letter.company || "—" }),
        el("span", { text: letter.date.replace("T", " ").slice(0, 16) }),
        el("span", { text: letter.doc_type === "message" ? "✉ message" : "📄 lettre" }),
        el("span", { text: `ton ${letter.tone}` }),
        el("span", { text: letter.language === "en" ? "🇬🇧 EN" : "🇫🇷 FR" }),
      ]),
      actions,
    ]);
    card.addEventListener("click", () => openLetterPreview(letter).catch((e) => toast(e.message, "err")));
    card.style.setProperty("--i", Math.min(i, 12));
    grid.appendChild(card);
  });
}

// ─── Onglet Mes CV ──────────────────────────────────────────────────────────

const SECTION_DEFS = [
  { key: "contact", title: "Coordonnées" },
  { key: "skills", title: "Compétences" },
  { key: "experiences", title: "Expériences" },
  { key: "education", title: "Formations" },
  { key: "languages", title: "Langues" },
];

// État du détail ouvert : entrée, sections marquées manuelles, sections éditées
let CVD = null;

async function loadCvs() {
  try {
    const out = await api("/api/cvs");
    CVS = out.cvs;
  } catch (e) {
    toast(e.message, "err");
    return;
  }
  rebuildCvChips();
  renderCvList();
}

// Sélection multiple pour les actions groupées (distincte de la sélection de
// recherche SELECTED.cvs) — ne contient que des ids de CV actifs.
const CV_SELECTED = new Set();
let CV_BULK_BUSY = false;  // une analyse groupée est en cours

function renderCvToolbar() {
  const bar = $("#cv-toolbar");
  bar.replaceChildren();
  bar.hidden = CVS.length === 0;
  if (!CVS.length) return;

  // On ne garde dans la sélection que des CV encore présents.
  const ids = new Set(CVS.map((c) => c.id));
  for (const id of [...CV_SELECTED]) if (!ids.has(id)) CV_SELECTED.delete(id);

  const analyzable = CVS.filter((c) => c.file_exists);
  const allSelected = analyzable.length > 0 && analyzable.every((c) => CV_SELECTED.has(c.id));

  const btnAll = el("button", {
    class: "btn-ghost small",
    text: "🔄 Tout analyser",
    title: "Lance l'analyse IA de tous les CV (un par un)",
  });
  btnAll.disabled = CV_BULK_BUSY || analyzable.length === 0;
  btnAll.addEventListener("click", () => analyzeCvBatch(analyzable, "tous les CV"));

  const btnToggle = el("button", {
    class: "btn-ghost small",
    text: allSelected ? "☐ Tout désélectionner" : "☑ Tout sélectionner",
  });
  btnToggle.addEventListener("click", () => {
    if (allSelected) CV_SELECTED.clear();
    else for (const c of analyzable) CV_SELECTED.add(c.id);
    renderCvList();
  });

  const row = el("div", { class: "cv-toolbar-row" }, [btnAll, btnToggle]);
  bar.appendChild(row);

  if (CV_SELECTED.size > 0) {
    const btnSel = el("button", {
      class: "btn-primary small",
      text: `🔄 Analyser la sélection (${CV_SELECTED.size})`,
    });
    btnSel.disabled = CV_BULK_BUSY;
    btnSel.addEventListener("click", () => {
      const chosen = CVS.filter((c) => CV_SELECTED.has(c.id) && c.file_exists);
      analyzeCvBatch(chosen, `${chosen.length} CV sélectionné(s)`);
    });
    bar.appendChild(el("div", { class: "cv-toolbar-row" }, [btnSel]));
  }

  const status = el("div", { class: "cv-bulk-status", id: "cv-bulk-status" });
  status.hidden = true;
  bar.appendChild(status);
}

function renderCvList() {
  renderCvToolbar();
  const list = $("#cv-list");
  list.replaceChildren();
  $("#cvs-empty").hidden = CVS.length > 0;
  if (!CVS.length) { $("#cv-detail").hidden = true; CVD = null; return; }

  for (const cv of CVS) {
    const check = el("input", { type: "checkbox", class: "ci-check", title: "Sélectionner pour une action groupée" });
    check.checked = CV_SELECTED.has(cv.id);
    check.disabled = !cv.file_exists;
    check.addEventListener("click", (e) => {
      e.stopPropagation();  // ne pas ouvrir le détail
      if (check.checked) CV_SELECTED.add(cv.id); else CV_SELECTED.delete(cv.id);
      renderCvToolbar();
    });

    const trash = el("button", {
      class: "ci-del", title: "Supprimer ce CV", text: "🗑", "aria-label": "Supprimer ce CV",
    });
    trash.addEventListener("click", (e) => { e.stopPropagation(); deleteCv(cv); });

    const item = el("div", { class: "cv-item" + (CVD && CVD.entry.id === cv.id ? " active" : "") }, [
      el("div", { class: "ci-row" }, [
        check,
        el("div", { class: "ci-main" }, [
          el("div", { class: "ci-label", text: cv.label || cv.filename }),
          el("div", { class: "ci-meta" }, [
            el("span", { text: cv.filename }),
            el("span", { text: "ajouté " + (cv.added || "").slice(0, 10) }),
            cv.analyzed
              ? el("span", { text: "profil IA " + cv.analyzed.slice(0, 10) })
              : el("span", { text: "non analysé" }),
            Object.keys(cv.overrides || {}).length
              ? el("span", { text: "✎ corrigé" }) : null,
            cv.file_exists ? null : el("span", { class: "ci-missing", text: "fichier introuvable" }),
          ]),
        ]),
        trash,
      ]),
    ]);
    item.addEventListener("click", () => openCvDetail(cv));
    list.appendChild(item);
  }
}

// Attend la fin d'un job (analyse CV) en résolvant/rejetant une promesse.
function waitForJob(jobId) {
  return new Promise((resolve, reject) => {
    const tick = async () => {
      let job;
      try { job = await api(`/api/job?id=${encodeURIComponent(jobId)}`); }
      catch (e) { reject(e); return; }
      if (job.status === "running") { setTimeout(tick, 900); return; }
      if (job.status === "error") { reject(new Error(job.error || "erreur")); return; }
      resolve(job);
    };
    setTimeout(tick, 900);
  });
}

// Analyse IA d'une liste de CV, séquentiellement (ne sature pas le LLM).
async function analyzeCvBatch(cvList, label) {
  if (CV_BULK_BUSY) return;
  const targets = (cvList || []).filter((c) => c.file_exists);
  if (!targets.length) { toast("Aucun CV analysable (fichiers introuvables).", "err"); return; }
  CV_BULK_BUSY = true;
  renderCvToolbar();
  const status = $("#cv-bulk-status");
  const setStatus = (txt) => { if (status) { status.hidden = false; status.textContent = txt; } };
  let done = 0, failed = 0;
  setStatus(`Analyse IA de ${label} : 0/${targets.length}…`);
  for (const cv of targets) {
    try {
      const out = await api("/api/cv-analyze", { method: "POST", body: JSON.stringify({ id: cv.id }) });
      await waitForJob(out.job_id);
    } catch (e) {
      failed += 1;
    }
    done += 1;
    setStatus(`Analyse IA de ${label} : ${done}/${targets.length}…`);
  }
  CV_BULK_BUSY = false;
  await refreshCvData();
  if (CVD) { const fresh = CVS.find((c) => c.id === CVD.entry.id); if (fresh) openCvDetail(fresh); }
  renderCvList();
  const okCount = done - failed;
  if (failed === 0) toast(`${okCount} CV analysé(s) par l'IA.`, "ok");
  else toast(`${okCount}/${targets.length} CV analysé(s) — ${failed} échec(s).`, okCount ? "ok" : "err");
}

function openCvDetail(cv) {
  CVD = {
    entry: cv,
    manual: new Set(Object.keys(cv.overrides || {})),
    dirty: new Set(),
    sections: {},   // key → {body, badge, revert}
  };
  renderCvList();
  const box = $("#cv-detail");
  box.replaceChildren();
  box.hidden = false;

  // En-tête : label éditable + méta
  const labelInput = el("input", { type: "text", maxlength: "80", value: cv.label || "" });
  box.appendChild(el("div", { class: "cvd-head" }, [
    el("div", { class: "field" }, [el("label", { text: "Label du CV" }), labelInput]),
  ]));
  box.appendChild(el("div", { class: "cvd-meta", text:
    `${cv.filename} · ajouté le ${(cv.added || "").slice(0, 10)}`
    + (cv.analyzed ? ` · profil extrait le ${cv.analyzed.slice(0, 10)}` : " · pas encore analysé par l'IA") }));
  CVD.labelInput = labelInput;

  // Sections
  for (const def of SECTION_DEFS) {
    box.appendChild(buildSection(def, cv));
  }

  // Zone de progression d'analyse
  const progress = el("div", { class: "letter-loading", hidden: "" }, [
    el("span", { class: "spinner" }), "Analyse IA du CV en cours…",
  ]);
  progress.hidden = true;
  box.appendChild(progress);
  CVD.progress = progress;

  // Actions
  const btnAnalyze = el("button", { class: "btn-ghost", text: "🔄 Ré-analyser avec l'IA" });
  btnAnalyze.addEventListener("click", () => analyzeCv(cv.id, btnAnalyze));
  if (!cv.file_exists) { btnAnalyze.disabled = true; btnAnalyze.title = "Fichier introuvable"; }
  const btnSave = el("button", { class: "btn-primary", text: "💾 Enregistrer les corrections" });
  btnSave.addEventListener("click", saveCvDetail);
  const btnDelete = el("button", { class: "btn-danger", text: "🗑 Supprimer ce CV" });
  btnDelete.addEventListener("click", () => deleteCv(cv));
  box.appendChild(el("div", { class: "cvd-actions" }, [btnAnalyze, btnSave, btnDelete]));
}

function sectionBadge(key) {
  /* Badge de provenance : manuel (prioritaire) / IA / vide. */
  const manual = CVD.manual.has(key) || CVD.dirty.has(key);
  const fromAi = (CVD.entry.sources || {})[key] === "ai";
  if (manual) return { text: "✎ modifié manuellement", cls: "src-badge manual" };
  if (fromAi) return { text: "✓ extrait par l'IA", cls: "src-badge ai" };
  return { text: "à compléter", cls: "src-badge" };
}

function buildSection(def, cv) {
  const profile = cv.profile || {};
  const data = profile[def.key];

  const badgeInfo = { ...sectionBadge(def.key) };
  const badge = el("span", { class: badgeInfo.cls, text: badgeInfo.text });
  const revert = el("button", { class: "btn-ghost small revert-btn", text: "↺ Revenir à l'extraction IA" });
  const body = el("div");

  const section = el("div", { class: "cv-section" }, [
    el("div", { class: "cv-section-head" }, [
      el("h4", { text: def.title }), badge, revert,
    ]),
    body,
  ]);

  const fill = (value) => {
    body.replaceChildren();
    FILLERS[def.key](body, value);
  };
  fill(data);

  const refreshBadge = () => {
    const info = sectionBadge(def.key);
    badge.className = info.cls;
    badge.textContent = info.text;
    revert.hidden = !(CVD.manual.has(def.key) || CVD.dirty.has(def.key))
      || !((CVD.entry.extracted || {})[def.key]);
  };
  refreshBadge();

  body.addEventListener("input", () => {
    CVD.dirty.add(def.key);
    refreshBadge();
  });
  revert.addEventListener("click", () => {
    CVD.manual.delete(def.key);
    CVD.dirty.delete(def.key);
    fill((CVD.entry.extracted || {})[def.key]);
    refreshBadge();
    toast(`Section « ${def.title} » revenue à l'extraction IA — enregistrez pour confirmer.`, "ok");
  });

  CVD.sections[def.key] = { body, refreshBadge };
  return section;
}

/* Constructeurs de formulaires par section (remplissage) */

function labeledInput(labelText, value, attrs = {}) {
  return el("div", { class: "field" }, [
    el("label", { text: labelText }),
    el("input", { type: "text", value: value || "", ...attrs }),
  ]);
}

const FILLERS = {
  contact(body, data) {
    const c = data || {};
    body.appendChild(el("div", { class: "grid2" }, [
      labeledInput("Nom", c.name, { dataset: { f: "name" }, maxlength: "80" }),
      labeledInput("Intitulé pro", c.headline, { dataset: { f: "headline" }, maxlength: "120" }),
      labeledInput("Email", c.email, { dataset: { f: "email" }, maxlength: "120" }),
      labeledInput("Téléphone", c.phone, { dataset: { f: "phone" }, maxlength: "40" }),
      labeledInput("Ville", c.city, { dataset: { f: "city" }, maxlength: "80" }),
    ]));
  },
  skills(body, data) {
    const lines = (data || []).map((cat) => `${cat.category} : ${(cat.items || []).join(", ")}`);
    body.appendChild(el("div", { class: "field" }, [
      el("label", { text: "Une catégorie par ligne — « Catégorie : item1, item2 »" }),
      el("textarea", { rows: "6", text: lines.join("\n"), placeholder: "Langages : Python, C++\nOutils : Git, Docker" }),
    ]));
  },
  experiences(body, data) {
    const rows = el("div");
    const addRow = (exp = {}) => rows.appendChild(experienceRow(exp, rows));
    for (const exp of data || []) addRow(exp);
    if (!(data || []).length) body.appendChild(el("div", { class: "cv-empty-hint", text: "Aucune expérience extraite — ajoutez-en ou lancez l'analyse IA." }));
    body.appendChild(rows);
    const add = el("button", { class: "btn-ghost small add-row-btn", text: "＋ Ajouter une expérience" });
    add.addEventListener("click", () => { addRow(); body.dispatchEvent(new Event("input", { bubbles: true })); });
    body.appendChild(add);
  },
  education(body, data) {
    const rows = el("div");
    const addRow = (edu = {}) => rows.appendChild(educationRow(edu, rows));
    for (const edu of data || []) addRow(edu);
    if (!(data || []).length) body.appendChild(el("div", { class: "cv-empty-hint", text: "Aucune formation extraite." }));
    body.appendChild(rows);
    const add = el("button", { class: "btn-ghost small add-row-btn", text: "＋ Ajouter une formation" });
    add.addEventListener("click", () => { addRow(); body.dispatchEvent(new Event("input", { bubbles: true })); });
    body.appendChild(add);
  },
  languages(body, data) {
    const rows = el("div");
    const addRow = (lang = {}) => rows.appendChild(languageRow(lang, rows));
    for (const lang of data || []) addRow(lang);
    if (!(data || []).length) body.appendChild(el("div", { class: "cv-empty-hint", text: "Aucune langue extraite." }));
    body.appendChild(rows);
    const add = el("button", { class: "btn-ghost small add-row-btn", text: "＋ Ajouter une langue" });
    add.addEventListener("click", () => { addRow(); body.dispatchEvent(new Event("input", { bubbles: true })); });
    body.appendChild(add);
  },
};

function removableRow(cls, children, rows) {
  const row = el("div", { class: "cv-row-item " + cls }, children);
  const remove = el("button", { class: "btn-ghost small row-remove", text: "✕", title: "Supprimer" });
  remove.addEventListener("click", () => {
    row.remove();
    rows.dispatchEvent(new Event("input", { bubbles: true }));
  });
  row.appendChild(remove);
  return row;
}

function experienceRow(exp, rows) {
  return removableRow("exp-row", [
    el("div", { class: "grid2" }, [
      labeledInput("Poste", exp.title, { dataset: { f: "title" }, maxlength: "120" }),
      labeledInput("Entreprise", exp.company, { dataset: { f: "company" }, maxlength: "120" }),
      labeledInput("Début", exp.start, { dataset: { f: "start" }, maxlength: "20", placeholder: "2023" }),
      labeledInput("Fin", exp.end, { dataset: { f: "end" }, maxlength: "20", placeholder: "auj." }),
      el("div", { class: "field span2" }, [
        el("label", { text: "Réalisations (1-2 phrases)" }),
        el("textarea", { rows: "2", dataset: { f: "description" }, text: exp.description || "" }),
      ]),
    ]),
  ], rows);
}

function educationRow(edu, rows) {
  return removableRow("edu-row", [
    el("div", { class: "grid2" }, [
      labeledInput("Diplôme", edu.degree, { dataset: { f: "degree" }, maxlength: "150" }),
      labeledInput("École", edu.school, { dataset: { f: "school" }, maxlength: "120" }),
      labeledInput("Année", edu.year, { dataset: { f: "year" }, maxlength: "20" }),
    ]),
  ], rows);
}

function languageRow(lang, rows) {
  return removableRow("lang-row", [
    el("div", { class: "grid2" }, [
      labeledInput("Langue", lang.name, { dataset: { f: "name" }, maxlength: "40" }),
      labeledInput("Niveau", lang.level, { dataset: { f: "level" }, maxlength: "60", placeholder: "B2, courant…" }),
    ]),
  ], rows);
}

/* Sérialisation des formulaires par section */

const SERIALIZERS = {
  contact(body) {
    const out = {};
    body.querySelectorAll("input[data-f]").forEach((inp) => (out[inp.dataset.f] = inp.value.trim()));
    return Object.values(out).some(Boolean) ? out : null;
  },
  skills(body) {
    const raw = body.querySelector("textarea").value;
    const cats = [];
    for (const line of raw.split("\n")) {
      const trimmed = line.trim();
      if (!trimmed) continue;
      const sep = trimmed.indexOf(":");
      const category = sep > 0 ? trimmed.slice(0, sep).trim() : "Autres";
      const items = (sep > 0 ? trimmed.slice(sep + 1) : trimmed)
        .split(",").map((s) => s.trim()).filter(Boolean);
      if (items.length) cats.push({ category, items });
    }
    return cats.length ? cats : null;
  },
  experiences(body) {
    const out = [];
    body.querySelectorAll(".exp-row").forEach((row) => {
      const get = (f) => {
        const node = row.querySelector(`[data-f="${f}"]`);
        return node ? node.value.trim() : "";
      };
      const entry = {
        title: get("title"), company: get("company"),
        start: get("start"), end: get("end"), description: get("description"),
      };
      if (entry.title || entry.company) out.push(entry);
    });
    return out.length ? out : null;
  },
  education(body) {
    const out = [];
    body.querySelectorAll(".edu-row").forEach((row) => {
      const get = (f) => (row.querySelector(`[data-f="${f}"]`) || { value: "" }).value.trim();
      const entry = { degree: get("degree"), school: get("school"), year: get("year") };
      if (entry.degree || entry.school) out.push(entry);
    });
    return out.length ? out : null;
  },
  languages(body) {
    const out = [];
    body.querySelectorAll(".lang-row").forEach((row) => {
      const get = (f) => (row.querySelector(`[data-f="${f}"]`) || { value: "" }).value.trim();
      const entry = { name: get("name"), level: get("level") };
      if (entry.name) out.push(entry);
    });
    return out.length ? out : null;
  },
};

async function saveCvDetail() {
  if (!CVD) return;
  // Une section reste « manuelle » si elle l'était déjà ou vient d'être éditée
  const overrides = {};
  for (const def of SECTION_DEFS) {
    if (!CVD.manual.has(def.key) && !CVD.dirty.has(def.key)) continue;
    const value = SERIALIZERS[def.key](CVD.sections[def.key].body);
    if (value !== null) overrides[def.key] = value;
  }
  try {
    const out = await api("/api/cv-update", {
      method: "POST",
      body: JSON.stringify({
        id: CVD.entry.id,
        label: CVD.labelInput.value.trim(),
        overrides,
      }),
    });
    toast("CV enregistré — vos corrections priment sur l'extraction IA.", "ok");
    await refreshCvData();
    const fresh = CVS.find((c) => c.id === out.cv.id);
    if (fresh) openCvDetail(fresh);
  } catch (e) {
    toast(e.message, "err");
  }
}

function analyzeCv(cvId, btn) {
  btn.disabled = true;
  CVD.progress.hidden = false;
  api("/api/cv-analyze", { method: "POST", body: JSON.stringify({ id: cvId }) })
    .then((out) => pollCvJob(out.job_id, btn))
    .catch((e) => {
      btn.disabled = false;
      CVD.progress.hidden = true;
      toast(e.message, "err");
    });
}

function pollCvJob(jobId, btn) {
  setTimeout(async () => {
    let job;
    try {
      job = await api(`/api/job?id=${encodeURIComponent(jobId)}`);
    } catch (e) {
      btn.disabled = false;
      if (CVD) CVD.progress.hidden = true;
      toast(e.message, "err");
      return;
    }
    if (job.status === "running") { pollCvJob(jobId, btn); return; }
    btn.disabled = false;
    if (CVD) CVD.progress.hidden = true;
    if (job.status === "error") {
      toast("Analyse échouée : " + (job.error || "erreur"), "err");
      return;
    }
    toast("Profil extrait par l'IA — vos corrections manuelles restent prioritaires.", "ok");
    await refreshCvData();
    const fresh = CVS.find((c) => c.id === (job.result.cv || {}).id);
    if (fresh) openCvDetail(fresh);
  }, 900);
}

async function deleteCv(cv) {
  const ok = await confirmDialog(
    "Supprimer ce CV ?",
    `« ${cv.label || cv.filename} » sera définitivement supprimé (fichier + profil). ` +
    "Les sessions et lettres déjà générées restent dans l'historique, où ce CV " +
    `apparaîtra comme « CV supprimé : ${cv.label || cv.filename} ». Action irréversible.`,
  );
  if (!ok) return;
  try {
    const out = await api("/api/cv-delete", { method: "POST", body: JSON.stringify({ id: cv.id }) });
    CVS = out.cvs;
    CV_SELECTED.delete(cv.id);
    // Sélection de recherche : retirer le CV disparu, état propre si plus rien
    SELECTED.cvs.delete(cv.filename);
    localStorage.setItem("cvs", JSON.stringify([...SELECTED.cvs]));
    rebuildCvChips();
    renderCvList();
    $("#cv-detail").hidden = true;
    CVD = null;
    toast(`CV supprimé : ${out.label}. L'historique garde son nom.`, "ok");
  } catch (e) {
    toast(e.message, "err");
  }
}

// ─── Onglet Suivi ───────────────────────────────────────────────────────────

async function loadTrack() {
  let stats;
  try {
    stats = await api("/api/stats");
  } catch (e) {
    toast(e.message, "err");
    return;
  }
  $("#count-fav").textContent = stats.favorites.length;
  $("#count-applied").textContent = stats.applied.length;
  $("#count-followup").textContent = stats.followups.length;
  $("#count-rejected").textContent = stats.rejected.length;

  fillColumn($("#col-favorites"), stats.favorites, [
    { label: "✓ postulée", status: "applied" },
    { label: "✗ rejeter", status: "rejected" },
  ]);
  fillColumn($("#col-applied"), stats.applied, [
    { label: "★ favori", status: "favorite" },
  ]);
  fillColumn($("#col-followups"), stats.followups, [
    { label: "↻ relancée", status: "applied" },
    { label: "✗ abandonner", status: "rejected" },
  ]);
  fillColumn($("#col-rejected"), stats.rejected, [
    { label: "↩ restaurer", status: "seen" },
  ]);
}

async function setTrackStatus(key, status) {
  try {
    await api("/api/track-key", { method: "POST", body: JSON.stringify({ key, status }) });
    loadTrack();
    if (status === "forget") toast("Offre retirée du suivi — elle pourra réapparaître aux prochains scans.", "ok");
  } catch (e) {
    toast(e.message, "err");
  }
}

// Glisser-déposer entre colonnes du kanban
let DRAG_KEY = null;
let DRAG_STATUS = null;
document.querySelectorAll(".kanban-list[data-drop]").forEach((zone) => {
  zone.addEventListener("dragover", (e) => {
    if (!DRAG_KEY) return;
    e.preventDefault();
    zone.classList.add("drop-target");
  });
  zone.addEventListener("dragleave", () => zone.classList.remove("drop-target"));
  zone.addEventListener("drop", (e) => {
    e.preventDefault();
    zone.classList.remove("drop-target");
    const target = zone.dataset.drop;
    if (DRAG_KEY && target !== DRAG_STATUS) setTrackStatus(DRAG_KEY, target);
    DRAG_KEY = null;
    DRAG_STATUS = null;
  });
});

function fillColumn(box, entries, actions) {
  box.replaceChildren();
  if (!entries.length) {
    box.appendChild(el("div", { class: "muted small", text: "Rien pour le moment." }));
    return;
  }
  for (const entry of entries) {
    const meta = el("div", { class: "ti-meta" }, [
      el("span", { text: entry.company || "—" }),
      entry.source ? el("span", { text: entry.source }) : null,
      entry.updated ? el("span", { text: entry.updated.slice(0, 10) }) : null,
      entry.score != null ? el("span", { text: `${entry.score}/10` }) : null,
    ]);
    const actionBox = el("div", { class: "ti-actions" });
    if (entry.url && /^https?:\/\//i.test(entry.url)) {
      actionBox.appendChild(el("a", { class: "btn-ghost", text: "↗", target: "_blank", rel: "noopener noreferrer", href: entry.url }));
    }
    for (const act of actions) {
      const btn = el("button", { class: "btn-ghost", text: act.label });
      btn.addEventListener("click", () => setTrackStatus(entry.key, act.status));
      actionBox.appendChild(btn);
    }
    const btnForget = el("button", {
      class: "btn-ghost ti-forget", text: "🗑",
      title: "Retirer du suivi : l'offre pourra réapparaître aux prochains scans",
    });
    btnForget.addEventListener("click", () => setTrackStatus(entry.key, "forget"));
    actionBox.appendChild(btnForget);

    const card = el("div", { class: "track-item", draggable: "true" }, [
      el("div", { class: "ti-title", text: entry.title || "—" }),
      meta,
      actionBox,
    ]);
    card.addEventListener("dragstart", (e) => {
      DRAG_KEY = entry.key;
      DRAG_STATUS = box.dataset.drop || null;
      card.classList.add("dragging");
      if (e.dataTransfer) e.dataTransfer.effectAllowed = "move";
    });
    card.addEventListener("dragend", () => {
      card.classList.remove("dragging");
      DRAG_KEY = null;
      DRAG_STATUS = null;
    });
    box.appendChild(card);
  }
}

// ─── Onglet Statistiques ────────────────────────────────────────────────────

async function loadStats() {
  let stats;
  try {
    stats = await api("/api/stats");
  } catch (e) {
    toast(e.message, "err");
    return;
  }
  const c = stats.counts;
  const counters = $("#stats-counters");
  counters.replaceChildren(
    counterCard(c.total || 0, "offres connues", ""),
    counterCard(c.favorite || 0, "favoris", "c-fav"),
    counterCard(c.applied || 0, "candidatures", "c-applied"),
    counterCard(stats.followups.length, "à relancer", "c-fav"),
    counterCard(c.rejected || 0, "rejetées", "c-rejected"),
  );

  // Barres hebdo
  const weekly = $("#chart-weekly");
  weekly.replaceChildren();
  if (!stats.weekly.length) {
    weekly.appendChild(el("div", { class: "chart-empty", text: "Aucune candidature pour l'instant." }));
  } else {
    const max = Math.max(...stats.weekly.map((w) => w.count), 1);
    for (const w of stats.weekly) {
      const bar = el("div", { class: "bar" });
      bar.style.height = `${Math.max(4, (w.count / max) * 110)}px`;
      weekly.appendChild(el("div", { class: "bar-col" }, [
        el("span", { class: "bar-val", text: String(w.count) }),
        bar,
        el("span", { class: "bar-lbl", text: w.week.replace(/^\d{4}-/, "") }),
      ]));
    }
  }

  // Barres par source
  const srcChart = $("#chart-sources");
  srcChart.replaceChildren();
  if (!stats.by_source.length) {
    srcChart.appendChild(el("div", { class: "chart-empty", text: "Aucune candidature pour l'instant." }));
  } else {
    const max = Math.max(...stats.by_source.map((s) => s.count), 1);
    for (const s of stats.by_source) {
      const fill = el("div", { class: "hbar-fill" });
      fill.style.width = `${(s.count / max) * 100}%`;
      srcChart.appendChild(el("div", { class: "hbar-row" }, [
        el("span", { class: "hb-label", text: s.source }),
        el("div", { class: "hbar-track" }, [fill]),
        el("strong", { text: String(s.count) }),
      ]));
    }
  }
}

function counterCard(num, label, cls) {
  return el("div", { class: `counter ${cls}` }, [
    el("div", { class: "num", text: String(num) }),
    el("div", { class: "lbl", text: label }),
  ]);
}

// ─── Onglet Réglages ────────────────────────────────────────────────────────

function refreshSettingsHints(settings) {
  document.querySelectorAll(".set-hint").forEach((hint) => {
    const info = settings[hint.dataset.hint];
    if (info && info.set) {
      hint.textContent = info.display ? `— ${info.display}` : "— configuré";
      hint.classList.add("ok");
    } else {
      hint.textContent = "";
      hint.classList.remove("ok");
    }
  });
}

$("#btn-save-settings").addEventListener("click", async () => {
  const body = {};
  document.querySelectorAll("[data-key]").forEach((input) => {
    const value = input.value.trim();
    if (value) body[input.dataset.key] = value;
  });
  if (!Object.keys(body).length) { toast("Aucun champ rempli — rien à enregistrer.", "err"); return; }
  try {
    const out = await api("/api/settings", { method: "POST", body: JSON.stringify(body) });
    refreshSettingsHints(out.settings);
    document.querySelectorAll("[data-key]").forEach((input) => {
      if (input.tagName === "INPUT") input.value = "";
    });
    toast(`Enregistré dans .env : ${out.saved.join(", ")}`, "ok");
  } catch (e) {
    toast(e.message, "err");
  }
});

// ─── Détection des modèles LLM locaux (Ollama, LM Studio, llama.cpp) ─────────

$("#btn-scan-models").addEventListener("click", async () => {
  const btn = $("#btn-scan-models");
  const box = $("#local-models-result");
  btn.disabled = true;
  btn.textContent = "Détection en cours…";
  box.hidden = false;
  box.replaceChildren(el("span", { class: "muted small", text: "Sonde des ports locaux (Ollama 11434, LM Studio 1234, llama.cpp 8080)…" }));
  let report;
  try {
    report = await api("/api/local-models");
  } catch (e) {
    box.replaceChildren(el("span", { class: "muted small", text: "Détection impossible : " + e.message }));
    btn.disabled = false;
    btn.textContent = "🔍 Détecter les modèles locaux (Ollama, LM Studio, llama.cpp)";
    return;
  }
  btn.disabled = false;
  btn.textContent = "🔍 Détecter les modèles locaux (Ollama, LM Studio, llama.cpp)";
  box.replaceChildren();

  const hw = [];
  if (report.ram_gb) hw.push(`RAM : ${report.ram_gb} Go`);
  if (report.vram_gb) hw.push(`VRAM GPU : ${report.vram_gb} Go`);
  else hw.push("pas de GPU NVIDIA détecté");
  box.appendChild(el("div", { class: "lm-hw", text: "Matériel — " + hw.join(" · ") }));

  if (!report.servers.length) {
    box.appendChild(el("div", { class: "muted small", text:
      "Aucun serveur LLM local détecté. Installez Ollama (ollama.com) ou LM Studio (lmstudio.ai), puis relancez la détection." }));
  }
  for (const server of report.servers) {
    const head = el("div", { class: "lm-server", text: `${server.server} — ${server.url}` });
    box.appendChild(head);
    if (!server.models.length) {
      box.appendChild(el("div", { class: "muted small", text: "Serveur actif mais aucun modèle installé." }));
    }
    for (const m of server.models) {
      const useBtn = el("button", { class: "btn-ghost small", text: "Utiliser" });
      useBtn.title = "Renseigne ce modèle dans « Modèle Ollama » (pensez à Enregistrer)";
      useBtn.addEventListener("click", () => {
        $("#s-ollama-model").value = m.name;
        toast(`Modèle « ${m.name} » prérempli — cliquez sur Enregistrer pour l'activer.`, "ok");
      });
      box.appendChild(el("div", { class: "lm-model" }, [
        el("span", { text: m.name + (m.size_gb ? ` (${m.size_gb} Go)` : "") }),
        server.server === "Ollama" ? useBtn : null,
      ]));
    }
  }
  if (report.suggestions && report.suggestions.length) {
    box.appendChild(el("div", { class: "lm-server", text: "Modèles conseillés pour cette machine :" }));
    for (const s of report.suggestions) {
      box.appendChild(el("div", { class: "lm-model" }, [
        el("span", { text: `${s.model} — ${s.reason}` }),
      ]));
    }
    box.appendChild(el("div", { class: "muted small", text: "Installation : « ollama pull <modèle> » dans un terminal, puis bouton Utiliser." }));
  }
});

init();
