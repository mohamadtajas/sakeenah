import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const css = readFileSync(new URL("../src/app.css", import.meta.url), "utf8");

function blockAfter(selector) {
  const selectorAt = css.indexOf(selector);
  assert.notEqual(selectorAt, -1, `Missing theme block: ${selector}`);
  const openAt = css.indexOf("{", selectorAt);
  assert.notEqual(openAt, -1, `Missing opening brace for ${selector}`);
  let depth = 0;
  for (let index = openAt; index < css.length; index++) {
    if (css[index] === "{") depth++;
    if (css[index] === "}") {
      depth--;
      if (depth === 0) return css.slice(openAt + 1, index);
    }
  }
  assert.fail(`Unclosed theme block: ${selector}`);
}

function variables(block) {
  return new Map(
    [...block.matchAll(/--([a-z0-9-]+)\s*:\s*(#[0-9a-f]{6})\s*;/gi)].map(
      ([, name, value]) => [name, value.toUpperCase()],
    ),
  );
}

function requireColors(tokens, expected, theme) {
  for (const [name, value] of Object.entries(expected)) {
    assert.equal(
      tokens.get(name),
      value,
      `${theme} token --${name} must be ${value}`,
    );
  }
}

function luminance(hex) {
  const channels = [1, 3, 5].map((start) => {
    const channel = Number.parseInt(hex.slice(start, start + 2), 16) / 255;
    return channel <= 0.04045
      ? channel / 12.92
      : ((channel + 0.055) / 1.055) ** 2.4;
  });
  return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
}

function contrast(foreground, background) {
  const values = [luminance(foreground), luminance(background)].sort(
    (a, b) => b - a,
  );
  return (values[0] + 0.05) / (values[1] + 0.05);
}

function requireContrast(tokens, foreground, background, minimum, theme) {
  const ratio = contrast(tokens.get(foreground), tokens.get(background));
  assert.ok(
    ratio >= minimum,
    `${theme}: --${foreground} on --${background} is ${ratio.toFixed(2)}:1; expected >= ${minimum}:1`,
  );
}

const light = variables(blockAfter("@theme"));
requireColors(
  light,
  {
    "color-canvas": "#F7F5F0",
    "color-surface": "#FFFFFF",
    "color-primary": "#145349",
    "color-primary-soft": "#E6F0ED",
    "color-accent": "#B88E3B",
    "color-accent-ink": "#6B511A",
    "color-text": "#1B2422",
    "color-secondary-text": "#5A6864",
    "color-border": "#E5E0D5",
  },
  "light",
);
requireContrast(light, "color-text", "color-canvas", 7, "light");
requireContrast(light, "color-secondary-text", "color-canvas", 4.5, "light");
requireContrast(light, "color-primary", "color-surface", 4.5, "light");
requireContrast(light, "color-accent-ink", "color-surface", 4.5, "light");
requireContrast(light, "color-primary", "color-primary-soft", 4.5, "light");

const dark = variables(blockAfter(':root[data-theme="dark"]'));
requireColors(
  dark,
  {
    "color-canvas": "#0C1512",
    "color-surface": "#13211D",
    "color-primary": "#7FC3B2",
    "color-primary-soft": "#1D332C",
    "color-accent": "#D4AF63",
    "color-accent-ink": "#D4AF63",
    "color-text": "#F4F1E8",
    "color-secondary-text": "#A8B5AF",
    "color-border": "#2A3B35",
  },
  "dark",
);
requireContrast(dark, "color-text", "color-canvas", 7, "dark");
requireContrast(dark, "color-secondary-text", "color-canvas", 4.5, "dark");
requireContrast(dark, "color-primary", "color-surface", 4.5, "dark");
requireContrast(dark, "color-accent", "color-surface", 4.5, "dark");
requireContrast(dark, "color-primary", "color-primary-soft", 4.5, "dark");

console.log("Theme token values and text contrast are valid for light and dark.");
