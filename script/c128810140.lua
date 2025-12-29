--헤블론-악몽의 네르베
local s,id=GetID()
function s.initial_effect(c)
	-- ①: 몬스터 3장 이상을 소재로 하는 빛/어둠 속성 엑시즈 몬스터를 엑시즈 소환할 경우, 이 카드는 2장만큼의 엑시즈 소재로 할 수 있다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_XYZ_MATERIAL_COUNT)
	e1:SetCondition(s.xyzmatcon)
	e1:SetValue(2)
	c:RegisterEffect(e1)
	
	-- ②: 이 카드가 필드 이외에서 묘지로 보내졌을 경우 덱에서 "헤블론" 마법/함정 카드 1장을 자신 필드에 세트
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOFIELD)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.tgcon)
	e2:SetTarget(s.tgtg)
	e2:SetOperation(s.tgop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc06}

-- ① 조건: 몬스터 3장 이상을 소재로 하는 빛/어둠 속성 엑시즈 몬스터
function s.xyzmatcon(e,c,tp)
	local mc=c:GetMaterialCount(tp)
	local rk=c:GetRank()
	local attribute=c:GetAttribute()
	return mc>=3 and (attribute==ATTRIBUTE_LIGHT or attribute==ATTRIBUTE_DARK)
end

-- ② 발동 조건: 필드 이외에서 묘지로 보내졌을 경우
function s.tgcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return not c:IsPreviousLocation(LOCATION_ONFIELD)
end

-- ② 타겟: 덱에서 "헤블론" 마법/함정 카드 1장을 자신 필드에 세트
function s.tgfilter(c)
	return c:IsSetCard(0xc06) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and not c:IsForbidden()
end

function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
			and Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOFIELD,nil,1,tp,LOCATION_DECK)
end

-- ② 처리: 덱에서 "헤블론" 마법/함정 카드 1장을 자신 필드에 세트
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	local tc=g:GetFirst()
	if tc then
		Duel.SSet(tp,tc)
	end
end
