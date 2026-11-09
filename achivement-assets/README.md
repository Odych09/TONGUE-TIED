# Google Play Games Achievements Package

This folder contains the complete, ready-to-upload Google Play Games Services (GPGS) bulk achievement package and individual 512x512 icons for **Tongue Twister: The Frog**.

---

## 📦 What's Inside

1. **`google_play_achievements.zip`**
   * The upload bundle for Google Play Console bulk import.
   * Contains `AchievementsMetadata.csv`, `AchievementsIconsMappings.csv`, and all 12 individual 512x512 PNG achievement icons sitting directly in the root of the archive (no subdirectories, compliant with Google's bulk upload specs).

2. **`AchievementsMetadata.csv`**
   * The metadata definition for all 12 achievements:
     * No header row (as required by Google Play Console).
     * Exact 7-column format: `Name,Description,Incremental value,Steps Needed,Initial State,Points,List Order`.
     * Points for each achievement are multiples of 5 between 5 and 200.
     * Total Points: **800 Points** (leaves a 200-point reserve for future updates under Google's 1,000 cap).

3. **`AchievementsIconsMappings.csv`**
   * Maps each achievement name to its corresponding icon filename.

4. **`icons/`**
   * Uncompressed individual 512x512 transparent pixel art icons (Format32bppArgb) scaled with nearest-neighbor filtering so the pixel art stays razor sharp.

5. **`achievements_template.xml`**
   * Android resource template following the standard Android Play Games format (`res/values/ids.xml`).

---

## 🚀 How to Import into Google Play Console

1. Open the [Google Play Console](https://play.google.com/console) and select your game.
2. In the left menu, navigate to:
   **Play Games Services** → **Setup and management** → **Achievements**.
3. Click the **Import achievements** button (usually in the top right or within the 3 dots menu).
4. Select and upload **`google_play_achievements.zip`**.
5. Once imported:
   * Google Play will automatically create all 12 achievements with their icons, points, and descriptions.
   * Click the **Get resources** button at the top/bottom of the Achievements page.
   * Copy the generated XML or the list of Achievement IDs (they start with `CgkI...`).
6. Paste the IDs back to the AI assistant to start coding the game integration!

---

## 📋 Achievement Summary

| # | Name | Type | Steps | Initial State | Points | Description | Icon File |
|---|------|------|-------|---------------|--------|-------------|-----------|
| 1 | **First Leap** | Standard | - | Revealed | **10** | Complete Level 1 and begin your swamp journey. | `first_leap.png` |
| 2 | **Lily Pad Hopper** | Standard | - | Revealed | **25** | Successfully clear Level 5. | `lily_pad_hopper.png` |
| 3 | **Swamp Navigator** | Standard | - | Revealed | **50** | Conquer Level 10 and survive the deeper swamp hazards. | `swamp_navigator.png` |
| 4 | **Tongue Master** | Standard | - | Revealed | **150** | Complete all 15 handcrafted levels. | `tongue_master.png` |
| 5 | **Beyond the Pond** | Standard | - | Revealed | **75** | Complete your first ASCII bonus level. | `beyond_the_pond.png` |
| 6 | **Stargazer** | Standard | - | Revealed | **25** | Collect a total of 15 stars across your adventures. | `stargazer.png` |
| 7 | **Superstar Frog** | Standard | - | Revealed | **50** | Collect a total of 30 stars across your adventures. | `superstar_frog.png` |
| 8 | **Perfectionist** | Standard | - | Revealed | **150** | Earn a perfect 3-star rating on all 15 levels. | `perfectionist.png` |
| 9 | **Bug Buffet** | Incremental | 50 | Revealed | **75** | Munch on 50 tasty bugs across your adventures. | `bug_buffet.png` |
| 10 | **Frog Gourmet** | Incremental | 100 | Revealed | **125** | Catch 100 bugs with your tongue. | `frog_gourmet.png` |
| 11 | **Clutch Pull** | Standard | - | Revealed | **50** | Clear a level with exactly your final pull remaining. | `clutch_pull.png` |
| 12 | **Bonk!** | Standard | - | Hidden (Secret) | **15** | Stretch your tongue straight into a wall. Ouch! | `bonk.png` |
| **Total** | | | | | **800** | | |
