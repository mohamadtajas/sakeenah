<script lang="ts">
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { adhkar } from "$lib/stores/adhkar.svelte.ts";
  import Icon from "./Icon.svelte";

  let { embedded = false }: { embedded?: boolean } = $props();

  const morning = adhkar.categories.find((category) => category.streakKey === "morning")!;
  const evening = adhkar.categories.find((category) => category.streakKey === "evening")!;
  const streak = $derived(adhkar.streak);

  const streakLabel = $derived(
    (streak?.current ?? 0) === 1
      ? i18n.t("adhkar.streakOne")
      : i18n.t("adhkar.streakDays", { count: fmtNumber(streak?.current ?? 0) }),
  );

  function open(id: string) {
    nav.go("adhkar", id);
  }
</script>

<section class={embedded ? "" : "mt-4"}>
  {#if !embedded}
    <div class="flex flex-wrap items-center justify-between gap-2">
      <h2 class="flex items-center gap-2 text-sm font-semibold text-text">
        <Icon name="moon" size={15} class="text-primary" />
        {i18n.t("adhkar.title")}
      </h2>
      <div class="flex items-center gap-2">
        <span class="pill pill-accent">
          <Icon name="flame" size={11} />
          {streakLabel}
        </span>
        <button
          type="button"
          onclick={() => nav.go("adhkar")}
          class="rounded-lg border border-line px-2.5 py-1.5 text-[11px] text-muted transition-colors hover:border-primary/40 hover:text-primary"
        >
          {i18n.t("adhkar.open")}
        </button>
      </div>
    </div>
  {/if}

  <div class="{embedded ? '' : 'mt-2.5'} grid gap-3 sm:grid-cols-2">
    {#each [{ category: morning, icon: "sun" }, { category: evening, icon: "moon" }] as entry (entry.category.id)}
      {@const done = adhkar.isComplete(entry.category)}
      {@const percent = adhkar.percent(entry.category)}
      <button
        type="button"
        onclick={() => open(entry.category.id)}
        class="group rounded-2xl border border-line bg-surface p-4 text-start shadow-card transition-colors hover:border-primary/35"
      >
        <div class="flex items-center justify-between gap-3">
          <span class="grid size-9 shrink-0 place-items-center rounded-xl bg-accent/10 text-accent-ink">
            <Icon name={entry.icon as "sun" | "moon"} size={16} />
          </span>
          <span
            class="rounded-full border px-2 py-0.5 text-[10px] font-medium
                   {done
              ? 'border-primary/35 bg-primary-soft text-primary'
              : 'border-line text-muted'}"
          >
            {done ? i18n.t("adhkar.todayDone") : `${fmtNumber(percent)}%`}
          </span>
        </div>

        <p dir="rtl" lang="ar" class="mt-3 text-sm font-semibold text-text group-hover:text-primary">
          {entry.category.title}
        </p>
        <p class="mt-0.5 text-[10px] text-muted">
          {i18n.t("adhkar.items", { count: fmtNumber(entry.category.items.length) })}
          <span class="mx-1">·</span>
          {i18n.t("adhkar.repeats", { count: fmtNumber(adhkar.totalRepeats(entry.category)) })}
        </p>

        <div class="mt-2.5 h-1.5 overflow-hidden rounded-full bg-line">
          <div
            class="h-full rounded-full transition-[width] duration-300 {done ? 'bg-primary' : 'bg-accent'}"
            style={`width: ${percent}%`}
          ></div>
        </div>
        <p class="mt-1.5 text-[10px] text-muted">
          {i18n.t("adhkar.progress", {
            done: fmtNumber(adhkar.completedItems(entry.category)),
            total: fmtNumber(entry.category.items.length),
          })}
        </p>
      </button>
    {/each}
  </div>
</section>
