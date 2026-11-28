<script lang="ts">
  import type { Reciter } from "$lib/types";
  import Artwork from "./Artwork.svelte";

  let {
    reciter,
    onselect,
  }: { reciter: Reciter; onselect: () => void } = $props();
</script>

<button
  type="button"
  onclick={onselect}
  class="group w-[140px] text-start"
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
        <svg width="14" height="14" viewBox="0 0 24 24" class="ms-0.5" fill="currentColor"><path d="M7 3.8v16.4L20 12z" /></svg>
      </span>
    </div>
  </div>
  <div class="mt-2 truncate text-[0.85rem] font-medium text-text group-hover:text-primary">
    {reciter.name}
  </div>
  <div class="truncate text-[11px] text-muted">{reciter.moshafs[0]?.name ?? ""}</div>
</button>
