<script lang="ts">
  import type { Track } from "$lib/types";
  import { player } from "$lib/stores/player.svelte.ts";
  import { library } from "$lib/stores/library.svelte.ts";
  import { fmtTime, i18n } from "$lib/i18n/index.svelte.ts";
  import Artwork from "./Artwork.svelte";
  import Icon from "./Icon.svelte";
  import PlaylistPicker from "./PlaylistPicker.svelte";

  let {
    track,
    queue,
    index,
    onRemove,
  }: { track: Track; queue?: Track[]; index?: number; onRemove?: () => void } = $props();

  const active = $derived(player.current?.id === track.id);
  const favorite = $derived(library.isFavorite(track.id));
  const download = $derived(library.downloadFor(track.id));

  let picker = $state<{ x: number; y: number } | null>(null);

  const downloadPct = $derived(
    download && download.bytesTotal > 0
      ? Math.round((download.bytesDone / download.bytesTotal) * 100)
      : 0,
  );

  function openPicker(event: MouseEvent) {
    const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
    const width = 268;
    const height = 320;
    picker = {
      x: Math.max(8, Math.min(rect.left, window.innerWidth - width - 8)),
      y: Math.max(8, Math.min(rect.bottom + 6, window.innerHeight - height)),
    };
  }

  function downloadHint() {
    if (!download) return i18n.t("library.download");
    if (download.status === "done") return i18n.t("library.downloaded");
    if (download.status === "queued" || download.status === "downloading")
      return i18n.t("library.cancelDownload");
    return i18n.t("library.retryDownload");
  }
</script>

<div
  class="group flex w-full items-center gap-2 rounded-xl px-2.5 py-2 transition-colors
         {active ? 'bg-primary-soft' : 'hover:bg-primary-soft/40'}"
>
  <button
    type="button"
    onclick={() => player.play(track, queue)}
    class="flex min-w-0 flex-1 items-center gap-3 text-start"
  >
    <div class="relative shrink-0">
      <Artwork
        url={track.artworkUrl}
        seed={track.title}
        kind={track.kind}
        class="size-11"
        rounded="rounded-lg"
      />
      <div
        class="absolute inset-0 grid place-items-center rounded-lg bg-canvas/65 opacity-0 transition-opacity group-hover:opacity-100
               {active ? 'opacity-100' : ''}"
      >
        {#if active && player.playing}
          <div class="eq">
            <i></i><i></i><i></i><i></i>
          </div>
        {:else}
          <Icon name="play" size={16} class="text-primary" />
        {/if}
      </div>
    </div>

    <div class="min-w-0 flex-1">
      <div class="truncate text-[0.95rem] font-medium {active ? 'text-primary' : 'text-text'}">
        {track.title}
      </div>
      <div class="flex items-center gap-1.5 text-xs text-muted">
        <span class="truncate">{track.artist || (track.kind === "local" ? i18n.t("library.local") : "")}</span>
        {#if track.live}
          <span
            class="flex shrink-0 items-center gap-1 rounded-md border border-primary/25 bg-primary-soft px-1.5 py-px text-[9px] font-semibold tracking-wide text-primary"
          >
            <span class="size-1 animate-pulse rounded-full bg-primary"></span>
            {i18n.t("radio.live")}
          </span>
        {:else if track.subtitle}
          <span class="truncate text-muted">· {track.subtitle}</span>
        {/if}
        {#if track.license && (track.kind === "music" || track.kind === "anasheed")}
          <span
            class="shrink-0 rounded border border-accent/30 bg-accent/8 px-1 py-px text-[9px] font-medium text-accent-ink"
            title={track.licenseUrl ?? track.license}
          >
            {track.license}
          </span>
        {/if}
      </div>
    </div>
  </button>

  <div class="flex shrink-0 items-center gap-0.5">
    {#if !track.live && track.durationS}
      <span class="me-1 text-xs tabular-nums text-muted">{fmtTime(track.durationS)}</span>
    {/if}

    <button
      type="button"
      onclick={() => library.toggleFavorite(track)}
      aria-label={i18n.t("library.favorites")}
      aria-pressed={favorite}
      class="rounded-lg p-1.5 transition-all
             {favorite
        ? 'text-accent-ink'
        : 'text-muted opacity-0 hover:text-text group-hover:opacity-100 focus-visible:opacity-100'}"
    >
      <Icon name="heart" size={14} />
    </button>

    {#if track.streamUrl && !track.live}
      <button
        type="button"
        onclick={() => {
          if (download?.status === "queued" || download?.status === "downloading") {
            void library.cancelDownload(track.id);
          } else if (download?.status !== "done") {
            void library.startDownload(track);
          }
        }}
        aria-label={downloadHint()}
        title={downloadHint()}
        class="rounded-lg p-1.5 transition-all
               {download?.status === 'done'
          ? 'text-primary'
          : download?.status === 'error'
            ? 'text-red-500'
            : download?.status === 'cancelled'
              ? 'text-muted hover:text-text'
              : download
                ? 'text-accent-ink'
                : 'text-muted opacity-0 hover:text-text group-hover:opacity-100 focus-visible:opacity-100'}"
      >
        {#if download?.status === "queued" || download?.status === "downloading"}
          <span class="flex items-center gap-1 text-[9px] tabular-nums" title={i18n.t("library.cancelDownload")}>
            <span class="relative grid size-3.5 place-items-center">
              <span class="absolute inset-0 animate-spin rounded-full border border-accent/30 border-t-accent"></span>
              <span class="size-1 rounded-[1px] bg-accent"></span>
            </span>
            {#if downloadPct > 0}{downloadPct}%{/if}
          </span>
        {:else if download?.status === "done"}
          <Icon name="check" size={14} />
        {:else}
          <Icon name="download" size={14} />
        {/if}
      </button>
    {/if}

    <button
      type="button"
      onclick={openPicker}
      aria-label={i18n.t("library.addToPlaylist")}
      class="rounded-lg p-1.5 text-muted opacity-0 transition-all hover:text-text group-hover:opacity-100 focus-visible:opacity-100"
    >
      <Icon name="list" size={14} />
    </button>

    {#if onRemove}
      <button
        type="button"
        onclick={onRemove}
        aria-label={i18n.t("library.remove")}
        class="rounded-lg p-1.5 text-muted opacity-0 transition-all hover:text-red-500 group-hover:opacity-100 focus-visible:opacity-100"
      >
        <Icon name="x" size={14} />
      </button>
    {/if}
  </div>
</div>

{#if picker}
  <PlaylistPicker track={track} x={picker.x} y={picker.y} onclose={() => (picker = null)} />
{/if}
