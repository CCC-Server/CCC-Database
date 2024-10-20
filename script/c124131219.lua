--一時休戦
--One Day of Peace
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.pltg)
	e1:SetOperation(s.plop)
	c:RegisterEffect(e1)
end
    	--Register that a player has activated "Millennium Ankh" during this Duel
		aux.GlobalCheck(s,function()
			local ge1=Effect.CreateEffect(c)
			ge1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
			ge1:SetCode(EVENT_CHAIN_SOLVED)
			ge1:SetOperation(s.regop)
			Duel.RegisterEffect(ge1,0)
		end)
	end
	s.listed_names={95308449} --"종언의 카운트 다운"
	function s.regop(e,tp,eg,ep,ev,re,r,rp)
		if not Duel.HasFlagEffect(rp,id) and re:GetHandler():IsCode(95308449) and re:IsHasType(EFFECT_TYPE_ACTIVATE) then
			Duel.RegisterFlagEffect(rp,id,0,0,0)
		end
	end
    function s.plfilter(c,tp)
        return c:IsContinuousTrap() and not c:IsForbidden() and c:CheckUniqueOnField(tp)
    end
    function s.pltg(e,tp,eg,ep,ev,re,r,rp,chk)
        if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
            and Duel.IsExistingMatchingCard(s.plfilter,tp,LOCATION_HAND,0,1,nil,tp) end
    end
    function s.plop(e,tp,eg,ep,ev,re,r,rp)
        if Duel.GetLocationCount(tp,LOCATION_SZONE)==0 then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
        local tc=Duel.SelectMatchingCard(tp,s.plfilter,tp,LOCATION_HAND,0,1,1,nil,tp):GetFirst()
        if tc then
            Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
        end
    end