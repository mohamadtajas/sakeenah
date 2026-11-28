<script lang="ts">
  import type { Ayah } from "$lib/types";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import Icon from "./Icon.svelte";

  let {
    ayah,
    fontSize,
    bookmarked,
    onselect,
    ontoggle,
  }: {
    ayah: Ayah;
    fontSize: number;
    bookmarked: boolean;
    onselect: () => void;
    ontoggle: () => void;
  } = $props();
</script>

<div
  id={`ayah-${ayah.surah ?? 0}-${ayah.number}`}
  class="group scroll-mt-6 rounded-2xl border border-transparent px-2 py-4 transition-colors hover:border-line/70 hover:bg-primary-soft/20"
>
  <div class="flex items-start gap-3">
    <button
      type="button"
      onclick={onselect}
      aria-label={i18n.t("reader.markPosition")}
      class="mt-0.5 grid size-8 shrink-0 place-items-center rounded-full border border-accent/30 bg-accent/8 text-[11px] font-semibold tabular-nums text-accent-ink transition-colors hover:border-accent/60 hover:bg-accent/12"
    >
      {fmtNumber(ayah.number)}
    </button>

    <div class="min-w-0 flex-1 select-text">
      <p
        dir="rtl"
        lang="ar"
        class="font-quran text-text"
        style={`font-size: ${fontSize}px; line-height: ${Math.round(fontSize * 2.05)}px`}
      >
        {ayah.text}
      </p>
      {#if ayah.translation}
        <p dir="ltr" lang="en" class="mt-2.5 text-[0.82rem] leading-relaxed text-muted">
          {ayah.translation}
        </p>
      {/if}

      <div class="mt-2 flex items-center gap-3 text-[10px] text-muted">
        {#if ayah.juz}<span>{i18n.t("reader.juz")} {fmtNumber(ayah.juz)}</span>{/if}
        {#if ayah.page}<span>{i18n.t("reader.page", { page: fmtNumber(ayah.page) })}</span>{/if}
      </div>
    </div>

    <button
      type="button"
      onclick={ontoggle}
      aria-label={bookmarked ? i18n.t("reader.bookmarkRemove") : i18n.t("reader.bookmarkAdd")}
      aria-pressed={bookmarked}
      class="mt-0.5 grid size-8 shrink-0 place-items-center rounded-lg border transition-colors
             {bookmarked
        ? 'border-accent/40 bg-accent/10 text-accent-ink'
        : 'border-line/60 text-muted/50 hover:border-primary/40 hover:text-primary'}"
    >
      <Icon name={bookmarked ? "bookmarkFilled" : "bookmark"} size={14} />
    </button>
  </div>
</div>
