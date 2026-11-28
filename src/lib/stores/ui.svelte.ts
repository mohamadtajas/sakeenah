const THEME_KEY = "sakeenah.theme";

class UiStore {
  theme = $state<"dark" | "light">("light");
  /** Narrow-window navigation drawer. */
  sidebarOpen = $state(false);
  /** Transient message shown above the player bar. */
  toast = $state<string | null>(null);
  private toastTimer: ReturnType<typeof setTimeout> | null = null;

  notify(message: string, ms = 3600) {
    this.toast = message;
    if (this.toastTimer) clearTimeout(this.toastTimer);
    this.toastTimer = setTimeout(() => {
      this.toast = null;
      this.toastTimer = null;
    }, ms);
  }

  constructor() {
    if (typeof localStorage !== "undefined") {
      const saved = localStorage.getItem(THEME_KEY);
      if (saved === "light" || saved === "dark") this.theme = saved;
    }
    if (typeof document !== "undefined") this.apply();
  }

  setTheme(theme: "dark" | "light") {
    this.theme = theme;
    if (typeof localStorage !== "undefined") localStorage.setItem(THEME_KEY, theme);
    this.apply();
  }

  toggleTheme() {
    this.setTheme(this.theme === "dark" ? "light" : "dark");
  }

  toggleSidebar(open = !this.sidebarOpen) {
    this.sidebarOpen = open;
  }

  private apply() {
    document.documentElement.dataset.theme = this.theme;
    document.documentElement.style.colorScheme = this.theme;
  }
}

export const ui = new UiStore();
