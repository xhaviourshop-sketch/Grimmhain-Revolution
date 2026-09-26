import { LANG } from "../lang";

const BASE = import.meta.env.BASE_URL;
// same paths as the token seals → swapping the marker art updates the legend too
const markerUrl = (key: string) => `${BASE}assets/markers/marker-${key}.webp`;

/** the 15 status seals with label + one-line meaning. Wording reuses the vanilla
 *  i18n terms where they exist (Offenbart/Revealed, Stimme/Vote, Vorbild/Role
 *  Model) so the legend matches the game. Keys = the marker-<key>.webp files. */
const STR = {
  de: {
    title: "Legende — Status-Siegel",
    close: "Schließen",
    entries: [
      { key: "dead", label: "Tot", desc: "Spieler ist tot." },
      { key: "protected", label: "Geschützt", desc: "Diese Nacht vor dem Tod geschützt." },
      { key: "nominated", label: "Nominiert", desc: "Zur Lynch-Abstimmung nominiert." },
      { key: "poison", label: "Vergiftet", desc: "Vergiftet — stirbt durch das Gift." },
      { key: "love", label: "Verliebt", desc: "Verliebtes Paar — stirbt gemeinsam." },
      { key: "hate", label: "Hass", desc: "Hass-Paar (Rivalen)." },
      { key: "enchanted", label: "Verzaubert", desc: "Vom Rattenfänger verzaubert." },
      { key: "burned", label: "Gebrannt", desc: "Gebrannt — zum Verbrennen markiert." },
      { key: "puppet", label: "Puppe", desc: "Als Puppe kontrolliert." },
      { key: "wolf", label: "Wolf-Marker", desc: "Zählt als Werwolf." },
      { key: "vorbild", label: "Vorbild", desc: "Vorbild (z. B. Wolfskind)." },
      { key: "silenced", label: "Stimme entzogen", desc: "Tote Stimme entzogen — ohne Stimme." },
      { key: "vote", label: "Hat Stimme", desc: "Tote behält eine Stimme (Nekromant)." },
      { key: "revealed", label: "Offenbart", desc: "Vom Totenrat offenbart." },
      { key: "unholy", label: "Unheilig", desc: "Unheilig markiert." }
    ]
  },
  en: {
    title: "Legend — Status seals",
    close: "Close",
    entries: [
      { key: "dead", label: "Dead", desc: "The player is dead." },
      { key: "protected", label: "Protected", desc: "Protected from death this night." },
      { key: "nominated", label: "Nominated", desc: "Nominated for the lynch vote." },
      { key: "poison", label: "Poisoned", desc: "Poisoned — dies from the poison." },
      { key: "love", label: "In Love", desc: "Lovers — die together." },
      { key: "hate", label: "Hate", desc: "Hate pair (rivals)." },
      { key: "enchanted", label: "Charmed", desc: "Charmed by the Pied Piper." },
      { key: "burned", label: "Burned", desc: "Burned — marked to burn." },
      { key: "puppet", label: "Puppet", desc: "Controlled as a puppet." },
      { key: "wolf", label: "Wolf Mark", desc: "Counts as a werewolf." },
      { key: "vorbild", label: "Role Model", desc: "Role model (e.g. Wild Child)." },
      { key: "silenced", label: "Vote Removed", desc: "Dead vote removed — no vote." },
      { key: "vote", label: "Has Vote", desc: "Dead keeps a vote (Necromancer)." },
      { key: "revealed", label: "Revealed", desc: "Revealed by the Totenrat." },
      { key: "unholy", label: "Unholy", desc: "Marked unholy." }
    ]
  }
}[LANG];

/**
 * MarkerLegend — dismissable dark overlay (click-outside or ✕) explaining every
 * status seal. Icons load from the same marker-<key>.webp paths as the tokens.
 */
export function MarkerLegend({ open, onClose }: { open: boolean; onClose: () => void }) {
  if (!open) return null;
  return (
    <div className="legend-overlay" data-testid="legend-overlay" onClick={onClose}>
      <div className="legend-panel panel-gothic" onClick={(e) => e.stopPropagation()}>
        <div className="legend-head">
          <h3 className="legend-title">{STR.title}</h3>
          <button type="button" className="legend-close" onClick={onClose} aria-label={STR.close}>
            ✕
          </button>
        </div>
        <ul className="legend-list">
          {STR.entries.map((e) => (
            <li className="legend-row" key={e.key} data-testid={`legend-${e.key}`}>
              <img className="legend-icon" src={markerUrl(e.key)} alt={e.label} />
              <span className="legend-text">
                <span className="legend-label">{e.label}</span>
                <span className="legend-desc">{e.desc}</span>
              </span>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
