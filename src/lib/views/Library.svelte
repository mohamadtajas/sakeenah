<script lang="ts">
  import { onMount } from "svelte";
  import { api, isTauri } from "$lib/api";
  import type { Memorization, Playlist, Surah, Track } from "$lib/types";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { library } from "$lib/stores/library.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { DEFAULT_AYAH_RECITER } from "$lib/constants";
  import TrackRow from "$lib/components/TrackRow.svelte";
  import Icon from "$lib/components/Icon.svelte";
  import type { IconName } from "$lib/components/Icon.svelte";

  type Tab = "recent" | "hifz" | "favorites" | "playlists" | "downloads" | "local";

  let tab = $state<Tab>("recent");
  let recent = $state<Track[]>([]);
  let memorisation = $state<Memorization[]>([]);
  let surahs = $state<Surah[]>([]);
  let loading = $state(true);

  let newPlaylistName = $state("");
  let creating = $state(false);
  let renaming = $state(false);
  let renameValue = $state("");

  let playlistTracks = $state<Track[]>([]);
  let playlistLoading = $state(false);
  let playlistToken = 0;

  let selectedDownloads = $state<string[]>([]);

  const busyDownloads = $derived(
    library.downloads.filter(
      (row) => row.status === "queued" || row.status === "downloading",
    ),
  );
  const removableDownloads = $derived(
    library.downloads.filter(
      (row) => row.status !== "queued" && row.status !== "downloading",
    ),
  );
  const selectedCount = $derived(
    selectedDownloads.filter((id) =>
      library.downloads.some((row) => row.track.id === id),
    ).length,
  );
  const allSelected = $derived(
    removableDownloads.length > 0 &&
      removableDownloads.every((row) => selectedDownloads.includes(row.track.id)),
  );

  const tabs: { id: Tab; label: "library.recent" | "library.hifz" | "library.favorites" | "library.playlists" | "library.downloads" | "library.local"; icon: IconName }[] = [
    { id: "recent", label: "library.recent", icon: "clock" },
    { id: "favorites", label: "library.favorites", icon: "heart" },
    { id: "playlists", label: "library.playlists", icon: "list" },
    { id: "downloads", label: "library.downloads", icon: "download" },
    { id: "local", label: "library.local", icon: "disc" },
    { id: "hifz", label: "library.hifz", icon: "bookmark" },
  ];

  const playlistId = $derived(nav.params[0] ?? null);
  const openPlaylist = $derived(
    playlistId ? (library.playlists.find((p) => p.id === playlistId) ?? null) : null,
  );

  let loadError = $state(false);

  onMount(async () => {
    await loadLibrary();
  });

  async function loadLibrary() {
    loading = true;
    loadError = false;
    const [r, m, s] = await Promise.allSettled([
      api.recent(40),
      api.memorization(),
      api.surahs(),
    ]);
    if (r.status === "fulfilled") recent = r.value;
    if (m.status === "fulfilled") memorisation = m.value;
    if (s.status === "fulfilled") surahs = s.value;
    loadError = r.status === "rejected";
    loading = false;
    if (library.error) await library.load();
  }

  $effect(() => {
    const id = nav.params[0];
    if (!id) {
      playlistTracks = [];
      return;
    }
    if (id === "downloads") {
      tab = "downloads";
      playlistTracks = [];
      return;
    }
    // Wait until the store knows this playlist, then load its contents.
    if (!library.playlists.some((p) => p.id === id)) return;
    tab = "playlists";
    void loadPlaylist(id);
  });

  async function loadPlaylist(id: string) {
    const token = ++playlistToken;
    playlistLoading = true;
    const tracks = await api.playlistTracks(id).catch(() => [] as Track[]);
    if (token === playlistToken) {
      playlistTracks = tracks;
      playlistLoading = false;
    }
  }

  const hifzRows = $derived(
    memorisation
      .map((row) => ({ row, surah: surahs.find((s) => s.number === row.surah) }))
      .filter((x): x is { row: Memorization; surah: Surah } => Boolean(x.surah)),
  );

  function shortName(name: string) {
    return name.replace(/^سُورَةُ\s*/, "").replace(/^سورة\s*/, "");
  }

  function removeFromOpenPlaylist(track: Track) {
    if (!openPlaylist) return;
    const id = openPlaylist.id;
    playlistTracks = playlistTracks.filter((t) => t.id !== track.id);
    void library.removeFromPlaylist(id, track.id);
  }

  async function createPlaylist(event: Event) {
    event.preventDefault();
    if (creating) return;
    creating = true;
    const playlist = await library.createPlaylist(newPlaylistName);
    creating = false;
    if (playlist) {
      newPlaylistName = "";
      nav.go("library", playlist.id);
    }
  }

  async function saveRename(event: Event) {
    event.preventDefault();
    if (!openPlaylist || !renameValue.trim()) return;
    await library.renamePlaylist(openPlaylist.id, renameValue);
    renaming = false;
  }

  async function askDelete(playlist: Playlist) {
    const message = i18n.t("library.deleteConfirm", { name: playlist.name });
    let confirmed = false;
    if (isTauri) {
      const { ask } = await import("@tauri-apps/plugin-dialog");
      confirmed = await ask(message, { kind: "warning" });
    } else {
      confirmed = window.confirm(message);
    }
    if (confirmed) {
      await library.deletePlaylist(playlist.id);
      nav.go("library");
    }
  }

  function playAll(tracks: Track[]) {
    if (tracks.length) player.play(tracks[0], tracks);
  }

  function fmtBytes(bytes: number) {
    if (!bytes) return "";
    const mb = bytes / 1_048_576;
    return mb >= 1 ? `${mb.toFixed(1)} MB` : `${Math.round(bytes / 1024)} KB`;
  }

  /** Stable backend codes → translated copy; raw English stays in the log. */
  function downloadError(code?: string): string {
    switch (code) {
      case "interrupted":
        return i18n.t("library.downloadInterrupted");
      case "missing":
        return i18n.t("library.downloadMissing");
      case "resume-mismatch":
      case "range-invalid":
        return i18n.t("library.downloadResumeFailed");
      case "empty-file":
      case "truncated":
        return i18n.t("library.downloadIncomplete");
      case "no-url":
        return i18n.t("library.downloadUnavailable");
      case "active":
        return i18n.t("library.downloadBusy");
      default:
        return i18n.t("library.downloadFailed");
    }
  }

  function toggleSelected(trackId: string) {
    selectedDownloads = selectedDownloads.includes(trackId)
      ? selectedDownloads.filter((id) => id !== trackId)
      : [...selectedDownloads, trackId];
  }

  function toggleSelectAll() {
    selectedDownloads = allSelected
      ? []
      : removableDownloads.map((row) => row.track.id);
  }

  async function deleteSelected() {
    const ids = selectedDownloads.filter((id) =>
      removableDownloads.some((row) => row.track.id === id),
    );
    if (ids.length === 0) return;
    if (ids.length > 20) {
      const message = i18n.t("library.deleteSelectedConfirm", {
        count: fmtNumber(ids.length),
      });
      let confirmed = false;
      if (isTauri) {
        const { ask } = await import("@tauri-apps/plugin-dialog");
        confirmed = await ask(message, { kind: "warning" });
      } else {
        confirmed = window.confirm(message);
      }
      if (!confirmed) return;
    }
    const summary = await library.removeDownloads(ids);
    if (summary) {
      const failed = new Set(summary.failed.map((entry) => entry.trackId));
      selectedDownloads = ids.filter((id) => failed.has(id));
    }
  }

  async function cancelAll() {
    await Promise.all(busyDownloads.map((row) => library.cancelDownload(row.track.id)));
  }
</script>

{#snippet emptyState(icon: IconName, text: string)}
  <div class="card rounded-2xl px-6 py-14 text-center">
    <Icon name={icon} size={28} class="mx-auto text-muted" />
    <p class="mt-3 text-sm text-muted">{text}</p>
  </div>
{/snippet}

{#snippet trackList(tracks: Track[], onRemove?: (track: Track) => void)}
  <div class="card overflow-hidden rounded-2xl p-1.5">
    {#each tracks as track (track.id)}
      <TrackRow {track} queue={tracks} onRemove={onRemove ? () => onRemove(track) : undefined} />
    {/each}
  </div>
{/snippet}

<div class="fade-in">
  {#if loadError || library.error}
    <div class="mb-4 rounded-2xl border border-accent/30 bg-accent/5 px-4 py-3 text-xs text-muted">
      {i18n.t("common.offline")}
      <button
        type="button"
        onclick={() => loadLibrary()}
        class="ms-2 rounded-md border border-accent/40 px-2 py-0.5 text-accent-ink"
      >
        {i18n.t("common.retry")}
      </button>
    </div>
  {/if}
  {#if openPlaylist}
    <!-- Playlist detail -->
    <button
      type="button"
      onclick={() => nav.go("library")}
      class="mb-5 flex items-center gap-1.5 text-xs text-muted transition-colors hover:text-primary"
    >
      <Icon name="chevron" size={13} class="rotate-180 rtl:rotate-0" />
      {i18n.t("library.playlists")}
    </button>

    <header class="flex flex-wrap items-end gap-4">
      <div class="min-w-0 flex-1">
        {#if renaming}
          <form onsubmit={saveRename} class="flex items-center gap-2">
            <input
              bind:value={renameValue}
              aria-label={i18n.t("library.rename")}
              class="w-full max-w-sm rounded-lg border border-primary/40 bg-surface px-3 py-1.5 text-xl font-bold text-text focus:outline-none"
            />
            <button type="submit" class="btn btn-primary min-h-0 rounded-lg px-3 py-1.5 text-xs">
              {i18n.t("library.create")}
            </button>
          </form>
        {:else}
          <p class="text-[10px] font-bold uppercase tracking-[0.22em] text-accent-ink">
            {i18n.t("library.playlists")}
          </p>
          <h1 class="mt-1 text-2xl font-bold text-text">{openPlaylist.name}</h1>
        {/if}
        <p class="mt-1 text-xs text-muted">
          {fmtNumber(playlistTracks.length)} {i18n.t("library.tracks")}
        </p>
      </div>

      <div class="flex items-center gap-2">
        <button
          type="button"
          onclick={() => playAll(playlistTracks)}
          disabled={!playlistTracks.length}
          class="btn btn-primary"
        >
          <Icon name="play" size={14} />
          {i18n.t("library.playAll")}
        </button>
        <button
          type="button"
          onclick={() => {
            renameValue = openPlaylist.name;
            renaming = true;
          }}
          class="rounded-lg border border-line p-2 text-muted transition-colors hover:border-primary/40 hover:text-primary"
          aria-label={i18n.t("library.rename")}
        >
          <Icon name="pencil" size={15} />
        </button>
        <button
          type="button"
          onclick={() => askDelete(openPlaylist)}
          class="rounded-lg border border-line p-2 text-muted transition-colors hover:border-red-400/40 hover:text-red-400"
          aria-label={i18n.t("library.delete")}
        >
          <Icon name="x" size={15} />
        </button>
      </div>
    </header>

    <div class="mt-6">
      {#if playlistLoading}
        <div class="space-y-1">
          {#each Array(6) as _, i (i)}
            <div class="flex animate-pulse items-center gap-3 px-2.5 py-2">
              <div class="size-11 rounded-lg bg-primary-soft"></div>
              <div class="h-3 w-56 rounded bg-primary-soft"></div>
            </div>
          {/each}
        </div>
      {:else if playlistTracks.length === 0}
        {@render emptyState("list", i18n.t("library.noTracks"))}
      {:else}
        {@render trackList(playlistTracks, removeFromOpenPlaylist)}
      {/if}
    </div>
  {:else}
    <header>
      <h1 class="text-2xl font-bold text-text">{i18n.t("library.title")}</h1>
    </header>

    <div class="mt-5 flex flex-wrap gap-2">
      {#each tabs as t (t.id)}
        <button
          type="button"
          onclick={() => (tab = t.id)}
          class="flex items-center gap-2 rounded-xl border px-3 py-2 text-[12px] transition-colors
                 {tab === t.id
            ? 'border-primary/35 bg-primary-soft font-semibold text-primary'
            : 'border-line text-muted hover:border-primary/25 hover:text-text'}"
        >
          <Icon name={t.icon} size={14} />
          {i18n.t(t.label)}
        </button>
      {/each}
    </div>

    <div class="mt-6">
      {#if tab === "recent"}
        {#if loading}
          <div class="space-y-1">
            {#each Array(8) as _, i (i)}
              <div class="flex animate-pulse items-center gap-3 px-2.5 py-2">
                <div class="size-11 rounded-lg bg-primary-soft"></div>
                <div class="h-3 w-56 rounded bg-primary-soft"></div>
              </div>
            {/each}
          </div>
        {:else if recent.length === 0}
          {@render emptyState("clock", i18n.t("home.empty"))}
        {:else}
          {@render trackList(recent)}
        {/if}
      {:else if tab === "favorites"}
        {#if library.favorites.length === 0}
          {@render emptyState("heart", i18n.t("library.emptyFavorites"))}
        {:else}
          {@render trackList(library.favorites)}
        {/if}
      {:else if tab === "playlists"}
        <form onsubmit={createPlaylist} class="mb-4 flex max-w-md items-center gap-2">
          <input
            bind:value={newPlaylistName}
            aria-label={i18n.t("library.playlistName")}
            placeholder={i18n.t("library.playlistName")}
            class="min-w-0 flex-1 rounded-xl border border-line bg-surface px-3 py-2 text-sm text-text placeholder:text-muted/70 focus:border-primary/60 focus:outline-none"
          />
          <button
            type="submit"
            disabled={!newPlaylistName.trim() || creating}
            class="flex items-center gap-1.5 rounded-xl border border-primary/40 bg-primary-soft px-3 py-2 text-xs font-semibold text-primary disabled:opacity-40"
          >
            <Icon name="list" size={13} />
            {i18n.t("library.newPlaylist")}
          </button>
        </form>

        {#if library.playlists.length === 0}
          {@render emptyState("list", i18n.t("library.emptyPlaylists"))}
        {:else}
          <div class="card overflow-hidden rounded-2xl">
            {#each library.playlists as playlist (playlist.id)}
              <div
                class="group flex items-center gap-3 border-b border-line/50 px-4 py-3 last:border-0 transition-colors hover:bg-primary-soft/35"
              >
                <button
                  type="button"
                  onclick={() => nav.go("library", playlist.id)}
                  class="flex min-w-0 flex-1 items-center gap-3 text-start"
                >
                  <span
                    class="grid size-10 shrink-0 place-items-center rounded-xl border border-line text-primary group-hover:border-primary/30"
                  >
                    <Icon name="list" size={16} />
                  </span>
                  <span class="min-w-0">
                    <span class="block truncate text-sm font-medium text-text group-hover:text-primary">
                      {playlist.name}
                    </span>
                    <span class="block text-[11px] text-muted">
                      {fmtNumber(playlist.trackCount)} {i18n.t("library.tracks")}
                    </span>
                  </span>
                </button>
                <Icon
                  name="chevron"
                  size={14}
                  class="shrink-0 text-muted opacity-0 transition-opacity group-hover:opacity-100"
                />
              </div>
            {/each}
          </div>
        {/if}
      {:else if tab === "downloads"}
        {#if library.storage}
          {@const st = library.storage}
          <div class="card mb-4 rounded-2xl p-4">
            <div class="flex flex-wrap items-center gap-4">
              <div class="min-w-0 flex-1">
                <p class="text-[10px] font-bold uppercase tracking-[0.18em] text-accent-ink">
                  {i18n.t("library.storage")}
                </p>
                <p class="mt-1 text-xl font-bold text-text">
                  {fmtBytes(st.totalBytes) || "0 KB"}
                </p>
                <div class="mt-1 flex flex-wrap gap-x-3 gap-y-1 text-[10px] text-muted">
                  <span>{i18n.t("library.storageDownloaded")}: {fmtBytes(st.downloadedBytes) || "0 KB"}</span>
                  {#if st.partialBytes}
                    <span>{i18n.t("library.storagePartial")}: {fmtBytes(st.partialBytes)}</span>
                  {/if}
                  {#if st.localBytes}
                    <span>{i18n.t("library.storageLocal")}: {fmtBytes(st.localBytes)}</span>
                  {/if}
                  {#if st.active}
                    <span class="text-accent-ink">{i18n.t("library.storageActive")}: {fmtNumber(st.active)}</span>
                  {/if}
                  {#if st.queued}
                    <span>{i18n.t("library.storageQueued")}: {fmtNumber(st.queued)}</span>
                  {/if}
                </div>
              </div>
              <div class="flex flex-wrap items-center gap-2">
                {#if busyDownloads.length > 0}
                  <button
                    type="button"
                    onclick={cancelAll}
                    class="rounded-lg border border-line px-2.5 py-1.5 text-[11px] text-muted transition-colors hover:border-red-400/40 hover:text-red-400"
                  >
                    {i18n.t("library.cancelAll")}
                  </button>
                {/if}
                {#if removableDownloads.length > 0}
                  <button
                    type="button"
                    onclick={toggleSelectAll}
                    class="rounded-lg border border-line px-2.5 py-1.5 text-[11px] text-muted transition-colors hover:border-primary/40 hover:text-primary"
                  >
                    {i18n.t(allSelected ? "library.deselectAll" : "library.selectAll")}
                  </button>
                  <button
                    type="button"
                    onclick={deleteSelected}
                    disabled={selectedCount === 0}
                    class="flex items-center gap-1.5 rounded-lg border border-red-400/30 bg-red-400/10 px-2.5 py-1.5 text-[11px] text-red-300 transition-colors hover:bg-red-400/15 disabled:cursor-not-allowed disabled:opacity-40"
                  >
                    <Icon name="x" size={12} />
                    {i18n.t("library.deleteSelected")}
                    {#if selectedCount}<span class="tabular-nums">({fmtNumber(selectedCount)})</span>{/if}
                  </button>
                {/if}
              </div>
            </div>
          </div>
        {/if}

        {#if library.downloads.length === 0}
          {@render emptyState("download", i18n.t("library.emptyDownloads"))}
        {:else}
          <div class="card overflow-hidden rounded-2xl">
            {#each library.downloads as row (row.track.id)}
              {@const busy = row.status === "queued" || row.status === "downloading"}
              {@const pct = row.bytesTotal > 0 ? Math.round((row.bytesDone / row.bytesTotal) * 100) : 0}
              {@const picked = selectedDownloads.includes(row.track.id)}
              <div class="flex items-center gap-3 border-b border-line/50 px-3 py-2.5 last:border-0">
                <button
                  type="button"
                  role="checkbox"
                  aria-checked={picked}
                  disabled={busy}
                  onclick={() => toggleSelected(row.track.id)}
                  class="grid size-5 shrink-0 place-items-center rounded-md border transition-colors
                         {picked
                    ? 'border-primary/50 bg-primary-soft text-primary'
                    : 'border-line text-transparent hover:border-primary/40'}
                         disabled:opacity-30"
                  aria-label={row.track.title}
                >
                  <Icon name="check" size={11} />
                </button>
                <button
                  type="button"
                  onclick={() => {
                    if (row.status === "done") player.play(row.track);
                    else if (!busy) void library.startDownload(row.track);
                  }}
                  disabled={busy}
                  class="grid size-10 shrink-0 place-items-center rounded-xl border border-line text-primary disabled:opacity-40"
                  aria-label={row.status === "done" ? i18n.t("player.play") : i18n.t("library.retryDownload")}
                >
                  <Icon
                    name={row.status === "done" ? "play" : busy ? "download" : "repeat"}
                    size={15}
                  />
                </button>
                <div class="min-w-0 flex-1">
                  <div class="truncate text-sm text-text">{row.track.title}</div>
                  <div class="truncate text-[11px] text-muted">{row.track.artist}</div>
                  {#if busy}
                    <div class="mt-1.5 flex items-center gap-2">
                      <span
                        class="h-1 flex-1 overflow-hidden rounded-full bg-line"
                        role="progressbar"
                        aria-valuemin="0"
                        aria-valuemax="100"
                        aria-valuenow={pct}
                        aria-label={row.track.title}
                      >
                        <span class="block h-full rounded-full bg-accent transition-[width]" style="width: {pct}%"></span>
                      </span>
                      <span class="shrink-0 text-[10px] tabular-nums text-muted">
                        {row.status === "queued" ? i18n.t("library.storageQueued") : `${pct}%`}
                      </span>
                    </div>
                  {:else if row.status === "done"}
                    <div class="mt-0.5 text-[10px] text-primary">
                      {i18n.t("library.downloaded")}
                      {#if row.bytesTotal} · {fmtBytes(row.bytesTotal)}{/if}
                    </div>
                  {:else if row.status === "cancelled"}
                    <div class="mt-0.5 text-[10px] text-muted">
                      {i18n.t("library.downloadCancelled")}
                    </div>
                  {:else if row.status === "error"}
                    <div class="mt-0.5 truncate text-[10px] text-red-400">
                      {downloadError(row.error)}
                    </div>
                  {/if}
                </div>
                <button
                  type="button"
                  onclick={() =>
                    busy
                      ? library.cancelDownload(row.track.id)
                      : library.removeDownloads([row.track.id]).then(() => {
                          selectedDownloads = selectedDownloads.filter((id) => id !== row.track.id);
                        })}
                  class="rounded-lg p-1.5 text-muted transition-colors hover:text-red-400"
                  aria-label={busy ? i18n.t("library.cancelDownload") : i18n.t("library.deleteDownload")}
                >
                  <Icon name={busy ? "pause" : "x"} size={14} />
                </button>
              </div>
            {/each}
          </div>
        {/if}
      {:else if tab === "local"}
        <div class="mb-4 flex flex-wrap items-center gap-3">
          <button
            type="button"
            onclick={() => library.importFolders()}
            class="flex items-center gap-2 rounded-xl border border-primary/40 bg-primary-soft px-3.5 py-2 text-xs font-semibold text-primary transition-colors hover:bg-primary-soft/70"
          >
            <Icon name="download" size={13} />
            {i18n.t("library.importFolder")}
          </button>
          <span class="text-[11px] text-muted">
            {fmtNumber(library.local.length)} {i18n.t("library.tracks")}
          </span>
        </div>

        {#if library.local.length === 0}
          {@render emptyState("disc", i18n.t("library.emptyLocal"))}
        {:else}
          {@render trackList(library.local, (track) => library.forgetLocalTrack(track.id))}
        {/if}
      {:else if tab === "hifz"}
        {#if hifzRows.length === 0}
          {@render emptyState("bookmark", i18n.t("library.noHifz"))}
        {:else}
          <div class="card overflow-hidden rounded-2xl">
            {#each hifzRows as { row, surah } (row.surah)}
              {@const pct = surah.ayahs > 0 ? Math.round((row.memorized.length / surah.ayahs) * 100) : 0}
              <button
                type="button"
                onclick={() =>
                  nav.go("quran", "ayah", DEFAULT_AYAH_RECITER, surah.number)}
                class="group flex w-full items-center gap-3 border-b border-line/50 px-4 py-3 text-start transition-colors last:border-0 hover:bg-primary-soft/35"
              >
                <span
                  class="grid size-9 shrink-0 place-items-center rounded-lg border border-line text-[11px] tabular-nums text-muted group-hover:border-primary/30 group-hover:text-primary"
                >
                  {fmtNumber(surah.number)}
                </span>
                <span class="min-w-0 flex-1">
                  <span class="block truncate font-quran text-[1.05rem] leading-snug text-text group-hover:text-primary">
                    {shortName(surah.name)}
                  </span>
                  <span class="mt-1 block h-1 w-full max-w-40 overflow-hidden rounded-full bg-line">
                    <span class="block h-full rounded-full bg-accent" style="width: {pct}%"></span>
                  </span>
                </span>
                <span class="shrink-0 text-[11px] tabular-nums text-primary">
                  {fmtNumber(row.memorized.length)} / {fmtNumber(surah.ayahs)}
                </span>
                <Icon
                  name="chevron"
                  size={13}
                  class="shrink-0 text-muted opacity-0 transition-opacity group-hover:opacity-100"
                />
              </button>
            {/each}
          </div>
        {/if}
      {/if}
    </div>
  {/if}
</div>
