<script lang="ts">
  import { onMount } from "svelte";
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { logComplete, logCount, worship } from "$lib/stores/worship.svelte.ts";
  import { nearestCity } from "$lib/data/cities";
  import NextPrayer from "$lib/components/NextPrayer.svelte";
  import PrayerTimeline from "$lib/components/PrayerTimeline.svelte";
  import QiblaDial from "$lib/components/QiblaDial.svelte";
  import Icon from "$lib/components/Icon.svelte";

  onMount(() => {
    if (!worship.day) void worship.load();
    worship.start();
  });

  const day = $derived(worship.day);
  const log = $derived(worship.todayLog);
  const streak = $derived(worship.streak);
  const settings = $derived(worship.settings);
  const complete = $derived(logComplete(log));
  const excused = $derived(log.excused);

  const city = $derived(
    settings ? nearestCity(settings.latitude, settings.longitude) : null,
  );

  function distanceKm(lat1: number, lon1: number, lat2: number, lon2: number) {
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos((lat1 * Math.PI) / 180) *
        Math.cos((lat2 * Math.PI) / 180) *
        Math.sin(dLon / 2) ** 2;
    return 6371.0088 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  const atKaaba = $derived(
    !!settings &&
      distanceKm(settings.latitude, settings.longitude, 21.4225241, 39.8261818) < 0.05,
  );

  const week = $derived.by(() => {
    if (!day) return [];
    const base = new Date(day.date + "T00:00:00");
    const formatter = new Intl.DateTimeFormat(i18n.locale === "ar" ? "ar" : "en", {
      weekday: "short",
    });
    const rows = [];
    for (let offset = 6; offset >= 0; offset -= 1) {
      const date = new Date(base);
      date.setDate(date.getDate() - offset);
      const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(
        date.getDate(),
      ).padStart(2, "0")}`;
      const entry = worship.logs.find((item) => item.date === key);
      rows.push({
        key,
        weekday: formatter.format(date),
        day: date.getDate(),
        complete: logComplete(entry),
        excused: entry?.excused ?? false,
        partial: logCount(entry) > 0,
        count: logCount(entry),
        today: key === day.date,
      });
    }
    return rows;
  });

  const streakLabel = $derived(
    (streak?.current ?? 0) === 1
      ? i18n.t("prayer.streakOne")
      : i18n.t("prayer.streakDays", { count: fmtNumber(streak?.current ?? 0) }),
  );
</script>

<div class="fade-in">
  <header class="flex flex-wrap items-start justify-between gap-4">
    <div>
      <p class="text-[10px] font-bold uppercase tracking-[0.24em] text-accent-ink">{i18n.t("app.name")}</p>
      <h1 class="mt-1 text-2xl font-bold text-text">{i18n.t("prayer.title")}</h1>
      <p class="mt-1 text-sm text-muted">{i18n.t("prayer.subtitle")}</p>
    </div>
    <button
      type="button"
      onclick={() => nav.go("settings")}
      class="btn btn-outline"
    >
      <Icon name="settings" size={14} />
      {i18n.t("prayer.openSettings")}
    </button>
  </header>

  {#if settings && !settings.configured}
    <button
      type="button"
      onclick={() => nav.go("settings")}
      class="mt-4 flex w-full items-center gap-3 rounded-2xl border border-accent/30 bg-accent/5 px-4 py-3 text-start transition-colors hover:border-accent/50"
    >
      <span class="grid size-9 shrink-0 place-items-center rounded-xl bg-accent/12 text-accent-ink">
        <Icon name="compass" size={17} />
      </span>
      <span class="min-w-0 flex-1">
        <span class="block text-sm font-semibold text-text">{i18n.t("prayer.notConfigured")}</span>
        <span class="mt-0.5 block text-xs text-muted">{i18n.t("settings.prayerHint")}</span>
      </span>
      <Icon name="chevron" size={16} class="shrink-0 text-accent-ink rtl:rotate-180" />
    </button>
  {/if}

  <NextPrayer showLink={false} showSetup={false} />

  {#if worship.error && !day}
    <div class="card mt-6 rounded-2xl px-6 py-10 text-center">
      <Icon name="compass" size={26} class="mx-auto text-muted" />
      <p class="mt-3 text-sm text-muted">{i18n.t("prayer.error")}</p>
      <button
        type="button"
        onclick={() => worship.load()}
        class="btn btn-outline mt-4"
      >
        {i18n.t("prayer.retry")}
      </button>
    </div>
  {:else if day}
    <div class="mt-4 grid gap-4 lg:grid-cols-[minmax(0,1.08fr)_minmax(0,0.92fr)]">
      <section class="card rounded-2xl p-5">
        <div class="flex flex-wrap items-center justify-between gap-2">
          <h2 class="text-sm font-semibold text-text">{i18n.t("prayer.today")}</h2>
          <span
            class="pill {complete ? 'pill-primary' : ''}"
          >
            {complete
              ? i18n.t("prayer.todayComplete")
              : i18n.t("prayer.todayCount", { count: fmtNumber(logCount(log)) })}
          </span>
        </div>
        <p class="mt-1 text-xs text-muted">{i18n.t("prayer.logHint")}</p>

        <div class="mt-3">
          <PrayerTimeline
            {day}
            {log}
            disabled={worship.pending}
            ontoggle={(prayer) => worship.togglePrayer(prayer)}
          />
        </div>

        <div class="mt-4 flex items-start justify-between gap-4 rounded-xl border border-line bg-canvas/60 px-3.5 py-3">
          <div class="min-w-0">
            <div class="text-sm text-text">{i18n.t("prayer.excused")}</div>
            <p class="mt-1 text-[11px] leading-relaxed text-muted">{i18n.t("prayer.excusedHint")}</p>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={excused}
            aria-label={i18n.t("prayer.excused")}
            disabled={worship.pending}
            onclick={() => worship.setExcused(!excused)}
            class="relative mt-0.5 h-6 w-11 shrink-0 rounded-full border transition-colors disabled:opacity-50
                   {excused ? 'border-primary/60 bg-primary/70' : 'border-line bg-raised'}"
          >
            <span
              class="absolute top-[3px] size-[18px] rounded-full bg-surface shadow transition-all
                     {excused ? 'start-[22px]' : 'start-[3px]'}"
            ></span>
          </button>
        </div>
      </section>

      <div class="flex flex-col gap-4">
        <section class="card rounded-2xl p-5">
          <div class="flex items-center justify-between gap-2">
            <h2 class="flex items-center gap-2 text-sm font-semibold text-text">
              <Icon name="flame" size={15} class="text-primary" />
              {i18n.t("prayer.streak")}
            </h2>
            <span class="text-[11px] text-muted">
              {i18n.t("prayer.streakBest", { count: fmtNumber(streak?.best ?? 0) })}
            </span>
          </div>

          <p class="mt-3 text-2xl font-bold text-text">{streakLabel}</p>
          <p class="mt-1 text-[11px] leading-relaxed text-muted">{i18n.t("prayer.streakHint")}</p>

          <div class="mt-4">
            <div class="flex items-center justify-between">
              <span class="text-[10px] font-semibold uppercase tracking-wider text-muted">{i18n.t("prayer.week")}</span>
            </div>
            <div class="mt-2 grid grid-cols-7 gap-1.5">
              {#each week as entry (entry.key)}
                <div
                  role="img"
                  aria-label={`${entry.weekday} ${entry.day}: ${
                    entry.excused
                      ? i18n.t("prayer.excused")
                      : i18n.t("prayer.todayCount", { count: fmtNumber(entry.count) })
                  }`}
                  class="flex flex-col items-center gap-1 rounded-lg border px-1 py-1.5
                         {entry.excused
                    ? 'border-primary/30 bg-primary-soft/70'
                    : entry.complete
                      ? 'border-primary/40 bg-primary-soft'
                      : entry.partial
                        ? 'border-accent/25 bg-accent/5'
                        : 'border-line bg-canvas/50'}
                         {entry.today ? 'ring-1 ring-primary/40' : ''}"
                  title={entry.key}
                >
                  <span class="text-[9px] text-muted">{entry.weekday}</span>
                  <span class="text-[11px] font-semibold tabular-nums text-text">{fmtNumber(entry.day)}</span>
                  <span
                    class="size-1.5 rounded-full
                           {entry.excused ? 'bg-primary' : entry.complete ? 'bg-primary' : entry.partial ? 'bg-accent' : 'bg-line'}"
                  ></span>
                </div>
              {/each}
            </div>
          </div>
        </section>

        <section class="card rounded-2xl p-5">
          <div class="flex items-center justify-between gap-2">
            <h2 class="flex items-center gap-2 text-sm font-semibold text-text">
              <Icon name="compass" size={15} class="text-primary" />
              {i18n.t("prayer.qibla")}
            </h2>
            <span class="text-[11px] text-muted">
              {i18n.t("prayer.location")}:
              {city
                ? i18n.locale === "ar"
                  ? city.name
                  : city.nameEn
                : i18n.t("settings.customLocation")}
            </span>
          </div>
          <div class="mt-4">
            {#if atKaaba}
              <p class="rounded-xl border border-accent/25 bg-accent/5 px-3 py-4 text-center text-xs leading-relaxed text-accent-ink">
                {i18n.t("prayer.atKaaba")}
              </p>
            {:else}
              <QiblaDial bearing={day.qibla} />
            {/if}
          </div>
          <p class="mt-3 flex flex-wrap gap-x-3 gap-y-1 text-[10px] tabular-nums text-muted">
            <span>{i18n.t("settings.latitude")} {(settings?.latitude ?? 0).toFixed(3)}°</span>
            <span>{i18n.t("settings.longitude")} {(settings?.longitude ?? 0).toFixed(3)}°</span>
          </p>
        </section>
      </div>
    </div>
  {/if}
</div>
