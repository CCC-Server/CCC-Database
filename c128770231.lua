--Sparkle Arcadia Synchro Example
local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환 조건
	Synchro.AddProcedure(c,aux.FilterBoolFunction(Card.IsType,TYPE_TUNER),1,1,Synchro.NonTunerEx(Card.IsSetCard,0x760),1,99)
	c:EnableReviveLimit()

	--① 이번 턴에 특수 소환된 상대 몬스터의 효과 무효화
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_DISABLE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetTargetRange(0,LOCATION_MZONE)
	e1:SetTarget(s.distg)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EFFECT_DISABLE_EFFECT)
	e1b:SetValue(RESET_TURN_SET)
	c:RegisterEffect(e1b)

	--② 뒷면표시 마법/함정 카드 발동 봉쇄 (1턴에 1번)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DISABLE)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_NO_TURN_RESET)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
end

--① 이번 턴에 특수 소환된 상대 몬스터 무효
function s.distg(e,c)
	return c:IsSummonType(SUMMON_TYPE_SPECIAL) and c:GetSummonPlayer()==1-e:GetHandlerPlayer()
		and Duel.GetTurnCount()==c:GetTurnID()
end

--② 효과 - 마함 봉쇄 관련
function s.filter(c)
	return c:IsFacedown() and c:IsOnField() and c:IsSpellTrap()
end
function s.arccount(tp)
	return Duel.GetMatchingGroupCount(aux.FaceupFilter(Card.IsSetCard,0x760),tp,LOCATION_MZONE,0,nil)
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local max=s.arccount(tp)
	if chkc then return chkc:IsControler(1-tp) and s.filter(chkc) end
	if chk==0 then return max>0 and Duel.IsExistingTarget(s.filter,tp,0,LOCATION_SZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.filter,tp,0,LOCATION_SZONE,1,max,nil)
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,g,#g,0,0)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetTargetCards(e)
	if not c:IsRelateToEffect(e) or #g==0 then return end
	local tc=g:GetFirst()
	for tc in aux.Next(g) do
		--발동 불가 설정
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_FIELD)
		e1:SetCode(EFFECT_CANNOT_TRIGGER)
		e1:SetRange(LOCATION_MZONE)
		e1:SetTargetRange(0,LOCATION_SZONE)
		e1:SetTarget(function(e2,c2) return c2==tc end)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end
end
