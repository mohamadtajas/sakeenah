<script lang="ts">
  import { player } from "$lib/stores/player.svelte.ts";
  import { library } from "$lib/stores/library.svelte.ts";
  import { ayahOf } from "$lib/stores/hifz.svelte.ts";
  import { fmtNumber, fmtTime, i18n } from "$lib/i18n/index.svelte.ts";
  import Artwork from "./Artwork.svelte";
  import Icon from "./Icon.svelte";
  import SeekBar from "./SeekBar.svelte";

  const track = $derived(player.current);
  const rateLabel = $derived(Number(player.rate.toFixed(2)).toString());
  const ayah = $derived(ayahOf(track));
  const favorite = $derived(track ? library.isFavorite(track.id) : false);

  function ctrlClass(active = false) {
    return `grid place-items-center rounded-full p-2 transition-colors ${
      active ? "text-primary" : "text-muted hover:text-text"
    }`;
  }
</script>

<!-- Queue drawer -->
{#if player.queueOpen}
  <div
    role="presentation"
    class="fixed inset-0 z-30"
    onclick={() => (player.queueOpen = false)}
  ></div>
  <div
    class="fixed bottom-[100px] end-5 z-40 flex max-h-[52vh] w-[340px] flex-col overflow-hidden rounded-2xl border border-line bg-surface shadow-pop backdrop-blur fade-in"
  >
    <div class="flex items-center justify-between border-b border-line px-4 py-3">
      <span class="text-sm font-semibold">{i18n.t("player.queue")}</span>
      <button
        type="button"
        class="rounded-lg p-1 text-muted hover:bg-primary-soft/60 hover:text-text"
        onclick={() => (player.queueOpen = false)}
        aria-label={i18n.t("common.close")}
      >
        <Icon name="x" size={16} />
      </button>
    </div>
    <div class="overflow-y-auto p-2">
      {#each player.queue as item, i (item.id + i)}
        <button
          type="button"
          onclick={() => player.play(item)}
          class="flex w-full items-center gap-3 rounded-lg px-2 py-2 text-start transition-colors
                 {player.current?.id === item.id ? 'bg-primary-soft text-primary' : 'hover:bg-primary-soft/50'}"
        >
          <span class="w-5 shrink-0 text-center text-[11px] tabular-nums text-muted">{i + 1}</span>
          <span class="min-w-0 flex-1 truncate text-sm">{item.subtitle ?? item.title}</span>
          <span class="shrink-0 text-[11px] text-muted">{item.artist}</span>
        </button>
      {/each}
    </div>
  </div>
{/if}

<footer class="player-bar">
  <div class="player-inner">
    <!-- Now playing -->
    <div class="player-now flex w-[26%] min-w-0 items-center gap-3">
      {#if track}
        <Artwork
          url={track.artworkUrl}
          seed={track.title}
          kind={track.kind}
          class="player-art size-14 shrink-0"
          rounded="rounded-xl"
        />
        <div class="min-w-0">
          <div class="flex items-center gap-1.5">
            <span class="truncate text-sm font-semibold text-text">{track.title}</span>
            {#if ayah}
              <span class="shrink-0 rounded bg-primary-soft px-1.5 py-px text-[9px] font-semibold text-primary">
                {i18n.t("quran.ayah")} {fmtNumber(ayah)}
              </span>
            {/if}
          </div>
          <div class="truncate text-xs text-muted">
            {track.artist || i18n.t("player.nowPlaying")}
          </div>
        </div>
        <button
          type="button"
          class="{ctrlClass(favorite)} ms-1"
          onclick={() => track && library.toggleFavorite(track)}
          disabled={!track}
          aria-label={i18n.t("library.favorites")}
          aria-pressed={favorite}
        >
          <Icon name="heart" size={16} />
        </button>
      {:else}
        <div class="player-art grid size-14 place-items-center rounded-xl border border-line bg-raised text-muted">
          <Icon name="disc" size={22} />
        </div>
        <div class="text-sm text-muted">
          <span class="player-tagline line-clamp-2">{i18n.t("app.tagline")}</span>
        </div>
      {/if}
    </div>

    <!-- Transport -->
    <div class="flex min-w-0 flex-1 flex-col items-center gap-1">
      <div class="flex items-center gap-1">
        <button
          type="button"
          class="{ctrlClass(player.shuffle)} player-extra"
          onclick={() => (player.shuffle = !player.shuffle)}
          aria-label={i18n.t("player.shuffle")}
        >
          <Icon name="shuffle" size={16} />
        </button>
        <button
          type="button"
          class={ctrlClass()}
          onclick={() => player.prev()}
          aria-label={i18n.t("player.previous")}
        >
          <Icon name="skip-back" size={18} />
        </button>
        <button
          type="button"
          onclick={() => player.toggle()}
          class="mx-1 grid size-11 place-items-center rounded-full bg-primary text-on-primary shadow-lg shadow-primary/20 transition-transform hover:scale-105 active:scale-95 disabled:opacity-40"
          disabled={!track && !player.queue.length}
          aria-label={player.playing ? i18n.t("player.pause") : i18n.t("player.play")}
        >
          {#if player.loading}
            <span class="size-4 animate-spin rounded-full border-2 border-on-primary/30 border-t-on-primary"></span>
          {:else}
            <Icon name={player.playing ? "pause" : "play"} size={18} />
          {/if}
        </button>
        <button
          type="button"
          class={ctrlClass()}
          onclick={() => player.next()}
          aria-label={i18n.t("player.next")}
        >
          <Icon name="skip-forward" size={18} />
        </button>
        <button
          type="button"
          class="{ctrlClass(player.repeat !== 'off')} player-extra relative"
          onclick={() => player.cycleRepeat()}
          aria-label={i18n.t("player.repeat")}
        >
          <Icon name="repeat" size={16} />
          {#if player.repeat === "one"}
            <span class="absolute -top-0.5 -end-0.5 rounded-full bg-accent px-1 text-[8px] font-bold leading-tight text-canvas">1</span>
          {/if}
        </button>
      </div>

      <div class="flex w-full max-w-xl items-center gap-2 text-[11px] tabular-nums text-muted">
        <span class="w-9 shrink-0 text-end">{fmtTime(player.position)}</span>
        <SeekBar
          value={player.position}
          max={player.duration || 0}
          disabled={!player.duration || player.isLive}
          onseek={(v) => player.seek(v)}
          label={i18n.t("player.seek")}
        />
        <span class="w-9 shrink-0">{player.isLive ? i18n.t("player.live") : fmtTime(player.duration)}</span>
      </div>
    </div>

    <!-- Right controls -->
    <div class="player-right flex w-[26%] items-center justify-end gap-1">
      <button
        type="button"
        class="rounded-lg px-2 py-1 text-[11px] font-semibold tabular-nums text-muted transition-colors hover:bg-primary-soft/60 hover:text-primary"
        onclick={() => player.cycleRate()}
        title={i18n.t("player.speed")}
      >
        {rateLabel}×
      </button>
      <button
        type="button"
        class={ctrlClass(player.muted || player.volume === 0)}
        onclick={() => player.toggleMute()}
        aria-label={i18n.t("player.volume")}
      >
        <Icon name={player.muted || player.volume === 0 ? "volume-x" : "volume"} size={16} />
      </button>
      <div class="player-volume w-20">
        <SeekBar
          value={player.muted ? 0 : player.volume}
          max={1}
          onseek={(v) => player.setVolume(v)}
          label={i18n.t("player.volume")}
          step={0.05}
        />
      </div>
      <button
        type="button"
        class={ctrlClass(player.queueOpen)}
        onclick={() => (player.queueOpen = !player.queueOpen)}
        aria-label={i18n.t("player.queue")}
      >
        <Icon name="list" size={17} />
      </button>
    </div>
  </div>
</footer>
