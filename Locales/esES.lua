-- esES/esMX locale

if ( GetLocale() == "esES" or GetLocale() == "esMX" ) then
	TriviaBotLocalization = setmetatable( {
			-- Zones --
-- 			TB_ZONE_AB = "Arathi Basin",
-- 			TB_ZONE_WSG = "Warsong Gulch",
-- 			TB_ZONE_AV = "Alterac Valley",
-- 			TB_ZONE_EOTS = "Eye of the Storm",
-- 			TB_ZONE_SOTA = "Strand of the Ancients",
-- 			TB_ZONE_IOC = "Isle of Conquest",
-- 			TB_ZONE_TBFG = "The Battle for Gilneas",
-- 			TB_ZONE_TP = "Twin Peaks",
			-- GUI --
-- 			TB_GUI_WIDTH = "350", -- v2.8.0.1
-- 			TB_GUI_PRINT_WIDTH = "45", -- v2.8.0.1
-- 			TB_GUI_UPDATE_WIDTH = "70", -- v2.8.0.1
	}, { __index = TriviaBotLocalization; } );
end 