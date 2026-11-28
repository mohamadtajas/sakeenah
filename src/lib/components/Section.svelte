<script lang="ts">
  import type { Snippet } from "svelte";
  import Icon from "./Icon.svelte";

  let {
    title,
    subtitle,
    action,
    onaction,
    children,
  }: {
    title: string;
    subtitle?: string;
    action?: string;
    onaction?: () => void;
    children: Snippet;
  } = $props();
</script>

<section class="mt-9 first:mt-0">
  <header class="mb-3.5 flex items-end justify-between gap-4">
    <div>
      <h2 class="text-[1.05rem] font-bold tracking-tight text-text">{title}</h2>
      {#if subtitle}
        <p class="mt-0.5 text-xs text-muted">{subtitle}</p>
      {/if}
    </div>
    {#if action && onaction}
      <button
        type="button"
        onclick={onaction}
        class="flex shrink-0 items-center gap-1 rounded-lg px-2 py-1 text-xs font-medium text-muted transition-colors hover:bg-primary-soft/60 hover:text-primary"
      >
        {action}
        <Icon name="chevron" size={13} class="rtl:rotate-180" />
      </button>
    {/if}
  </header>
  {@render children()}
</section>
