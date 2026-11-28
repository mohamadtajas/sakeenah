<script lang="ts">
  import { onMount } from "svelte";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { reader } from "$lib/stores/reader.svelte.ts";
  import Icon from "./Icon.svelte";

  onMount(() => {
    void reader.loadDaily();
    if (!reader.surahs.length) void reader.loadIndex();
    // The card stays on Home across midnight; revalidate the local day.
    const timer = setInterval(() => void reader.loadDaily(), 60000);
    return () => clearInterval(timer);
  });

  const ayah = $derived(reader.daily);
  const surah = $derived(
    reader.surahs.find((entry) => entry.number === ayah?.surah) ?? null,
  );

  function open() {
    if (ayah?.surah) nav.go("reader", ayah.surah, ayah.number);
  }
</script>

{#if ayah}
  <section class="card mt-4 overflow-hidden rounded-2xl">
    <div class="flex items-center justify-between gap-3 border-b border-line/60 px-4 py-2.5">
      <span class="flex items-center gap-2 text-[11px] font-semibold text-accent-ink">
        <Icon name="bookOpen" size={13} />
        {i18n.t("reader.daily")}
      </span>
      <button
        type="button"
        onclick={open}
        class="rounded-lg border border-line px-2.5 py-1 text-[10px] text-muted transition-colors hover:border-primary/40 hover:text-primary"
      >
        {i18n.t("reader.openInReader")}
      </button>
    </div>

    <button type="button" onclick={open} class="block w-full px-5 py-5 text-center transition-colors hover:bg-primary-soft/30">
      <p
        dir="rtl"
        lang="ar"
        class="mx-auto line-clamp-4 max-w-3xl font-quran text-[1.2rem] leading-[2.05] text-text"
      >
        {ayah.text}
      </p>
      <p class="mt-3 text-[10px] text-muted">
        {i18n.t("reader.surahLabel", { name: surah?.name ?? "" })}
        <span class="mx-1.5">·</span>
        {i18n.t("reader.ayah")} {fmtNumber(ayah.number)}
      </p>
    </button>
  </section>
{/if}
