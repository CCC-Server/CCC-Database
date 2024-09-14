--링크된 자의 
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Link.AddProcedure(c,s.matfilter,1,1)
end
function s.matfilter(c,lc,sumtype,tp)
	return c:GetLevel()==1
end 
