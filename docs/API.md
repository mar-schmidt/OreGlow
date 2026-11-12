# API choices

Research date: 2026-11-12. Installed client metadata: **1.60.1.70888**, `wowf`.
Metadata inspection is not an in-game test.

| Interface | Purpose |
| --- | --- |
| `UnitGUID("softinteract")`, `UnitName("softinteract")` | Require a live GameObject GUID and exact known English ore name. |
| `PLAYER_SOFT_INTERACT_CHANGED` | Documented synchronous event. Payload identities are never read; observe on the next 0.25-second tick. |
| `Minimap:IsMouseOver()` and `C_TooltipInfo.GetMinimapMouseover()` | Read only the real mouse hover. |
| `issecretvalue` | Reject restricted values before comparisons/indexing/formatting. |
| `C_CVar.GetCVar("SoftTargetInteract")` | Explain readiness without writing settings. |
| `InCombatLockdown`, `UnitIsDeadOrGhost`, `UnitOnTaxi` | Suspend observations. |
| `CreateFrame`, `CreateColor`, `Texture:SetGradient` | Four input-transparent gold gradients. |

No broad name matching, combat-log registration, world scan, process inspection
or external program is included. No third-party implementation is bundled.

## References

- [Blizzard addon policy](https://eu.forums.blizzard.com/en/wow/t/wow-user-interface-add-on-development-policy/1642).
- [Minimap restriction #894](https://github.com/Stanzilla/WoWUIBugs/issues/894):
  Nevcairiel describes the 70862 change as intentional, relaying Blizzard's
  position. This is not approval of any alternative method.
- [Exported Unit documentation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua).
- [Exported TooltipInfo documentation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua).
- [CVar documentation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/CVarDocumentation.lua).
- [Soft target flags](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SoftTargetConstantsDocumentation.lua):
  keyboard/mouse 2, any input 3.
- [NodeRadar](https://www.curseforge.com/wow/addons/node-radar):
  the author's restriction report and moving-minimap workaround; OreGlow does
  not implement that workaround.
- [PartyGatherRadar](https://www.curseforge.com/wow/addons/partygatherradar):
  the author's actual hovering/proximity tests, including reported 4–13 m range.
- [OreSentry](https://www.curseforge.com/wow/addons/oresentry):
  the author's interaction-system approach and Interact Key prerequisite.

The export repository mirrors Blizzard code but is not operated by Blizzard.
API documentation does not prove unrestricted access in every live context.
