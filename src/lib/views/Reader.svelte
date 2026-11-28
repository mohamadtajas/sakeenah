<script lang="ts">
  import { onMount, tick } from "svelte";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import type { TranslationKey } from "$lib/i18n/dict";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { reader } from "$lib/stores/reader.svelte.ts";
  import { normalizeArabic } from "$lib/text";
  import type { Ayah, QuranBookmark, Surah } from "$lib/types";
  import AyahRow from "$lib/components/AyahRow.svelte";
  import Icon from "$lib/components/Icon.svelte";

  let tab = $state<"surahs" | "juzs" | "bookmarks">("surahs");
  let query = $state("");
  let lastRoute = "";
  let mainEl: HTMLElement | null = null;
  let scrollTimer: ReturnType<typeof setTimeout> | null = null;
  let lastVisible = "";

  const tabs = [
    { id: "surahs" as const, label: "reader.surahs" as const, icon: "bookOpen" as const },
    { id: "juzs" as const, label: "reader.juzs" as const, icon: "list" as const },
    { id: "bookmarks" as const, label: "reader.bookmarks" as const, icon: "bookmark" as const },
  ];

  const filteredSurahs = $derived.by(() => {
    const needle = normalizeArabic(query);
    if (!needle) return reader.surahs;
    return reader.surahs.filter(
      (surah) =>
        normalizeArabic(surah.name).includes(needle) ||
        surah.englishName.toLowerCase().includes(needle) ||
        String(surah.number) === query.trim(),
    );
  });

  const juzGroups = $derived.by(() => {
    if (reader.mode !== "juz") return [];
    const groups: { surah: Surah; ayahs: Ayah[] }[] = [];
    for (const ayah of reader.ayahs) {
      const meta = reader.surahs.find((surah) => surah.number === ayah.surah);
      if (!meta) continue;
      let group = groups[groups.length - 1];
      if (!group || group.surah.number !== meta.number) {
        group = { surah: meta, ayahs: [] };
        groups.push(group);
      }
      group.ayahs.push(ayah);
    }
    return groups;
  });

  // Keep the reader in sync with the hash (surah, juz and daily-ayah deep links).
  $effect(() => {
    if (nav.view !== "reader") return;
    const key = `reader:${nav.params.join("/")}`;
    if (key === lastRoute) return;
    lastRoute = key;
    void boot();
  });

  // Scroll to the target ayah after it renders.
  $effect(() => {
    const target = reader.scrollTarget;
    if (!target) return;
    void (async () => {
      await tick();
      document
        .getElementById(`ayah-${target.surah}-${target.ayah}`)
        ?.scrollIntoView({ behavior: "smooth", block: "center" });
      reader.clearScrollTarget();
    })();
  });

  // Remember the first ayah the reader is looking at, not just explicit clicks.
  onMount(() => {
    mainEl = document.querySelector("main");
    const onScroll = () => {
      if (scrollTimer) return;
      scrollTimer = setTimeout(() => {
        scrollTimer = null;
        saveVisible();
      }, 250);
    };
    mainEl?.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll);
    return () => {
      mainEl?.removeEventListener("scroll", onScroll);
      window.removeEventListener("resize", onScroll);
      if (scrollTimer) clearTimeout(scrollTimer);
    };
  });

  $effect(() => {
    reader.ayahs;
    reader.mode;
    reader.juz;
    void tick().then(() => saveVisible());
  });

  function saveVisible() {
    if (!mainEl || reader.loading || !reader.ayahs.length) return;
    const top = mainEl.getBoundingClientRect().top + 80;
    for (const element of mainEl.querySelectorAll<HTMLElement>('[id^="ayah-"]')) {
      const rect = element.getBoundingClientRect();
      if (rect.bottom <= top) continue;
      const [, surah, ayah] = element.id.split("-");
      if (!surah || !ayah) return;
      const key = `${surah}:${ayah}`;
      if (key !== lastVisible) {
        lastVisible = key;
        void reader.savePosition(Number(surah), Number(ayah));
      }
      return;
    }
  }

  async function boot() {
    if (!reader.surahs.length) await reader.loadIndex();
    if (nav.view !== "reader") return;

    const [first, second] = nav.params;
    if (first === "juz") {
      const number = Number(second);
      if (number >= 1 && number <= 30) {
        await reader.openJuz(number);
        return;
      }
    }

    const surah = Number(first);
    if (Number.isInteger(surah) && surah >= 1 && surah <= 114) {
      const ayah = Number(second);
      await reader.openSurah(
        surah,
        Number.isInteger(ayah) && ayah > 0 ? ayah : undefined,
      );
      return;
    }

    if (reader.position) {
      if (reader.position.mode === "juz" && reader.position.juz) {
        await reader.openJuz(reader.position.juz, {
          surah: reader.position.surah,
          ayah: reader.position.ayah,
        });
      } else {
        await reader.openSurah(reader.position.surah, reader.position.ayah);
      }
      return;
    }
    await reader.openSurah(1);
  }

  function openSurah(number: number) {
    if (reader.mode === "surah" && reader.surah === number) {
      mainEl?.scrollTo({ top: 0, behavior: "smooth" });
      reader.clearScrollTarget();
      return;
    }
    nav.go("reader", number);
  }

  function openJuz(number: number) {
    if (reader.mode === "juz" && reader.juz === number) {
      mainEl?.scrollTo({ top: 0, behavior: "smooth" });
      reader.clearScrollTarget();
      return;
    }
    nav.go("reader", "juz", number);
  }

  function openBookmark(bookmark: QuranBookmark) {
    nav.go("reader", bookmark.surah, bookmark.ayah);
  }

  function surahName(number?: number) {
    return reader.surahs.find((surah) => surah.number === number)?.name ?? "";
  }

  function revelation(meta: Surah | null) {
    if (!meta) return "";
    return i18n.t(meta.revelation === "makkah" ? "quran.makkah" : "quran.madinah");
  }

  function basmalaFor(ayah: Ayah | undefined) {
    return ayah?.bismillah ?? "";
  }
</script>

<div class="fade-in">
  <header class="flex flex-wrap items-start justify-between gap-4">
    <div>
      <p class="text-[10px] font-bold uppercase tracking-[0.24em] text-accent-ink">{i18n.t("app.name")}</p>
      <h1 class="mt-1 text-2xl font-bold text-text">{i18n.t("reader.title")}</h1>
      <p class="mt-1 text-sm text-muted">{i18n.t("reader.subtitle")}</p>
    </div>

    <div class="flex flex-wrap items-center gap-2">
      <div class="flex items-center gap-1 rounded-xl border border-line bg-surface p-1 shadow-card">
        <button
          type="button"
          onclick={() => reader.setFontSize(reader.fontSize - 2)}
          disabled={reader.fontSize <= 20}
          aria-label={i18n.t("reader.fontSmaller")}
          class="grid size-8 place-items-center rounded-lg text-sm font-semibold text-muted transition-colors hover:bg-primary-soft/60 hover:text-primary disabled:opacity-35"
        >
          أ−
        </button>
        <span class="w-8 text-center text-[10px] tabular-nums text-muted">
          {fmtNumber(reader.fontSize)}
        </span>
        <button
          type="button"
          onclick={() => reader.setFontSize(reader.fontSize + 2)}
          disabled={reader.fontSize >= 48}
          aria-label={i18n.t("reader.fontLarger")}
          class="grid size-8 place-items-center rounded-lg text-base font-semibold text-muted transition-colors hover:bg-primary-soft/60 hover:text-primary disabled:opacity-35"
        >
          أ+
        </button>
      </div>

      <button
        type="button"
        role="switch"
        aria-checked={reader.translation}
        onclick={() => reader.setTranslation(!reader.translation)}
        class="flex items-center gap-2 rounded-xl border px-3 py-2 text-xs transition-colors
               {reader.translation
          ? 'border-primary/40 bg-primary-soft font-semibold text-primary'
          : 'border-line bg-surface text-muted hover:border-primary/35 hover:text-primary'}"
      >
        <Icon name="globe" size={14} />
        {i18n.t("reader.translation")}
        <span
          class="relative h-4 w-7 rounded-full border transition-colors
                 {reader.translation ? 'border-primary/60 bg-primary/70' : 'border-line bg-raised'}"
        >
          <span
            class="absolute top-[1px] size-3 rounded-full bg-surface transition-all
                   {reader.translation ? 'start-[11px]' : 'start-[2px]'}"
          ></span>
        </span>
      </button>
    </div>
  </header>

  <div class="mt-5 grid gap-4 lg:grid-cols-[250px_minmax(0,1fr)]">
    <aside class="card rounded-2xl p-3 lg:sticky lg:top-0 lg:max-h-[calc(100vh-9rem)] lg:self-start">
      <div class="grid grid-cols-3 gap-1 rounded-xl bg-canvas p-1">
        {#each tabs as entry (entry.id)}
          <button
            type="button"
            onclick={() => (tab = entry.id)}
            class="flex items-center justify-center gap-1 rounded-lg px-1 py-2 text-[11px] transition-colors
                   {tab === entry.id ? 'bg-primary-soft font-semibold text-primary' : 'text-muted hover:text-text'}"
          >
            <Icon name={entry.icon} size={12} />
            {i18n.t(entry.label)}
          </button>
        {/each}
      </div>

      {#if reader.indexError}
        <p class="mt-2 rounded-lg border border-accent/30 bg-accent/5 px-2.5 py-2 text-[10px] leading-relaxed text-accent-ink">
          {i18n.t(reader.indexError as TranslationKey)}
        </p>
      {/if}

      <div class="mt-3 max-h-[42vh] overflow-y-auto pe-1 lg:max-h-[62vh]">
        {#if tab === "surahs"}
          <label class="field px-2.5 py-1.5">
            <Icon name="search" size={13} class="shrink-0 text-muted" />
            <input
              bind:value={query}
              placeholder={i18n.t("reader.search")}
              aria-label={i18n.t("reader.search")}
              class="w-full bg-transparent text-[11px] text-text placeholder:text-muted focus:outline-none"
            />
          </label>

          <div class="mt-2 space-y-0.5">
            {#each filteredSurahs as surah (surah.number)}
              {@const active = reader.mode === "surah" && reader.surah === surah.number}
              <button
                type="button"
                onclick={() => openSurah(surah.number)}
                class="flex w-full items-center gap-2 rounded-lg px-2 py-1.5 text-start transition-colors
                       {active ? 'bg-primary-soft text-primary' : 'text-muted hover:bg-primary-soft/40 hover:text-text'}"
              >
                <span class="w-6 shrink-0 text-[10px] tabular-nums opacity-70">
                  {fmtNumber(surah.number)}
                </span>
                <span dir="rtl" lang="ar" class="min-w-0 flex-1 truncate text-[12px]">
                  {surah.name}
                </span>
                <span class="shrink-0 text-[10px] tabular-nums text-muted">
                  {fmtNumber(surah.ayahs)}
                </span>
              </button>
            {/each}
          </div>
        {:else if tab === "juzs"}
          <div class="space-y-0.5">
            {#each reader.juzs as juz (juz.number)}
              {@const active = reader.mode === "juz" && reader.juz === juz.number}
              <button
                type="button"
                onclick={() => openJuz(juz.number)}
                class="flex w-full items-center gap-2 rounded-lg px-2 py-2 text-start transition-colors
                       {active ? 'bg-primary-soft text-primary' : 'text-muted hover:bg-primary-soft/40 hover:text-text'}"
              >
                <span class="grid size-7 shrink-0 place-items-center rounded-full border border-line/70 text-[10px] tabular-nums">
                  {fmtNumber(juz.number)}
                </span>
                <span class="min-w-0 flex-1">
                  <span class="block truncate text-[12px]">{surahName(juz.surah)}</span>
                  <span class="block text-[10px] text-muted">
                    {i18n.t("reader.juzStart", {
                      surah: surahName(juz.surah),
                      ayah: fmtNumber(juz.ayah),
                    })}
                  </span>
                </span>
                <span class="shrink-0 text-[10px] tabular-nums text-muted">
                  {fmtNumber(juz.ayahs)}
                </span>
              </button>
            {/each}
          </div>
        {:else if reader.bookmarks.length === 0}
          <p class="px-2 py-6 text-center text-[11px] text-muted">{i18n.t("reader.noBookmarks")}</p>
        {:else}
          <div class="space-y-0.5">
            {#each reader.bookmarks as bookmark (`${bookmark.surah}:${bookmark.ayah}`)}
              <div class="flex items-center gap-1 rounded-lg transition-colors hover:bg-primary-soft/40">
                <button
                  type="button"
                  onclick={() => openBookmark(bookmark)}
                  class="flex min-w-0 flex-1 items-center gap-2 px-2 py-2 text-start text-muted hover:text-text"
                >
                  <Icon name="bookmarkFilled" size={12} class="shrink-0 text-accent-ink" />
                  <span class="min-w-0 flex-1 truncate text-[12px]">
                    {surahName(bookmark.surah)}
                  </span>
                  <span class="shrink-0 text-[10px] tabular-nums text-muted">
                    {fmtNumber(bookmark.ayah)}
                  </span>
                </button>
                <button
                  type="button"
                  onclick={() => reader.toggleBookmark(bookmark.surah, bookmark.ayah)}
                  aria-label={i18n.t("reader.bookmarkRemove")}
                  class="me-1 grid size-6 shrink-0 place-items-center rounded text-muted hover:text-red-500"
                >
                  <Icon name="x" size={11} />
                </button>
              </div>
            {/each}
          </div>
        {/if}
      </div>
    </aside>

    <section class="min-w-0">
      {#if reader.error}
        <div class="mb-3 flex flex-wrap items-center justify-between gap-2 rounded-xl border border-accent/30 bg-accent/5 px-3 py-2 text-[11px] text-accent-ink">
          <span>{i18n.t("reader.error")}</span>
          <button type="button" onclick={() => reader.reload()} class="font-semibold underline">
            {i18n.t("reader.retry")}
          </button>
        </div>
      {/if}

      {#if reader.translation && reader.translationLoading}
        <p class="mb-3 rounded-xl border border-line bg-surface px-3 py-2 text-[11px] text-muted">
          {i18n.t("reader.translationLoading")}
        </p>
      {:else if reader.translation && reader.ayahs.length && !reader.ayahs.some((ayah) => ayah.translation)}
        <p class="mb-3 rounded-xl border border-line bg-surface px-3 py-2 text-[11px] text-muted">
          {i18n.t("reader.translationUnavailable")}
        </p>
      {/if}

      {#if reader.loading}
        <div class="space-y-3">
          {#each Array(5) as _, index (index)}
            <div class="animate-pulse rounded-xl border border-line bg-surface p-5">
              <div class="h-4 w-2/3 rounded bg-primary-soft"></div>
              <div class="mt-3 h-4 w-full rounded bg-primary-soft"></div>
              <div class="mt-2 h-4 w-4/5 rounded bg-primary-soft"></div>
            </div>
          {/each}
        </div>
      {:else if reader.mode === "surah"}
        <div class="card rounded-2xl px-4 py-4 sm:px-6">
          <div class="flex flex-wrap items-start justify-between gap-3 border-b border-line/60 pb-4">
            <div>
              <h2 dir="rtl" lang="ar" class="font-quran text-2xl leading-tight text-text">
                {i18n.t("reader.surahLabel", { name: reader.surahMeta?.name ?? "" })}
              </h2>
              <p class="mt-1 text-[11px] text-muted">
                {i18n.t("reader.ayahCount", { count: fmtNumber(reader.ayahs.length) })}
                {#if reader.surahMeta}
                  <span class="mx-1.5">·</span>
                  {revelation(reader.surahMeta)}
                {/if}
                {#if reader.ayahs[0]?.page}
                  <span class="mx-1.5">·</span>
                  {i18n.t("reader.page", { page: fmtNumber(reader.ayahs[0].page!) })}
                {/if}
              </p>
            </div>
            <span class="pill pill-primary">
              {i18n.t("reader.ayahCount", { count: fmtNumber(reader.ayahs.length) })}
            </span>
          </div>

          {#if reader.ayahs[0] && basmalaFor(reader.ayahs[0])}
            <p
              dir="rtl"
              lang="ar"
              class="mx-auto mt-5 max-w-2xl text-center font-quran text-accent-ink leading-[2.1]"
              style={`font-size: ${reader.fontSize + 2}px`}
            >
              {basmalaFor(reader.ayahs[0])}
            </p>
          {/if}

          <div class="mt-2">
            {#each reader.ayahs as ayah (ayah.number)}
              <AyahRow
                {ayah}
                fontSize={reader.fontSize}
                bookmarked={reader.isBookmarked(ayah.surah ?? reader.surah, ayah.number)}
                onselect={() => reader.selectAyah(ayah)}
                ontoggle={() => reader.toggleBookmark(ayah.surah ?? reader.surah, ayah.number)}
              />
            {/each}
          </div>
        </div>
      {:else}
        <div class="card rounded-2xl p-4">
          <div class="flex items-center justify-between gap-3">
            <h2 class="text-lg font-bold text-text">
              {i18n.t("reader.juzLabel", { number: fmtNumber(reader.juz) })}
            </h2>
            {#if reader.juzMeta}
              <span class="text-[10px] text-muted">
                {i18n.t("reader.juzStart", {
                  surah: surahName(reader.juzMeta.surah),
                  ayah: fmtNumber(reader.juzMeta.ayah),
                })}
              </span>
            {/if}
          </div>
        </div>

        {#each juzGroups as group (group.surah.number)}
          <div class="card mt-3 rounded-2xl px-4 py-4 sm:px-6">
            <div class="border-b border-line/60 pb-3">
              <h3 dir="rtl" lang="ar" class="font-quran text-xl text-text">
                {i18n.t("reader.surahLabel", { name: group.surah.name })}
              </h3>
              <p class="mt-1 text-[10px] text-muted">
                {i18n.t("reader.ayahCount", { count: fmtNumber(group.surah.ayahs) })}
                <span class="mx-1.5">·</span>
                {revelation(group.surah)}
              </p>
            </div>
            {#if basmalaFor(group.ayahs[0])}
              <p
                dir="rtl"
                lang="ar"
                class="mx-auto mt-4 max-w-2xl text-center font-quran text-accent-ink leading-[2.1]"
                style={`font-size: ${reader.fontSize + 2}px`}
              >
                {basmalaFor(group.ayahs[0])}
              </p>
            {/if}
            <div class="mt-1">
              {#each group.ayahs as ayah (ayah.number)}
                <AyahRow
                  {ayah}
                  fontSize={reader.fontSize}
                  bookmarked={reader.isBookmarked(ayah.surah ?? group.surah.number, ayah.number)}
                  onselect={() => reader.selectAyah(ayah)}
                  ontoggle={() =>
                    reader.toggleBookmark(ayah.surah ?? group.surah.number, ayah.number)}
                />
              {/each}
            </div>
          </div>
        {/each}
      {/if}
    </section>
  </div>
</div>
