/**
 * Mirrors the legacy dialog surfaces (hidden #overlay and #pickbar) into
 * plain data so React can render them. The legacy logic keeps full control
 * of the flow — buttons are answered by clicking the REAL hidden legacy
 * button (pressDialogButton), never by re-implementing rules.
 */

export interface MirroredDialog {
  title: string;
  body: string;
  buttons: string[];
}

export interface MirroredPick {
  prompt: string;
  hint: string;
}

export interface MirrorState {
  dialog: MirroredDialog | null;
  pick: MirroredPick | null;
}

/**
 * Read the legacy dialog body (#mb) as readable text. The body is sometimes a
 * flat text node (e.g. a yes/no question) and sometimes structured DIV blocks
 * (the morning death summary: one block per dead seat with a cause line + a name
 * line). A plain `textContent` glues those together ("⚔️ RitterBert🐺 WerwolfNils").
 * Here we join the lines WITHIN a block by spaces and the blocks by newlines, so
 * each death reads "⚔️ Ritter Bert" on its own line.
 */
function readBody(mb: HTMLElement | null): string {
  if (!mb) return "";
  const blocks = [...mb.children].filter((c) => c.tagName === "DIV");
  if (!blocks.length) return mb.textContent ?? "";
  return blocks
    .map((b) => {
      const lines = [...b.children].filter((c) => c.tagName === "DIV");
      const text = lines.length
        ? lines.map((l) => (l.textContent ?? "").trim()).filter(Boolean).join(" ")
        : (b.textContent ?? "").trim();
      return text;
    })
    .filter(Boolean)
    .join("\n");
}

export function readMirror(): MirrorState {
  const overlay = document.getElementById("overlay");
  const pickbar = document.getElementById("pickbar");

  let dialog: MirroredDialog | null = null;
  if (overlay && overlay.style.display !== "none" && overlay.style.display !== "") {
    dialog = {
      title: document.getElementById("mt")?.textContent ?? "",
      body: readBody(document.getElementById("mb")),
      buttons: [...(document.getElementById("mbtns")?.querySelectorAll("button") ?? [])].map(
        (b) => b.textContent ?? ""
      )
    };
  }

  let pick: MirroredPick | null = null;
  if (pickbar && pickbar.style.display === "flex") {
    pick = {
      prompt: document.getElementById("picktxt")?.textContent ?? "",
      hint: document.getElementById("pickhint")?.textContent ?? ""
    };
  }

  return { dialog, pick };
}

/** Press the n-th button of the live legacy dialog. */
export function pressMirroredButton(index: number): boolean {
  const buttons = document.getElementById("mbtns")?.querySelectorAll("button");
  const btn = buttons?.[index];
  if (!btn) return false;
  btn.click();
  return true;
}

/** Cancel a running legacy pick (the pickbar's own cancel button). */
export function cancelMirroredPick(): boolean {
  const btn = document.getElementById("pickcancel") as HTMLButtonElement | null;
  if (!btn) return false;
  btn.click();
  return true;
}

/** Observe both surfaces; fires on every change (returns disconnect). */
export function observeMirror(onChange: () => void): () => void {
  const targets = ["overlay", "pickbar"]
    .map((id) => document.getElementById(id))
    .filter((el): el is HTMLElement => !!el);
  const obs = new MutationObserver(() => onChange());
  for (const t of targets) {
    obs.observe(t, { childList: true, subtree: true, attributes: true, characterData: true });
  }
  return () => obs.disconnect();
}
