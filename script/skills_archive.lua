Duel.LoadScript("proc_skill_links.lua")

-- constants
SKILL_COVER_ARCHIVE_START    = 301000003
SKILL_COVER_ARCHIVE_ACTIVATE = 302000003

-- proc for memorize starting LP
Duel.GetStartingLP=nil
local startinglp_check=false
Auxiliary.addStartingLPCheck=function()
	if startinglp_check then return end
	startinglp_check=true
	local t={}
	t[0]=Duel.GetLP(0)
	t[1]=Duel.GetLP(1)
	Duel.GetStartingLP=function(tp)
		return t[tp]
	end
end
