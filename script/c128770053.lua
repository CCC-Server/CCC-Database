--매지컬★시스터-세레니티 화이트
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	-- Synchro Summon Procedure
	Synchro.AddProcedure(c,
		aux.FilterBoolFunctionEx(Card.IsAttribute, ATTRIBUTE_LIGHT), -- 빛 속성 튜너
		1, -- 최소 1장 (튜너)
		99, -- 최대 무제한 (튜너)
		Synchro.NonTunerEx(Card.IsRace, RACE_SPELLCASTER), -- 마법사족 비튜너
		1, -- 최소 1장 (비튜너)
		99 -- 최대 무제한 (비튜너)
	)

	--① 효과: 묘지의 마법사족/빛 속성 몬스터 수만큼 상대 필드 카드 덱으로 되돌리기
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.tdcon)
	e1:SetTarget(s.tdtg)
	e1:SetOperation(s.tdop)
	c:RegisterEffect(e1)

	--② 효과: 특정 효과를 제외한 효과를 받지 않음
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_IMMUNE_EFFECT)
	e2:SetValue(s.immval)
	c:RegisterEffect(e2)

	--③ 효과: 싱크로 소환된 이 카드가 상대에 의해 필드에서 벗어났을 때 레벨 4 몬스터 2장 특수 소환
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_LEAVE_FIELD)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

--① 효과: 싱크로 소환 성공 시 발동 조건
function s.tdcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.tdfilter(c)
	return c:IsAbleToDeck()
end
function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local ct=Duel.GetMatchingGroupCount(Card.IsAttribute,tp,LOCATION_GRAVE,0,nil,ATTRIBUTE_LIGHT)
	if chk==0 then return ct>0 and Duel.IsExistingMatchingCard(s.tdfilter,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,ct,0,LOCATION_ONFIELD)
end
function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local ct=Duel.GetMatchingGroupCount(Card.IsAttribute,tp,LOCATION_GRAVE,0,nil,ATTRIBUTE_LIGHT)
	if ct>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local g=Duel.SelectMatchingCard(tp,s.tdfilter,tp,0,LOCATION_ONFIELD,1,ct,nil)
		if #g>0 then
			Duel.SendtoDeck(g,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		end
	end
end

--② 효과: 면역 효과
function s.immval(e,te)
	return te:GetOwner()~=e:GetOwner() and not te:IsHasProperty(EFFECT_FLAG_CARD_TARGET)
end

--③ 효과: 싱크로 소환된 이 카드가 상대에 의해 벗어났을 때 레벨 4 몬스터 2장 특수 소환
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_SYNCHRO) and c:IsPreviousControler(tp)
end
function s.spfilter(c,e,tp)
	return c:IsLevel(4) and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_SPELLCASTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE+LOCATION_HAND,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_GRAVE+LOCATION_HAND)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	local g=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_GRAVE+LOCATION_HAND,0,nil,e,tp)
	if #g==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=g:Select(tp,1,math.min(2,ft),nil)
	Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_FACEUP)
end
