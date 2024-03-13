Duel.LoadScript("proc_archetype.lua")
--초전사
CARD_BLACK_LUSTER_SOLDIER = CARD_BLACK_LUSTER_SOLDIER or 5405694
ARCHETYPE_SUPER_SOLDIER   = SET_SUPER_SOLDIER or ARCHETYPE_SUPER_SOLDIER or 0xf00
Archetype.MakeCheck(0xf00,{
	["초전사의 혼"]=79234734,
	["초전사 카오스 솔저"]=54484652,
	["초전사의 의식"]=14094090,
	["전생의 초전사"]=73694478,
	["초전사의 방패"]=799183,
	["초전사의 맹아"]=45948430
},nil)
