<script lang="ts">
  import type { Track } from "$lib/types";
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import Artwork from "./Artwork.svelte";
  import Icon from "./Icon.svelte";

  let {
    track,
    onplay,
  }: { track: Track; onplay: () => void } = $props();
</script>

<button
  type="button"
  onclick={onplay}
  class="group flex w-[190px] items-center gap-3 rounded-xl border border-line bg-surface p-2.5 text-start shadow-card transition-colors hover:border-primary/35 hover:bg-primary-soft/30"
>
  <Artwork
    url={track.artworkUrl}
    seed={track.title}
    kind={track.kind}
    class="size-12 shrink-0"
    rounded="rounded-lg"
  />
  <div class="min-w-0 flex-1">
    <div class="truncate text-[0.82rem] font-medium text-text group-hover:text-primary">
      {track.title}
    </div>
    <div class="mt-0.5 flex items-center gap-1.5">
      {#if track.live}
        <span class="flex items-center gap-1 text-[10px] font-semibold text-primary">
          <span class="size-1.5 animate-pulse rounded-full bg-primary"></span>
          {i18n.t("radio.live")}
        </span>
      {:else}
        <span class="truncate text-[11px] text-muted">{track.artist}</span>
      {/if}
    </div>
  </div>
  <Icon
    name="play"
    size={13}
    class="shrink-0 text-muted opacity-0 transition-opacity group-hover:opacity-100"
  />
</button>
