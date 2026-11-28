<script lang="ts">
  import { onMount } from "svelte";
  import { api } from "$lib/api";
  import type { SearchResults } from "$lib/types";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import { DEFAULT_AYAH_RECITER } from "$lib/constants";
  import Artwork from "$lib/components/Artwork.svelte";
  import TrackRow from "$lib/components/TrackRow.svelte";
  import Icon from "$lib/components/Icon.svelte";
  import Section from "$lib/components/Section.svelte";

  let term = $state(nav.query);
  let results = $state<SearchResults>({ reciters: [], surahs: [], tracks: [] });
  let loading = $state(false);
  let failed = $state(false);
  let retryTick = $state(0);
  let filter = $state<"all" | "quran" | "radio" | "music">("all");
  let inputEl = $state<HTMLInputElement>();

  onMount(() => inputEl?.focus());

  $effect(() => {
    void retryTick;
    const q = term.trim();
    const f = filter;
    if (!q) {
      results = { reciters: [], surahs: [], tracks: [] };
      loading = false;
      failed = false;
      return;
    }
    loading = true;
    failed = false;
    const handle = setTimeout(async () => {
      try {
        const kinds = f === "all" ? undefined : [f];
        results = await api.search(q, kinds);
        failed = false;
      } catch {
        results = { reciters: [], surahs: [], tracks: [] };
        failed = true;
      } finally {
        loading = false;
      }
    }, 320);
    return () => clearTimeout(handle);
  });

  $effect(() => {
    if (nav.query) term = nav.query;
  });

  const hasResults = $derived(
    results.reciters.length > 0 || results.surahs.length > 0 || results.tracks.length > 0,
  );

  function shortName(name: string) {
    return name.replace(/^سُورَةُ\s*/, "").replace(/^سورة\s*/, "");
  }
</script>

<div class="fade-in">
  <header>
    <h1 class="text-2xl font-bold text-text">{i18n.t("search.title")}</h1>
  </header>

  <label
    class="field mt-4 rounded-2xl px-4 py-3"
  >
    <Icon name="search" size={18} class="shrink-0 text-muted" />
    <input
      bind:this={inputEl}
      bind:value={term}
      aria-label={i18n.t("search.placeholder")}
      placeholder={i18n.t("search.placeholder")}
      class="w-full bg-transparent text-base text-text placeholder:text-muted/70 focus:outline-none"
    />
    {#if term}
      <button
        type="button"
        onclick={() => (term = "")}
        class="rounded-lg p-1 text-muted hover:bg-primary-soft/60 hover:text-text"
        aria-label={i18n.t("common.close")}
      >
        <Icon name="x" size={15} />
      </button>
    {/if}
  </label>

  <div class="mt-3 flex gap-2">
    {#each [["all", "search.filterAll"], ["quran", "search.filterQuran"], ["radio", "search.filterRadio"], ["music", "search.filterFree"]] as [value, key] (value)}
      <button
        type="button"
        onclick={() => (filter = value as "all" | "quran" | "radio" | "music")}
        class="chip"
        data-active={filter === value ? "true" : "false"}
      >
        {i18n.t(key as "search.filterAll")}
      </button>
    {/each}
  </div>

  {#if !term.trim()}
    <div class="mt-16 text-center">
      <Icon name="search" size={34} class="mx-auto text-muted/60" />
      <p class="mt-3 text-sm text-muted">{i18n.t("search.hint")}</p>
    </div>
  {:else if failed}
    <div class="card mt-12 rounded-2xl px-5 py-6 text-center">
      <p class="text-sm text-muted">{i18n.t("common.offline")}</p>
      <button
        type="button"
        onclick={() => (retryTick += 1)}
        class="btn btn-outline mt-3"
      >
        {i18n.t("common.retry")}
      </button>
    </div>
  {:else if loading}
    <div class="mt-8 space-y-1">
      {#each Array(6) as _, i (i)}
        <div class="flex animate-pulse items-center gap-3 px-2.5 py-2">
          <div class="size-11 rounded-lg bg-primary-soft"></div>
          <div class="h-3 w-52 rounded bg-primary-soft"></div>
        </div>
      {/each}
    </div>
  {:else if !hasResults}
    <div class="mt-16 text-center">
      <Icon name="search" size={34} class="mx-auto text-muted/60" />
      <p class="mt-3 text-sm text-muted">{i18n.t("search.empty")}</p>
    </div>
  {:else}
    {#if results.surahs.length}
      <Section title={i18n.t("search.surahs")}>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-4">
          {#each results.surahs as surah (surah.number)}
            <button
              type="button"
              onclick={() =>
                nav.go("quran", "ayah", DEFAULT_AYAH_RECITER, surah.number)}
              class="group flex items-center gap-3 rounded-xl border border-line bg-surface p-2.5 text-start shadow-card transition-colors hover:border-primary/35 hover:bg-primary-soft/30"
            >
              <span
                class="grid size-11 shrink-0 place-items-center rounded-xl border border-line font-quran text-sm tabular-nums text-accent-ink group-hover:border-primary/35"
              >
                {fmtNumber(surah.number)}
              </span>
              <div class="min-w-0 flex-1">
                <div class="truncate font-quran text-base text-text group-hover:text-primary">
                  {shortName(surah.name)}
                </div>
                <div class="truncate text-[11px] text-muted">
                  {surah.englishName} · {fmtNumber(surah.ayahs)} {i18n.t("quran.ayahs")}
                </div>
              </div>
            </button>
          {/each}
        </div>
      </Section>
    {/if}

    {#if results.reciters.length}
      <Section title={i18n.t("search.reciters")}>
        <div class="grid grid-cols-2 gap-3 sm:grid-cols-3 xl:grid-cols-4">
          {#each results.reciters as reciter (reciter.id)}
            <button
              type="button"
              onclick={() => nav.go("quran", reciter.id)}
              class="group flex items-center gap-3 rounded-xl border border-line bg-surface p-2.5 text-start shadow-card transition-colors hover:border-primary/35 hover:bg-primary-soft/30"
            >
              <Artwork
                seed={reciter.name}
                kind="quran"
                initials
                class="size-11 shrink-0"
                rounded="rounded-xl"
              />
              <div class="min-w-0 flex-1">
                <div class="truncate font-quran text-base text-text group-hover:text-primary">
                  {reciter.name}
                </div>
                <div class="truncate text-[11px] text-muted">{reciter.moshafs[0]?.name ?? ""}</div>
              </div>
            </button>
          {/each}
        </div>
      </Section>
    {/if}

    {#if results.tracks.length}
      <Section title={i18n.t("search.tracks")}>
        <div class="card overflow-hidden rounded-2xl p-1.5">
          {#each results.tracks as track (track.id)}
            <TrackRow {track} queue={results.tracks} />
          {/each}
        </div>
      </Section>
    {/if}
  {/if}
</div>
