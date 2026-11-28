<script lang="ts">
  import { onMount } from "svelte";
  import { api } from "$lib/api";
  import type { Track } from "$lib/types";
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import { countries, countryName } from "$lib/data/countries.ts";
  import TrackRow from "$lib/components/TrackRow.svelte";
  import Icon from "$lib/components/Icon.svelte";

  let country = $state("SA");
  let tag = $state("");
  let stations = $state<Track[]>([]);
  let loading = $state(true);
  let failed = $state(false);

  const tags = [
    { value: "", key: "radio.all" as const },
    { value: "quran", key: "radio.quran" as const },
    { value: "nasheed", key: "radio.anasheed" as const },
  ];

  onMount(load);

  async function load() {
    loading = true;
    failed = false;
    try {
      stations = await api.radios(80, country || undefined, tag || undefined);
    } catch {
      stations = [];
      failed = true;
    } finally {
      loading = false;
    }
  }

  async function setCountry(code: string) {
    country = code;
    await load();
  }

  async function setTag(value: string) {
    tag = value;
    await load();
  }
</script>

<div class="fade-in">
  <header>
    <p class="text-[10px] font-bold uppercase tracking-[0.22em] text-accent-ink">
      {i18n.t("radio.subtitle")}
    </p>
    <h1 class="mt-1 text-2xl font-bold text-text">{i18n.t("radio.title")}</h1>
  </header>

  <div class="mt-5 flex flex-wrap items-center gap-2">
    <button
      type="button"
      onclick={() => setTag("")}
      class="chip"
      data-active={tag === "" ? "true" : "false"}
    >
      {i18n.t("search.filterAll")}
    </button>
    {#each tags.slice(1) as t (t.value)}
      <button
        type="button"
        onclick={() => setTag(t.value)}
        class="chip"
        data-active={tag === t.value ? "true" : "false"}
      >
        {i18n.t(t.key)}
      </button>
    {/each}

    <span class="mx-1 h-4 w-px bg-line"></span>

    <select
      value={country}
      onchange={(e) => setCountry((e.currentTarget as HTMLSelectElement).value)}
      class="rounded-full border border-line bg-surface px-3 py-1.5 text-[11px] text-text focus:border-primary/60 focus:outline-none"
      aria-label={i18n.t("radio.all")}
    >
      <option value="">{i18n.t("radio.all")}</option>
      {#each countries as c (c.code)}
        <option value={c.code}>{countryName(c.code, i18n.locale)}</option>
      {/each}
    </select>
  </div>

  {#if loading}
    <div class="mt-6 space-y-1">
      {#each Array(12) as _, i (i)}
        <div class="flex animate-pulse items-center gap-3 px-2.5 py-2">
          <div class="size-11 rounded-lg bg-primary-soft"></div>
          <div class="h-3 w-48 rounded bg-primary-soft"></div>
        </div>
      {/each}
    </div>
  {:else if failed}
    <div class="card mt-10 rounded-2xl px-6 py-10 text-center">
      <Icon name="globe" size={26} class="mx-auto text-muted" />
      <p class="mt-3 text-sm text-muted">{i18n.t("common.offline")}</p>
      <button
        type="button"
        class="btn btn-outline mt-4"
        onclick={load}>{i18n.t("common.retry")}</button
      >
    </div>
  {:else if stations.length === 0}
    <p class="mt-10 text-sm text-muted">{i18n.t("search.empty")}</p>
  {:else}
    <div class="card mt-6 overflow-hidden rounded-2xl p-1.5">
      {#each stations as station (station.id)}
        <TrackRow track={station} queue={stations} />
      {/each}
    </div>
  {/if}
</div>
