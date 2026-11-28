<script lang="ts">
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { navItems } from "$lib/stores/nav.svelte.ts";
  import { ui } from "$lib/stores/ui.svelte.ts";
  import type { View } from "$lib/types";
  import Icon, { type IconName } from "./Icon.svelte";

  let query = $state("");

  function submit(e: Event) {
    e.preventDefault();
    if (query.trim()) {
      nav.search(query.trim());
      query = "";
      ui.toggleSidebar(false);
    }
  }

  function go(view: View) {
    nav.go(view);
    ui.toggleSidebar(false);
  }
</script>

<aside
  class="app-sidebar flex h-full flex-col border-e border-line bg-ivory"
  class:is-open={ui.sidebarOpen}
  aria-label={i18n.t("nav.primary")}
>
  <div class="flex items-center gap-3 px-5 pb-6 pt-6">
    <img src="/logo.png" alt="" class="size-11 shrink-0 rounded-2xl ring-1 ring-accent/30" />
    <div class="sidebar-brand-text min-w-0">
      <div class="truncate text-lg font-bold leading-none text-primary">{i18n.t("app.name")}</div>
      <div class="mt-1 text-[10px] font-medium tracking-[0.18em] text-secondary-text">SAKEENAH</div>
    </div>
  </div>

  <form onsubmit={submit} class="sidebar-search px-4 pb-4">
    <label class="field">
      <Icon name="search" size={16} class="shrink-0 text-secondary-text" />
      <input
        bind:value={query}
        placeholder={i18n.t("search.placeholder")}
        class="w-full bg-transparent text-sm text-text placeholder:text-secondary-text/70 focus:outline-none"
        aria-label={i18n.t("nav.search")}
      />
    </label>
  </form>

  <button
    type="button"
    class="sidebar-rail-action icon-btn mx-auto mb-4 border border-line"
    onclick={() => go("search")}
    aria-label={i18n.t("nav.search")}
    title={i18n.t("nav.search")}
  >
    <Icon name="search" size={18} />
  </button>

  <nav class="flex flex-col gap-1 px-3">
    {#each navItems as item (item.view)}
      {@const active = nav.view === item.view}
      <button
        type="button"
        onclick={() => go(item.view as View)}
        class="nav-item"
        data-active={active ? "true" : "false"}
        aria-current={active ? "page" : undefined}
        title={i18n.t(item.label)}
      >
        <Icon name={item.icon as IconName} size={18} class="shrink-0" />
        <span class="sidebar-label">{i18n.t(item.label)}</span>
      </button>
    {/each}
  </nav>

  <div class="mt-auto px-4 pb-5">
    <div class="mb-3 h-px bg-line/70"></div>
    <div class="sidebar-footer flex items-center justify-between text-[11px] text-secondary-text">
      <button
        type="button"
        onclick={() => i18n.toggle()}
        class="icon-btn w-auto gap-1.5 px-2 text-[11px]"
        aria-label={i18n.locale === "ar" ? "English" : "العربية"}
        title={i18n.locale === "ar" ? "English" : "العربية"}
      >
        <Icon name="globe" size={14} class="shrink-0" />
        <span class="sidebar-label">{i18n.locale === "ar" ? "English" : "العربية"}</span>
      </button>
      <button
        type="button"
        onclick={() => go("settings")}
        class="icon-btn"
        aria-label={i18n.t("nav.settings")}
        title={i18n.t("nav.settings")}
      >
        <Icon name="settings" size={16} />
      </button>
    </div>
  </div>
</aside>
