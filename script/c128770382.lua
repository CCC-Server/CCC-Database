local s,id=GetID()
function s.initial_effect(c)
	 -- 싱크로 소환 조건
	Synchro.AddProcedure(c,nil,1,1,aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_FIRE),1,99)
	c:EnableReviveLimit()

	-- ① 싱크로 소환 성공 시 묘지로 보내기
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOGRAVE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.tgcon)
	e1:SetTarget(s.tgtg)
	e1:SetOperation(s.tgop)
	c:RegisterEffect(e1)

	-- ② 라바르 카드가 효과로 파괴될 경우, 묘지의 라바르 몬스터 1장 제외로 대체
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	e2:SetCountLimit(1,{id,1})
	c:RegisterEffect(e2)
end

-- 🔹소재 조건: 튜너 + 튜너 이외 화염속성
function s.matfilter(c,sc,sumtype,tp)
	return c:IsAttribute(ATTRIBUTE_FIRE) and not c:IsType(TYPE_TUNER)
end

-- 🔹① 싱크로 소환 성공 체크
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.tgfilter(c)
	return c:IsSetCard(0x39) and c:IsMonster() and c:IsAbleToGrave()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

-- 🔹② 파괴 대체 효과
function s.repfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0x39) and c:IsOnField()
		and c:IsControler(tp) and c:IsReason(REASON_EFFECT)
end
function s.remfilter(c)
	return c:IsSetCard(0x39) and c:IsMonster() and c:IsAbleToRemove()
end
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return eg:IsExists(s.repfilter,1,nil,tp)
			and Duel.IsExistingMatchingCard(s.remfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	return Duel.SelectEffectYesNo(tp,e:GetHandler(),aux.Stringid(id,1))
end
function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.remfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_EFFECT)
end
