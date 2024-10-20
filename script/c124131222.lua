--종말의 기도
local s,id=GetID()
function s.initial_effect(c)
	--Activate
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)
    --Place 1 "Branded" Continuous Spell/Trap on the field
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1)
	e3:SetTarget(s.target)
	e3:SetOperation(s.activate)
	c:RegisterEffect(e3)
    --Place 1 "Branded" Continuous Spell/Trap on the field
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_SZONE)
	e3:SetHintTiming(TIMING_END_PHASE)
	e3:SetCountLimit(1,id)
    e3:SetCondition(s.discon)
	e3:SetTarget(s.tftg)
	e3:SetOperation(s.tfop)
	c:RegisterEffect(e3)
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
    function s.filter(c)
        return c:IsSpellTrap() and c:IsType(TYPE_CONTINUOUS) and c:IsDiscardable(REASON_EFFECT)
    end
    function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
        if chk==0 then return Duel.IsPlayerCanDraw(tp,2)
            and Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_HAND,0,1,e:GetHandler()) end
        Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,2)
    end
    function s.activate(e,tp,eg,ep,ev,re,r,rp)
        if Duel.DiscardHand(tp,s.filter,1,1,REASON_EFFECT+REASON_DISCARD,nil)~=0 then
            Duel.BreakEffect()
            Duel.Draw(tp,2,REASON_EFFECT)
        end
    end
    
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.HasFlagEffect(tp,id)
end

function s.plsfilter(c,tp)
	return c:IsSpellTrap() and c:IsType(TYPE_CONTINUOUS) and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end
function s.tftg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.plsfilter,tp,LOCATION_HAND,0,1,nil,tp) end
end
function s.tfop(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsExistingMatchingCard(s.plsfilter,tp,LOCATION_HAND,0,1,nil,tp) then end
	if Duel.GetLocationCount(tp,LOCATION_SZONE)==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local tc
	tc=Duel.SelectMatchingCard(tp,s.plsfilter,tp,LOCATION_HAND,0,1,1,nil,tp):GetFirst()
	if tc then
		Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end