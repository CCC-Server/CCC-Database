local s,id=GetID()
function s.initial_effect(c)
	--① 패에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	--② 소재로 묘지로 보내졌을 때, 엑시즈 몬스터에 소재 추가
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.matcon)
	e2:SetTarget(s.mattg)
	e2:SetOperation(s.matop)
	c:RegisterEffect(e2)
end

---------------------------------------
--① 패에서 특수 소환
function s.spfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x763) and c:IsType(TYPE_XYZ) and c:GetRank()==4
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE,0,1,nil)
end

---------------------------------------
--② 묘지로 보내졌을 때, 소재 추가 효과
function s.matcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	-- 엑시즈 소재로서 효과 발동 코스트로 묘지로 보내졌을 경우
	return c:IsReason(REASON_COST) and re and re:IsActivated() 
		and re:GetHandler():IsType(TYPE_XYZ) and c:IsPreviousLocation(LOCATION_OVERLAY)
end
function s.xyzfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x763) and c:IsType(TYPE_XYZ)
end
function s.matfilter(c)
	return c:IsSetCard(0x763) and c:IsType(TYPE_NORMAL)
end
function s.mattg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.xyzfilter(chkc) end
	if chk==0 then 
		return Duel.IsExistingTarget(s.xyzfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.xyzfilter,tp,LOCATION_MZONE,0,1,1,nil)
end
function s.matop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.matfilter),tp,LOCATION_DECK+LOCATION_HAND+LOCATION_GRAVE,0,1,1,nil)
	local mg=g:GetFirst()
	if mg then
		Duel.Overlay(tc,mg)
	end
end
