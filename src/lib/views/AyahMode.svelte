<script lang="ts">
  import { onMount } from "svelte";
  import { api } from "$lib/api";
  import type { AyahReciter, Surah } from "$lib/types";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { normalizeArabic } from "$lib/text";
  import Artwork from "$lib/components/Artwork.svelte";
  import Icon from "$lib/components/Icon.svelte";
  import AyahPlayer from "./AyahPlayer.svelte";

  let reciters = $state<AyahReciter[]>([]);
  let surahs = $state<Surah[]>([]);
  let memorised = $state<Record<number, number>>({});
  let loading = $state(true);
  let filter = $state("");

  const reciterId = $derived(nav.params[1] ?? null);
  const surahNumber = $derived(nav.params[2] ? Number(nav.params[2]) : null);
  const reciter = $derived(reciters.find((r) => r.id === reciterId) ?? null);
  const surah = $derived(surahs.find((s) => s.number === surahNumber) ?? null);

  const visibleReciters = $derived(
    filter.trim()
      ? reciters.filter((r) => {
          const q = normalizeArabic(filter);
          return (
            normalizeArabic(r.name).includes(q) ||
            r.english.toLowerCase().includes(q) ||
            r.id.toLowerCase().includes(q)
          );
        })
      : reciters,
  );

  const visibleSurahs = $derived(
    filter.trim()
      ? surahs.filter((s) => {
          const q = normalizeArabic(filter);
          return (
            normalizeArabic(s.name).includes(q) ||
            s.englishName.toLowerCase().includes(q) ||
            String(s.number) === filter.trim()
          );
        })
      : surahs,
  );

  onMount(async () => {
    const [r, s, m] = await Promise.allSettled([
      api.ayahReciters(),
      api.surahs(),
      api.memorization(),
    ]);
    if (r.status === "fulfilled") reciters = r.value;
    if (s.status === "fulfilled") surahs = s.value;
    if (m.status === "fulfilled") {
      const counts: Record<number, number> = {};
      for (const row of m.value) counts[row.surah] = row.memorized.length;
      memorised = counts;
    }
    loading = false;
  });

  // Coming back from a surah should show fresh memorisation counts.
  $effect(() => {
    if (nav.params.length !== 2) return;
    void refreshCounts();
  });

  async function refreshCounts() {
    const rows = await api.memorization().catch(() => null);
    if (!rows) return;
    const counts: Record<number, number> = {};
    for (const row of rows) counts[row.surah] = row.memorized.length;
    memorised = counts;
  }

  function shortName(name: string) {
    return name.replace(/^سُورَةُ\s*/, "").replace(/^سورة\s*/, "");
  }

  function openSurah(n: number) {
    if (reciter) nav.go("quran", "ayah", reciter.id, n);
  }
</script>

{#if reciter && surah && surahNumber}
  <AyahPlayer {reciter} {surah} />
{:else if reciter}
  <div class="fade-in">
    <button
      type="button"
      onclick={() => nav.go("quran", "ayah")}
      class="mb-5 flex items-center gap-1.5 text-xs text-muted transition-colors hover:text-primary"
    >
      <Icon name="chevron" size={13} class="rotate-180 rtl:rotate-0" />
      {i18n.t("quran.chooseAyahReciter")}
    </button>

    <header class="flex flex-wrap items-center gap-5">
      <Artwork
        seed={reciter.name}
        kind="quran"
        initials
        class="size-24 shrink-0 shadow-card"
        rounded="rounded-3xl"
      />
      <div class="min-w-0 flex-1">
        <p class="text-[10px] font-bold uppercase tracking-[0.22em] text-accent-ink">
          {i18n.t("quran.byAyah")}
        </p>
        <h1 class="mt-1 truncate pb-1 font-quran text-3xl leading-[1.5] text-text">
          {reciter.name}
        </h1>
        <p class="mt-1 text-xs text-muted">
          {reciter.style} · {reciter.bitrate} kbps · {fmtNumber(114)} {i18n.t("quran.surah")}
        </p>
      </div>
    </header>

    <label
      class="field mt-5 max-w-sm"
    >
      <Icon name="search" size={15} class="text-muted" />
      <input
        bind:value={filter}
        aria-label={i18n.t("quran.searchReciter")}
        placeholder={i18n.t("quran.searchReciter")}
        class="w-full bg-transparent text-sm text-text placeholder:text-muted/70 focus:outline-none"
      />
    </label>

    {#if loading}
      <div class="card mt-6 overflow-hidden rounded-2xl">
        {#each Array(10) as _, i (i)}
          <div class="flex animate-pulse items-center gap-3 border-b border-line/50 px-4 py-3 last:border-0">
            <div class="size-9 rounded-lg bg-primary-soft"></div>
            <div class="h-3 w-40 rounded bg-primary-soft"></div>
          </div>
        {/each}
      </div>
    {:else}
      <div class="card mt-6 overflow-hidden rounded-2xl">
        {#each visibleSurahs as s (s.number)}
          {@const done = memorised[s.number] ?? 0}
          {@const pct = s.ayahs > 0 ? Math.round((done / s.ayahs) * 100) : 0}
          <button
            type="button"
            onclick={() => openSurah(s.number)}
            class="group flex w-full items-center gap-3 border-b border-line/50 px-4 py-2.5 text-start transition-colors last:border-0 hover:bg-primary-soft/35"
          >
            <span
              class="grid size-9 shrink-0 place-items-center rounded-lg border border-line text-[11px] tabular-nums text-muted transition-colors group-hover:border-primary/30 group-hover:text-primary"
            >
              {fmtNumber(s.number)}
            </span>
            <span class="min-w-0 flex-1">
              <span class="block truncate font-quran text-[1.05rem] leading-snug text-text group-hover:text-primary">
                {shortName(s.name)}
              </span>
              <span class="block truncate text-[11px] text-muted">
                {s.englishName} · {fmtNumber(s.ayahs)} {i18n.t("quran.ayahs")}
              </span>
            </span>
            {#if done > 0}
              <span class="flex shrink-0 items-center gap-1.5 text-[10px] text-accent-ink">
                <span class="h-1 w-10 overflow-hidden rounded-full bg-line">
                  <span class="block h-full rounded-full bg-accent" style="width: {pct}%"></span>
                </span>
                {fmtNumber(done)}
              </span>
            {/if}
            <Icon
              name="chevron"
              size={13}
              class="shrink-0 text-muted opacity-0 transition-opacity group-hover:opacity-100"
            />
          </button>
        {/each}
      </div>
    {/if}
  </div>
{:else}
  <div class="fade-in">
    <header>
      <p class="text-[10px] font-bold uppercase tracking-[0.22em] text-accent-ink">
        {i18n.t("quran.byAyah")}
      </p>
      <h1 class="mt-1 text-2xl font-bold text-text">{i18n.t("quran.chooseAyahReciter")}</h1>
      <p class="mt-1 text-xs text-muted">{i18n.t("quran.ayahSubtitle")}</p>
      <label
        class="field mt-5 max-w-sm"
      >
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
        {#each Array(8) as _, i (i)}
          <div class="animate-pulse">
            <div class="aspect-square rounded-2xl bg-primary-soft"></div>
            <div class="mt-2 h-3 w-3/4 rounded bg-primary-soft"></div>
          </div>
        {/each}
      </div>
    {:else if visibleReciters.length === 0}
      <p class="mt-10 text-sm text-muted">{i18n.t("search.empty")}</p>
    {:else}
      <div class="mt-7 grid grid-cols-2 gap-x-4 gap-y-6 sm:grid-cols-4 lg:grid-cols-6 xl:grid-cols-8">
        {#each visibleReciters as r (r.id)}
          <button
            type="button"
            onclick={() => nav.go("quran", "ayah", r.id)}
            class="group text-start"
          >
            <div class="relative">
              <Artwork
                seed={r.name}
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
              {r.name}
            </div>
            <div class="truncate text-[11px] text-muted">
              {r.style} · {r.bitrate} kbps
            </div>
          </button>
        {/each}
      </div>
    {/if}
  </div>
{/if}
