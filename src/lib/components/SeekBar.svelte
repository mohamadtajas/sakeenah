<script lang="ts">
  let {
    value,
    max,
    onseek,
    disabled = false,
    label = "",
    step = 5,
    class: klass = "",
  }: {
    value: number;
    max: number;
    onseek: (v: number) => void;
    disabled?: boolean;
    label?: string;
    step?: number;
    class?: string;
  } = $props();

  let bar = $state<HTMLDivElement>();
  let dragging = $state(false);

  const pct = $derived(max > 0 ? Math.min(100, Math.max(0, (value / max) * 100)) : 0);

  function pick(e: PointerEvent) {
    if (!bar || max <= 0) return;
    const r = bar.getBoundingClientRect();
    const rtl = getComputedStyle(bar).direction === "rtl";
    const f = rtl ? (r.right - e.clientX) / r.width : (e.clientX - r.left) / r.width;
    onseek(Math.min(1, Math.max(0, f)) * max);
  }

  function down(e: PointerEvent) {
    if (disabled) return;
    dragging = true;
    bar?.setPointerCapture(e.pointerId);
    pick(e);
  }

  function move(e: PointerEvent) {
    if (dragging) pick(e);
  }

  function up(e: PointerEvent) {
    dragging = false;
    bar?.releasePointerCapture(e.pointerId);
  }
</script>

<div
  bind:this={bar}
  role="slider"
  tabindex={disabled ? -1 : 0}
  aria-label={label || undefined}
  aria-valuemin={0}
  aria-valuemax={max}
  aria-valuenow={value}
  onpointerdown={down}
  onpointermove={move}
  onpointerup={up}
  onpointercancel={up}
  onkeydown={(e) => {
    if (disabled) return;
    const nudge = (delta: number) => {
      const next = Math.min(max, Math.max(0, value + delta));
      onseek(Math.round(next * 1000) / 1000);
    };
    if (e.key === "ArrowRight" || e.key === "ArrowUp") {
      e.preventDefault();
      e.stopPropagation();
      nudge(step);
    }
    if (e.key === "ArrowLeft" || e.key === "ArrowDown") {
      e.preventDefault();
      e.stopPropagation();
      nudge(-step);
    }
    if (e.key === "Home") {
      e.preventDefault();
      e.stopPropagation();
      onseek(0);
    }
    if (e.key === "End") {
      e.preventDefault();
      e.stopPropagation();
      onseek(max);
    }
  }}
  class="group relative h-2 w-full cursor-pointer touch-none select-none focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary/70 focus-visible:ring-offset-2 focus-visible:ring-offset-canvas {disabled
    ? 'pointer-events-none opacity-50'
    : ''} {klass}"
>
  <div class="absolute inset-x-0 top-1/2 h-1.5 -translate-y-1/2 overflow-hidden rounded-full bg-line">
    <div class="h-full rounded-full bg-accent" style="width:{pct}%"></div>
  </div>
  <div
    class="absolute top-1/2 size-3 -translate-y-1/2 rounded-full bg-accent ring-4 ring-accent/15 transition-opacity {dragging
      ? 'opacity-100'
      : 'opacity-0 group-hover:opacity-100'}"
    style="inset-inline-start: calc({pct}% - 6px)"
  ></div>
</div>
