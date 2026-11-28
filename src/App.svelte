<script lang="ts">
  import { onMount } from "svelte";
  import Sidebar from "$lib/components/Sidebar.svelte";
  import PlayerBar from "$lib/components/PlayerBar.svelte";
  import Toast from "$lib/components/Toast.svelte";
  import Home from "$lib/views/Home.svelte";
  import Worship from "$lib/views/Worship.svelte";
  import Adhkar from "$lib/views/Adhkar.svelte";
  import Reader from "$lib/views/Reader.svelte";
  import Quran from "$lib/views/Quran.svelte";
  import Explore from "$lib/views/Explore.svelte";
  import Radio from "$lib/views/Radio.svelte";
  import Search from "$lib/views/Search.svelte";
  import Library from "$lib/views/Library.svelte";
  import Settings from "$lib/views/Settings.svelte";
  import Credits from "$lib/views/Credits.svelte";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import { player } from "$lib/stores/player.svelte.ts";
  import { library } from "$lib/stores/library.svelte.ts";
  import { worship } from "$lib/stores/worship.svelte.ts";
  import { adhkar } from "$lib/stores/adhkar.svelte.ts";
  import { adhan } from "$lib/stores/adhan.svelte.ts";
  import { isTauri } from "$lib/api";
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import { ui } from "$lib/stores/ui.svelte.ts";
  import Icon from "$lib/components/Icon.svelte";

  onMount(() => {
    void library.load();
    void worship.load();
    worship.start();
    void adhkar.load();
    adhkar.start();
    void adhan.init();
    void i18n.hydrate();
    const cleanups: (() => void)[] = [];

    // Tray menu, global hotkeys and Windows media keys all arrive here.
    void (async () => {
      if (!isTauri) return;
      try {
        const { listen } = await import("@tauri-apps/api/event");
        cleanups.push(
          await listen<string>("player:command", (event) => {
            switch (event.payload) {
              case "toggle":
                void player.toggle();
                break;
              case "play":
                if (!player.playing) void player.toggle();
                break;
              case "pause":
                if (player.playing) void player.toggle();
                break;
              case "next":
                void player.next();
                break;
              case "previous":
                void player.prev();
                break;
              case "stop":
                player.stop();
                break;
            }
          }),
        );
        cleanups.push(
          await listen<number>("player:seek", (event) => player.seek(event.payload)),
        );
      } catch {
        /* media keys are best-effort */
      }
    })();

    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape" && ui.sidebarOpen) {
        ui.toggleSidebar(false);
        return;
      }
      // Never steal keys from a focused control or an already-handled action.
      if (e.defaultPrevented || e.ctrlKey || e.metaKey || e.altKey) return;
      const target = e.target instanceof Element ? e.target : null;
      if (
        target?.closest(
          'input, textarea, select, button, a[href], summary, [contenteditable="true"], [role="slider"], [role="button"], [role="switch"]',
        )
      ) {
        return;
      }
      switch (e.code) {
        case "Space":
          e.preventDefault();
          void player.toggle();
          break;
        case "ArrowRight":
          e.preventDefault();
          void player.next();
          break;
        case "ArrowLeft":
          e.preventDefault();
          void player.prev();
          break;
        case "ArrowUp":
          e.preventDefault();
          player.setVolume(player.volume + 0.05);
          break;
        case "ArrowDown":
          e.preventDefault();
          player.setVolume(player.volume - 0.05);
          break;
        case "KeyM":
          player.toggleMute();
          break;
        default:
          break;
      }
    };
    window.addEventListener("keydown", onKey);
    return () => {
      window.removeEventListener("keydown", onKey);
      for (const cleanup of cleanups) cleanup();
    };
  });
</script>

<svelte:head>
  <title>{i18n.t("app.name")} · {i18n.t("app.tagline")}</title>
</svelte:head>

<div class="app-shell" dir={i18n.dir}>
  <Sidebar />

  <header class="mobile-topbar">
    <button
      type="button"
      class="icon-btn"
      onclick={() => ui.toggleSidebar()}
      aria-label={i18n.t("nav.menu")}
      aria-expanded={ui.sidebarOpen}
    >
      <Icon name="menu" size={20} />
    </button>
    <span class="flex min-w-0 items-center gap-2">
      <img src="/logo.png" alt="" class="size-8 shrink-0 rounded-xl ring-1 ring-accent/30" />
      <span class="truncate text-sm font-bold text-primary">{i18n.t("app.name")}</span>
    </span>
    <span class="ms-auto truncate text-[11px] text-secondary-text">{i18n.t("app.tagline")}</span>
  </header>

  {#if ui.sidebarOpen}
    <button
      type="button"
      class="drawer-scrim"
      onclick={() => ui.toggleSidebar(false)}
      aria-label={i18n.t("common.close")}
    ></button>
  {/if}

  <main class="app-main">
    <div class="mx-auto w-full max-w-[1180px] px-5 pb-12 pt-6 sm:px-7 sm:pt-7">
      {#if nav.view === "home"}
        <Home />
      {:else if nav.view === "worship"}
        <Worship />
      {:else if nav.view === "adhkar"}
        <Adhkar />
      {:else if nav.view === "reader"}
        <Reader />
      {:else if nav.view === "quran"}
        <Quran />
      {:else if nav.view === "explore"}
        <Explore />
      {:else if nav.view === "radio"}
        <Radio />
      {:else if nav.view === "search"}
        <Search />
      {:else if nav.view === "library"}
        <Library />
      {:else if nav.view === "settings"}
        <Settings />
      {:else if nav.view === "credits"}
        <Credits />
      {/if}
    </div>
  </main>

  <div class="app-player">
    <PlayerBar />
  </div>

  <Toast />
</div>
