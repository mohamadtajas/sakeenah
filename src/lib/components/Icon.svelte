<script lang="ts" module>
  export const icons = {
    home: '<path d="M3 10.4 12 3l9 7.4V20a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1z"/>',
    search: '<circle cx="11" cy="11" r="7"/><path d="m20 20-3.6-3.6"/>',
    menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
    book: '<path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/>',
    radio:
      '<rect x="2.5" y="8.5" width="19" height="12.5" rx="2.5"/><circle cx="8.5" cy="14.75" r="2.4"/><path d="M15.5 12.5h3M15.5 17h3M7 8.5 17 3"/>',
    music:
      '<path d="M9 18V5.5l11-2V16"/><circle cx="6" cy="18" r="3"/><circle cx="17" cy="16" r="3"/>',
    settings:
      '<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .34 1.87l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.7 1.7 0 0 0-1.87-.34 1.7 1.7 0 0 0-1 1.55V21a2 2 0 1 1-4 0v-.09A1.7 1.7 0 0 0 9 19.36a1.7 1.7 0 0 0-1.87.34l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.7 1.7 0 0 0 4.64 15a1.7 1.7 0 0 0-1.55-1H3a2 2 0 1 1 0-4h.09A1.7 1.7 0 0 0 4.64 9a1.7 1.7 0 0 0-.34-1.87l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.7 1.7 0 0 0 9 4.64h.08a1.7 1.7 0 0 0 1-1.55V3a2 2 0 1 1 4 0v.09a1.7 1.7 0 0 0 1 1.55 1.7 1.7 0 0 0 1.87-.34l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.7 1.7 0 0 0 19.36 9v.08a1.7 1.7 0 0 0 1.55 1H21a2 2 0 1 1 0 4h-.09a1.7 1.7 0 0 0-1.51 1z"/>',
    info: '<circle cx="12" cy="12" r="9"/><path d="M12 16v-4.5M12 8h.01"/>',
    play: '<path d="M7 4.5v15l13-7.5z" fill="currentColor" stroke="none"/>',
    pause:
      '<rect x="7" y="4.5" width="3.6" height="15" rx="1.2" fill="currentColor" stroke="none"/><rect x="13.4" y="4.5" width="3.6" height="15" rx="1.2" fill="currentColor" stroke="none"/>',
    "skip-back":
      '<path d="M18.5 5.5v13L8.5 12z" fill="currentColor" stroke="none"/><path d="M5 5v14"/>',
    "skip-forward":
      '<path d="M5.5 5.5v13L15.5 12z" fill="currentColor" stroke="none"/><path d="M19 5v14"/>',
    shuffle:
      '<path d="M17 3.5 21 7l-4 3.5"/><path d="M3 7h3.6c1.6 0 3 .8 3.9 2.1l3 4.4A4.7 4.7 0 0 0 17.4 15H21"/><path d="m17 11.5 4 3.5-4 3.5"/><path d="M3 17h3.6c1.6 0 3-.8 3.9-2.1"/>',
    repeat: '<path d="M17 3.5 21 7l-4 3.5"/><path d="M3 11V9.5A2.5 2.5 0 0 1 5.5 7H21"/><path d="m7 20.5-4-3.5 4-3.5"/><path d="M21 13v1.5a2.5 2.5 0 0 1-2.5 2.5H3"/>',
    volume:
      '<path d="M11 5 6.5 8.5H3v7h3.5L11 19z"/><path d="M15.5 8.8a4.5 4.5 0 0 1 0 6.4"/><path d="M18.5 6a8.5 8.5 0 0 1 0 12"/>',
    "volume-x":
      '<path d="M11 5 6.5 8.5H3v7h3.5L11 19z"/><path d="m16 9 5 6M21 9l-5 6"/>',
    heart:
      '<path d="M12 20s-7.5-4.6-7.5-9.6A4.4 4.4 0 0 1 12 7.4a4.4 4.4 0 0 1 7.5 3c0 5-7.5 9.6-7.5 9.6z"/>',
    list: '<path d="M8 6h13M8 12h13M8 18h13M3.5 6h.01M3.5 12h.01M3.5 18h.01"/>',
    x: '<path d="M18 6 6 18M6 6l12 12"/>',
    chevron: '<path d="m9 6 6 6-6 6"/>',
    download: '<path d="M12 3v12"/><path d="m7 11 5 5 5-5"/><path d="M4 20h16"/>',
    clock: '<circle cx="12" cy="12" r="9"/><path d="M12 7.5V12l3 2"/>',
    globe: '<circle cx="12" cy="12" r="9"/><path d="M3 12h18"/><path d="M12 3a15 15 0 0 1 0 18a15 15 0 0 1 0-18z"/>',
    mic: '<rect x="9" y="2.5" width="6" height="11" rx="3"/><path d="M5.5 11a6.5 6.5 0 0 0 13 0"/><path d="M12 17.5V21"/>',
    disc: '<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="2.5"/>',
    sparkle: '<path d="M12 3.5 13.9 9l5.6 1.9-5.6 1.9L12 18.5 10.1 12.8 4.4 10.9 10.1 9z"/>',
    compass: '<circle cx="12" cy="12" r="9"/><path d="m15.5 8.5-2.2 5-4.8 2 2.2-5z"/>',
    moon: '<path d="M20.5 14.3A8.5 8.5 0 0 1 9.7 3.5 8.5 8.5 0 1 0 20.5 14.3z"/>',
    sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/>',
    flame: '<path d="M12 22c4.4 0 7-2.8 7-6.5 0-4.8-4.6-7.2-5.7-11.5-2 2.4-3 4.3-3 6.2 0 1.4.6 2.4.6 3.3 0 1.2-.9 2-2 2-.9 0-1.7-.5-2.1-1.3-.5.9-.8 2-.8 3.2C6 19.3 8.1 22 12 22z"/>',
    check: '<path d="m4.5 12.5 5 5 10-10"/>',
    bookmarkFilled: '<path d="M6 3h12v18l-6-4-6 4z" fill="currentColor" stroke="none"/>',
    bookOpen: '<path d="M2 4h6a4 4 0 0 1 4 4v13a3 3 0 0 0-3-3H2z"/><path d="M22 4h-6a4 4 0 0 0-4 4v13a3 3 0 0 1 3-3h7z"/>',
    bookmark:
      '<path d="M6.5 3.5h11a1 1 0 0 1 1 1v16l-6.5-4.2L5.5 20.5v-16a1 1 0 0 1 1-1z"/>',
    "chevron-down": '<path d="m6 9 6 6 6-6"/>',
    pencil: '<path d="M4 20h4L20 8l-4-4L4 16z"/><path d="m14.5 5.5 4 4"/>',
  } as const;

  export type IconName = keyof typeof icons;
</script>

<script lang="ts">
  let {
    name,
    size = 20,
    stroke = 1.7,
    class: klass = "",
  }: { name: IconName; size?: number; stroke?: number; class?: string } = $props();
</script>

<svg
  width={size}
  height={size}
  viewBox="0 0 24 24"
  fill="none"
  stroke="currentColor"
  stroke-width={stroke}
  stroke-linecap="round"
  stroke-linejoin="round"
  class={klass}
  aria-hidden="true"
>
  {@html icons[name]}
</svg>
