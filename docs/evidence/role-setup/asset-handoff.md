# Medien-Übergabeliste · Rollen-Setup

Übergabe an Grimmhain-3 für die spätere Aufnahme in das gemeinsame Assetregister. Dieser Branch ändert das Register, sein Prüfwerkzeug und dessen CI nicht; die Integration ist offen.

Integriert am 27.09.2026 im lokalen Branch `integration/cloud-to-local-20260927`: alle 27 Dateien gegen SHA-256 und Größe dieser Liste geprüft (identisch), 19 Registerzeilen ergänzt, 8 aktualisiert; Status weiterhin `prüfartefakt`, keine Freigabe.

- Branch: `claude/sleepy-babbage-u2o0i2`
- Vergleichsbasis: `250d3d2` (Branchbasis; `origin/main` enthält diese Dateien noch nicht)
- Umfang: alle gegenüber der Basis neuen oder veränderten Mediendateien (nur PNG; keine Audio-, Schrift- oder Grafikassets)
- Herkunft: erzeugt mit `godot/tools/capture_ui_screenshots.gd` unter Xvfb (Godot 4.7.2, Mesa llvmpipe), fester Setup-Seed 20260926
- Lizenz: eigene Bildschirmaufnahmen der App, keine Fremdinhalte, keine eingebetteten Schriftdateien (Engine-Standardschrift)
- Zweck aller Dateien: UI-Prüfartefakt (keine Produktionsassets, nicht Teil des App-Exports)

| Pfad | SHA-256 | Größe (Byte) | Zweck | Status |
|---|---|---|---|---|
| `docs/evidence/player-setup/01-empty-1024x768-de.png` | `5f7c7e8c06a7519450fc518a159b2b3efd4e3f0379edc4793636e3257aa65dd6` | 77630 | UI-Prüfartefakt | verändert |
| `docs/evidence/player-setup/02-six-players-1024x768-de.png` | `cb17dcde276705a6990a3eadb1b83e5709516af559941c2aa6367353215e6736` | 96065 | UI-Prüfartefakt | verändert |
| `docs/evidence/player-setup/03-24-players-scrolled-1024x768-de.png` | `93295c2c1a57eb278106659b28fa21f012e8ba0d03ad34a4a8932f472f78b915` | 99542 | UI-Prüfartefakt | verändert |
| `docs/evidence/player-setup/04-import-open-1280x800-de.png` | `37cbced4c16e786ed48d6cf84e11e2cd79963e483d27050a88e6f38967c83e6f` | 99292 | UI-Prüfartefakt | verändert |
| `docs/evidence/player-setup/05-duplicates-1280x800-de.png` | `55bc94e2dba1087ab6c32fae755e0916527da7db00d22dd0fcab79a0239919be` | 110572 | UI-Prüfartefakt | verändert |
| `docs/evidence/player-setup/06-edit-mode-1280x800-en.png` | `6aa00e9dfb3c04e54c3d81fe1ec447736edbcd67685cca248c9d6b3b0a9779ea` | 89999 | UI-Prüfartefakt | verändert |
| `docs/evidence/player-setup/07-remove-dialog-1280x800-de.png` | `c11aca9873546b4321bc35793cf017c89f57e28947c587b392f29325b587e418` | 96477 | UI-Prüfartefakt | verändert |
| `docs/evidence/player-setup/08-confirmed-1280x800-de.png` | `9533e6638a1e6a264bfcf1320d7ce1a1899b1bf232d8ed2c1eab1dcdd97750d3` | 116986 | UI-Prüfartefakt | verändert |
| `docs/evidence/role-setup/01-roles-suggestion-1024x768-de.png` | `b7e47101176bdeae6929a347e51567d7ddc8f96fdd292187528d3b4c30e863a7` | 122561 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/02-roles-too-few-1024x768-de.png` | `09c431804767544ee633afa581aa5a69cc0cd8b3ea48661f303dcc5c675c1116` | 125252 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/03-roles-valid-manual-1280x800-de.png` | `e66fde631c4408dcdba57bbca5bce13be52adbc475c8b6793aeb660aea3395ea` | 131142 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/04-roles-1280x800-en.png` | `cb41744b6540ce7f7dd94d93508d500c066ad0c8b8a1bedfdc5767aa37e6ed68` | 127334 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/05-suggestion-overwrite-dialog-1280x800-de.png` | `44cd133da205e6f474a092c93468673c2877c34b39921598aba2516ecaa9ee0a` | 115895 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/06-distribution-mode-1024x768-de.png` | `cfde4e63a101f28ea56bf52e58414eb838f4e7b5b39147f63ae2182bef6d86c0` | 117718 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/07-random-hidden-1024x768-de.png` | `4c8d2274b1c5f2078d7b9e39fefe1e8cb211d687dea553edb4f5358dd877402d` | 114821 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/08-secret-open-1280x800-de.png` | `95f9b02b866e61a61dc31796795c7d9b69fb108556561b8fb1d0cfc75bf1ba25` | 120933 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/09-manual-partial-1280x800-de.png` | `6d9ca0ba7851e453212b6f93ff38e6c845a1284e5488833bade006c167232b43` | 125994 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/10-manual-picker-1280x800-de.png` | `36bde0e3e64a93c44295cf0a960d697b4a9f178b3ac521296f87c678ad7a9a28` | 108522 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/11-manual-complete-1280x800-en.png` | `4a4cbd02938cd29ad4f34bbc2c84042e5cc57a3ed2299bc2e10e06faf571c95b` | 119864 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/12-confirmed-ready-1280x800-de.png` | `f62ac16fff26caff0bfb1b75623fc28dfe7efdb7ba27e57f9566789e6d94ff0c` | 128495 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/13-decoy-wolf-secret-1280x800-de.png` | `1f95b9af87d79880ab11838e460b7c3fadf4199d7555152ec3ca4641b29bf085` | 122435 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/14-decoy-missing-1024x768-de.png` | `268a0382bb38de5585f6c771cbe954fea05228e031408405f679a0df479f2f37` | 135609 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/15-decoy-chosen-1280x800-de.png` | `80e513022f0040751c1eed4067fd8f9de8c616a23112ae69260b98f082f7a39d` | 141819 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/16-decoy-two-copies-1024x768-de.png` | `914c50d714d607077223c155f5a51bee92c0bed6c9f35bbbaa16869271c6011e` | 132654 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/17-decoy-manual-picker-1280x800-de.png` | `089d57f672d70c295b1dea873a713056bdb86650a73e04ac0325af54012f96a6` | 121197 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/18-decoy-random-closed-1024x768-de.png` | `e5f47b108f58196bd19be6a6eac3b9f099a1ed7799a04808c1145adf1f857cb4` | 113815 | UI-Prüfartefakt | neu |
| `docs/evidence/role-setup/19-decoy-random-open-1280x800-de.png` | `6973f1e3ea84a95c9af431669018ef943b057079dd35bcf4f989597fdf5959ce` | 122392 | UI-Prüfartefakt | neu |

Prüfsummen neu berechnen: `sha256sum docs/evidence/player-setup/*.png docs/evidence/role-setup/*.png`
