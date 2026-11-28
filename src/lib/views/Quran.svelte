<script lang="ts">
  import { onMount } from "svelte";
  import { api, isTauri } from "$lib/api";
  import type { Reciter, Surah, Track } from "$lib/types";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import { library } from "$lib/stores/library.svelte.ts";
  import { normalizeArabic } from "$lib/text";
  import Artwork from "$lib/components/Artwork.svelte";
  import Icon from "$lib/components/Icon.svelte";
  import AyahMode from "./AyahMode.svelte";

  let reciters = $state<Reciter[]>([]);
  let surahs = $state<Surah[]>([]);
  let tracks = $state<Track[]>([]);
  let loading = $state(true);
  let loadError = $state(false);
  let loadingTracks = $state(false);
  let filter = $state("");
  let selectedId = $state<number | null>(null);
  let moshafId = $state<number | null>(null);
  let booted = $state(false);

  const surahMap = $derived(new Map(surahs.map((s) => [s.number, s])));
  const selected = $derived(reciters.find((r) => r.id === selectedId) ?? null);
  const moshaf = $derived(
    selected?.moshafs.find((m) => m.id === moshafId) ?? selected?.moshafs[0] ?? null,
  );

  const visibleReciters = $derived(
    filter.trim()
      ? reciters.filter((r) => {
          const q = normalizeArabic(filter);
          return normalizeArabic(r.name).includes(q) || normalizeArabic(r.letter) === q;
        })
      : reciters,
  );

  const rows = $derived(
    tracks
      .map((track, i) => {
        const number = moshaf?.surahs[i];
        const surah = number ? surahMap.get(number) : undefined;
        return surah ? { track, surah } : null;
      })
      .filter((x): x is { track: Track; surah: Surah } => x !== null),
  );

  async function loadCatalogue() {
    loading = true;
    loadError = false;
    const [r, s] = await Promise.allSettled([api.reciters(), api.surahs()]);
    if (r.status === "fulfilled") reciters = r.value;
    if (s.status === "fulfilled") surahs = s.value;
    loadError = r.status === "rejected";
    loading = false;
  }

  onMount(async () => {
    await loadCatalogue();
    booted = true;
    if (nav.param) await openReciter(Number(nav.param));
  });

  $effect(() => {
    if (!booted) return;
    if (nav.params[0] === "ayah") return;
    const p = nav.param;
    if (!p) {
      selectedId = null;
      tracks = [];
      return;
    }
    const id = Number(p);
    if (!Number.isNaN(id) && id !== selectedId) void openReciter(id);
  });

  async function openReciter(id: number) {
    const reciter = reciters.find((r) => r.id === id);
    if (!reciter) return;
    selectedId = id;
    moshafId = reciter.moshafs[0]?.id ?? null;
    await loadTracks();
  }

  async function loadTracks() {
    if (selectedId === null) return;
    loadingTracks = true;
    try {
      tracks = await api.moshafTracks(selectedId, moshafId ?? undefined);
    } catch {
      tracks = [];
    } finally {
      loadingTracks = false;
    }
  }

  async function chooseMoshaf(id: number) {
    if (id === moshafId) return;
    moshafId = id;
    await loadTracks();
  }

  function shortName(name: string) {
    return name.replace(/^سُورَةُ\s*/, "").replace(/^سورة\s*/, "");
  }

  function play(track: Track) {
    player.play(track, tracks);
  }

  function playAll() {
    if (tracks.length) player.play(tracks[0], tracks);
  }

  async function downloadAll() {
    if (!tracks.length || loadingTracks) return;
    if (tracks.length > 20) {
      const message = i18n.t("quran.downloadAllConfirm", { count: fmtNumber(tracks.length) });
      let confirmed = false;
      if (isTauri) {
        const { ask } = await import("@tauri-apps/plugin-dialog");
        confirmed = await ask(message, { kind: "warning" });
      } else {
        confirmed = window.confirm(message);
      }
      if (!confirmed) return;
    }
    await library.startDownloads(tracks);
  }
</script>

<div class="fade-in">
  <div class="mb-6 inline-flex rounded-xl border border-line bg-surface p-1 shadow-card">
    <button
      type="button"
      onclick={() => nav.go("quran")}
      class="rounded-lg px-3 py-1.5 text-xs font-medium transition-colors
             {nav.params[0] !== 'ayah' ? 'bg-primary-soft font-semibold text-primary' : 'text-muted hover:text-text'}"
    >
      {i18n.t("quran.fullSurah")}
    </button>
    <button
      type="button"
      onclick={() => nav.go("quran", "ayah")}
      class="rounded-lg px-3 py-1.5 text-xs font-medium transition-colors
             {nav.params[0] === 'ayah' ? 'bg-primary-soft font-semibold text-primary' : 'text-muted hover:text-text'}"
    >
      {i18n.t("quran.byAyah")}
    </button>
  </div>

  {#if nav.params[0] === "ayah"}
    <AyahMode />
  {:else if selected}
    <!-- Reciter header -->
    <button
      type="button"
      onclick={() => nav.go("quran")}
      class="mb-5 flex items-center gap-1.5 text-xs text-muted transition-colors hover:text-primary"
    >
      <Icon name="chevron" size={13} class="rotate-180 rtl:rotate-0" />
      {i18n.t("quran.backToReciters")}
    </button>

    <header class="flex flex-wrap items-center gap-5">
      <Artwork
        seed={selected.name}
        kind="quran"
        initials
        class="size-24 shrink-0 shadow-card"
        rounded="rounded-3xl"
      />
      <div class="min-w-0 flex-1">
        <p class="text-[10px] font-bold uppercase tracking-[0.22em] text-accent-ink">
          {i18n.t("quran.title")}
        </p>
        <h1 class="mt-1 truncate pb-1 font-quran text-3xl leading-[1.5] text-text">{selected.name}</h1>
        <p class="mt-1 text-xs text-muted">
          {moshaf?.name} · {fmtNumber(moshaf?.surahTotal ?? 0)} {i18n.t("quran.surah")}
        </p>
      </div>
      <button
        type="button"
        onclick={playAll}
        class="btn btn-primary"
      >
        <Icon name="play" size={14} />
        {i18n.t("quran.playAll")}
      </button>
      <button
        type="button"
        onclick={downloadAll}
        disabled={!tracks.length || loadingTracks}
        class="btn btn-outline"
        title={i18n.t("library.downloadAll")}
      >
        <Icon name="download" size={14} />
        {i18n.t("library.downloadAll")}
      </button>
    </header>

    {#if selected.moshafs.length > 1}
      <div class="mt-5 flex flex-wrap gap-2">
        {#each selected.moshafs as m (m.id)}
          <button
            type="button"
            onclick={() => chooseMoshaf(m.id)}
            class="rounded-full border px-3 py-1.5 text-[11px] transition-colors
                   {m.id === moshaf?.id
              ? 'border-primary/35 bg-primary-soft font-semibold text-primary'
              : 'border-line text-muted hover:border-primary/30 hover:text-text'}"
          >
            {m.name}
          </button>
        {/each}
      </div>
    {/if}

    <div class="card mt-6 overflow-hidden rounded-2xl">
      {#if loadingTracks}
        <div class="divide-y divide-line/60">
          {#each Array(10) as _, i (i)}
            <div class="flex animate-pulse items-center gap-3 px-4 py-3">
              <div class="size-9 rounded-lg bg-primary-soft"></div>
              <div class="h-3 w-40 rounded bg-primary-soft"></div>
            </div>
          {/each}
        </div>
      {:else}
        {#each rows as row, i (row.surah.number)}
          {@const active = player.current?.id === row.track.id}
          {@const dl = library.downloadFor(row.track.id)}
          <div
            class="group flex w-full items-center gap-3 border-b border-line/50 px-4 py-2.5 transition-colors last:border-0
                   {active ? 'bg-primary-soft' : 'hover:bg-primary-soft/35'}"
          >
            <button
              type="button"
              onclick={() => play(row.track)}
              class="flex min-w-0 flex-1 items-center gap-3 text-start"
            >
              <span
                class="grid size-9 shrink-0 place-items-center rounded-lg border text-[11px] tabular-nums transition-colors
                       {active
                  ? 'border-primary/40 bg-primary-soft text-primary'
                  : 'border-line text-muted group-hover:border-primary/30 group-hover:text-primary'}"
              >
                {#if active && player.playing}
                  <div class="eq"><i></i><i></i><i></i><i></i></div>
                {:else}
                  {fmtNumber(row.surah.number)}
                {/if}
              </span>
              <span class="min-w-0 flex-1">
                <span class="block truncate font-quran text-[1.05rem] leading-snug {active ? 'text-primary' : 'text-text'}">
                  {shortName(row.surah.name)}
                </span>
                <span class="block truncate text-[11px] text-muted">
                  {row.surah.englishName} · {fmtNumber(row.surah.ayahs)} {i18n.t("quran.ayahs")}
                </span>
              </span>
              <span
                class="hidden shrink-0 rounded-md border border-line px-1.5 py-0.5 text-[10px] text-muted sm:block"
              >
                {i18n.t(row.surah.revelation === "makkah" ? "quran.makkah" : "quran.madinah")}
              </span>
            </button>

            <div class="flex shrink-0 items-center gap-0.5">
              <button
                type="button"
                onclick={() => library.startDownload(row.track)}
                disabled={dl?.status === "queued" || dl?.status === "downloading"}
                title={dl?.status === "done"
                  ? i18n.t("library.downloaded")
                  : i18n.t("library.download")}
                aria-label={i18n.t("library.download")}
                class="rounded-lg p-1.5 transition-colors
                       {dl?.status === 'done'
                  ? 'text-primary'
                  : dl?.status === 'error'
                    ? 'text-red-500'
                    : dl
                      ? 'text-accent-ink'
                      : 'text-muted opacity-0 group-hover:opacity-100 focus-visible:opacity-100 hover:text-text'}"
              >
                {#if dl?.status === "queued" || dl?.status === "downloading"}
                  <span class="size-3.5 animate-spin rounded-full border border-accent/30 border-t-accent"></span>
                {:else if dl?.status === "done"}
                  <Icon name="check" size={13} />
                {:else}
                  <Icon name="download" size={13} />
                {/if}
              </button>
              <Icon
                name="play"
                size={13}
                class="text-muted opacity-0 transition-opacity group-hover:opacity-100"
              />
            </div>
          </div>
        {/each}
      {/if}
    </div>
  {:else}
    <header>
      <p class="text-[10px] font-bold uppercase tracking-[0.22em] text-accent-ink">
        {i18n.t("quran.chooseReciter")}
      </p>
      <h1 class="mt-1 text-2xl font-bold text-text">{i18n.t("quran.title")}</h1>
      <p class="mt-1 text-xs text-muted">{i18n.t("quran.subtitle")}</p>
      <label class="field mt-5 max-w-sm">
        <Icon name="search" size={15} class="text-muted" />
        <input
          bind:value={filter}
          aria-label={i18n.t("quran.searchReciter")}
          placeholder={i18n.t("quran.searchReciter")}
          class="w-full bg-transparent text-sm text-text placeholder:text-muted/70 focus:outline-none"
        />
      </label>
    </header>

    {#if loading}
      <div class="mt-7 grid grid-cols-2 gap-4 sm:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8">
        {#each Array(16) as _, i (i)}
          <div class="animate-pulse">
            <div class="aspect-square rounded-2xl bg-primary-soft"></div>
            <div class="mt-2 h-3 w-3/4 rounded bg-primary-soft"></div>
          </div>
        {/each}
      </div>
    {:else if loadError}
      <div class="card mt-10 rounded-2xl px-5 py-6 text-center">
        <p class="text-sm text-muted">{i18n.t("common.offline")}</p>
        <button
          type="button"
          onclick={() => loadCatalogue()}
          class="btn btn-outline mt-3"
        >
          {i18n.t("common.retry")}
        </button>
      </div>
    {:else if visibleReciters.length === 0}
      <p class="mt-10 text-sm text-muted">{i18n.t("search.empty")}</p>
    {:else}
      <div class="mt-7 grid grid-cols-2 gap-x-4 gap-y-6 sm:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8">
        {#each visibleReciters as reciter (reciter.id)}
          <button
            type="button"
            onclick={() => nav.go("quran", reciter.id)}
            class="group text-start"
          >
            <div class="relative">
              <Artwork
                seed={reciter.name}
                kind="quran"
                initials
                class="aspect-square w-full transition-transform duration-200 group-hover:-translate-y-0.5"
                rounded="rounded-2xl"
              />
              <div
                class="absolute inset-0 grid place-items-center rounded-2xl bg-canvas/40 opacity-0 transition-opacity group-hover:opacity-100"
              >
                <span class="grid size-9 place-items-center rounded-full bg-accent text-canvas shadow-card">
                  <Icon name="play" size={13} />
                </span>
              </div>
            </div>
            <div class="mt-2 truncate text-[0.83rem] font-medium text-text group-hover:text-primary">
              {reciter.name}
            </div>
            <div class="truncate text-[11px] text-muted">{reciter.moshafs[0]?.name ?? ""}</div>
          </button>
        {/each}
      </div>
    {/if}
  {/if}
</div>
