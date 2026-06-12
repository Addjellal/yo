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

// ─── État global ────────────────────────────────────────────────────────────

let APP = null;            // réponse de /api/state
let SCAN_JOB = null;       // id du scan courant
let OFFERS = [];           // offres du dernier scan
let POLL_TIMER = null;
const SELECTED = { sectors: new Set(), sources: new Set(), experience: "" };
let EXP_PILLS = {};        // key → élément pill
let SEC_CHIPS = {};        // key → élément chip
let SRC_CHIPS = {};        // key → élément chip
let SRC_USABLE = {};       // key → bool

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

function applyCriteria(c) {
  /* Pré-remplit le formulaire de recherche avec des critères (défauts .env
     ou critères d'une session passée à relancer). */
  if (!c) return;
  if (c.query !== undefined && c.query && !c.query.startsWith("(")) $("#f-query").value = c.query;
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
  if (c.cv && [...$("#f-cv").options].some((o) => o.value === c.cv)) $("#f-cv").value = c.cv;
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

  // CV
  rebuildCvSelect(APP.cv_files);

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
}

function rebuildCvSelect(files) {
  const sel = $("#f-cv");
  sel.replaceChildren();
  if (!files.length) {
    sel.appendChild(el("option", { value: "", text: "Aucun CV trouvé" }));
    return;
  }
  for (const f of files) sel.appendChild(el("option", { value: f, text: f }));
  const saved = localStorage.getItem("cv");
  if (saved && files.includes(saved)) sel.value = saved;
  sel.addEventListener("change", () => localStorage.setItem("cv", sel.value));
}

// ─── Upload CV (bouton + glisser-déposer) ───────────────────────────────────

function uploadCvFile(file) {
  if (!file) return;
  if (!/\.(pdf|docx|txt)$/i.test(file.name)) {
    toast("Format non supporté : utilisez PDF, DOCX ou TXT.", "err");
    return;
  }
  if (file.size > 25 * 1024 * 1024) { toast("Fichier trop volumineux (max 25 Mo).", "err"); return; }
  const reader = new FileReader();
  reader.onload = async () => {
    try {
      const b64 = reader.result.split(",", 2)[1] || "";
      const out = await api("/api/cv", { method: "POST", body: JSON.stringify({ filename: file.name, data: b64 }) });
      rebuildCvSelect(out.cv_files);
      $("#f-cv").value = out.name;
      localStorage.setItem("cv", out.name);
      toast(`CV importé : ${out.name}`, "ok");
    } catch (err) {
      toast("Import échoué : " + err.message, "err");
    }
  };
  reader.readAsDataURL(file);
}

$("#cv-upload-btn").addEventListener("click", () => $("#cv-file").click());
$("#cv-file").addEventListener("change", (e) => uploadCvFile(e.target.files[0]));

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
  const file = e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0];
  uploadCvFile(file);
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
$("#btn-progress-hide").addEventListener("click", () => ($("#scan-progress").hidden = true));

async function startScan() {
  const query = $("#f-query").value.trim();
  if (!query) { toast("Indiquez un poste à rechercher.", "err"); return; }
  const cv = $("#f-cv").value;
  if (!cv) { toast("Importez d'abord un CV (bouton ＋).", "err"); return; }
  if (!SELECTED.sources.size) { toast("Sélectionnez au moins une source.", "err"); return; }

  const country = $("#f-country").value;
  const city = $("#f-city").value.trim();
  const region = country === "fr" ? $("#f-region").value : "";

  const body = {
    query, cv, country,
    location: city || region,
    sources: [...SELECTED.sources],
    sectors: [...SELECTED.sectors],
    experience: SELECTED.experience,
    min_score: parseInt($("#f-minscore").value, 10),
    max: parseInt($("#f-max").value, 10) || 50,
    exclude: $("#f-exclude").value,
    include_seen: $("#f-include-seen").checked,
  };

  let out;
  try {
    out = await api("/api/scan", { method: "POST", body: JSON.stringify(body) });
  } catch (e) {
    toast(e.message, "err");
    return;
  }
  pushHistory(query);
  SCAN_JOB = out.job_id;
  $("#btn-scan").disabled = true;
  $("#search-empty").hidden = true;
  $("#results-zone").hidden = true;
  $("#scan-progress").hidden = false;
  $("#progress-title").textContent = `Recherche : « ${query} »`;
  $("#progress-log").replaceChildren();
  pollScan();
}

// ─── Re-scoring de la base (sans scraper) ───────────────────────────────────

$("#btn-rescore").addEventListener("click", async () => {
  const cv = $("#f-cv").value;
  if (!cv) { toast("Importez d'abord un CV (bouton ＋).", "err"); return; }
  const body = {
    cv,
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
  $("#scan-progress").hidden = false;
  $("#progress-title").textContent = "Re-scoring de la base d'offres connues…";
  $("#progress-log").replaceChildren();
  pollScan();
});

function pollScan() {
  clearTimeout(POLL_TIMER);
  POLL_TIMER = setTimeout(async () => {
    let job;
    try {
      job = await api(`/api/job?id=${encodeURIComponent(SCAN_JOB)}`);
    } catch (e) {
      $("#btn-scan").disabled = false;
      toast("Suivi du scan perdu : " + e.message, "err");
      return;
    }
    renderLog(job.log);
    if (job.status === "running") { pollScan(); return; }
    $("#btn-scan").disabled = false;
    if (job.status === "error") {
      toast("Scan échoué : " + (job.error || "erreur inconnue"), "err");
      return;
    }
    OFFERS = job.offers || [];
    $("#scan-progress").hidden = OFFERS.length > 0;
    renderResults();
  }, 850);
}

function renderLog(lines) {
  const box = $("#progress-log");
  while (box.children.length < lines.length) {
    box.appendChild(el("div", { text: lines[box.children.length] }));
  }
  box.scrollTop = box.scrollHeight;
}

// ─── Rendu des résultats ────────────────────────────────────────────────────

$("#sort-select").addEventListener("change", renderResults);
$("#btn-export").addEventListener("click", exportResults);
$("#btn-notion").addEventListener("click", exportNotion);

function renderResults() {
  const zone = $("#results-zone");
  const grid = $("#results-grid");
  grid.replaceChildren();

  if (!OFFERS.length) {
    zone.hidden = true;
    $("#search-empty").hidden = false;
    $("#search-empty").querySelector("p").textContent =
      "Aucune offre au-dessus du score minimum. Essayez d'autres mots-clés ou baissez le score.";
    return;
  }
  zone.hidden = false;
  $("#search-empty").hidden = true;
  $("#results-count").textContent = `${OFFERS.length} offre${OFFERS.length > 1 ? "s" : ""}`;

  const mode = $("#sort-select").value;
  const sorted = [...OFFERS].sort((a, b) => {
    if (mode === "source") return a.source.localeCompare(b.source) || (b.score || 0) - (a.score || 0);
    if (mode === "company") return a.company.localeCompare(b.company);
    return (b.score || 0) - (a.score || 0);
  });

  for (const offer of sorted) grid.appendChild(offerCard(offer));
}

function offerCard(offer) {
  const score = offer.score || 0;
  const ring = el("div", { class: "score-ring", text: String(score) });
  ring.style.setProperty("--pct", score * 10);
  ring.style.setProperty("--ring", scoreColor(score));

  const badges = el("div", { class: "offer-badges" }, [
    offer.location ? el("span", { class: "badge", text: "📍 " + offer.location }) : null,
    offer.contract ? el("span", { class: "badge", text: offer.contract }) : null,
    offer.salary ? el("span", { class: "badge", text: "💰 " + offer.salary }) : null,
    el("span", { class: "badge src", text: offer.source }),
  ]);
  const statusBadge = el("span", { class: "badge status-badge", text: "" });
  badges.appendChild(statusBadge);

  // Détails repliables : atouts, lacunes, description
  const details = el("div", { class: "offer-details" }, [
    offer.strengths ? el("div", { class: "strengths", text: "✔ Vos atouts : " + offer.strengths }) : null,
    offer.gaps ? el("div", { class: "gaps", text: "△ À combler : " + offer.gaps }) : null,
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

  const btnFav = el("button", { class: "btn-ghost act-fav", text: "★" , title: "Favori" });
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
    badges,
    offer.reasons ? el("p", { class: "offer-reasons", text: offer.reasons }) : null,
    toggle,
    details,
    el("div", { class: "offer-actions" }, [openLink, btnFav, btnApplied, btnReject, btnLetter]),
  ]);

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

  async function mark(status) {
    try {
      await api("/api/track", {
        method: "POST",
        body: JSON.stringify({ job_id: SCAN_JOB, indices: [offer.index], status }),
      });
      applyStatus(status);
    } catch (e) {
      toast(e.message, "err");
    }
  }
  btnFav.addEventListener("click", () => mark(offer.status === "favorite" ? "seen" : "favorite"));
  btnApplied.addEventListener("click", () => mark(offer.status === "applied" ? "seen" : "applied"));
  btnReject.addEventListener("click", () => mark(offer.status === "rejected" ? "seen" : "rejected"));
  btnLetter.addEventListener("click", () => openLetterModal(offer, applyStatus));

  return card;
}

async function exportResults() {
  try {
    const out = await api("/api/export", { method: "POST", body: JSON.stringify({ job_id: SCAN_JOB }) });
    for (const f of [out.csv_file, out.json_file]) {
      const a = el("a", { href: `/api/download?file=${encodeURIComponent(f)}`, download: f });
      document.body.appendChild(a);
      a.click();
      a.remove();
    }
    toast("Export CSV + JSON téléchargé.", "ok");
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

// ─── Modale lettre ──────────────────────────────────────────────────────────

let LETTER_TONE = "standard";
let LETTER_OFFER = null;
let LETTER_APPLY_STATUS = null;

function openLetterModal(offer, applyStatus) {
  LETTER_OFFER = offer;
  LETTER_APPLY_STATUS = applyStatus;
  $("#modal-title").textContent = `Lettre — ${offer.title} · ${offer.company}`;
  $("#letter-config").hidden = false;
  $("#letter-loading").hidden = true;
  $("#letter-result").hidden = true;

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

$("#modal-close").addEventListener("click", () => ($("#modal-overlay").hidden = true));
$("#modal-overlay").addEventListener("click", (e) => {
  if (e.target === $("#modal-overlay")) $("#modal-overlay").hidden = true;
});

$("#btn-generate-letter").addEventListener("click", async () => {
  $("#letter-config").hidden = true;
  $("#letter-loading").hidden = false;
  let out;
  try {
    out = await api("/api/letter", {
      method: "POST",
      body: JSON.stringify({ job_id: SCAN_JOB, index: LETTER_OFFER.index, tone: LETTER_TONE }),
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
    $("#letter-subject").textContent = r.email_subject || "—";
    $("#letter-email").textContent = r.email_body || "—";
    $("#letter-body").value = r.letter;
    $("#letter-dl-txt").href = `/api/download?file=${encodeURIComponent(r.txt_file)}`;
    if (r.pdf_file) {
      $("#letter-dl-pdf").hidden = false;
      $("#letter-dl-pdf").href = `/api/download?file=${encodeURIComponent(r.pdf_file)}`;
    } else {
      $("#letter-dl-pdf").hidden = true;
    }
    $("#letter-result").hidden = false;
    if (LETTER_APPLY_STATUS) LETTER_APPLY_STATUS("applied");
    const lang = r.language === "en" ? " (offre en anglais → cover letter EN)" : "";
    toast(`Lettre générée${lang} — offre marquée postulée. Vous pouvez l'éditer avant export.`, "ok");
  }, 900);
}

// Édition de la lettre : réécrit le .txt et le .pdf, sans appel IA
$("#btn-letter-save").addEventListener("click", async () => {
  if (!LETTER_OFFER) return;
  try {
    const out = await api("/api/letter-save", {
      method: "POST",
      body: JSON.stringify({
        job_id: SCAN_JOB,
        index: LETTER_OFFER.index,
        letter: $("#letter-body").value,
        email_subject: $("#letter-subject").textContent === "—" ? "" : $("#letter-subject").textContent,
        email_body: $("#letter-email").textContent === "—" ? "" : $("#letter-email").textContent,
      }),
    });
    $("#letter-dl-txt").href = `/api/download?file=${encodeURIComponent(out.txt_file)}`;
    if (out.pdf_file) {
      $("#letter-dl-pdf").hidden = false;
      $("#letter-dl-pdf").href = `/api/download?file=${encodeURIComponent(out.pdf_file)}`;
    }
    toast("Modifications enregistrées (txt + PDF régénérés).", "ok");
  } catch (e) {
    toast(e.message, "err");
  }
});

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
  if (!data.sessions.length) {
    list.appendChild(el("div", { class: "empty-state" }, [
      el("div", { class: "empty-icon", text: "🕘" }),
      el("p", { text: "Aucune session pour l'instant — chaque recherche sera enregistrée ici avec ses critères et ses scores." }),
    ]));
  }
  const kindLabels = { web: "Web", scan: "CLI", watch: "Veille", rescore: "Re-scoring" };
  for (const s of data.sessions) {
    const btnView = el("button", { class: "btn-ghost small", text: "Voir les offres" });
    btnView.addEventListener("click", () => loadSession(s.id));
    const btnRerun = el("button", { class: "btn-ghost small", text: "↻ Relancer" });
    btnRerun.addEventListener("click", () => {
      applyCriteria(s.criteria);
      switchTab("search");
      toast("Critères repris — lancez la recherche quand vous êtes prêt.", "ok");
    });
    if (s.kind === "rescore") btnRerun.hidden = true;
    list.appendChild(el("div", { class: "card session-item" }, [
      el("div", { class: "session-main" }, [
        el("div", { class: "session-title" }, [
          el("strong", { text: s.criteria.query || "(re-scoring de la base)" }),
          el("span", { class: "badge src", text: kindLabels[s.kind] || s.kind }),
        ]),
        el("div", { class: "session-meta muted small", text:
          `${s.date.replace("T", " ").slice(0, 16)} · ${s.summary} · ` +
          `${s.kept} offre(s) retenue(s) sur ${s.found}` }),
      ]),
      el("div", { class: "session-actions" }, [btnView, btnRerun]),
    ]));
  }

  $("#count-letters").textContent = data.letters.length;
  const lettersBox = $("#letters-list");
  lettersBox.replaceChildren();
  if (!data.letters.length) {
    lettersBox.appendChild(el("div", { class: "muted small", text: "Aucune lettre générée pour l'instant." }));
  }
  for (const letter of data.letters) {
    const actions = el("div", { class: "ti-actions" });
    for (const [file, label] of [[letter.txt_file, "⬇ .txt"], [letter.pdf_file, "⬇ .pdf"]]) {
      if (file) actions.appendChild(el("a", {
        class: "btn-ghost", text: label, download: file,
        href: `/api/download?file=${encodeURIComponent(file)}`,
      }));
    }
    lettersBox.appendChild(el("div", { class: "track-item" }, [
      el("div", { class: "ti-title", text: letter.title || "—" }),
      el("div", { class: "ti-meta" }, [
        el("span", { text: letter.company || "—" }),
        el("span", { text: letter.date.replace("T", " ").slice(0, 16) }),
        el("span", { text: `ton ${letter.tone}` }),
        el("span", { text: letter.language === "en" ? "🇬🇧 EN" : "🇫🇷 FR" }),
      ]),
      actions,
    ]));
  }
}

async function loadSession(id) {
  let out;
  try {
    out = await api("/api/session-load", { method: "POST", body: JSON.stringify({ id }) });
  } catch (e) {
    toast(e.message, "err");
    return;
  }
  SCAN_JOB = out.job_id;
  OFFERS = out.offers;
  switchTab("search");
  $("#scan-progress").hidden = true;
  renderResults();
  const when = out.date ? out.date.replace("T", " ").slice(0, 16) : "";
  toast(`Session du ${when} rechargée (${OFFERS.length} offre(s), scores de l'époque).`
    + (out.letters_available ? "" : " CV introuvable : lettres indisponibles."), "ok");
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
      btn.addEventListener("click", async () => {
        try {
          await api("/api/track-key", { method: "POST", body: JSON.stringify({ key: entry.key, status: act.status }) });
          loadTrack();
        } catch (e) {
          toast(e.message, "err");
        }
      });
      actionBox.appendChild(btn);
    }
    box.appendChild(el("div", { class: "track-item" }, [
      el("div", { class: "ti-title", text: entry.title || "—" }),
      meta,
      actionBox,
    ]));
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

init();
