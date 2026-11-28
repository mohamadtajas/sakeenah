<script lang="ts">
  import { onMount } from "svelte";
  import { api, isTauri } from "$lib/api";
  import type { Track } from "$lib/types";
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import TrackRow from "$lib/components/TrackRow.svelte";
  import Icon from "$lib/components/Icon.svelte";

  type Section = "all" | "music" | "anasheed";

  interface CcBatch {
    requestId: string;
    source: string;
    tracks: Track[];
    done: boolean;
    error?: string;
  }

  let term = $state("");
  let section = $state<Section>("all");
  let tracks = $state<Track[]>([]);
  let loading = $state(true);
  let streaming = $state(false);
  let failed = $state(false);
  let reload = $state(0);
  let requestId = $state<string | null>(null);

  let seen = new Set<string>();
  let hadError = false;
  let token = 0;
  let unlisten: (() => void) | null = null;

  const sections: { id: Section; label: "explore.all" | "explore.music" | "explore.anasheed" }[] = [
    { id: "all", label: "explore.all" },
    { id: "music", label: "explore.music" },
    { id: "anasheed", label: "explore.anasheed" },
  ];

  onMount(() => {
    let disposed = false;
    void (async () => {
      if (!isTauri) return;
      try {
        const { listen } = await import("@tauri-apps/api/event");
        const stop = await listen<CcBatch>("cc:batch", (event) => applyBatch(event.payload));
        if (disposed) stop();
        else unlisten = stop;
      } catch {
        /* streaming is best-effort */
      }
    })();
    return () => {
      disposed = true;
      unlisten?.();
    };
  });

  function applyBatch(batch: CcBatch) {
    if (!requestId || batch.requestId !== requestId) return;

    if (batch.tracks.length) {
      const fresh = batch.tracks.filter((track) => !seen.has(track.id));
      for (const track of fresh) seen.add(track.id);
      if (fresh.length) tracks = [...tracks, ...fresh];
      loading = false;
    }
    if (batch.error) hadError = true;
    if (batch.done) {
      loading = false;
      streaming = false;
      failed = tracks.length === 0 && hadError;
    }
  }

  async function run(ticket: number, query: string, selected: Section) {
    if (ticket !== token) return;

    requestId = null;
    seen = new Set();
    tracks = [];
    loading = true;
    streaming = true;
    failed = false;
    hadError = false;

    if (!isTauri) {
      try {
        const result = await api.exploreCc(query, selected);
        if (ticket === token) tracks = result;
      } catch {
        if (ticket === token) failed = true;
      } finally {
        if (ticket === token) {
          loading = false;
          streaming = false;
        }
      }
      return;
    }

    try {
      const id = await api.startExplore(query, selected);
      if (ticket === token) requestId = id;
    } catch {
      if (ticket !== token) return;
      failed = true;
      loading = false;
      streaming = false;
    }
  }

  $effect(() => {
    const query = term.trim();
    const selected = section;
    reload;
    const ticket = ++token;
    const handle = setTimeout(() => void run(ticket, query, selected), query ? 420 : 0);
    return () => clearTimeout(handle);
  });

  function retry() {
    reload += 1;
  }
</script>

<div class="fade-in">
  <header>
    <p class="text-[10px] font-bold uppercase tracking-[0.22em] text-accent-ink">
      {i18n.t("explore.sources")}
    </p>
    <h1 class="mt-1 text-2xl font-bold text-text">{i18n.t("explore.title")}</h1>
    <p class="mt-1 max-w-2xl text-xs leading-relaxed text-muted">{i18n.t("explore.note")}</p>
  </header>

  <div class="mt-5 flex flex-wrap items-center gap-2">
    {#each sections as item (item.id)}
      <button
        type="button"
        onclick={() => (section = item.id)}
        class="chip"
        data-active={section === item.id ? "true" : "false"}
      >
        {i18n.t(item.label)}
      </button>
    {/each}
  </div>

  <label
    class="field mt-4 max-w-lg"
  >
    <Icon name="search" size={15} class="text-muted" />
    <input
      bind:value={term}
      aria-label={i18n.t("explore.placeholder")}
      placeholder={i18n.t("explore.placeholder")}
      class="w-full bg-transparent text-sm text-text placeholder:text-muted/70 focus:outline-none"
    />
    {#if term}
      <button
        type="button"
        onclick={() => (term = "")}
        class="rounded p-0.5 text-muted hover:text-text"
        aria-label={i18n.t("common.close")}
      >
        <Icon name="x" size={13} />
      </button>
    {/if}
  </label>

  <div class="mt-6">
    {#if loading}
      <div class="space-y-1">
        {#each Array(7) as _, i (i)}
          <div class="flex animate-pulse items-center gap-3 px-2.5 py-2">
            <div class="size-11 rounded-lg bg-primary-soft"></div>
            <div class="h-3 w-56 rounded bg-primary-soft"></div>
          </div>
        {/each}
      </div>
      <p class="mt-3 text-center text-[11px] text-muted">{i18n.t("explore.loading")}</p>
    {:else if failed}
      <div class="card rounded-2xl px-6 py-14 text-center">
        <Icon name="globe" size={28} class="mx-auto text-muted" />
        <p class="mt-3 text-sm text-muted">{i18n.t("explore.error")}</p>
        <button
          type="button"
          onclick={retry}
          class="btn btn-outline mt-4"
        >
          {i18n.t("common.retry")}
        </button>
      </div>
    {:else if tracks.length === 0}
      <div class="card rounded-2xl px-6 py-14 text-center">
        <Icon name="sparkle" size={28} class="mx-auto text-muted" />
        <p class="mt-3 text-sm text-muted">{i18n.t("explore.empty")}</p>
      </div>
    {:else}
      {#if streaming}
        <div class="mb-2 flex items-center gap-2 px-1 text-[11px] text-muted">
          <span class="size-3 animate-spin rounded-full border border-accent/30 border-t-accent"></span>
          {i18n.t("explore.loadingMore")}
        </div>
      {/if}
      <div class="card overflow-hidden rounded-2xl p-1.5">
        {#each tracks as track (track.id)}
          <TrackRow {track} queue={tracks} />
        {/each}
      </div>
    {/if}
  </div>
</div>
