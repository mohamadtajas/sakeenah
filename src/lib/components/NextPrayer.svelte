<script lang="ts">
  import { fmtNumber, fmtTime, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { worship } from "$lib/stores/worship.svelte.ts";
  import type { TranslationKey } from "$lib/i18n/dict";
  import Icon from "./Icon.svelte";

  let { showLink = true, showSetup = true }: { showLink?: boolean; showSetup?: boolean } = $props();

  const day = $derived(worship.day);
  const unconfigured = $derived(!!worship.settings && !worship.settings.configured);
  const next = $derived(day?.next ?? null);
  const hijri = $derived(day?.hijri ?? null);
  const hijriText = $derived(
    hijri
      ? i18n.locale === "ar"
        ? hijri.formatted
        : `${hijri.day} ${hijri.monthNameEn} ${hijri.year} AH`
      : "",
  );
  const streak = $derived(worship.streak);
  const excused = $derived(worship.todayLog.excused);

  const label = (key: string) => i18n.t(`prayer.${key}` as TranslationKey);
  const prayerTimes = $derived((day?.times ?? []).filter((time) => time.key !== "sunrise"));
  // After Isha `next` is tomorrow's Fajr; it must not highlight today's row.
  const nextIsToday = $derived(!!day && !!next && next.iso.startsWith(day.date));
</script>

<section
  class="card relative mt-6 overflow-hidden rounded-2xl"
>
  <div class="pointer-events-none absolute -end-16 -top-20 size-56 rounded-full bg-accent/[0.08] blur-3xl"></div>
  <div class="pointer-events-none absolute -bottom-24 start-1/3 size-52 rounded-full bg-primary/[0.06] blur-3xl"></div>

  {#if showSetup && unconfigured}
    <button
      type="button"
      onclick={() => nav.go("settings")}
      class="relative flex w-full items-center gap-2 border-b border-accent/25 bg-accent/5 px-6 py-2 text-start text-[11px] text-accent-ink transition-colors hover:bg-accent/10"
    >
      <Icon name="compass" size={13} class="shrink-0" />
      <span class="min-w-0 flex-1">{i18n.t("prayer.notConfigured")}</span>
      <span class="shrink-0 font-semibold">{i18n.t("prayer.openSettings")}</span>
    </button>
  {/if}

  {#if day && next && !unconfigured}
    <div class="relative flex flex-col gap-7 px-6 py-6 lg:flex-row lg:items-center lg:justify-between">
      <div class="min-w-0">
        <div class="flex flex-wrap items-center gap-x-3 gap-y-1 text-[11px] font-medium text-accent-ink">
          <span class="flex items-center gap-1.5"><Icon name="moon" size={13} />{hijriText}</span>
          <span class="text-muted/60">·</span>
          <span class="text-muted">{i18n.t("prayer.calculated")}</span>
        </div>

        <div class="mt-3 flex flex-wrap items-baseline gap-x-3 gap-y-1">
          <span class="text-sm text-muted">{i18n.t("prayer.next")}</span>
          <h2 class="font-quran text-[1.7rem] leading-tight text-primary">
            {next.key === "dhuhr" && new Date(day.date + "T12:00:00").getDay() === 5
              ? i18n.t("prayer.jumuah")
              : label(next.key)}
          </h2>
          <span class="text-[1.7rem] font-bold tabular-nums text-accent-ink">{next.time}</span>
        </div>

        <p class="mt-1.5 text-sm text-muted">
          <span class="tabular-nums text-text">{fmtTime(worship.remaining)}</span>
          <span class="mx-1.5">·</span>
          {i18n.t("prayer.left")}
          {#if day.timezone}<span class="mx-1.5">·</span><span class="text-xs">{day.timezone}</span>{/if}
        </p>
      </div>

      <div class="flex flex-wrap items-stretch gap-1.5">
        {#each prayerTimes as time (time.key)}
          {@const active = nextIsToday && time.key === next.key}
          {@const done = worship.todayLog[time.key as "fajr" | "dhuhr" | "asr" | "maghrib" | "isha"]}
          <div
            class="flex min-w-[4.3rem] flex-col items-center rounded-xl border px-2.5 py-2 transition-colors
                   {active
              ? 'border-primary/40 bg-primary-soft'
              : done
                ? 'border-primary/20 bg-primary-soft/40'
                : 'border-line/70 bg-canvas/60'}"
          >
            <span class="text-[10px] font-medium {active ? 'text-primary' : 'text-muted'}">{label(time.key)}</span>
            <span class="mt-0.5 text-[13px] font-semibold tabular-nums {time.passed ? 'text-muted' : 'text-text'}">
              {time.time}
            </span>
            <span class="mt-1 h-1 w-1 rounded-full {done ? 'bg-primary' : active ? 'bg-accent' : 'bg-line'}"></span>
          </div>
        {/each}
      </div>
    </div>

    <div class="relative flex flex-wrap items-center justify-between gap-3 border-t border-line/70 px-6 py-3">
      <div class="flex flex-wrap items-center gap-2 text-[11px]">
        <span class="pill pill-accent">
          <Icon name="flame" size={12} />
          {streak?.current === 1
            ? i18n.t("prayer.streakOne")
            : i18n.t("prayer.streakDays", { count: fmtNumber(streak?.current ?? 0) })}
        </span>
        {#if excused}
          <span class="pill pill-primary">{i18n.t("prayer.excused")}</span>
        {:else}
          <span class="pill">
            {i18n.t("prayer.todayCount", { count: fmtNumber(streak?.todayCount ?? 0) })}
          </span>
        {/if}
        {#if worship.error}
          <span class="pill pill-accent">
            {i18n.t("prayer.stale")}
          </span>
        {/if}
      </div>

      {#if showLink}
        <button
          type="button"
          onclick={() => nav.go("worship")}
          class="btn btn-outline min-h-0 px-2.5 py-1.5 text-[11px]"
        >
          <Icon name="compass" size={13} />
          {i18n.t("prayer.viewAll")}
        </button>
      {/if}
    </div>
  {:else if unconfigured}
    <div class="relative flex min-h-[8rem] flex-col items-center justify-center gap-2 px-6 py-6 text-center">
      <Icon name="compass" size={24} class="text-muted" />
      <p class="text-xs text-muted">{i18n.t("prayer.notConfigured")}</p>
    </div>
  {:else}
    <div class="flex h-[9.5rem] animate-pulse items-center justify-center px-6">
      <p class="text-sm text-muted">{i18n.t(worship.error ? "prayer.error" : "prayer.loading")}</p>
    </div>
  {/if}
</section>
