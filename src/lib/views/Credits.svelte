<script lang="ts">
  import { i18n } from "$lib/i18n/index.svelte.ts";
  import { nav } from "$lib/stores/nav.svelte.ts";
  import Icon from "$lib/components/Icon.svelte";

  const sources: {
    name: string;
    url: string;
    what: { ar: string; en: string };
    license: { ar: string; en: string };
    notice?: string;
  }[] = [
    {
      name: "Tanzil Quran Text",
      url: "https://tanzil.net",
      what: {
        ar: "النص القرآني العثماني وبيانات السور والأجزاء",
        en: "Uthmani Quran text and surah/juz metadata",
      },
      license: {
        ar: "CC BY 3.0 — © Tanzil Project",
        en: "CC BY 3.0 — © Tanzil Project",
      },
      notice: `Tanzil Quran Text (Uthmani, Version 1.1)
Copyright (C) 2007-2026 Tanzil Project
License: Creative Commons Attribution 3.0

Permission is granted to copy and distribute verbatim copies of this text, but CHANGING IT IS NOT ALLOWED.
This Quran text can be used in any website or application, provided that its source (Tanzil Project) is clearly indicated, and a link is made to tanzil.net.
This copyright notice shall be included in all verbatim copies of the text, and shall be reproduced appropriately in all files derived from or containing a substantial portion of this text.`,
    },
    {
      name: "Beautiful adhan",
      url: "https://commons.wikimedia.org/wiki/File:Beautiful_adhan.ogg",
      what: {
        ar: "تسجيل الأذان المضمَّن (بدون تعديل)",
        en: "Bundled adhan recording (unmodified)",
      },
      license: { ar: "CC0 1.0 — Adam-synagda", en: "CC0 1.0 — Adam-synagda" },
      notice:
        "Beautiful adhan by Adam-synagda, Wikimedia Commons, CC0 1.0 Universal Public Domain Dedication. No changes were made.",
    },
    {
      name: "mp3quran.net",
      url: "https://mp3quran.net",
      what: { ar: "تلاوات القرآن الكريم وأكثر من ٢٠٠ قارئ", en: "Quran recitations from 200+ reciters" },
      license: { ar: "متاح مجانًا للاستخدام", en: "Freely available for use" },
    },
    {
      name: "EveryAyah",
      url: "https://everyayah.com",
      what: { ar: "تلاوة آية بآية", en: "Ayah-by-ayah recitation audio" },
      license: { ar: "متاح مجانًا", en: "Freely available" },
    },
    {
      name: "AlQuran Cloud",
      url: "https://alquran.cloud",
      what: {
        ar: "أسماء السور وعدد الآيات، وترجمة Sahih International",
        en: "Surah names/counts and the Sahih International translation",
      },
      license: { ar: "بيانات مفتوحة", en: "Open data" },
    },
    {
      name: "Hisn al-Muslim (HisnElMuslim)",
      url: "https://github.com/asellam/HisnElMuslim",
      what: {
        ar: "نصوص الأذكار وتكرارها ومصادرها من حصن المسلم",
        en: "Adhkar texts, repeat counts and references from Hisn al-Muslim",
      },
      license: {
        ar: "MIT — © ٢٠٢١ Abdellah SELLAM",
        en: "MIT — © 2021 Abdellah SELLAM",
      },
    },
    {
      name: "radio-browser.info",
      url: "https://www.radio-browser.info",
      what: { ar: "دليل محطات الإذاعة المباشرة", en: "Live radio station directory" },
      license: { ar: "بيانات مفتوحة (CC0)", en: "Open data (CC0)" },
    },
    {
      name: "Openverse",
      url: "https://openverse.org",
      what: { ar: "فهرس صوتي بتراخيص مفتوحة (يشمل Jamendo)", en: "Openly licensed audio index (includes Jamendo)" },
      license: { ar: "Creative Commons — حسب كل عمل", en: "Creative Commons — per work" },
    },
    {
      name: "Jamendo",
      url: "https://www.jamendo.com",
      what: { ar: "موسيقى بتراخيص Creative Commons", en: "Creative Commons music" },
      license: { ar: "CC — يتطلب ذكر المصدر", en: "CC — attribution required" },
    },
    {
      name: "Internet Archive",
      url: "https://archive.org",
      what: { ar: "أناشيد وتسجيلات في الملك العام", en: "Anasheed and public-domain recordings" },
      license: { ar: "حسب كل تسجيل", en: "Per-item license" },
    },
  ];
</script>

<div class="fade-in max-w-3xl">
  <button
    type="button"
    onclick={() => nav.go("settings")}
    class="mb-4 flex items-center gap-1.5 text-xs text-muted transition-colors hover:text-primary"
  >
    <Icon name="chevron" size={13} class="rotate-180 rtl:rotate-0" />
    {i18n.t("settings.title")}
  </button>

  <h1 class="text-2xl font-bold text-text">{i18n.t("credits.title")}</h1>
  <p class="mt-2 text-sm leading-relaxed text-muted">{i18n.t("credits.intro")}</p>

  <div class="mt-6 space-y-3">
    {#each sources as source (source.name)}
      <div class="card rounded-2xl p-4">
        <div class="flex items-start justify-between gap-4">
          <div class="min-w-0">
            <div class="text-sm font-semibold text-text">{source.name}</div>
            <div class="mt-0.5 text-xs text-muted">{source.what[i18n.locale]}</div>
          </div>
          <span class="shrink-0 rounded-md border border-primary/25 bg-primary-soft px-2 py-0.5 text-[10px] text-primary">
            {source.license[i18n.locale]}
          </span>
        </div>
        <a
          href={source.url}
          target="_blank"
          rel="noreferrer"
          class="mt-2 block truncate text-[11px] text-muted transition-colors hover:text-primary"
          dir="ltr">{source.url}</a
        >
        {#if source.notice}
          <details class="mt-2">
            <summary class="cursor-pointer text-[10px] text-muted hover:text-primary">
              {i18n.t("credits.license")}
            </summary>
            <pre
              class="mt-2 max-h-40 overflow-auto whitespace-pre-wrap rounded-lg border border-line/60 bg-canvas p-2 text-[9px] leading-relaxed text-muted"
              dir="ltr">{source.notice}</pre>
          </details>
        {/if}
      </div>
    {/each}
  </div>
</div>
