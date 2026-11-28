<script lang="ts">
  import { fmtNumber, i18n } from "$lib/i18n/index.svelte.ts";
  import Icon from "./Icon.svelte";

  let { bearing }: { bearing: number } = $props();

  /** Manual compass heading: the user rotates the dial to face true north. */
  let heading = $state(0);

  const degrees = $derived(Math.round(bearing));
  const cardinals = [
    { label: "N", x: 100, y: 26 },
    { label: "E", x: 174, y: 104 },
    { label: "S", x: 100, y: 182 },
    { label: "W", x: 26, y: 104 },
  ];
</script>

<div class="flex flex-col gap-4 sm:flex-row sm:items-center">
  <div class="relative mx-auto w-full max-w-[13.5rem] shrink-0">
    <svg viewBox="0 0 200 200" role="img" aria-label={i18n.t("prayer.qibla")} class="w-full">
      <circle cx="100" cy="100" r="94" style="fill: var(--color-ink-850); stroke: var(--color-line)" stroke-width="1.5" />
      <circle cx="100" cy="100" r="74" fill="none" style="stroke: var(--color-line)" stroke-width="0.75" opacity="0.6" />

      <!-- Rose: rotates with the manual heading so N can be aligned to true north. -->
      <g transform="rotate({-heading} 100 100)">
        {#each Array(24) as _, i}
          <line
            x1="100"
            y1="10"
            x2="100"
            y2={i % 6 === 0 ? 19 : 14}
            transform="rotate({i * 15} 100 100)"
            style="stroke: var(--color-line)"
            stroke-width={i % 6 === 0 ? 2 : 1}
          />
        {/each}
        {#each cardinals as point (point.label)}
          <text
            x={point.x}
            y={point.y}
            text-anchor="middle"
            font-size={point.label === "N" ? 15 : 12}
            font-weight="700"
            style="fill: {point.label === 'N' ? 'var(--color-gold)' : 'var(--color-muted)'}"
          >
            {point.label}
          </text>
        {/each}
      </g>

      <!-- Qibla needle: rotated relative to the manually aligned rose so the
           angle from N always reads as the true bearing. -->
      <g transform="rotate({bearing - heading} 100 100)">
        <polygon points="100,26 94,100 106,100" style="fill: var(--color-gold)" />
        <polygon points="100,174 96,100 104,100" style="fill: var(--color-line)" />
        <g transform="rotate({-(bearing - heading)} 100 18)">
          <rect
            x="93"
            y="11"
            width="14"
            height="14"
            rx="2.5"
            style="fill: var(--color-ink-950); stroke: var(--color-gold)"
            stroke-width="1.5"
          />
          <rect x="93" y="16" width="14" height="3" style="fill: var(--color-gold)" />
        </g>
      </g>

      <circle cx="100" cy="100" r="7" style="fill: var(--color-ink-900); stroke: var(--color-gold)" stroke-width="2" />
    </svg>
  </div>

  <div class="min-w-0 flex-1">
    <p class="text-sm font-semibold text-text">{i18n.t("prayer.qiblaBearing", { degrees: fmtNumber(degrees) })}</p>
    <p class="mt-1 text-xs leading-relaxed text-muted">{i18n.t("prayer.qiblaHint")}</p>

    <label class="mt-4 block text-[11px] text-muted" for="qibla-heading">{i18n.t("prayer.qiblaHeading")}</label>
    <div class="mt-1.5 flex items-center gap-2">
      <button
        type="button"
        onclick={() => (heading = (heading + 345) % 360)}
        class="grid size-8 shrink-0 place-items-center rounded-lg border border-line text-muted transition-colors hover:border-primary/40 hover:text-primary"
        aria-label={i18n.t("prayer.qiblaRotateLeft")}
      >
        <Icon name="chevron" size={14} class="rotate-180 rtl:rotate-0" />
      </button>
      <input
        id="qibla-heading"
        type="range"
        min="0"
        max="359"
        step="1"
        bind:value={heading}
        class="h-1.5 w-full cursor-pointer appearance-none rounded-full bg-line accent-[var(--color-accent)]"
      />
      <button
        type="button"
        onclick={() => (heading = (heading + 15) % 360)}
        class="grid size-8 shrink-0 place-items-center rounded-lg border border-line text-muted transition-colors hover:border-primary/40 hover:text-primary"
        aria-label={i18n.t("prayer.qiblaRotateRight")}
      >
        <Icon name="chevron" size={14} />
      </button>
      <button
        type="button"
        onclick={() => (heading = 0)}
        class="shrink-0 rounded-lg border border-line px-2.5 py-1.5 text-[10px] text-muted transition-colors hover:border-primary/40 hover:text-primary"
      >
        {i18n.t("prayer.qiblaReset")}
      </button>
    </div>
  </div>
</div>
