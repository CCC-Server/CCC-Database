--Tramid Processor (가칭)
local s,id=GetID()
function s.initial_effect(c)
	--① 드로우 이외로 패에 들어왔을 때 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_TO_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--② 소환 성공시 지속 마/함 세트 (※ 필드 마법 제외됨)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	--③ 필드 마법 교체 (상대 턴 1회)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_TOGRAVE)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,{id,2})
	e4:SetCondition(s.fldcon)
	e4:SetTarget(s.fldtg)
	e4:SetOperation(s.fldop)
	c:RegisterEffect(e4)
end

--① 드로우 이외로 패에 들어오면 발동
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return not c:IsPublic() and re and (re:GetHandler()~=c or r~=REASON_DRAW)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
	end
end

--② 지속 마법 / 함정 세트 (※ 필드 마법 제외됨)
function s.setfilter(c)
	return c:IsSetCard(0xe2)
		and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP))
		and c:IsType(TYPE_CONTINUOUS)
		and not c:IsType(TYPE_FIELD) -- 필드 마법 제외
		and not c:IsForbidden()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.MoveToField(g:GetFirst(),tp,tp,LOCATION_SZONE,POS_FACEUP,true)
	end
end

--③ 필드 마법 교체 (상대 턴)
function s.fldcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
end
function s.fldfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0xe2) and c:IsType(TYPE_FIELD) and Duel.IsExistingMatchingCard(s.fldnewfilter,tp,LOCATION_DECK,0,1,nil,c:GetCode(),tp)
end
function s.fldnewfilter(c,code,tp)
	return c:IsSetCard(0xe2) and c:IsType(TYPE_FIELD) and not c:IsCode(code) and c:GetActivateEffect():IsActivatable(tp,true,true)
end
function s.fldtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.fldfilter,tp,LOCATION_SZONE,LOCATION_SZONE,1,nil,tp) end
end
function s.fldop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2))
	local g=Duel.SelectMatchingCard(tp,s.fldfilter,tp,LOCATION_SZONE,LOCATION_SZONE,1,1,nil,tp)
	local tc=g:GetFirst()
	if tc and Duel.SendtoGrave(tc,REASON_EFFECT)~=0 and tc:IsLocation(LOCATION_GRAVE) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
		local sg=Duel.SelectMatchingCard(tp,s.fldnewfilter,tp,LOCATION_DECK,0,1,1,nil,tc:GetCode(),tp)
		if #sg>0 then
			Duel.ActivateFieldSpell(sg:GetFirst(),e,tp)
		end
	end
end
