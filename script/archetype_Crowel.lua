Duel.LoadScript("proc_archetype.lua")
--령술사
CARD_SPIRITUAL_LIGHT_ART = CARD_SPIRITUAL_LIGHT_ART or 5037726
CARD_DARK_SPIRIT_ART     = CARD_DARK_SPIRIT_ART     or 38167722
ARCHETYPE_SPIRITUAL_ART  = SET_SPIRITUAL_ART or ARCHETYPE_SPIRITUAL_ART or 0x14d
ARCHETYPES_SPIRITUAL     = {0xd01,0xd05}
ARCHETYPE_SPIRITUAL_LIGHT_ART = 0x9d01
ARCHETYPE_DARK_SPIRIT_ART     = 0xcd01
ARCHETYPE_SPIRITUALIST   = 0xd05 --reserved
Archetype.MakeCheck(ARCHETYPE_SPIRITUAL_ART,nil,ARCHETYPES_SPIRITUAL)
Archetype.MakeCheck(ARCHETYPE_SPIRITUAL_LIGHT_ART,{
	["광령술-「성」"]=5037726
},nil)
Archetype.MakeCheck(ARCHETYPE_DARK_SPIRIT_ART,{
	["암령술-\"욕망\""]=5037726
},nil)
Archetype.MakeCheck(ARCHETYPE_SPIRITUALIST,{
	["승령술사 조겐"]=41855169,
	["묘지기의 영술사"]=58657303,
	--"령술사" 지정 카드가 없어서 cdb에서 생략한 부분 처리
	["광령술사 라이너"]=124061011,
	["암령술사 달크"]=124061012,
	["지령술사 아우스"]=124061013,
	["수령술사 에리아"]=124061014,
	["화령술사 히타"]=124061015,
	["풍령술사 윈"]=124061016,
	["정령술사의 기도"]=124061020
},nil)
--드리야드
ARCHETYPE_DORIADO = SET_DORIADO or ARCHETYPE_DORIADO or 0xd02
Archetype.MakeCheck(ARCHETYPE_DORIADO,{
	["드리야드"]=84916669,
	["엘리멘틀 마스터 드리야드"]=99414168,
	["드리야드의 기도"]=23965037,
	["다크 드리야드"]=62312469,
	["엘리멘틀 그레이스 드리야드"]=32965616
},nil)
